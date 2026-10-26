import 'package:aqi_app/configs/size_config.dart';
import 'package:aqi_app/constants/constants.dart';
import 'package:aqi_app/data/local/HiveLDB/HiveModel/MainNavigationHistory.dart';
import 'package:aqi_app/data/models/user_model.dart';
import 'package:aqi_app/presentation/common_blocs/auth/auth_event.dart';
import 'package:aqi_app/presentation/screens/profile/ProfileWidget/aqi_history_tile.dart';
import 'package:aqi_app/presentation/screens/settings/Privacypolicy.dart';
import 'package:aqi_app/presentation/screens/settings/Setting_card_widget.dart';
import 'package:aqi_app/utils/dialog.dart';
import 'package:aqi_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geodesy/geodesy.dart';
import 'package:geolocator/geolocator.dart';
import '../../common_blocs/common_bloc.dart';
import '../../common_blocs/profile/bloc.dart';
import 'ProfileWidget/aqi_bar_chart.dart';

class ProfileScreen extends StatelessWidget {
  final Position clatlng;
  ProfileScreen({required this.clatlng});
  final ProfileBloc _profileBloc = ProfileBloc();
  List<MainNavigationHistory> myHistory = [];
  UserModel? loggedUser;
  List aqidata = [];
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (_) =>
              _profileBloc..add(
                GetLast7DaysAqiEvent(
                  clatlng: LatLng(clatlng.latitude, clatlng.longitude),
                ),
              ),
      child: Scaffold(
        backgroundColor: Color(0xfff2f2f2),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Color(0xfff2f2f2),
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(Icons.arrow_back, color: Colors.black),
          ),
          title: Text("AQI Record", style: TextStyle(color: Colors.black)),
          actions: [
            SizedBox.square(
              dimension: 65,
              child: IconButton(
                onPressed: () {
                  UtilDialog.showLogoutWarning(
                    context,
                    content: "Are you sure want to Logout?",
                    title: "Logout Alert",
                    onClose: () {
                      CommonBloc.authencationBloc.add(LoggedOut());
                    },
                  );
                },
                icon: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.logout,
                      color: Colors.brown,
                      size: 22,
                      weight: 3,
                    ),
                    Text(
                      'Logout',
                      style: FONT_CONST.MEDIUM_DEFAULT.copyWith(
                        color: Colors.brown,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        body: BlocConsumer<ProfileBloc, ProfileState>(
          listener: (context, state) {
            if (state is FetchHistoryNavDataState) {
              myHistory = state.mainHistory;
              if (myHistory.length > 2) {
                showNavigationHistoryBottomSheet(context, myHistory);
              }
            }
            if (state is ProfileLoaded) {
              loggedUser = state.loggedUser;
              aqidata = state.aqidata!;
              _profileBloc.add(GetNavHistoryAqiEvent(frominit: true));
            }
          },
          builder: (context, state) {
            if (state is ProfileLoading) {
              return Center(
                child: CircularProgressIndicator(color: Colors.black),
              );
            }
            // final data = state as AQILoaded;

            return SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (loggedUser != null)
                    _buildProfileCard(context, loggedUser!),
                  SizedBox(height: 16),
                  if (aqidata.isNotEmpty) _buildBarChartSection((aqidata)),
                  SizedBox(height: 16),
                  _buildHistorySection(
                    context,
                    myHistory.length > 2
                        ? myHistory
                            .sublist(0, 2)
                            .map(
                              (e) => AQIRecord(
                                location: e.startAddress,
                                address: e.endAddress,
                                avgAqi: e.routeAvgAqi.round(),
                                date: e.dateOfSync,
                              ),
                            )
                            .toList()
                        : myHistory
                            .map(
                              (e) => AQIRecord(
                                location: e.startAddress,
                                address: e.endAddress,
                                avgAqi: e.routeAvgAqi.round(),
                                date: e.dateOfSync,
                              ),
                            )
                            .toList(),
                  ),
                  SizedBox(height: 8),
                  SettingsCard(
                    onPrivacyPolicy: () {
                      // Navigate to privacy policy page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => CommanWebViewWidget(
                                url: "https://sites.google.com/view/aqi-path/",
                                title: 'privacy policy',
                              ),
                        ),
                      );
                    },
                    onAbout: () {
                      // Show about dialog/page
                    },
                    onRemoveAccount: () {
                      // Handle account deletion logic
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => CommanWebViewWidget(
                                url:
                                    "https://sites.google.com/view/aqi-path/delete-account",
                                title: 'Help & Support',
                              ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileCard(context, UserModel data) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.deepPurple.shade100,
            child: Icon(Icons.person, size: 30, color: Colors.deepPurple),
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(data.email, style: TextStyle(color: Colors.black)),
            ],
          ),
          Spacer(),
          // InkWell(
          //   onTap: () {
          //     UtilToast.showMessageForUser(context, "Comming Soon...");
          //   },
          //   child: Icon(Icons.edit_square, color: Colors.grey),
          // ),
        ],
      ),
    );
  }

  Widget _buildBarChartSection(data) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Recent days AQI",
                style: FONT_CONST.BOLD_DEFAULT_24.copyWith(color: Colors.black),
              ),
              Spacer(),
              SizedBox(
                width: 120,
                height: 60,
                child: Image.asset("assets/images/profile_aqi_bg.png"),
              ),
            ],
          ),
          SizedBox(height: 12),
          // ... inside a StatelessWidget or StatefulWidget's build method
          CustomBarChart(
            data: data.map((e) => BarData(e['day'], e['aqi'])).toList(),
            maxYValue: 500,
          ),

          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  "7-Day Average AQI: Know What You’re Breathing.",
                  style: FONT_CONST.REGULAR_DEFAULT.copyWith(
                    color: Colors.black,
                  ),
                ),
              ),

              SizedBox(
                width: SizeConfig.screenWidth * 0.14,
                child: CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.grey,

                  child: Text(
                    "${(data.fold(0, (sum, e) => sum + (e["aqi"] ?? 0)) / data.length).round()}",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection(context, List records) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "History",
              style: FONT_CONST.BOLD_DEFAULT.copyWith(color: Colors.black),
            ),
            if (myHistory.isNotEmpty && myHistory.length > 1)
              TextButton(
                onPressed: () {
                  if (myHistory.length < 3) {
                    _profileBloc.add(GetNavHistoryAqiEvent(frominit: false));
                  } else {
                    showNavigationHistoryBottomSheet(context, myHistory);
                  }
                },
                child: Text(
                  "Show More >",
                  style: FONT_CONST.REGULAR_DEFAULT.copyWith(
                    color: Colors.black87,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 4),
        if (records.isEmpty)
          Center(
            child: Text(
              "No Record",
              style: FONT_CONST.BOLD_DEFAULT_20.copyWith(color: Colors.black12),
            ),
          ),

        ...records.map((r) => AQIHistoryTile(record: r)),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
    );
  }

  Future<void> showNavigationHistoryBottomSheet(
    BuildContext context,
    List<MainNavigationHistory>
    records, // Replace dynamic with your actual model type
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return SafeArea(
              top: false,
              child: Column(
              children: [
                // Top drag handle
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  height: 5,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Navigation History",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: records.length,
                    itemBuilder: (context, index) {
                      final e = records[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 4.0,
                        ),
                        child: AQIHistoryTile(
                          record: AQIRecord(
                            location: e.startAddress,
                            address: e.endAddress,
                            avgAqi: e.routeAvgAqi.round(),
                            date: e.dateOfSync,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              ),
            );
          },
        );
      },
    );
  }
}

class AQIRecord {
  final String location;
  final String address;
  final int avgAqi;
  final DateTime date;

  AQIRecord({
    required this.location,
    required this.address,
    required this.avgAqi,
    required this.date,
  });
}
