class MpuLocationModel {
  final int? locationId;
  final String? locationName;
  final String? baseIp;
  final int? mpuId;
  final String? mpuName;
  final String? ip;
  final String? macAddress;

  MpuLocationModel({
    this.locationId,
    this.locationName,
    this.baseIp,
    this.mpuId,
    this.mpuName,
    this.ip,
    this.macAddress,
  });

  factory MpuLocationModel.fromJson(Map<String, dynamic> json) {
    return MpuLocationModel(
      locationId: json['id'],
      locationName: json['location_name'],
      baseIp: json['baseIp'],
      mpuId: json['mpu_id'],
      mpuName: json['mpu_name'],
      ip: json['ip'],
      macAddress: json['macAddress'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': locationId,
      'location_name': locationName,
      'baseIp': baseIp,
      'mpu_id': mpuId,
      'mpu_name': mpuName,
      'ip': ip,
      'macAddress': macAddress,
    };
  }
}
