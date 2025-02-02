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
import 'package:autonomy_flutter/view/au_text_field.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:autonomy_flutter/view/responsive.dart';

class LinkManuallyPage extends StatefulWidget {
  final String type;
  const LinkManuallyPage({required this.type, Key? key}) : super(key: key);

  @override
  State<LinkManuallyPage> createState() => _LinkManuallyPageState();
}

class _LinkManuallyPageState extends State<LinkManuallyPage> {
  final TextEditingController _addressController = TextEditingController();
  bool _linkEnabled = false;

  String get title {
    switch (widget.type) {
      case 'address':
        return 'link_address'.tr();
      case 'indexerTokenID':
        return 'indexer_tokenId'.tr();
      default:
        return '';
    }
  }

  String get description {
    switch (widget.type) {
      case 'address':
        return 'to_manually_input_a'
            .tr(); //"To manually input an address (Debug only)."
      case 'indexerTokenID':
        return 'to_manually_input_ti'
            .tr(); //"To manually input an indexer TokenID (Debug only)."
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Container(
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
                      title,
                      style: theme.textTheme.headline1,
                    ),
                    addTitleSpace(),
                    Text(
                      description,
                      style: theme.textTheme.bodyText1,
                    ),
                    const SizedBox(height: 40),
                    AuTextField(
                      title: "",
                      placeholder: "paste".tr(args: [widget.type]),
                      controller: _addressController,
                      onChanged: (value) => setState(() {
                        _linkEnabled = value.trim().isNotEmpty;
                      }),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: AuFilledButton(
                    text: "link".tr().toUpperCase(),
                    enabled: _linkEnabled,
                    onPress: () => _link(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _link() async {
    switch (widget.type) {
      case 'address':
        await injector<AccountService>()
            .linkManuallyAddress(_addressController.text.trim());
        if (!mounted) return;
        UIHelper.showInfoDialog(context, 'account_linked'.tr(),
            'autonomy_has_linked_your_address'.tr());
        break;

      case 'indexerTokenID':
        await injector<AccountService>()
            .linkIndexerTokenID(_addressController.text.trim());
        if (!mounted) return;
        UIHelper.showInfoDialog(context, 'account_linked'.tr(),
            'autonomy_has_linked_your_address'.tr());
        break;

      default:
        return;
    }

    Future.delayed(SHORT_SHOW_DIALOG_DURATION, () {
      if (injector<ConfigurationService>().isDoneOnboarding()) {
        Navigator.of(context)
            .popUntil((route) => route.settings.name == AppRouter.settingsPage);
      } else {
        doneOnboarding(context);
      }
    });
  }
}
