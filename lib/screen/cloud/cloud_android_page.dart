//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:open_settings/open_settings.dart';
import 'package:autonomy_flutter/view/responsive.dart';

class CloudAndroidPage extends StatefulWidget {
  final bool? isEncryptionAvailable;

  const CloudAndroidPage({Key? key, required this.isEncryptionAvailable})
      : super(key: key);

  @override
  State<CloudAndroidPage> createState() => _CloudAndroidPageState();
}

class _CloudAndroidPageState extends State<CloudAndroidPage>
    with WidgetsBindingObserver {
  bool? isEncryptionAvailable;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    setState(() {
      isEncryptionAvailable = widget.isEncryptionAvailable;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      checkCloudBackup();
    }
  }

  Future checkCloudBackup() async {
    if (isEncryptionAvailable == true) return;

    final accountService = injector<AccountService>();
    final isAndroidEndToEndEncryptionAvailable =
        await accountService.isAndroidEndToEndEncryptionAvailable();

    if (isEncryptionAvailable == isAndroidEndToEndEncryptionAvailable) return;

    if (isEncryptionAvailable == null &&
        isAndroidEndToEndEncryptionAvailable != null) {
      await accountService.androidBackupKeys();
    }

    setState(() {
      isEncryptionAvailable = isAndroidEndToEndEncryptionAvailable;
    });
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: canPop == true
            ? () {
                Navigator.of(context).pop();
              }
            : null,
      ),
      body: _contentWidget(context),
    );
  }

  Widget _contentWidget(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: ResponsiveLayout.pageEdgeInsetsWithSubmitButton,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEncryptionAvailable == true
                          ? "backed_up".tr()
                          : isEncryptionAvailable == false
                              ? "enable_backup_encryption".tr()
                              : "google_cld_bk_unavailable".tr(),
                      style: theme.textTheme.headline1,
                    ),
                    addTitleSpace(),
                    Text(
                      "autonomy_will_auto_bk".tr(),
                      //"Autonomy will automatically back up all of your account information securely, including cryptographic material from accounts you manage as well as links to your accounts. If you ever lose your phone, you will be able to recover everything.",
                      style: theme.textTheme.bodyText1,
                    ),
                    if (isEncryptionAvailable == true) ...[
                      const SizedBox(height: 40),
                      Center(
                          child: SvgPicture.asset("assets/images/cloudOn.svg")),
                    ] else ...[
                      const SizedBox(height: 16),
                      Text(
                        isEncryptionAvailable == false
                            ? "automatic_google_cloud_bks"
                                .tr() //"Automatic Google cloud backups are enabled, but you are not using end-to-end encryption. We recommend enabling it so we can securely back up your account."
                            : "google_cloud_backup_is"
                                .tr(), //"Google cloud backup is currently turned off on your device. If your device supports it, we recommend you enable it so we can safely back up your account.",
                        style: theme.textTheme.headline4,
                      ),
                      const SizedBox(height: 40),
                      Center(
                          child: SvgPicture.asset(isEncryptionAvailable == false
                              ? "assets/images/cloudEncryption.svg"
                              : "assets/images/cloudOff.svg")),
                    ],
                  ]),
            ),
          ),
          _buttonsGroup(context),
        ],
      ),
    );
  }

  Widget _buttonsGroup(BuildContext context) {
    final theme = Theme.of(context);

    if (isEncryptionAvailable == true) {
      return Row(
        children: [
          Expanded(
            child: AuFilledButton(
              text: "continue".tr().toUpperCase(),
              onPress: () => _continue(context),
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AuFilledButton(
                  text: "open_device_setting".tr().toUpperCase(),
                  onPress: () => isEncryptionAvailable == false
                      ? OpenSettings.openBiometricEnrollSetting()
                      : OpenSettings.openAddAccountSetting(),
                ),
              ),
            ],
          ),
          TextButton(
              onPressed: () => _continue(context),
              child: Text("continue_without_it".tr(),
                  style: theme.textTheme.button)),
        ],
      );
    }
  }

  void _continue(BuildContext context) {
    if (injector<ConfigurationService>().isDoneOnboarding()) {
      Navigator.of(context).popUntil((route) =>
          route.settings.name == AppRouter.claimSelectAccountPage ||
          route.settings.name == AppRouter.settingsPage ||
          route.settings.name == AppRouter.wcConnectPage ||
          route.settings.name == AppRouter.homePage ||
          route.settings.name == AppRouter.homePageNoTransition);
    } else {
      doneOnboarding(context);
    }
  }
}
