import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'bindings/feed_binding.dart';
import 'services/network_service.dart';
import 'views/feed_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();

  final networkService = NetworkService();
  await networkService.init();
  Get.put<NetworkService>(networkService, permanent: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Short Video Feed Test',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      initialBinding: FeedBinding(),
      home: const FeedScreen(),
    );
  }
}