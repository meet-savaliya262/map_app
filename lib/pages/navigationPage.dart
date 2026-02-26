import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../controller/map_two_locationController.dart';

class NavigationView extends StatelessWidget {
  const NavigationView({super.key});

  @override
  Widget build(BuildContext context) {
    final TwoMapRouteController twomap = Get.find();

    return Scaffold(
      body: Stack(
        children: [
          Obx(() => GoogleMap(
            initialCameraPosition: CameraPosition(
              target: twomap.start ?? const LatLng(0, 0),
              zoom: 19,
              tilt: 65,
            ),
            markers: twomap.markers,
            polylines: Set<Polyline>.of(twomap.polylines),
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            indoorViewEnabled: false,
            mapToolbarEnabled: false,
            onCameraMoveStarted: () {
              twomap.isAutoFollow.value = false;
            },
            onMapCreated: (controller) {
              twomap.mapController = controller;
              twomap.isAutoFollow.value = true;
              twomap.startNavigation();
            },
          )),

          // Exit Button
          Positioned(
            top: 50,
            left: 20,
            child: FloatingActionButton.small(
              backgroundColor: Colors.white,
              onPressed: () => Get.back(),
              child: const Icon(Icons.arrow_back, color: Colors.black),
            ),
          ),

          Positioned(
            bottom: 30,
            left: 15,
            right: 15,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
              ),
              child: Obx(() => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    twomap.stepsList.isNotEmpty
                        ? twomap.stepsList[0]["instruction"]
                        : "Follow the route",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const Divider(),
                  Text("${twomap.distanceText.value} remaining"),
                ],
              )),
            ),
          )
        ],
      ),
    );
  }
}