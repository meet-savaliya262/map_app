  import 'package:google_maps_flutter/google_maps_flutter.dart';
  import 'package:geocoding/geocoding.dart';
  import 'package:get/get.dart';
  import 'package:geolocator/geolocator.dart';
  import 'package:map_app/constant/colorconstant.dart';
  import 'map_two_locationController.dart';

  class MapController extends GetxController {
    late TwoMapRouteController twomap;
    var currentMapType = MapType.normal.obs;
    GoogleMapController? googleMapController;
    var markers = <Marker>{}.obs;

    @override
    void onInit() {
      super.onInit();
      twomap = Get.find<TwoMapRouteController>();
    }

    void changeMapType(MapType type) {
      currentMapType.value = type;
    }

    Future<void> goToCurrentLocation() async {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      LatLng currentLatLng = LatLng(position.latitude, position.longitude);

      googleMapController?.animateCamera(
        CameraUpdate.newLatLngZoom(currentLatLng, 15),
      );
    }



    Future<void> searchAndPinCity(String placeName) async {
      try {
        markers.clear();
        twomap.markers.clear();
        twomap.polylines.clear();

        List<Location> locations = await locationFromAddress(placeName);

        if (locations.isNotEmpty) {
          Location loc = locations.first;
          LatLng targetPosition = LatLng(loc.latitude, loc.longitude);

          markers.add(
            Marker(
              markerId: MarkerId(placeName),
              position: targetPosition,
              infoWindow: InfoWindow(title: placeName),
            ),
          );

          googleMapController?.animateCamera(
            CameraUpdate.newLatLngZoom(targetPosition, 16),
          );
        }
      } catch (e) {
        Get.snackbar(
          "Error",
          "Location Not Found $placeName",
          colorText: ColorConstant.blackColor,
        );
      }
    }


    void clearAll() {
      markers.clear();
    }
  }