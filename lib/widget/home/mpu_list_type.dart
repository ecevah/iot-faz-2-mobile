import 'package:flutter/material.dart';
import 'package:mpu_sql/model/mpu_model.dart';
import 'package:mpu_sql/view/mpu_detail/mpu_detail.dart';

class MpuListType extends StatelessWidget {
  const MpuListType({
    super.key,
    required this.mpus,
    required this.locationId,
  });

  final List<MpuModel> mpus;
  final int locationId;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: mpus
          .map(
            (mpu) => GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MpuDetail(
                      id: mpu.id!,
                      locationId: locationId,
                      ip: mpu.ip!,
                    ),
                  ),
                );
              },
              child: ListTile(
                title: Text(mpu.name ?? ''),
                subtitle: Text(mpu.ip ?? ''),
              ),
            ),
          )
          .toList(),
    );
  }
}
