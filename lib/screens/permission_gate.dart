import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'home_screen.dart';

class PermissionGate extends StatefulWidget {
  const PermissionGate({super.key});
  @override
  State<PermissionGate> createState() => _PermissionGateState();
}

class _PermissionGateState extends State<PermissionGate> {
  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    // Request microphone via permission_handler
    await Permission.microphone.request();

    // Request location via geolocator (handles both coarse + fine on Android,
    // and NSLocationWhenInUseUsageDescription on iOS).
    // We only call this once here — the provider checks the current status
    // without requesting again.
    final locPermission = await Geolocator.requestPermission();

    // If permanently denied, open settings so the user can enable it manually
    if (locPermission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Requesting permissions…'),
          ],
        ),
      ),
    );
  }
}
