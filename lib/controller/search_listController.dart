import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SuggestionController extends GetxController {
  final String apiKey = "AIzaSyB4OsZKR2hF7xBBCJR8sM2b6xf17v5DWZs";

  var suggestions = <String>[].obs; // list of suggestions
  var isLoading = false.obs;

  Future<void> searchPlace(String input) async {
    if (input.isEmpty) {
      suggestions.clear();
      return;
    }

    isLoading.value = true;

    // અહીં types=geocode કાઢી નાખ્યું છે અથવા તમે types=establishment વાપરી શકો
    // ફક્ત types=geocode હટાવવાથી બધું જ (shops, hotels, hospitals) આવવા માંડશે.
    final url =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$apiKey";

    try {
      final response = await http.get(Uri.parse(url));
      final data = jsonDecode(response.body);

      if (data["status"] == "OK") {
        final predictions = data["predictions"] as List;
        suggestions.value =
            predictions.map((e) => e["description"].toString()).toList();
      } else {
        suggestions.clear();
      }
    } catch (e) {
      suggestions.clear();
    } finally {
      isLoading.value = false;
    }
  }
  Future<LatLng?> getLatLngFromAddress(String address) async {
    final url = "https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=$apiKey";

    final response = await http.get(Uri.parse(url));
    final data = jsonDecode(response.body);

    if (data["status"] == "OK" && data["results"].isNotEmpty) {
      final location = data["results"][0]["geometry"]["location"];
      return LatLng(location["lat"], location["lng"]);
    }
    return null;
  }
  void clearSuggestions() {
    suggestions.clear();
  }
}