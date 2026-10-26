import 'package:aqi_app/configs/config.dart';
import 'package:aqi_app/constants/constants.dart';
import 'package:aqi_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AQIHistoryTile extends StatelessWidget {
  final record;

  AQIHistoryTile({required this.record});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white60,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: SizeConfig.screenWidth * 0.8,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        2.toSpace,
                        Icon(
                          Icons.gps_fixed,
                          color: Colors.amberAccent,
                          size: 23,
                        ),
                        Container(
                          width: 2,
                          height: 10,
                          color: Colors.amberAccent,
                        ),
                      ],
                    ),
                    8.toSpace,
                    Flexible(
                      child: Text(
                        record.location,
                        style: FONT_CONST.REGULAR.copyWith(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: SizeConfig.screenWidth * 0.8,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        2.toSpace,
                        Container(width: 2, height: 10, color: Colors.blueGrey),
                        Icon(
                          Icons.location_pin,
                          color: Colors.blueGrey,
                          size: 23,
                        ),
                        2.toSpace,
                      ],
                    ),
                    8.toSpace,
                    Flexible(
                      child: Text(
                        record.address,
                        style: FONT_CONST.REGULAR.copyWith(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: Colors.grey.withOpacity(0.5), height: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    "Route Avg. AQI: ${record.avgAqi}",
                    style: FONT_CONST.BOLD.copyWith(color: Colors.black54),
                  ),
                  Spacer(),
                  Text(
                    DateFormat("dd MM yyyy").format(record.date),
                    style: FONT_CONST.REGULAR_DEFAULT.copyWith(
                      color: Colors.black54,
                    ),
                  ),
                  4.toSpace,
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.black26,
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
        4.toSpace,
      ],
    );
  }
}
