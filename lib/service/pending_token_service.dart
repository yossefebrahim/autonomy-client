import 'package:autonomy_flutter/gateway/tzkt_api.dart';
import 'package:autonomy_flutter/model/tzkt_operation.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:collection/collection.dart';
import 'package:nft_collection/database/dao/asset_token_dao.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/services/tokens_service.dart';
import 'package:web3dart/web3dart.dart';

const _erc1155Topic =
    "0XC3D58168C5AE7397731D063D5BBF3D657854427343F4C083240F7AACAA2D0F62";
const _erc721Topic =
    "0XDDF252AD1BE2C89B69C2B068FC378DAA952BA7F163C4A11628F55A4DF523B3EF";

const _maxRetries = 5;

extension FilterEventExt on FilterEvent {
  bool isERC721() {
    return topics?.firstOrNull?.toUpperCase() == _erc721Topic;
  }

  bool isErc1155() {
    return topics?.firstOrNull?.toUpperCase() == _erc1155Topic;
  }

  BigInt? getERC721TokenId() {
    if (topics?.length == 4) {
      return BigInt.tryParse(
        topics?.last.replacePrefix("0x", "") ?? "",
        radix: 16,
      );
    } else {
      return null;
    }
  }

  BigInt? getERC1155TokenId() {
    final tokenId = data?.replaceFirst("0x", "").substring(0, 64);
    return BigInt.tryParse(tokenId ?? "", radix: 16);
  }

  AssetToken? toAssetToken(String owner, DateTime timestamp) {
    String? contractType;
    BigInt? tokenId;

    if (isErc1155()) {
      contractType = "erc1155";
      tokenId = getERC1155TokenId();
    } else if (isERC721()) {
      contractType = "erc721";
      tokenId = getERC721TokenId();
    }

    if (contractType != null && tokenId != null) {
      final indexerId = "eth-${address?.hexEip55}-${tokenId.toRadixString(16)}";
      final token = AssetToken(
        artistName: null,
        artistURL: null,
        artistID: null,
        assetData: null,
        assetID: null,
        assetURL: null,
        basePrice: null,
        baseCurrency: null,
        blockchain: "ethereum",
        blockchainUrl: null,
        fungible: false,
        contractType: contractType,
        tokenId: "$tokenId",
        contractAddress: address?.hexEip55 ?? "",
        desc: null,
        edition: 0,
        id: indexerId,
        maxEdition: 1,
        medium: null,
        mimeType: null,
        mintedAt: null,
        previewURL: null,
        source: address?.hexEip55,
        sourceURL: null,
        thumbnailID: null,
        thumbnailURL: null,
        galleryThumbnailURL: null,
        title: "",
        ownerAddress: owner,
        owners: {
          owner: 1,
        },
        lastActivityTime: timestamp,
        pending: true,
      );
      return token;
    }
    return null;
  }
}

extension TZKTTokenExtension on TZKTToken {
  AssetToken toAssetToken(
    String owner,
    DateTime timestamp,
  ) {
    return AssetToken(
      artistName:
          (metadata?["creators"] as List<dynamic>?)?.cast<String>().firstOrNull,
      artistURL: null,
      artistID: null,
      assetData: null,
      assetID: null,
      assetURL: null,
      basePrice: null,
      baseCurrency: null,
      blockchain: "tezos",
      blockchainUrl: null,
      fungible: false,
      contractType: standard,
      tokenId: tokenId,
      contractAddress: contract?.address,
      desc: null,
      edition: 0,
      id: "tez-${contract?.address}-$tokenId",
      maxEdition: 1,
      medium: null,
      mimeType: metadata?["formats"]?[0]?["mimeType"],
      mintedAt: null,
      previewURL: metadata?["thumbnailUri"],
      source: contract?.address,
      sourceURL: null,
      thumbnailID: null,
      thumbnailURL: metadata?["thumbnailUri"],
      galleryThumbnailURL: metadata?["thumbnailUri"],
      title: metadata?["name"] ?? "",
      ownerAddress: owner,
      owners: {
        owner: 1,
      },
      lastActivityTime: timestamp,
      pending: true,
    );
  }
}

class PendingTokenService {
  final TZKTApi _tzktApi;
  final Web3Client _web3Client;
  final TokensService _tokenService;
  final AssetTokenDao _assetTokenDao;

  PendingTokenService(
    this._tzktApi,
    this._web3Client,
    this._tokenService,
    this._assetTokenDao,
  );

  Future<bool> checkPendingEthereumTokens(String owner, String tx) async {
    log.info(
        "[PendingTokenService] Check pending Ethereum tokens: $owner, $tx");
    int retryCount = 0;
    TransactionReceipt? receipt;
    while (receipt == null && retryCount < _maxRetries) {
      receipt = await _web3Client.getTransactionReceipt(tx);
      log.info("[PendingTokenService] Receipt: $receipt");
      if (receipt != null) {
        break;
      } else {
        await Future.delayed(Duration(milliseconds: 3000 * (retryCount + 1)));
        retryCount++;
      }
    }
    if (receipt != null) {
      final pendingTokens = receipt.logs
          .map((e) => e.toAssetToken(owner, DateTime.now()))
          .where((element) => element != null)
          .map((e) => e as AssetToken)
          .toList();
      log.info(
          "[PendingTokenService] Pending Tokens: ${pendingTokens.map((e) => e.id).toList()}");
      if (pendingTokens.isNotEmpty) {
        await _tokenService.setCustomTokens(pendingTokens);
        await _tokenService.reindexAddresses([owner]);
      }
      return pendingTokens.isNotEmpty;
    } else {
      return false;
    }
  }

  Future<bool> checkPendingTezosTokens(String owner) async {
    log.info("[PendingTokenService] Check pending Tezos tokens: $owner");
    int retryCount = 0;
    final pendingTokens = List<AssetToken>.empty(growable: true);
    final ownedTokenIds = await getTokenIDs(owner);

    while (pendingTokens.isEmpty && retryCount < _maxRetries) {
      final operations = await _tzktApi.getTokenTransfer(
        to: owner,
        sort: "timestamp",
        limit: 3,
      );
      final tokens = operations
          .map((e) => e.token?.toAssetToken(owner, DateTime.now()))
          .where((e) => e != null)
          .map((e) => e as AssetToken)
          .toList();
      final newTokens = tokens.where((e) => !ownedTokenIds.contains(e.id)).toList();
      pendingTokens.addAll(newTokens);
      if (pendingTokens.isNotEmpty) {
        log.info(
            "[PendingTokenService] Found ${pendingTokens.length} new tokens.");
        break;
      } else {
        log.info("[PendingTokenService] Not found any new tokens.");
        await Future.delayed(Duration(milliseconds: 3000 * (retryCount + 1)));
        retryCount++;
      }
    }

    if (pendingTokens.isNotEmpty) {
      await _tokenService.setCustomTokens(pendingTokens);
      await _tokenService.reindexAddresses([owner]);
    }
    return pendingTokens.isNotEmpty;
  }

  Future<List<String>> getTokenIDs(String owner) async {
    return _assetTokenDao.findAllAssetTokenIDsByOwner(owner);
  }
}