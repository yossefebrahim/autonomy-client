//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/screen/settings/subscription/upgrade_bloc.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_state.dart';
import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MoreAutonomyPage extends StatelessWidget {
  const MoreAutonomyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    context.read<UpgradesBloc>().add(UpgradeQueryInfoEvent());
    final theme = Theme.of(context);

    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () {
          Navigator.of(context).pop();
        },
      ),
      body: BlocConsumer<UpgradesBloc, UpgradeState>(
        listener: (context, state) {
          if (state.status == IAPProductStatus.completed ||
              state.status == IAPProductStatus.error) {
            newAccountPageOrSkipInCondition(context);
          }
        },
        builder: (context, state) {
          return Container(
            margin: const EdgeInsets.only(
                top: 16.0, left: 16.0, right: 16.0, bottom: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("more_autonomy".tr(), style: theme.textTheme.headline1),
                const SizedBox(height: 40),
                Expanded(
                  child: ListView(
                    children: [
                      Text('upgrading_gives_you'.tr(),
                          style: theme.textTheme.bodyText1),
                      FittedBox(
                        child: SvgPicture.asset(
                          'assets/images/premium_comparation_light.svg',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text("gg_tv_app".tr(), style: theme.textTheme.headline5),
                    ],
                  ),
                ),
                AuFilledButton(
                  text: "sub_then_price".tr(
                      args: [state.productDetails?.price ?? "4.99usd".tr()]),
                  //"SUBSCRIBE FOR A 30-DAY FREE TRIAL\n(THEN ${state.productDetails?.price ?? "US\$4.99"}/MONTH)",
                  textAlign: TextAlign.center,
                  onPress: state.status == IAPProductStatus.loading ||
                          state.status == IAPProductStatus.pending
                      ? null
                      : () {
                          context
                              .read<UpgradesBloc>()
                              .add(UpgradePurchaseEvent());
                        },
                  textStyle: theme.primaryTextTheme.button,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => newAccountPageOrSkipInCondition(context),
                      child: Text(
                        "not_now".tr(),
                        style: theme.textTheme.button,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
