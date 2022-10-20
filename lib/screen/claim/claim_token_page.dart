import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/screen/claim/preview_token_claim.dart';
import 'package:autonomy_flutter/screen/claim/select_account_page.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/util/feralfile_extension.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:autonomy_flutter/view/au_button_clipper.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class ClaimTokenPage extends StatefulWidget {
  final Exhibition exhibition;

  const ClaimTokenPage({
    Key? key,
    required this.exhibition,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ClaimTokenPageState();
  }
}

class _ClaimTokenPageState extends State<ClaimTokenPage> {
  bool _processing = false;

  @override
  Widget build(BuildContext context) {
    final exhibition = widget.exhibition;
    final artwork = exhibition.airdropArtwork;
    final artist = exhibition.getArtist(artwork);
    final artistName = artist?.getDisplayName();
    final artworkThumbnail =
        artwork?.getThumbnailURL() ?? exhibition.getThumbnailURL();
    String gifter =
        exhibition.airdropInfo?.gifter?.replaceAll(" ", "\u00A0") ?? "";
    String giftIntro = "you_can_receive_free_gift".tr();
    if (gifter.trim().isNotEmpty) {
      giftIntro += " ${'from'.tr().toLowerCase()} ";
    }
    double safeAreaTop = MediaQuery.of(context).padding.top;
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      body: Container(
        padding: EdgeInsets.fromLTRB(14, safeAreaTop, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 52,
              child: Center(
                child: Text(
                  "autonomy".tr(),
                  style: theme.primaryTextTheme.bodyText1?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            Expanded(
              child: NotificationListener<OverscrollIndicatorNotification>(
                onNotification: (overScroll) {
                  overScroll.disallowIndicator();
                  return false;
                },
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    const SizedBox(
                      height: 24,
                    ),
                    FittedBox(
                      child: Text(
                        "congratulations".tr(),
                        style: theme.primaryTextTheme.headline1,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(
                      height: 40,
                    ),
                    RichText(
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        text: giftIntro,
                        style: theme.primaryTextTheme.bodyText1,
                        children: [
                          TextSpan(
                            text: gifter,
                            style: theme.primaryTextTheme.bodyText1
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(
                            text: ".",
                            style: theme.primaryTextTheme.bodyText1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      child: Stack(
                        alignment: AlignmentDirectional.center,
                        children: [
                          Transform.translate(
                            offset: const Offset(1, 0),
                            child: ClipPath(
                              clipper: AutonomyTopRightRectangleClipper(),
                              child: CachedNetworkImage(
                                fit: BoxFit.cover,
                                imageUrl: artworkThumbnail,
                                width: 264,
                                height: 264,
                              ),
                            ),
                          ),
                          Image.asset("assets/images/ribbon.png"),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PreviewTokenClaim(
                              exhibition: widget.exhibition,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      child: Text(
                        artwork?.title ?? widget.exhibition.title,
                        style: makeLinkStyle(
                            theme.primaryTextTheme.bodyText1!.copyWith(
                          fontWeight: FontWeight.w700,
                        )),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PreviewTokenClaim(
                              exhibition: widget.exhibition,
                            ),
                          ),
                        );
                      },
                    ),
                    Text(
                      "by $artistName",
                      style: theme.primaryTextTheme.bodyText1,
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Text(
                      "accept_ownership_desc".tr(),
                      style: theme.primaryTextTheme.bodyText1,
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    RichText(
                      text: TextSpan(
                        text: "airdrop_accept_privacy_policy".tr(),
                        style: theme.primaryTextTheme.bodyText1
                            ?.copyWith(fontSize: 14),
                        children: [
                          TextSpan(
                              text: "airdrop_privacy_policy".tr(),
                              style: makeLinkStyle(
                                  theme.primaryTextTheme.bodyText1!.copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold)),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  _openPrivacyPolicy();
                                }),
                          TextSpan(
                            text: ".",
                            style: theme.primaryTextTheme.bodyText1
                                ?.copyWith(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(
              height: 24,
            ),
            AuFilledButton(
              text: "accept_ownership".tr(),
              color: theme.colorScheme.secondary,
              textStyle: theme.textTheme.button,
              enabled: !_processing,
              isProcessing: _processing,
              onPress: () async {
                setState(() {
                  _processing = true;
                });
                final blockchain =
                    widget.exhibition.mintBlockchain.capitalize();
                final accountService = injector<AccountService>();
                final addresses = await accountService.getAddress(blockchain);

                String? address;
                if (addresses.isEmpty) {
                  final defaultAccount =
                      await accountService.getDefaultAccount();
                  final configService = injector<ConfigurationService>();
                  await configService.setDoneOnboarding(true);
                  await configService.setPendingSettings(true);
                  address = blockchain == "Tezos"
                      ? await defaultAccount.getTezosAddress()
                      : await defaultAccount.getETHAddress();
                } else if (addresses.length == 1) {
                  address = addresses.first;
                } else {
                  if (!mounted) return;
                  final account = await Navigator.of(context).pushNamed(
                    AppRouter.claimSelectAccountPage,
                    arguments: SelectAccountPageArgs(
                      blockchain,
                      widget.exhibition.id,
                      widget.exhibition,
                    ),
                  ) as Account?;
                  final wallet = account?.persona?.wallet();
                  if (wallet != null) {
                    address = blockchain == "Tezos"
                        ? await wallet.getTezosAddress()
                        : await wallet.getETHAddress();
                  } else if (account?.connections?.isNotEmpty == true) {
                    final connectionType = blockchain == "Tezos"
                        ? "walletBeacon"
                        : "walletConnect";
                    address = account?.connections
                        ?.firstWhereOrNull(
                            (e) => e.connectionType == connectionType)
                        ?.accountNumber;
                  }
                  address ??= account?.accountNumber;
                }
                if (address != null && mounted) {
                  _claimToken(context, address);
                } else {
                  setState(() {
                    _processing = false;
                  });
                }
              },
            ),
            AuFilledButton(
              text: "decline".tr(),
              enabled: !_processing,
              onPress: () {
                memoryValues.airdropFFExhibitionId.value = null;
                Navigator.of(context).pop(false);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future _claimToken(BuildContext context, String receiveAddress) async {
    final ffService = injector<FeralFileService>();
    try {
      await ffService.claimToken(
        exhibitionId: widget.exhibition.id,
        address: receiveAddress,
      );
      memoryValues.airdropFFExhibitionId.value = null;
    } catch (e) {
      log.info("[ClaimTokenPage] Claim token failed. $e");
      await UIHelper.showClaimTokenError(
        context,
        e,
        exhibition: widget.exhibition,
      );
      memoryValues.airdropFFExhibitionId.value = null;
    }
    setState(() {
      _processing = false;
    });
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRouter.homePage,
        (route) => false,
      );
    }
  }

  void _openPrivacyPolicy() {
    Navigator.of(context).pushNamed(AppRouter.githubDocPage, arguments: {
      "prefix": "/bitmark-inc/autonomy.io/main/apps/docs/",
      "document": "privacy.md",
      "title": ""
    });
  }
}