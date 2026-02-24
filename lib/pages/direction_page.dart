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

class DirectionPage extends StatefulWidget {
  // આ બે લાઈન અને કન્સ્ટ્રક્ટર માં ફેરફાર કર્યો
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
        twomap.useCurrentLocation(true, startController);
        endController.text = widget.destinationName ?? "Selected Destination";
        String destinationString = "${widget.destinationLocation!.latitude},${widget.destinationLocation!.longitude}";
        await twomap.setPoint(destinationString, false);
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

  Widget _buildSuggestionList(
      TextEditingController controller, SuggestionController suggestionCtrl) {
    return Obx(() {
      if (suggestionCtrl.isLoading.value) {
        return Container(
          margin: const EdgeInsets.only(top: 5),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: ColorConstant.whiteColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(child: CircularProgressIndicator()),
        );
      }

      if (suggestionCtrl.suggestions.isEmpty) return const SizedBox();

      return Container(
        margin: const EdgeInsets.only(top: 5),
        decoration: BoxDecoration(
          color: ColorConstant.whiteColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: ColorConstant.blackColor.withValues(alpha: 0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        constraints: const BoxConstraints(maxHeight: 200),
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: suggestionCtrl.suggestions.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final suggestion = suggestionCtrl.suggestions[index];
            return ListTile(
              title: Text(suggestion),
              onTap: () {
                controller.text = suggestion;
                suggestionCtrl.clearSuggestions();
              },
            );
          },
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
            onMapCreated: (controller) {
              twomap.mapController = controller;
              map.googleMapController = controller;
              map.goToCurrentLocation();
            },
            myLocationEnabled: true,
          )),

          Positioned(
            top: 150,
            right: 15,
            child: FloatingActionButton.small(
              heroTag: "dirMapTypeBtn",
              backgroundColor: Colors.white,
              onPressed: () {
                Get.bottomSheet(const MapTypeSheet());
              },
              child: const Icon(Icons.layers_outlined, color: Colors.black87),
            ),
          ),
          Positioned(
            bottom: 40,
            right: 15,
            child: FloatingActionButton.small(
              heroTag: "dirMyLocationBtn",
              backgroundColor: ColorConstant.whiteColor,
              onPressed: () => map.goToCurrentLocation(),
              child: const Icon(Icons.my_location, color: ColorConstant.secondary),
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
                boxShadow: [
                  BoxShadow(
                    blurRadius: 8,
                    color: ColorConstant.blackColor.withValues(alpha: 0.2),
                  )
                ],
              ),
              child: ExpansionTile(
                controller: _tileController,
                initiallyExpanded: widget.destinationLocation == null,
                tilePadding: const EdgeInsets.symmetric(horizontal: 10),
                childrenPadding: EdgeInsets.zero,
                title: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        twomap.clearRouteInfo();
                        Get.back();
                      },
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      "Directions",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Column(
                      children: [
                        CommanSearchField(
                          searchcontroller: startController,
                          hintText: "Enter starting point",
                          onSearch: _onStartChanged,
                          prefixicon: Icons.circle_outlined,
                          suffixicon: Icons.pin_drop,
                          onSuffixTap: () {
                            twomap.useCurrentLocation(true, startController);
                          },
                        ),
                        _buildSuggestionList(startController, startSuggestionController),

                        const SizedBox(height: 10),

                        CommanSearchField(
                          searchcontroller: endController,
                          hintText: "Enter destination",
                          onSearch: _onEndChanged,
                          prefixicon: Icons.location_on,
                          prefixcolor: ColorConstant.redColor,
                        ),
                        _buildSuggestionList(endController, endSuggestionController),

                        const SizedBox(height: 15),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorConstant.secondary,
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          onPressed: () async {
                            if (startController.text.isNotEmpty && endController.text.isNotEmpty) {
                              if (startController.text != "Your Location") {
                                await twomap.setPoint(startController.text, true);
                              }
                              if (endController.text != "Your Location") {
                                await twomap.setPoint(endController.text, false);
                              }
                              _tileController.collapse();
                            } else {
                              Get.snackbar("Error", "Please enter both locations");
                            }

                          },
                          child: const Text("Show Route",
                            style: TextStyle(color:ColorConstant.whiteColor ),),
                        ),

                        const SizedBox(height: 15),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 30,
            left: 20,
            child: Obx(() {
              if (twomap.distanceText.value.isEmpty) {
                return const SizedBox();
              }

              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ColorConstant.whiteColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 6,
                      color: ColorConstant.blackColor.withValues(alpha: 0.2),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Distance: ${twomap.distanceText.value}",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Time: ${twomap.durationText.value}",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}