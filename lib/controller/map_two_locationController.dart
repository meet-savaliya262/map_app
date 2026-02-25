import 'dart:convert';
import 'package:flutter/material.dart';
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
  var distanceText = "".obs, durationText = "".obs;
  var showInfo = false.obs;
  var stepsList = <Map<String, dynamic>>[].obs;

  final String apiKey = "AIzaSyB4OsZKR2hF7xBBCJR8sM2b6xf17v5DWZs";

  // ૧. નવું ફંક્શન: જે એડ્રેસ (String) માંથી LatLng મેળવશે
  Future<void> setPointFromAddress(String address, bool isStart) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isEmpty) return;
      final point = LatLng(locations.first.latitude, locations.first.longitude);
      await setPoint(point, isStart);
    } catch (e) {
      Get.snackbar("Error", "Location not found: $address");
    }
  }

  // ૨. સુધારેલું ફંક્શન: જે ડાયરેક્ટ LatLng લેશે (એરર ફિક્સ કરવા માટે)
  Future<void> setPoint(LatLng point, bool isStart) async {
    if (isStart) start = point; else end = point;
    _updateMarkers();

    if (start != null && end != null) {
      _drawRoute();
    } else if (mapController != null) {
      mapController!.animateCamera(CameraUpdate.newLatLngZoom(point, 15));
    }
  }

  Future<void> updateTravelMode(String mode) async {
    if (selectedMode.value == mode) return;
    selectedMode.value = mode;
    if (start != null && end != null) {
      _drawRoute();
    }
  }

  Future<void> _drawRoute() async {
    if (start == null || end == null) return;
    bool success = await _fetchFromGoogle(selectedMode.value);
    if (!success && selectedMode.value != "driving") {
      await _fetchFromGoogle("driving", forceManualCalc: true);
    }
  }

  Future<bool> _fetchFromGoogle(String mode, {bool forceManualCalc = false}) async {
    final url = "https://maps.googleapis.com/maps/api/directions/json?"
        "origin=${start!.latitude},${start!.longitude}"
        "&destination=${end!.latitude},${end!.longitude}"
        "&mode=$mode"
        "&key=$apiKey";

    try {
      final response = await http.get(Uri.parse(url));
      final data = jsonDecode(response.body);

      if (data["status"] != "OK" || data["routes"].isEmpty) return false;

      final route = data["routes"][0];
      String polyString = route["overview_polyline"]["points"];

      // તમારું સી-રૂટ લોજિક અકબંધ છે
      if (polyString.length < 100 && mode != "driving") {
        return false;
      }

      final leg = route["legs"][0];
      distanceText.value = leg["distance"]["text"];

      if (forceManualCalc) {
        double km = leg["distance"]["value"] / 1000;
        double speed = (selectedMode.value == "walking") ? 5.0 : 15.0;
        int totalMins = ((km / speed) * 60).round();
        durationText.value = (totalMins < 60) ? "$totalMins mins" : "${totalMins ~/ 60}h ${totalMins % 60}m";
      } else {
        durationText.value = leg["duration"]["text"];
      }

      stepsList.clear();
      for (var step in leg["steps"]) {
        stepsList.add({
          "instruction": step["html_instructions"].replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ""),
          "distance": step["distance"]["text"],
          "maneuver": step["maneuver"] ?? "straight",
        });
      }

      List<LatLng> points = _decodePoly(polyString);
      polylines.value = {
        Polyline(
          polylineId: const PolylineId("main_route"),
          color: ColorConstant.secondary,
          width: 6,
          points: points,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        )
      };

      _fitRoute(points);
      showInfo.value = true;
      return true;
    } catch (e) {
      return false;
    }
  }

  List<LatLng> _decodePoly(String poly) {
    var list = poly.codeUnits;
    var lList = <double>[];
    int index = 0, len = poly.length, c = 0;
    do {
      var shift = 0, result = 0;
      do {
        c = list[index++] - 63;
        result |= (c & 0x1F) << shift;
        shift += 5;
      } while (c >= 32);
      if (result & 1 == 1) result = ~result;
      lList.add((result >> 1) * 0.00001);
    } while (index < len);
    for (var i = 2; i < lList.length; i++) lList[i] += lList[i - 2];
    List<LatLng> res = [];
    for (var i = 0; i < lList.length; i += 2) res.add(LatLng(lList[i], lList[i + 1]));
    return res;
  }

  void _updateMarkers() {
    markers.value = {
      if (start != null) Marker(markerId: const MarkerId("src"), position: start!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)),
      if (end != null) Marker(markerId: const MarkerId("dst"), position: end!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)),
    };
  }

  void _fitRoute(List<LatLng> points) {
    if (mapController == null || points.isEmpty) return;
    double minLat = points.first.latitude, maxLat = points.first.latitude;
    double minLng = points.first.longitude, maxLng = points.first.longitude;
    for (var p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    mapController!.animateCamera(CameraUpdate.newLatLngBounds(
        LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng)), 70));
  }

  void clearRouteInfo() {
    start = end = null;
    markers.clear(); polylines.clear();
    distanceText.value = ""; durationText.value = "";
    showInfo.value = false; stepsList.clear();
  }

  Future<void> useCurrentLocation(bool isStart, TextEditingController controller) async {
    Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    LatLng latLng = LatLng(pos.latitude, pos.longitude);
    controller.text = "Your Location";
    if (isStart) start = latLng; else end = latLng;
    _updateMarkers();
    if (start != null && end != null) _drawRoute();
  }
}