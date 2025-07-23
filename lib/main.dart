import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String status = "Memulai...";
  Timer? timer;

  @override
  void initState() {
    super.initState();
    startTracking();
  }

  Future<void> startTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Minta izin lokasi
    await Permission.location.request();
    if (await Permission.location.isDenied) {
      setState(() => status = "Izin lokasi ditolak.");
      return;
    }

    // Cek apakah layanan lokasi aktif
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => status = "Layanan lokasi tidak aktif.");
      return;
    }

    // Cek dan minta izin lokasi (lagi)
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => status = "Izin lokasi tidak diberikan.");
        return;
      }
    }

    // Mulai timer untuk kirim lokasi tiap 5 detik
    timer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await sendLocation(pos.latitude, pos.longitude);
    });

    setState(() => status = "Tracking aktif...");
  }

  Future<void> sendLocation(double lat, double lon) async {
    final url = Uri.parse(
      "http://192.168.1.8:5000/update_gps",
    ); // Ganti IP ke IP laptop Flask

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'latitude': lat, 'longitude': lon}),
      );

      if (response.statusCode == 200) {
        print("✅ Lokasi terkirim: $lat, $lon");
        setState(() => status = "Lokasi terakhir: $lat, $lon");
      } else {
        print("⚠️ Gagal mengirim lokasi: ${response.body}");
        setState(() => status = "Gagal mengirim lokasi.");
      }
    } catch (e) {
      print("❌ Error: $e");
      setState(() => status = "Error saat kirim lokasi.");
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text("GPS to Flask")),
        body: Center(child: Text(status, textAlign: TextAlign.center)),
      ),
    );
  }
}
