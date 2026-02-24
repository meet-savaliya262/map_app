import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class PlaceDetailController extends GetxController {
  var isLoading = false.obs;
  var placeData = {}.obs;

  final String apiKey = "AIzaSyB4OsZKR2hF7xBBCJR8sM2b6xf17v5DWZs";

  Future<void> getDetailsFromLatLng(double lat, double lng) async {
    try {
      isLoading.value = true;
      final geoUrl = "https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$apiKey&result_type=point_of_interest|establishment|premise";
      final res = await http.get(Uri.parse(geoUrl));
      final data = json.decode(res.body);

      if (data['status'] == 'OK' && data['results'].isNotEmpty) {
        String placeId = data['results'][0]['place_id'];
        await fetchFullDetails(placeId);
      } else {
        placeData.value = {};
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> getFamousPlaceOfCity(String userInput) async {
    String finalQuery;
    List<String> keywords = ['hospital', 'restaurant', 'temple', 'hotel', 'mall', 'road', 'garden', 'school'];

    bool isSpecific = keywords.any((key) => userInput.toLowerCase().contains(key));

    if (isSpecific || userInput.split(' ').length > 2) {
      finalQuery = Uri.encodeComponent(userInput);
    } else {
      finalQuery = Uri.encodeComponent("famous places in $userInput");
    }

    final String url = "https://maps.googleapis.com/maps/api/place/textsearch/json?query=$finalQuery&key=$apiKey";

    try {
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'] != null && data['results'].isNotEmpty) {
          String placeId = data['results'][0]['place_id'];
          await fetchFullDetails(placeId);
          return true;
        }
      }
      return false;
    } catch (e) {
      print("Search Error: $e");
      return false;
    }
  }
  Future<void> fetchFullDetails(String placeId) async {
    final detailUrl = "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=name,formatted_address,photos,rating,user_ratings_total,formatted_phone_number,website,opening_hours,reviews,url,editorial_summary,geometry&key=$apiKey";

    final res = await http.get(Uri.parse(detailUrl));
    final data = json.decode(res.body);

    if (data['status'] == 'OK') {
      placeData.value = data['result'];
    }
  }

  String getPhotoUrl(String photoRef) {
    return "https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photo_reference=$photoRef&key=$apiKey";
  }
}