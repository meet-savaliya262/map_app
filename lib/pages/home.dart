import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../constant/colorconstant.dart';
import '../controller/mapController.dart';
import '../controller/search_listController.dart';
import '../project_specific/comman_search_field.dart';
import '../project_specific/map_type_sheet.dart';
import 'direction_page.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController map = Get.find<MapController>();
  final SuggestionController placeController = Get.put(SuggestionController());
  final TextEditingController searchController = TextEditingController();

  Timer? _debounce;

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(22.3039, 70.8022),
    zoom: 12,
  );

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      placeController.searchPlace(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    Key mapKey = UniqueKey();
    return Scaffold(
      backgroundColor: ColorConstant.whiteColor,
      body: SafeArea(
        child: Stack(
          children: [
            Obx(() => GoogleMap(
              key: mapKey,
              initialCameraPosition: _initialPosition,
              mapType: map.currentMapType.value,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              markers: {...map.markers},
              onMapCreated: (GoogleMapController controller) {
                map.googleMapController = controller;
                map.goToCurrentLocation();
              },
              myLocationEnabled: true,
            )),

            Positioned(
              top: 10,
              right: 15,
              left: 15,
              child: Column(
                children: [
                  CommanSearchField(
                    searchcontroller: searchController,
                    onSearch: _onSearchChanged,
                  ),
                  Obx(() {
                    if (placeController.isLoading.value) {
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

                    if (placeController.suggestions.isEmpty) return const SizedBox();

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
                      constraints: const BoxConstraints(maxHeight: 250),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: placeController.suggestions.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final suggestion = placeController.suggestions[index];
                          return ListTile(
                            title: Text(suggestion),
                            onTap: () async {
                              searchController.text = suggestion;
                              placeController.clearSuggestions();
                              await map.searchAndPinCity(suggestion);
                            },
                          );
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),

            Positioned(
              top: 80,
              right: 15,
              child: FloatingActionButton.small(
                heroTag: "mapTypeBtn",
                backgroundColor: Colors.white,
                onPressed: () {
                  Get.bottomSheet(MapTypeSheet());
                },
                child: const Icon(Icons.layers_outlined, color: Colors.black87),
              ),
            ),

            Positioned(
              bottom: 90,
              right: 10,
              child: FloatingActionButton.small(
                heroTag: "myLocationBtn",
                backgroundColor: ColorConstant.whiteColor,
                onPressed: () => map.goToCurrentLocation(),
                child: const Icon(Icons.my_location, color: ColorConstant.secondary),
              ),
            ),


            Positioned(
              bottom: 16,
              right: 10,
              child: GestureDetector(
                onTap: () async {
                  await Get.to(() => const DirectionPage());
                  setState(() {
                    mapKey = UniqueKey();
                  });
                  map.clearAll();
                  searchController.clear();
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ColorConstant.lightBlueColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.directions,
                    size: 40,
                    color: ColorConstant.secondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}