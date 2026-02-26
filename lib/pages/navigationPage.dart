import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/Get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../constant/colorconstant.dart';
import '../controller/map_two_locationController.dart';

class NavigationView extends StatelessWidget {
  const NavigationView({super.key});

  IconData _getManeuverIcon(String maneuver) {
    switch (maneuver) {
      case 'turn-left':
      case 'turn-slight-left':
        return Icons.turn_left;
      case 'turn-right':
      case 'turn-slight-right':
        return Icons.turn_right;
      case 'straight':
        return Icons.straight;
      default:
        return Icons.arrow_forward;
    }
  }

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
            compassEnabled: false,
            onCameraMoveStarted: () {
              twomap.isAutoFollow.value = false;
            },
            onMapCreated: (controller) {
              twomap.mapController = controller;
              twomap.isAutoFollow.value = true;
              twomap.startNavigation();
            },
          )),

          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Obx(() {
              if (twomap.currentStepIndex.value >= twomap.stepsList.length) {
                return const SizedBox();
              }
              var currentStep = twomap.stepsList[twomap.currentStepIndex.value];
              return Container(
                padding: const EdgeInsets.all(16),
                color: ColorConstant.secondary,
                child: Row(
                  children: [
                    Icon(
                      _getManeuverIcon(currentStep["maneuver"]),
                      color: Colors.white,
                      size: 40,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        currentStep["instruction"],
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      currentStep["distance"],
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              );
            }),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Obx(() => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black),
                    onPressed: () {
                      twomap.clearRouteInfo();
                      Get.back();
                    },
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${twomap.remainingDistanceText.value} remaining",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "${twomap.remainingDurationText.value} ETA • Speed: ${twomap.currentSpeed.value.toStringAsFixed(0)} km/h",
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ),

          Positioned(
            top: 130,
            right: 15,
            child: Obx(() {
              return GestureDetector(
                onTap: () {
                  if (twomap.mapController != null) {
                    twomap.mapController!.animateCamera(
                      CameraUpdate.newCameraPosition(
                        CameraPosition(
                          target: twomap.start ?? const LatLng(0, 0),
                          zoom: 19,
                          tilt: 65,
                          bearing: 0,
                        ),
                      ),
                    );
                    twomap.isAutoFollow.value = true;
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                  ),
                  child: Transform.rotate(
                    angle: (twomap.currentBearing.value) * (math.pi / 180) * -1,
                    child: const Icon(
                      Icons.explore,
                      color: Colors.redAccent,
                      size: 35,
                    ),
                  ),
                ),
              );
            }),
          ),        ],
      ),
    );
  }
}