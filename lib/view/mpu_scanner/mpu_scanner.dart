import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MPUListScreen extends StatefulWidget {
  final baseIp;
  const MPUListScreen({super.key, required this.baseIp});

  @override
  _MPUListScreenState createState() => _MPUListScreenState();
}

class _MPUListScreenState extends State<MPUListScreen> {
  List<dynamic> mpuList = [];
  bool isLoading = false;

  Future<void> getMPUList() async {
    setState(() {
      isLoading = true;
      mpuList = [];
    });

    for (int i = 0; i <= 255; i++) {
      String ipAddress = '${widget.baseIp}$i';
      final response = await http.get(Uri.parse('http://$ipAddress/api'));

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['status'] == true) {
          setState(() {
            mpuList.add({
              'id': data['id'],
              'macAddress': data['macAddress'],
            });
          });
        }
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MPU Cihazları'),
      ),
      body: Column(
        children: [
          if (isLoading)
            CircularProgressIndicator()
          else
            Expanded(
              child: ListView.builder(
                itemCount: mpuList.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text('ID: ${mpuList[index]['id']}'),
                    subtitle:
                        Text('MAC Address: ${mpuList[index]['macAddress']}'),
                  );
                },
              ),
            ),
          ElevatedButton(
            onPressed: () {
              getMPUList();
            },
            child: Text('MPU Cihazlarını Bul'),
          ),
        ],
      ),
    );
  }
}
