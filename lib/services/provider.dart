import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mpu_sql/model/location_model.dart';
import 'package:mpu_sql/model/mpu_location_model.dart';
import 'package:mpu_sql/model/mpu_model.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;

class DatabaseProvider with ChangeNotifier {
  String _searchTextMpu = "";
  String get searchTextMpu => _searchTextMpu;
  set searchTextMpu(String value) {
    _searchTextMpu = value;
    notifyListeners();
  }

  String _searchTextLocation = "";
  String get searchTextLocation => _searchTextLocation;
  set searchTextLocation(String value) {
    _searchTextLocation = value;
    notifyListeners();
  }

  List<LocationModel> _locations = [];
  List<LocationModel> get locations {
    return _searchTextLocation != ""
        ? _locations
            .where((element) => element.name!
                .toLowerCase()
                .contains(_searchTextLocation.toLowerCase()))
            .toList()
        : _locations;
  }

  List<MpuModel> _mpus = [];
  List<MpuModel> get mpus {
    return _searchTextMpu != ""
        ? _mpus
            .where((element) => element.name!
                .toLowerCase()
                .contains(_searchTextMpu.toLowerCase()))
            .toList()
        : _mpus;
  }

  List<MpuLocationModel> _mpuLocation = [];
  List<MpuLocationModel> get mpusLocation => _mpuLocation;

  Database? _database;
  Future<Database> get database async {
    final dbDirectory = await getDatabasesPath();

    const dbName = 'expense_tc.db';

    final path = join(dbDirectory, dbName);

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: _createDb,
    );

    return _database!;
  }

  static const lTable = "locationTable";
  static const mTable = "mpuTable";

  Future<void> _createDb(Database db, int version) async {
    await db.transaction((txn) async {
      await txn.execute('''CREATE TABLE $lTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT, 
          name TEXT, 
          baseIp TEXT
          )''');

      await txn.execute('''CREATE TABLE $mTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT, 
          locationId INTEGER,
          name TEXT,
          ip TEXT,
          macAddress TEXT,
          FOREIGN KEY (locationId) REFERENCES $lTable(id)
      )''');
    });
  }

  Future<List<LocationModel>> fetchLocations() async {
    final db = await database;
    return await db.transaction((txn) async {
      return await txn.query(lTable).then((value) {
        final converted = List<Map<String, dynamic>>.from(value);

        List<LocationModel> nList = List.generate(
          converted.length,
          (index) => LocationModel.fromJson(converted[index]),
        );

        _locations = nList;
        return _locations;
      });
    });
  }

  Future<List<MpuModel>> fetchMpus() async {
    final db = await database;
    return await db.transaction((txn) async {
      return await txn.query(mTable).then((value) {
        final converted = List<Map<String, dynamic>>.from(value);

        List<MpuModel> nList = List.generate(
          converted.length,
          (index) => MpuModel.fromJson(converted[index]),
        );

        _mpus = nList;
        return _mpus;
      });
    });
  }

  Future<void> updateLocation(
    int id,
    String nName,
    String nBaseIp,
  ) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn
          .update(
        lTable,
        {'name': nName, 'baseIp': nBaseIp},
        where: 'id == ?',
        whereArgs: [id],
      )
          .then((_) {
        var file = _locations.firstWhere((element) => element.id == id);
        file.baseIp = nBaseIp;
        file.name = nName;
        notifyListeners();
      });
    });
  }

  Future<void> updateMpu(int id, String nMacAddress, String nIp,
      int nLocationId, String nName) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn
          .update(
        mTable,
        {
          'name': nName,
          'ip': nIp,
          'locationId': nLocationId,
          'macAddress': nMacAddress,
        },
        where: 'id == ?',
        whereArgs: [id],
      )
          .then((_) {
        var file = _mpus.firstWhere((element) => element.id == id);
        file.ip = nIp;
        file.locationId = nLocationId;
        file.name = nName;
        file.macAddress = nMacAddress;
        notifyListeners();
      });
    });
  }

  Future<void> findAndModifyMPUs(String baseIp) async {
    for (int i = 0; i <= 255; i++) {
      String ipAddress = '$baseIp$i';
      final response = await http.get(Uri.parse('http://$ipAddress/api'));

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['status'] == true) {
          String macAddress = data['macAddress'];
          await updateMpuByMacAddress(macAddress, ipAddress);
        }
      }
    }
  }

  Future<void> updateMpuByMacAddress(String macAddress, String nIp) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn
          .update(
        mTable,
        {
          'ip': nIp,
        },
        where: 'macAddress == ?',
        whereArgs: [macAddress],
      )
          .then((_) {
        _mpus.forEach((file) {
          if (file.macAddress == macAddress) {
            file.ip = nIp;
          }
        });
        notifyListeners();
      });
    });
  }

  Future<void> addLocation(LocationModel location) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn
          .insert(
        lTable,
        location.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      )
          .then((value) {
        final file = LocationModel(
            id: value, name: location.name, baseIp: location.baseIp);

        _locations.add(file);
        notifyListeners();
      });
    });
  }

  Future<void> addMpu(MpuModel mpu) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn
          .insert(mTable, mpu.toJson(),
              conflictAlgorithm: ConflictAlgorithm.replace)
          .then((value) {
        final file = MpuModel(
            id: value,
            name: mpu.name,
            locationId: mpu.locationId,
            macAddress: mpu.macAddress,
            ip: mpu.ip);

        _mpus.add(file);
        notifyListeners();
      });
    });
  }

  Future<void> deleteLocation(int locationId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn
          .delete(lTable, where: 'id == ?', whereArgs: [locationId]).then((_) {
        _locations.removeWhere((element) => element.id == locationId);
      });
      notifyListeners();
    });
  }

  Future<void> deleteMpu(int mpuId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(mTable, where: 'id == ?', whereArgs: [mpuId]).then((_) {
        _mpus.removeWhere((element) => element.id == mpuId);
      });
      notifyListeners();
    });
  }

  Future<void> fetchMpuLocations() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
    SELECT mpus.id, mpus.name AS mpuName, mpus.ip, mpus.macAddress, locations.name AS locationName, locations.baseIp AS baseIp
    FROM mpus
    JOIN locations ON mpus.locationId = locations.id
  ''');

    List<MpuLocationModel> mpuLocations = [];
    for (Map<String, dynamic> row in result) {
      mpuLocations.add(MpuLocationModel(
        locationId: row['locationId'],
        locationName: row['locationName'],
        baseIp: row['baseIp'],
        mpuId: row['id'],
        mpuName: row['mpuName'],
        ip: row['ip'],
        macAddress: row['macAddress'],
      ));
    }

    _mpuLocation = mpuLocations;
    notifyListeners();
  }

  Future<MpuModel?> fetchMpuById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      mTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      return MpuModel.fromJson(result.first);
    } else {
      return MpuModel();
    }
  }

  Future<LocationModel?> fetchLocationById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      lTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      return LocationModel.fromJson(result.first);
    } else {
      return LocationModel();
    }
  }

  Future<MpuModel> fetchMpuByLocation(int location) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      mTable,
      where: 'locationId = ?',
      whereArgs: [location],
    );

    if (result.isNotEmpty) {
      return MpuModel.fromJson(result.first);
    } else {
      return MpuModel();
    }
  }
}
