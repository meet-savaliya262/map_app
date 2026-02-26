import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:map_app/constant/colorconstant.dart';

class TwoMapRouteController extends GetxController {
  GoogleMapController? mapController;

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

      // 🔹 મહત્વનો સુધારો: Overview ની જગ્યાએ દરેક Step ની પોઈન્ટ લાઈન ભેગી કરવી
      // આનાથી લાઈન રોડના દરેક વળાંક પર પ્રોપર 'Snap to Road' થશે
      for (var step in leg["steps"]) {
        stepsList.add({
          "instruction": step["html_instructions"].replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ""),
          "distance": step["distance"]["text"],
          "maneuver": step["maneuver"] ?? "straight",
        });

        // દરેક નાના વળાંકના પોઈન્ટ્સ ડિકોડ કરીને લિસ્ટમાં ઉમેરો
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
    markers.removeWhere((m) => m.markerId.value == "start");

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
    positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1,
      ),
    ).listen((Position position) {
      LatLng currentLatLng = LatLng(position.latitude, position.longitude);

      mapController?.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          target: currentLatLng,
          zoom: 19,
          tilt: 60,
          bearing: position.heading,
        ),
      ));
      _updateNavigationMarker(currentLatLng, position.heading);
    });
  }

  void _updateNavigationMarker(LatLng pos, double heading) {
    markers.removeWhere((m) => m.markerId.value == "nav_arrow");

    markers.add(
      Marker(
        markerId: const MarkerId("nav_arrow"),
        position: pos,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        rotation: heading,
        flat: true,
        anchor: const Offset(0.5, 0.5),
      ),
    );
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

  // જુના અન્ય ફંક્શન (SetPoint, UpdateMarkers વગેરે)
  void _updateMarkers() {
    markers.value = {
      if (start != null && !isNavigating.value)
        Marker(
          markerId: const MarkerId("start"),
          position: start!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      if (end != null)
        Marker(
          markerId: const MarkerId("end"),
          position: end!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
    };
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