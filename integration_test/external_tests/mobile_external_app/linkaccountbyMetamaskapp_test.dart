//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:io';

import 'package:appium_driver/async_io.dart';
import 'package:test/test.dart';

import '../commons/test_util.dart';
import '../pages/onboarding_page.dart';
import '../pages/settings_page.dart';
import '../test_data/test_configurations.dart';

void main() {
  late AppiumWebDriver driver;
  // late AppiumWebDriver driver1;
  final dir = Directory.current;
  group("Link account by", () {
    setUpAll(() async {
      driver = await createDriver(
          uri: Uri.parse(APPIUM_SERVER_URL),
          desired: AUTONOMY_PROFILE(dir.path));

      await driver.timeouts.setImplicitTimeout(const Duration(seconds: 30));
    });

    tearDownAll(() async {
      await driver.app.remove(AUTONOMY_APPPACKAGE);
      await driver.quit();
    });

    test('Metamask', () async {
      try {
        await driver.app.activate(METAMASK_APPPACKAGE);
        sleep(const Duration(seconds: 15));
        await driver.app.activate(AUTONOMY_APPPACKAGE);

        await onBoardingSteps(driver);

        await selectSubSettingMenu(driver, "Settings->+ Account");

        Future<String> metaAccountAliasf = genTestDataRandom("Meta");
        String metaAccountAlias = await metaAccountAliasf;

        await addExistingMetaMaskAccount(driver, "app", metaAccountAlias);

        int isCreatedMetaMaskAcc = await driver
            .findElements(AppiumBy.xpath(
                "//android.view.View[contains(@content-desc,'$metaAccountAlias')]"))
            .length;
        expect(isCreatedMetaMaskAcc, 1);
      } catch (e) {
        await captureScreen(driver);
      }
    });
  }, timeout: Timeout.none);
}
