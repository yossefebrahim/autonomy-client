//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';
import 'dart:typed_data';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/mixPanel_client_service.dart';
import 'package:autonomy_flutter/service/tezos_beacon_service.dart';
import 'package:autonomy_flutter/service/tezos_service.dart';
import 'package:autonomy_flutter/util/debouce_util.dart';
import 'package:autonomy_flutter/util/inapp_notifications.dart';
import 'package:autonomy_flutter/util/tezos_beacon_channel.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:web3dart/crypto.dart';

class TBSignMessagePage extends StatefulWidget {
  static const String tag = 'tb_sign_message';
  final BeaconRequest request;

  const TBSignMessagePage({Key? key, required this.request}) : super(key: key);

  @override
  State<TBSignMessagePage> createState() => _TBSignMessagePageState();
}

class _TBSignMessagePageState extends State<TBSignMessagePage> {
  WalletStorage? _currentPersona;

  @override
  void initState() {
    super.initState();
    fetchPersona();
  }

  Future fetchPersona() async {
    final personas = await injector<CloudDatabase>().personaDao.getPersonas();
    WalletStorage? currentWallet;
    for (final persona in personas) {
      final address = await persona.wallet().getTezosAddress();
      if (address == widget.request.sourceAddress) {
        currentWallet = persona.wallet();
        break;
      }
    }

    if (currentWallet == null) {
      await injector<TezosBeaconService>().signResponse(widget.request.id, null);
      if (!mounted) return;
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _currentPersona = currentWallet;
    });
  }

  @override
  Widget build(BuildContext context) {
    final message = hexToBytes(widget.request.payload!);
    final Uint8List viewMessage = message.length > 6 &&
            message.sublist(0, 2).equals(Uint8List.fromList([5, 1]))
        ? message.sublist(6)
        : message;
    final messageInUtf8 = utf8.decode(viewMessage, allowMalformed: true);

    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: () async {
        await injector<TezosBeaconService>().signResponse(widget.request.id, null);
        return true;
      },
      child: Scaffold(
        appBar: getBackAppBar(
          context,
          onBack: () async {
            await injector<TezosBeaconService>()
                .signResponse(widget.request.id, null);
            Navigator.of(context).pop();
          },
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
                      const SizedBox(height: 8.0),
                      Text(
                        "signature_request".tr(),
                        style: theme.textTheme.headline1,
                      ),
                      const SizedBox(height: 40.0),
                      Text(
                        "connection".tr(),
                        style: theme.textTheme.headline4,
                      ),
                      const SizedBox(height: 16.0),
                      Text(
                        widget.request.appName ?? "",
                        style: theme.textTheme.bodyText2,
                      ),
                      const Divider(height: 32),
                      Text(
                        "message".tr(),
                        style: theme.textTheme.headline4,
                      ),
                      const SizedBox(height: 16.0),
                      Text(
                        messageInUtf8,
                        style: theme.textTheme.bodyText2,
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: AuFilledButton(
                      text: "sign".tr().toUpperCase(),
                      onPress: _currentPersona != null
                          ? () => withDebounce(() async {
                                final signature = await injector<TezosService>()
                                    .signMessage(_currentPersona!, message);
                                await injector<TezosBeaconService>()
                                    .signResponse(widget.request.id, signature);
                                if (!mounted) return;

                                final mixPanelClient = injector.get<MixPanelClientService>();
                                mixPanelClient.trackEvent(
                                  "Sign In",
                                  hashedData: {"uuid": widget.request.id},
                                );
                                Navigator.of(context).pop();
                                final notificationEnable =
                                    injector<ConfigurationService>().isNotificationEnabled() ?? false;
                                if (notificationEnable) {
                                  showInfoNotification(
                                    const Key("signed"),
                                    "signed".tr().toUpperCase(),
                                    frontWidget: SvgPicture.asset("assets/images/checkbox_icon.svg"),
                                  );
                                }
                              })
                          : null,
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
