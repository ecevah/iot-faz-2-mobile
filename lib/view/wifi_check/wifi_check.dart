import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mpu_sql/widget/wifi_check/no_check.dart';

class WifiCheck extends StatefulWidget {
  const WifiCheck({super.key});

  @override
  _WifiCheckState createState() => _WifiCheckState();
}

class _WifiCheckState extends State<WifiCheck> {
  bool _mpuConnection = false;

  @override
  void initState() {
    super.initState();
    _checkMpuConnection();
  }

  Future<void> _checkMpuConnection() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.4.1/'));
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final message = jsonData['message'];
        if (message == "Mpu Connection") {
          setState(() {
            _mpuConnection = true;
          });
        }
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("WiFi Connection"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: _mpuConnection
                ? const Checked()
                : Column(
                    children: [
                      const Text("Lütfen MPU-XXX-XXX ağına bağlanın."),
                      ElevatedButton(
                        onPressed: () {
                          _checkMpuConnection();
                        },
                        child: const Text("Tekrar Dene"),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
