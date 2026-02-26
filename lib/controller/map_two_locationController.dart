import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
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
  RxBool isAutoFollow = true.obs;

  var markers = <Marker>{}.obs;
  var polylines = <Polyline>{}.obs;

  LatLng? start, end;

  RxString selectedMode = "driving".obs;
  RxString distanceText = "".obs;
  RxString durationText = "".obs;

  RxBool isNavigating = false.obs;
  StreamSubscription<Position>? positionStream;

  var stepsList = <Map<String, dynamic>>[].obs;

  final String apiKey = "AIzaSyB4OsZKR2hF7xBBCJR8sM2b6xf17v5DWZs";

  Future<void> _drawRoute() async {
    if (start == null || end == null) return;

    String transitParams = selectedMode.value == "transit" ? "&departure_time=now" : "";
    final url = "https://maps.googleapis.com/maps/api/directions/json?"
        "origin=${start!.latitude},${start!.longitude}"
        "&destination=${end!.latitude},${end!.longitude}"
        "&mode=${selectedMode.value}"
        "$transitParams"
        "&alternatives=false"
        "&key=$apiKey";

    try {
      final response = await http.get(Uri.parse(url));
      final data = jsonDecode(response.body);

      if (data["status"] != "OK" || data["routes"].isEmpty) {
        Get.snackbar("Route Error", "No route found");
        return;
      }

      final route = data["routes"][0];
      final leg = route["legs"][0];

      distanceText.value = leg["distance"]["text"];
      durationText.value = leg["duration"]["text"];

      stepsList.clear();
      List<LatLng> detailedCoordinates = [];
      for (var step in leg["steps"]) {
        stepsList.add({
          "instruction": step["html_instructions"].replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ""),
          "distance": step["distance"]["text"],
          "maneuver": step["maneuver"] ?? "straight",
        });

        var points = _decodePoly(step["polyline"]["points"]);
        detailedCoordinates.addAll(points);
      }

      polylines.value = {
        Polyline(
          polylineId: const PolylineId("route"),
          points: detailedCoordinates, // હવે અહીં પ્રોપર રોડ પોઈન્ટ્સ છે
          color: Colors.blueAccent,
          width: 7, // લાઈન થોડી જાડી રાખવી જેથી રોડ કવર થાય
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          geodesic: true, // પૃથ્વીના ગોળાકાર વળાંક મુજબ લાઈન સેટ થશે
        )
      };

      if (!isNavigating.value) {
        _fitRoute(detailedCoordinates);
      }
      _updateMarkers();

    } catch (e) {
      Get.snackbar("Error", "Failed to fetch directions");
    }
  }

  void startNavigation() async {
    isNavigating.value = true;
    isAutoFollow.value = true;

    if (polylines.isNotEmpty && polylines.first.points.isNotEmpty) {
      List<LatLng> routePoints = polylines.first.points.toList();
      LatLng snapToRoadStart = routePoints.first;
      double initialHeading = 0.0;

      if (routePoints.length > 1) {
        initialHeading = Geolocator.bearingBetween(
            snapToRoadStart.latitude, snapToRoadStart.longitude,
            routePoints[1].latitude, routePoints[1].longitude
        );
      }

      mapController?.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          target: snapToRoadStart,
          zoom: 19,
          tilt: 65,
          bearing: initialHeading,
        ),
      ));

      _updateNavigationMarker(snapToRoadStart, initialHeading);
    }

    positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0
      ),
    ).listen((Position position) {
      if (position.heading != 0) {
        _updateNavigationMarker(
            LatLng(position.latitude, position.longitude),
            position.heading
        );
      }
    });
  }

  void _updateNavigationMarker(LatLng pos, double heading) async {
    markers.removeWhere((m) => m.markerId.value == "nav_arrow" || m.markerId.value == "start");

    Uint8List? markerIcon;
    if (selectedVehicleIcon.value.isNotEmpty) {
      markerIcon = await getBytesFromAsset(selectedVehicleIcon.value, 110);
    }

    markers.add(
      Marker(
        markerId: const MarkerId("nav_arrow"),
        position: pos,
        icon: markerIcon != null
            ? BitmapDescriptor.fromBytes(markerIcon)
            : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        rotation: heading + 90,
        flat: true,
        anchor: const Offset(0.5, 0.5),
        zIndex: 15,
      ),
    );

    if (isAutoFollow.value) {
      mapController?.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          target: pos,
          zoom: 19,
          tilt: 65,
          bearing: heading,
        ),
      ));
    }
    markers.refresh();
  }

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
      if (result & 1 == 1) {
        result = ~result;
      }
      var result1 = (result >> 1) * 0.00001;
      lList.add(result1);
    } while (index < len);

    for (var i = 2; i < lList.length; i++) {
      lList[i] += lList[i - 2];
    }

    List<LatLng> res = [];
    for (var i = 0; i < lList.length; i += 2) {
      res.add(LatLng(lList[i], lList[i + 1]));
    }
    return res;
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  }

  void _updateMarkers() async {
    BitmapDescriptor startIcon;

    if (selectedVehicleIcon.value.isNotEmpty) {
      try {
        // 100-120 width standard Google Maps car size mate perfect che
        final Uint8List markerIcon = await getBytesFromAsset(selectedVehicleIcon.value, 120);
        startIcon = BitmapDescriptor.fromBytes(markerIcon);
      } catch (e) {
        startIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      }
    } else {
      startIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    }

    markers.value = {
      Marker(
        markerId: const MarkerId("start"),
        position: start!,
        icon: startIcon,
        anchor: const Offset(0.5, 0.5),
        rotation: 0, // Jyare navigation chalu thase tyare heading pramane badlase
      ),
      if (end != null)
        Marker(
          markerId: const MarkerId("end"),
          position: end!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
    };
  }

  void updateVehicleIcon(String assetPath) {
    selectedVehicleIcon.value = assetPath;
    _updateMarkers();
  }

  Future<void> setPointFromAddress(String address, bool isStart) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isEmpty) return;
      await setPoint(LatLng(locations.first.latitude, locations.first.longitude), isStart);
    } catch (e) {
      Get.snackbar("Error", "Location not found");
    }
  }

  Future<void> setPoint(LatLng point, bool isStart) async {
    if (isStart) start = point; else end = point;
    _updateMarkers();
    if (start != null && end != null) await _drawRoute();
    else mapController?.animateCamera(CameraUpdate.newLatLngZoom(point, 15));
  }

  Future<void> updateTravelMode(String mode) async {
    if (selectedMode.value == mode) return;
    selectedMode.value = mode;
    if (start != null && end != null) await _drawRoute();
  }

  void _fitRoute(List<LatLng> points) {
    if (mapController == null || points.isEmpty) return;
    LatLngBounds bounds;
    double minLat = points.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
    double maxLat = points.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
    double minLng = points.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
    double maxLng = points.map((p) => p.longitude).reduce((a, b) => a > b ? a : b);
    bounds = LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng));
    mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 70));
  }

  Future<void> useCurrentLocation(bool isStart, TextEditingController controller) async {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    LatLng current = LatLng(position.latitude, position.longitude);
    controller.text = "Your Location";
    if (isStart) start = current; else end = current;
    _updateMarkers();
    if (start != null && end != null) await _drawRoute();
  }

  void clearRouteInfo() {
    positionStream?.cancel();
    isNavigating.value = false;
    start = null; end = null;
    markers.clear(); polylines.clear();
    distanceText.value = ""; durationText.value = "";
    stepsList.clear();
  }

  @override
  void onClose() {
    positionStream?.cancel();
    super.onClose();
  }
}