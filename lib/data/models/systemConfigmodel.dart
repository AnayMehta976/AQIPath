class SystemConfig {
  final String? changeLog;
  final String? googleAQIKey;
  final String? googleMapKey;
  final int? googleApiCallAfter;
  final bool? randomAqiGen;
  final int? versionCode;
  final String? versionName;
  final String? waqiKey;
  final bool? ismandotory;
  final String? changeLogIos;
  final int? versionCodeIos;
  final String? versionNameIos;

  SystemConfig({
    this.changeLog,
    this.googleAQIKey,
    this.googleMapKey,
    this.googleApiCallAfter,
    this.randomAqiGen,
    this.versionCode,
    this.versionName,
    this.waqiKey,
    this.ismandotory,
    this.changeLogIos,
    this.versionCodeIos,
    this.versionNameIos,
  });

  /// From Firestore / JSON
  factory SystemConfig.fromJson(Map<String, dynamic> json) {
    return SystemConfig(
      changeLog: json['ChangeLog'] as String?,
      googleAQIKey: json['GoogleAQIKey'] as String?,
      googleMapKey: json['GoogleMapKey'] as String?,
      googleApiCallAfter:
          json['Googleapicallafter'] is int
              ? json['Googleapicallafter'] as int
              : int.tryParse(json['Googleapicallafter']?.toString() ?? ''),
      randomAqiGen: json['RandomAqiGen'] as bool?,
      versionCode:
          json['VersionCode'] is int
              ? json['VersionCode'] as int
              : int.tryParse(json['VersionCode']?.toString() ?? ''),
      versionName: json['VersionName'] as String?,
      waqiKey: json['WaqiKey'] as String?,
      ismandotory: json["isMandatoryUpdate"] ?? false,
      changeLogIos: json['ChangeLogIos'] as String?,
      versionCodeIos:
          json['VersionCodeIos'] is int
              ? json['VersionCodeIos'] as int
              : int.tryParse(json['VersionCodeIos']?.toString() ?? ''),
      versionNameIos: json['VersionNameIos'] as String?,
    );
  }

  /// To JSON (for saving in SharedPreferences)
  Map<String, dynamic> toJson() {
    return {
      'ChangeLog': changeLog,
      'GoogleAQIKey': googleAQIKey,
      'GoogleMapKey': googleMapKey,
      'Googleapicallafter': googleApiCallAfter,
      'RandomAqiGen': randomAqiGen,
      'VersionCode': versionCode,
      'VersionName': versionName,
      'WaqiKey': waqiKey,
      'isMandatoryUpdate': ismandotory,
      'ChangeLogIos': changeLogIos,
      'VersionCodeIos': versionCodeIos,
      'VersionNameIos': versionNameIos,
    };
  }
}
