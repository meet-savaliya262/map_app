import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:map_app/pages/home.dart';
import 'package:permission_handler/permission_handler.dart';

import 'controller/mapController.dart';
import 'controller/map_two_locationController.dart'; // આ ઉમેરો

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _requestInitialPermissions();
  Get.put(TwoMapRouteController());
  Get.put(MapController(), permanent: true);
  runApp(const MyApp());
}
Future<void> _requestInitialPermissions() async {
  await [
    Permission.location,
    Permission.locationWhenInUse,
  ].request();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: MapPage(),
    );
  }
}