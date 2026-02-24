import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:map_app/constant/colorconstant.dart';
import '../controller/mapController.dart';

class MapTypeSheet extends StatelessWidget {
  const MapTypeSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final MapController map = Get.find<MapController>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: const BoxDecoration(
        color: ColorConstant.whiteColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Map Type",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.close, size: 20),
              )
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildOption(map, "Default", MapType.normal, Icons.map_rounded),
              _buildOption(map, "Satellite", MapType.satellite, Icons.satellite_alt_rounded),
              _buildOption(map, "Terrain", MapType.terrain, Icons.terrain_rounded),
              _buildOption(map, "Hybrid", MapType.hybrid, Icons.layers),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildOption(MapController map, String label, MapType type, IconData icon) {
    return GestureDetector(
      onTap: () {
        map.changeMapType(type);
        Get.back();
      },
      child: Column(
        children: [
          Obx(() {
            bool isSelected = map.currentMapType.value == type;
            return Container(
              height: 65,
              width: 65,
              decoration: BoxDecoration(
                color: isSelected ? ColorConstant.secondary.withValues(alpha: 0.1) : ColorConstant.lightGrayColor,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isSelected ? ColorConstant.secondary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Icon(
                icon,
                size: 30,
                color: isSelected ? ColorConstant.secondary : ColorConstant.blackColor,
              ),
            );
          }),
          const SizedBox(height: 8),
          Obx(() => Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: map.currentMapType.value == type ? FontWeight.bold : FontWeight.normal,
              color: map.currentMapType.value == type ? ColorConstant.secondary : ColorConstant.blackColor,
            ),
          )),
        ],
      ),
    );
  }
}