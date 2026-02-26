import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../constant/colorconstant.dart';
import '../controller/map_two_locationController.dart';

class VehicleSelectorSheet extends StatefulWidget {
  const VehicleSelectorSheet({super.key});

  @override
  State<VehicleSelectorSheet> createState() =>
      _VehicleSelectorSheetState();
}

class _VehicleSelectorSheetState
    extends State<VehicleSelectorSheet> {
  final TwoMapRouteController twomap = Get.find();

  final PageController _pageController =
  PageController(viewportFraction: 0.35);

  final List<String> vehicles = [
    "assets/icons/bike.png",
    "assets/icons/car1.png",
    "assets/icons/car2.png",
    "assets/icons/car3.png",
  ];

  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          Container(
            height: 5,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          const SizedBox(height: 25),

          SizedBox(
            height: 110,
            child: PageView.builder(
              controller: _pageController,
              itemCount: vehicles.length,
              onPageChanged: (index) {
                setState(() {
                  currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                bool isSelected = index == currentIndex;
                return GestureDetector(
                  onTap: () async {
                    setState(() { currentIndex = index; });
                    twomap.updateVehicleIcon(vehicles[index]);
                    Get.back();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? ColorConstant.secondary.withOpacity(.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 300),
                        scale: isSelected ? 1.2 : 0.9,
                        child: Image.asset(
                          vehicles[index].replaceAll(".svg", ".png"),
                          height: 50,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.directions_car),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 25),
        ],
      ),
    );
  }
}