//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/settings/crypto/wallet_detail/tezos_transaction_list_view.dart';
import 'package:autonomy_flutter/screen/settings/crypto/wallet_detail/wallet_detail_bloc.dart';
import 'package:autonomy_flutter/screen/settings/crypto/wallet_detail/wallet_detail_state.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:url_launcher/url_launcher_string.dart';

class WalletDetailPage extends StatefulWidget {
  final WalletDetailsPayload payload;

  const WalletDetailPage({Key? key, required this.payload}) : super(key: key);

  @override
  State<WalletDetailPage> createState() => _WalletDetailPageState();
}

class _WalletDetailPageState extends State<WalletDetailPage> with RouteAware {
  @override
  void didChangeDependencies() {
    routeObserver.subscribe(this, ModalRoute.of(context)!);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    final cryptoType = widget.payload.type;
    final wallet = widget.payload.wallet;
    context
        .read<WalletDetailBloc>()
        .add(WalletDetailBalanceEvent(cryptoType, wallet));
  }

  @override
  Widget build(BuildContext context) {
    final cryptoType = widget.payload.type;
    final wallet = widget.payload.wallet;
    context
        .read<WalletDetailBloc>()
        .add(WalletDetailBalanceEvent(cryptoType, wallet));
    final theme = Theme.of(context);
    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () {
          Navigator.of(context).pop();
        },
      ),
      body: BlocConsumer<WalletDetailBloc, WalletDetailState>(
          listener: (context, state) async {},
          builder: (context, state) {
        return Container(
          margin: const EdgeInsets.only(
            top: 16.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16.0),
              SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      state.balance.isNotEmpty
                          ? state.balance
                          : "-- ${widget.payload.type == CryptoType.ETH ? "ETH" : "XTZ"}",
                      style: theme.textTheme.ibmBlackBold24,
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      state.balanceInUSD.isNotEmpty
                          ? state.balanceInUSD
                          : "-- USD",
                      style: theme.textTheme.subtitle1,
                    )
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: widget.payload.type == CryptoType.XTZ
                    ? TezosTXListView(address: state.address)
                    : Container(),
              ),
              widget.payload.type == CryptoType.XTZ
                  ? GestureDetector(
                      onTap: () => launchUrlString(_txURL(state.address)),
                      child: Container(
                        alignment: Alignment.bottomCenter,
                        padding: const EdgeInsets.fromLTRB(0, 17, 0, 20),
                        color: AppColor.secondaryDimGreyBackground,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("powered_by_tzkt".tr().toUpperCase(),
                                style: theme.textTheme.button),
                            const SizedBox(
                              width: 4,
                            ),
                            SvgPicture.asset("assets/images/external_link.svg"),
                          ],
                        ),
                      ),
                    )
                  : Container(),
            ],
          ),
        );
      }),
    );
  }

  String _txURL(String address) {
    return "https://tzkt.io/$address/operations";
  }
}

class WalletDetailsPayload {
  final CryptoType type;
  final WalletStorage wallet;

  WalletDetailsPayload({
    required this.type,
    required this.wallet,
  });
}
