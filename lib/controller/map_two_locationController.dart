import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import 'package:map_app/constant/colorconstant.dart';

class TwoMapRouteController extends GetxController {

  GoogleMapController? mapController;

  var markers = <Marker>{}.obs;
  var polylines = <Polyline>{}.obs;

  LatLng? start;
  LatLng? end;

  var distanceText = "".obs;
  var durationText = "".obs;
  var showInfo = false.obs;

  final String apiKey = "AIzaSyB4OsZKR2hF7xBBCJR8sM2b6xf17v5DWZs";

  Future<void> setPoint(String address, bool isStart) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isEmpty) return;

      final point = LatLng(
        locations.first.latitude,
        locations.first.longitude,
      );

      if (isStart) {
        start = point;
      } else {
        end = point;
      }

      _updateMarkers();

      if (isStart && mapController != null) {
        mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(point, 15),
        );
      }

      if (start != null && end != null) {
        await _drawRoute();
        _zoomToFit();
      }

    } catch (e) {
      Get.snackbar("Error", "Location not found");
    }
  }

  void _updateMarkers() {
    markers.clear();
    if (start != null) {
      markers.add(
        Marker(
          markerId: const MarkerId("start"),
          position: start!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen),
        ),
      );
    }

    if (end != null) {
      markers.add(
        Marker(
          markerId: const MarkerId("end"),
          position: end!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed),
        ),
      );
    }
  }

  Future<void> _drawRoute() async {

    final url =
        "https://maps.googleapis.com/maps/api/directions/json?"
        "origin=${start!.latitude},${start!.longitude}"
        "&destination=${end!.latitude},${end!.longitude}"
        "&mode=driving"
        "&key=$apiKey";

    final response = await http.get(Uri.parse(url));
    final data = jsonDecode(response.body);

    if (data["routes"].isEmpty) {
      showInfo.value = false;
      return;
    }

    distanceText.value =
    data["routes"][0]["legs"][0]["distance"]["text"];

    durationText.value =
    data["routes"][0]["legs"][0]["duration"]["text"];

    showInfo.value = true;

    List<LatLng> routePoints = [];

    List steps = data["routes"][0]["legs"][0]["steps"];

    for (var step in steps) {
      String encoded = step["polyline"]["points"];

      List<PointLatLng> decoded =
      PolylinePoints.decodePolyline(encoded);

      for (var point in decoded) {
        routePoints.add(
            LatLng(point.latitude, point.longitude));
      }
    }

    polylines.clear();

    polylines.add(
      Polyline(
        polylineId: const PolylineId("route"),
        color: ColorConstant.secondary,
        width: 6,
        points: routePoints,
        geodesic: true,
      ),
    );
  }

  void _zoomToFit() {
    if (mapController == null) return;

    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(
        start!.latitude <= end!.latitude
            ? start!.latitude
            : end!.latitude,
        start!.longitude <= end!.longitude
            ? start!.longitude
            : end!.longitude,
      ),
      northeast: LatLng(
        start!.latitude >= end!.latitude
            ? start!.latitude
            : end!.latitude,
        start!.longitude >= end!.longitude
            ? start!.longitude
            : end!.longitude,
      ),
    );

    mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 80),
    );
  }

  void clearRouteInfo() {
    start = null;
    end = null;
    markers.clear();
    polylines.clear();
    distanceText.value = "";
    durationText.value = "";
    showInfo.value = false;
  }

  Future<void> useCurrentLocation(bool isStart, TextEditingController controller) async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      LatLng currentLatLng = LatLng(position.latitude, position.longitude);
      controller.text = "Your Location";

      if (isStart) {
        start = currentLatLng;
      } else {
        end = currentLatLng;
      }

      _updateMarkers();

      if (mapController != null) {
        mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(currentLatLng, 15)
        );
      }
      if (start != null && end != null) {
        await _drawRoute();
        _zoomToFit();
      }
    } catch (e) {
      Get.snackbar("Error", "Could not access location");
    }
  }}