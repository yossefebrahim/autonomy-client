import 'dart:io';

import 'package:autonomy_flutter/common/app_config.dart';
import 'package:autonomy_flutter/gateway/iap_api.dart';
import 'package:autonomy_flutter/model/network.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/device.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:floor/floor.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class BackupService {
  final IAPApi _iapApi;
  final ConfigurationService _configurationService;

  BackupService(this._iapApi, this._configurationService);

  Future backupCloudDatabase() async {
    log.info("[BackupService] start database backup");
    final filename = 'cloud_database.db';

    try {
      final path = await sqfliteDatabaseFactory.getDatabasePath(filename);
      final file = File(path);

      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String version = packageInfo.version;
      String? deviceId = await getBackupId();

      await _iapApi.uploadProfile(deviceId, filename, version, file);
    } catch (err) {
      print(err);
      log.warning("[BackupService] error database backup");
    }

    log.info("[BackupService] done database backup");
  }

  Future<String> fetchBackupVersion() async {
    final filename = 'cloud_database.db';

    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String version = packageInfo.version;

    String? deviceId = await getBackupId();

    final result = await _iapApi.getProfileVersions(deviceId, filename);

    var versions = result.versions..sort((a, b) => compare(b, a));

    String backupVersion = "";
    for (String element in versions) {
      if (compare(element, version) <= 0) {
        backupVersion = element;
        break;
      }
    }

    return backupVersion;
  }

  Future restoreCloudDatabase(String version) async {
    log.info("[BackupService] start database restore");
    final filename = 'cloud_database.db';

    String? deviceId = await getBackupId();

    final endpoint;

    if (_configurationService.getNetwork() == Network.TESTNET) {
      endpoint = AppConfig.testNetworkConfig.autonomyAuthUrl;
    } else {
      endpoint = AppConfig.mainNetworkConfig.autonomyAuthUrl;
    }

    final response = await http.get(
        Uri.parse(
            "$endpoint/apis/v1/premium/profile-data?filename=$filename&appVersion=$version"),
        headers: {"requester": deviceId});

    if (response.contentLength == 0 && response.statusCode != 200) {
      log.warning("[BackupService] failed database restore");
      return;
    }

    final path = await sqfliteDatabaseFactory.getDatabasePath(filename);
    final file = File(path);

    await file.writeAsBytes(response.bodyBytes, flush: true);

    log.info("[BackupService] done database restore");
  }

  int compare(String version1, String version2) {
    final ver1 = version1.split(".").map((e) => int.parse(e)).toList();
    final ver2 = version2.split(".").map((e) => int.parse(e)).toList();

    var i = 0;
    while (i < ver1.length) {
      final result = ver1[i] - ver2[i];
      if (result != 0) {
        return result;
      }
      i++;
    }

    return 0;
  }

  Future<String> getBackupId() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String? deviceId = await getDeviceID();

    return "$deviceId\_${packageInfo.packageName}";
  }
}