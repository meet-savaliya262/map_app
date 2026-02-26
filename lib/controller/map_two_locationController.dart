import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

class TwoMapRouteController extends GetxController {
  GoogleMapController? mapController;
  RxString selectedVehicleIcon = "".obs;
  RxDouble currentBearing = 0.0.obs;
  RxBool isAutoFollow = true.obs;

  var markers = <Marker>{}.obs;
  var polylines = <Polyline>{}.obs;

  LatLng? start, end;

  RxString selectedMode = "driving".obs;
  RxString distanceText = "".obs;
  RxString durationText = "".obs;
  RxString remainingDistanceText = "".obs;
  RxString remainingDurationText = "".obs;
  RxDouble currentSpeed = 0.0.obs;

  RxBool isNavigating = false.obs;
  StreamSubscription<Position>? positionStream;

  var stepsList = <Map<String, dynamic>>[].obs;
  RxInt currentStepIndex = 0.obs;
  List<LatLng> routePoints = [];

  final String apiKey = "AIzaSyB4OsZKR2hF7xBBCJR8sM2b6xf17v5DWZs";
  final double offRouteThreshold = 60.0;

  // રૂટ ડ્રો કરવાનું ફંક્શન - હવે તે સુપર ફાસ્ટ છે
  Future<void> _drawRoute() async {
    if (start == null || end == null) return;

    final url = "https://maps.googleapis.com/maps/api/directions/json?"
        "origin=${start!.latitude},${start!.longitude}"
        "&destination=${end!.latitude},${end!.longitude}"
        "&mode=${selectedMode.value}"
        "&key=$apiKey";

    try {
      final response = await http.get(Uri.parse(url));
      final data = jsonDecode(response.body);

      if (data["status"] == "OK") {
        final route = data["routes"][0];
        final leg = route["legs"][0];

        // ડેટા તાત્કાલિક અપડેટ કરો
        distanceText.value = leg["distance"]["text"];
        durationText.value = leg["duration"]["text"];
        remainingDistanceText.value = distanceText.value;
        remainingDurationText.value = durationText.value;

        stepsList.clear();
        routePoints.clear();
        List<LatLng> detailedCoordinates = [];

        for (var step in leg["steps"]) {
          stepsList.add({
            "instruction": step["html_instructions"].replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ""),
            "distance": step["distance"]["text"],
            "maneuver": step["maneuver"] ?? "straight",
            "end_location": LatLng(step["end_location"]["lat"], step["end_location"]["lng"]),
          });

          var points = _decodePoly(step["polyline"]["points"]);
          detailedCoordinates.addAll(points);
          routePoints.addAll(points);
        }

        polylines.value = {
          Polyline(
            polylineId: const PolylineId("route"),
            points: detailedCoordinates,
            color: Colors.blueAccent,
            width: 7,
            jointType: JointType.round,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
          )
        };

        if (!isNavigating.value) {
          _fitRoute(detailedCoordinates);
        }
        _updateMarkers();
      } else {
        // ખોટી સ્નેકબાર એરર રોકવા માટે અહીં કન્ડિશન મૂકી છે
        if(data["status"] == "ZERO_RESULTS") {
          Get.snackbar("Route Info", "No path found for ${selectedMode.value}");
        }
      }
    } catch (e) {
      print("Error fetching directions: $e");
    }
  }

  void startNavigation() async {
    isNavigating.value = true;
    isAutoFollow.value = true;
    currentStepIndex.value = 0;

    if (routePoints.isNotEmpty) {
      LatLng snapToRoadStart = routePoints.first;
      _updateNavigationMarker(snapToRoadStart, 0.0);

      mapController?.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: snapToRoadStart, zoom: 19, tilt: 65),
      ));
    }

    positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5),
    ).listen((Position position) async {
      LatLng currentPos = LatLng(position.latitude, position.longitude);
      currentSpeed.value = position.speed * 3.6;

      if (await _isOffRoute(currentPos)) {
        start = currentPos;
        _drawRoute();
      }

      _updateRemaining(currentPos, position.speed);
      _updateCurrentStep(currentPos);
      _updateNavigationMarker(currentPos, position.heading);

      if (isAutoFollow.value) {
        mapController?.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: currentPos, zoom: 19, tilt: 65, bearing: position.heading),
        ));
      }
    });
  }

  // ETA (Time) પ્રોપર બતાવવા માટે સુધારો
  void _updateRemaining(LatLng currentPos, double speed) {
    if (routePoints.isEmpty) return;

    int closestIndex = 0;
    double minDist = double.infinity;
    for (int i = 0; i < routePoints.length; i++) {
      double dist = Geolocator.distanceBetween(currentPos.latitude, currentPos.longitude, routePoints[i].latitude, routePoints[i].longitude);
      if (dist < minDist) { minDist = dist; closestIndex = i; }
    }

    double remainingDist = 0.0;
    for (int i = closestIndex; i < routePoints.length - 1; i++) {
      remainingDist += Geolocator.distanceBetween(routePoints[i].latitude, routePoints[i].longitude, routePoints[i+1].latitude, routePoints[i+1].longitude);
    }

    remainingDistanceText.value = "${(remainingDist / 1000).toStringAsFixed(1)} km";

    // જો ગાડી ઉભી હોય તો ઓરિજિનલ ટાઈમ બતાવો, બાકી ગણતરી કરો
    if (speed < 1.0) {
      remainingDurationText.value = durationText.value;
    } else {
      double remainingSeconds = remainingDist / speed;
      int hours = (remainingSeconds / 3600).floor();
      int mins = ((remainingSeconds % 3600) / 60).floor();
      remainingDurationText.value = hours > 0 ? "$hours hr $mins min" : "$mins min";
    }
  }

  // બેક આવવા પર અને ક્લોઝ કરવા પર બધું પરફેક્ટ ક્લીન કરવા માટે
  void clearRouteInfo() {
    positionStream?.cancel();
    isNavigating.value = false;
    polylines.clear();
    markers.clear();
    distanceText.value = "";
    durationText.value = "";
    remainingDistanceText.value = "";
    remainingDurationText.value = "";
    stepsList.clear();
    routePoints.clear();
    currentStepIndex.value = 0;
    // અગત્યનું: start/end લોકેશનને null ન કરો જેથી સર્ચમાં વેલ્યુ રહે પણ રૂટ રીસેટ થઈ જાય
  }

  Future<void> updateTravelMode(String mode) async {
    if (selectedMode.value == mode) return;
    selectedMode.value = mode;
    // મોડ બદલાતા જ તરત જ રૂટ ડ્રો કરો
    if (start != null && end != null) {
      await _drawRoute();
    }
  }

  // બાકીના હેલ્પર ફંક્શન્સ (decodePoly, markers, fitRoute) સેમ રાખવા...
  List<LatLng> _decodePoly(String poly) {
    var list = poly.codeUnits;
    var lList = <double>[];
    int index = 0;
    int len = poly.length;
    int c = 0;
    do {
      var shift = 0;
      int result = 0;
      do {
        c = list[index] - 63;
        result |= (c & 0x1F) << (shift);
        index++;
        shift += 5;
      } while (c >= 32);
      if (result & 1 == 1) result = ~result;
      var result1 = (result >> 1) * 0.00001;
      lList.add(result1);
    } while (index < len);

    for (var i = 2; i < lList.length; i++) lList[i] += lList[i - 2];

    List<LatLng> res = [];
    for (var i = 0; i < lList.length; i += 2) res.add(LatLng(lList[i], lList[i + 1]));
    return res;
  }

  void _updateMarkers() async {
    if (start == null) return;
    BitmapDescriptor startIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);

    if (selectedVehicleIcon.value.isNotEmpty) {
      final Uint8List iconData = await getBytesFromAsset(selectedVehicleIcon.value, 110);
      startIcon = BitmapDescriptor.fromBytes(iconData);
    }

    markers.value = {
      Marker(markerId: const MarkerId("start"), position: start!, icon: startIcon, anchor: const Offset(0.5, 0.5)),
      if (end != null) Marker(markerId: const MarkerId("end"), position: end!, icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)),
    };
  }

  Future<void> setPoint(LatLng point, bool isStart) async {
    if (isStart) start = point; else end = point;
    _updateMarkers();
    if (start != null && end != null) _drawRoute();
    else mapController?.animateCamera(CameraUpdate.newLatLngZoom(point, 15));
  }

  Future<void> setPointFromAddress(String address, bool isStart) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        await setPoint(LatLng(locations.first.latitude, locations.first.longitude), isStart);
      }
    } catch (e) { print("Geocoding error: $e"); }
  }

  void _fitRoute(List<LatLng> points) {
    if (mapController == null || points.isEmpty) return;
    double minLat = points.map((p) => p.latitude).reduce(math.min);
    double maxLat = points.map((p) => p.latitude).reduce(math.max);
    double minLng = points.map((p) => p.longitude).reduce(math.min);
    double maxLng = points.map((p) => p.longitude).reduce(math.max);
    mapController!.animateCamera(CameraUpdate.newLatLngBounds(LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng)), 70));
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  }

  Future<bool> _isOffRoute(LatLng pos) async {
    double minDist = double.infinity;
    for (var point in routePoints) {
      double dist = Geolocator.distanceBetween(pos.latitude, pos.longitude, point.latitude, point.longitude);
      if (dist < minDist) minDist = dist;
    }
    return minDist > offRouteThreshold;
  }

  void _updateCurrentStep(LatLng currentPos) {
    if (currentStepIndex.value < stepsList.length - 1) {
      LatLng stepEnd = stepsList[currentStepIndex.value]["end_location"];
      if (Geolocator.distanceBetween(currentPos.latitude, currentPos.longitude, stepEnd.latitude, stepEnd.longitude) < 25) {
        currentStepIndex.value++;
      }
    }
  }

  void _updateNavigationMarker(LatLng pos, double heading) async {
    markers.removeWhere((m) => m.markerId.value == "nav_arrow" || m.markerId.value == "start");
    Uint8List? markerIcon;
    if (selectedVehicleIcon.value.isNotEmpty) markerIcon = await getBytesFromAsset(selectedVehicleIcon.value, 110);

    markers.add(Marker(
      markerId: const MarkerId("nav_arrow"),
      position: pos,
      icon: markerIcon != null ? BitmapDescriptor.fromBytes(markerIcon) : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      rotation: heading,
      flat: true,
      anchor: const Offset(0.5, 0.5),
      zIndex: 15,
    ));
    markers.refresh();
  }

  Future<void> useCurrentLocation(bool isStart, TextEditingController controller) async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      LatLng current = LatLng(position.latitude, position.longitude);
      controller.text = "Your Location";
      if (isStart) start = current; else end = current;
      _updateMarkers();

      if (start != null && end != null) {
        _drawRoute();
      } else {
        mapController?.animateCamera(CameraUpdate.newLatLngZoom(current, 15));
      }
    } catch (e) {
      Get.snackbar("Error", "Could not get current location: $e");
    }
  }

  void updateVehicleIcon(String assetPath) {
    selectedVehicleIcon.value = assetPath;
    _updateMarkers();
  }

}