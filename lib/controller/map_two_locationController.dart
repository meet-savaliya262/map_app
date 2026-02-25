import 'dart:convert';
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

  var stepsList = <Map<String, dynamic>>[].obs;

  final String apiKey = "AIzaSyB4OsZKR2hF7xBBCJR8sM2b6xf17v5DWZs";

  // 🔹 SET POINT FROM ADDRESS
  Future<void> setPointFromAddress(String address, bool isStart) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isEmpty) return;

      LatLng point =
      LatLng(locations.first.latitude, locations.first.longitude);

      await setPoint(point, isStart);

    } catch (e) {
      Get.snackbar("Error", "Location not found");
    }
  }

  Future<void> setPoint(LatLng point, bool isStart) async {

    if (isStart) {
      start = point;
    } else {
      end = point;
    }

    _updateMarkers();

    if (start != null && end != null) {
      await _drawRoute();
    } else {
      mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(point, 15),
      );
    }
  }

  Future<void> updateTravelMode(String mode) async {

    if (selectedMode.value == mode) return;

    selectedMode.value = mode;

    if (start != null && end != null) {
      await _drawRoute();
    }
  }

  Future<void> _drawRoute() async {
    if (start == null || end == null) return;
    final url = "https://maps.googleapis.com/maps/api/directions/json?"
        "origin=${start!.latitude},${start!.longitude}"
        "&destination=${end!.latitude},${end!.longitude}"
        "&mode=${selectedMode.value}"
        "&alternatives=false"
        "&region=in"
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

      for (var step in leg["steps"]) {
        stepsList.add({
          "instruction": step["html_instructions"]
              .replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ""),
          "distance": step["distance"]["text"],
          "maneuver": step["maneuver"] ?? "straight",
        });
      }
      List<LatLng> polylineCoordinates = [];

      PolylinePoints polylinePoints =
      PolylinePoints(apiKey: apiKey);

      for (var step in leg["steps"]) {

        List<PointLatLng> decoded =
        PolylinePoints.decodePolyline(
            step["polyline"]["points"]);

        for (var p in decoded) {
          polylineCoordinates.add(
              LatLng(p.latitude, p.longitude));
        }
      }

      polylines.value = {
        Polyline(
          polylineId: const PolylineId("route"),
          points: polylineCoordinates,
          color: ColorConstant.secondary,
          width: 6,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          geodesic: false,
        )
      };

      _fitRoute(polylineCoordinates);

    } catch (e) {
      Get.snackbar("Error", "Route drawing failed");
    }
  }

  void _updateMarkers() {

    markers.value = {

      if (start != null)
        Marker(
          markerId: const MarkerId("start"),
          position: start!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen),
        ),

      if (end != null)
        Marker(
          markerId: const MarkerId("end"),
          position: end!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed),
        ),
    };
  }

  // 🔹 FIT ROUTE IN SCREEN
  void _fitRoute(List<LatLng> points) {

    if (mapController == null || points.isEmpty) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        70,
      ),
    );
  }

  // 🔹 USE CURRENT LOCATION
  Future<void> useCurrentLocation(
      bool isStart,
      TextEditingController controller,
      ) async {

    Position position =
    await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    LatLng current =
    LatLng(position.latitude, position.longitude);

    controller.text = "Your Location";

    if (isStart) {
      start = current;
    } else {
      end = current;
    }

    _updateMarkers();

    if (start != null && end != null) {
      await _drawRoute();
    }
  }

  // 🔹 CLEAR ROUTE
  void clearRouteInfo() {

    start = null;
    end = null;

    markers.clear();
    polylines.clear();

    distanceText.value = "";
    durationText.value = "";

    stepsList.clear();
  }
}