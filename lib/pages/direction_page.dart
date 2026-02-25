import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:map_app/constant/colorconstant.dart';
import 'package:map_app/controller/mapController.dart';
import '../controller/map_two_locationController.dart';
import '../controller/search_listController.dart';
import '../project_specific/comman_search_field.dart';
import '../project_specific/map_type_sheet.dart';
import '../project_specific/step_tile.dart';
import '../project_specific/vehical_select.dart';

class DirectionPage extends StatefulWidget {
  final LatLng? destinationLocation;
  final String? destinationName;

  const DirectionPage({super.key, this.destinationLocation, this.destinationName});

  @override
  State<DirectionPage> createState() => _DirectionPageState();
}

class _DirectionPageState extends State<DirectionPage> {

  final TwoMapRouteController twomap = Get.find();
  final MapController map = Get.find<MapController>();

  final SuggestionController startSuggestionController =
  Get.put(SuggestionController(), tag: "start");

  final SuggestionController endSuggestionController =
  Get.put(SuggestionController(), tag: "end");

  final TextEditingController startController = TextEditingController();
  final TextEditingController endController = TextEditingController();

  final ExpansionTileController _tileController = ExpansionTileController();

  Timer? _debounceStart;
  Timer? _debounceEnd;

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(22.3039, 70.8022),
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.destinationLocation != null) {

        await twomap.useCurrentLocation(true, startController);

        endController.text =
            widget.destinationName ?? "Selected Destination";

        await twomap.setPoint(widget.destinationLocation!, false);

        _tileController.collapse();
      }
    });
  }

  @override
  void dispose() {
    twomap.clearRouteInfo();
    startController.dispose();
    endController.dispose();
    _debounceStart?.cancel();
    _debounceEnd?.cancel();
    super.dispose();
  }

  void _onStartChanged(String value) {
    if (_debounceStart?.isActive ?? false) _debounceStart!.cancel();
    _debounceStart = Timer(const Duration(milliseconds: 400), () {
      startSuggestionController.searchPlace(value);
    });
  }

  void _onEndChanged(String value) {
    if (_debounceEnd?.isActive ?? false) _debounceEnd!.cancel();
    _debounceEnd = Timer(const Duration(milliseconds: 400), () {
      endSuggestionController.searchPlace(value);
    });
  }

  Widget _buildTransportModeItem(IconData icon, String mode) {
    return Obx(() {
      bool isSelected = twomap.selectedMode.value == mode;
      return GestureDetector(
        onTap: () async {
          await twomap.updateTravelMode(mode);
        },
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? ColorConstant.secondary
                  : Colors.grey,
              size: 28,
            ),

            const SizedBox(height: 4),

            if (isSelected)
              Text(
                twomap.durationText.value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: ColorConstant.secondary,
                ),
              ),

            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              width: isSelected ? 30 : 0,
              decoration: BoxDecoration(
                color: ColorConstant.secondary,
                borderRadius: BorderRadius.circular(10),
              ),
            )
          ],
        ),
      );
    });
  }


  Widget _buildSuggestionList(
      TextEditingController controller,
      SuggestionController suggestionCtrl) {

    return Obx(() {

      if (!suggestionCtrl.isLoading.value &&
          suggestionCtrl.suggestions.isEmpty) {
        return const SizedBox();
      }

      return Container(
        margin: const EdgeInsets.only(top: 5),
        decoration: BoxDecoration(
          color: ColorConstant.whiteColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 5)
          ],
        ),
        constraints: const BoxConstraints(maxHeight: 180),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: suggestionCtrl.suggestions.length,
          itemBuilder: (context, index) => ListTile(
            title: Text(suggestionCtrl.suggestions[index]),
            onTap: () {
              controller.text =
              suggestionCtrl.suggestions[index];
              suggestionCtrl.clearSuggestions();
            },
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Stack(
        children: [

          Obx(() => GoogleMap(
            initialCameraPosition: _initialPosition,
            mapType: map.currentMapType.value,
            markers: twomap.markers,
            polylines: Set<Polyline>.of(twomap.polylines),
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            myLocationEnabled: true,
            onMapCreated: (controller) {
              twomap.mapController = controller;
              map.googleMapController = controller;
              map.goToCurrentLocation();
            },
          )),

          Positioned(
            top: 120,
            right: 15,
            child: FloatingActionButton.small(
              heroTag: "dirMapTypeBtn",
              backgroundColor: Colors.white,
              onPressed: () =>
                  Get.bottomSheet(const MapTypeSheet()),
              child: const Icon(Icons.layers_outlined,
                  color: ColorConstant.secondary),
            ),
          ),

          Positioned(
            top: 170,
            right: 15,
            child: FloatingActionButton.small(
              heroTag: "myLocationBtn",
              backgroundColor: Colors.white,
              onPressed: () =>
                  map.goToCurrentLocation(),
              child: const Icon(Icons.my_location,
                  color: ColorConstant.secondary),
            ),
          ),

          Positioned(
            top: 50,
            left: 15,
            right: 15,
            child: Container(
              decoration: BoxDecoration(
                color: ColorConstant.whiteColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(blurRadius: 8,
                      color: Colors.black12)
                ],
              ),
              child: ExpansionTile(
                controller: _tileController,
                initiallyExpanded:
                widget.destinationLocation == null,
                leading: IconButton(
                  onPressed: () {
                    twomap.clearRouteInfo();
                    Get.back();
                  },
                  icon: const Icon(Icons.arrow_back),
                ),
                title: const Text("Directions",
                    style: TextStyle(
                        fontWeight: FontWeight.bold)),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10),
                    child: Column(
                      children: [

                        CommanSearchField(
                          searchcontroller: startController,
                          hintText: "Enter starting point",
                          onSearch: _onStartChanged,
                          prefixicon: Icons.circle_outlined,
                          suffixicon: Icons.pin_drop,
                          onSuffixTap: () =>
                              twomap.useCurrentLocation(
                                  true,
                                  startController),
                        ),

                        _buildSuggestionList(
                            startController,
                            startSuggestionController),

                        const SizedBox(height: 10),

                        CommanSearchField(
                          searchcontroller: endController,
                          hintText: "Enter destination",
                          onSearch: _onEndChanged,
                          prefixicon: Icons.location_on,
                          prefixcolor: Colors.red,
                        ),

                        _buildSuggestionList(
                            endController,
                            endSuggestionController),

                        const SizedBox(height: 15),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                            ColorConstant.secondary,
                            minimumSize:
                            const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(12)),
                          ),
                          onPressed: () async {
                            if (startController.text.isNotEmpty && endController.text.isNotEmpty) {
                              if (startController.text == "Your Location") {
                                // useCurrentLocation already sets the start LatLng
                              } else {
                                await twomap.setPointFromAddress(startController.text, true);
                              }

                              if (endController.text == "Your Location") {
                                // logic for end current location if needed
                              } else {
                                await twomap.setPointFromAddress(endController.text, false);
                              }
                              _tileController.collapse();
                            }
                          },
                          child: const Text("Show Route",
                              style: TextStyle(
                                  color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Obx(() {

            if (twomap.distanceText.value.isEmpty)
              return const SizedBox();

            return DraggableScrollableSheet(
              initialChildSize: 0.35,
              minChildSize: 0.15,
              maxChildSize: 0.85,
              builder: (context, scrollController) {

                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.vertical(
                        top: Radius.circular(25)),
                    boxShadow: [
                      BoxShadow(
                          blurRadius: 15,
                          color: Colors.black26)
                    ],
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: EdgeInsets.zero,
                    children: [

                      Align(
                        alignment:AlignmentGeometry.topRight,
                        child: IconButton(
                          icon: const Icon(Icons.settings),
                          onPressed: () {
                            Get.bottomSheet(
                                VehicleSelectorSheet());
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildTransportModeItem(Icons.directions_car, 'driving'),
                            _buildTransportModeItem(Icons.directions_bike, 'bicycling'),
                            _buildTransportModeItem(Icons.directions_train, 'transit'),
                            _buildTransportModeItem(Icons.directions_walk, 'walking'),
                          ],
                        ),
                      ),

                      const Divider(),

                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  twomap.durationText.value,
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green),
                                ),
                                Text(
                                  "${twomap.distanceText.value} • Fastest route",
                                  style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600]),
                                ),
                              ],
                            ),

                            ElevatedButton.icon(
                              onPressed: () {
                                twomap.startNavigation();
                              },
                              icon: const Icon(Icons.navigation,
                                  color: Colors.white),
                              label: const Text("Start",
                                  style: TextStyle(
                                      color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                ColorConstant.secondary,
                                shape: const StadiumBorder(),
                              ),
                            )
                          ],
                        ),
                      ),

                      const Divider(),

                      const Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10),
                        child: Text("Steps",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                      ),

                      Obx(() => Column(
                        children: twomap.stepsList
                            .map((step) {
                          return StepTileWidget(
                            instruction: step["instruction"],
                            distance: step["distance"],
                            maneuver: step["maneuver"],
                          );
                        }).toList(),
                      )),

                      const SizedBox(height: 50),
                    ],
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}