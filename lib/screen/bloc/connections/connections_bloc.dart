//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/model/p2p_peer.dart';
import 'package:autonomy_flutter/service/tezos_beacon_service.dart';
import 'package:autonomy_flutter/service/wallet_connect_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import "package:collection/collection.dart";
import 'package:wallet_connect/wallet_connect.dart';

part 'connections_state.dart';

class ConnectionsBloc extends AuBloc<ConnectionsEvent, ConnectionsState> {
  final CloudDatabase _cloudDB;
  final WalletConnectService _walletConnectService;
  final TezosBeaconService _tezosBeaconService;

  ConnectionsBloc(
      this._cloudDB, this._walletConnectService, this._tezosBeaconService)
      : super(ConnectionsState()) {
    on<GetETHConnectionsEvent>((event, emit) async {
      emit(state.resetConnectionItems());
      final personaUUID = event.personUUID;

      final connections = await _cloudDB.connectionDao
          .getConnectionsByType(ConnectionType.dappConnect.rawValue);

      List<Connection> personaConnections = [];
      for (var connection in connections) {
        final wcConnection = connection.wcConnection;
        if (wcConnection == null) continue;

        if (wcConnection.personaUuid == personaUUID &&
            wcConnection.sessionStore.remotePeerMeta.name !=
                AUTONOMY_TV_PEER_NAME) {
          personaConnections.add(connection);
        }
      }

      // PersonaConnectionsPage is showing combined connections based on app
      final resultGroup =
          groupBy(personaConnections, (Connection conn) => conn.appName);
      final connectionItems = resultGroup.values
          .map((conns) =>
              ConnectionItem(representative: conns.first, connections: conns))
          .toList();

      emit(state.copyWith(connectionItems: connectionItems));
    });

    on<GetXTZConnectionsEvent>((event, emit) async {
      emit(state.resetConnectionItems());
      final personaUUID = event.personUUID;

      final connections = await _cloudDB.connectionDao
          .getConnectionsByType(ConnectionType.beaconP2PPeer.rawValue);

      List<Connection> personaConnections = [];
      for (var connection in connections) {
        if (connection.beaconConnectConnection?.personaUuid == personaUUID) {
          personaConnections.add(connection);
        }
      }

      // PersonaConnectionsPage is showing combined connections based on app
      final resultGroup =
          groupBy(personaConnections, (Connection conn) => conn.appName);
      final connectionItems = resultGroup.values
          .map((conns) =>
              ConnectionItem(representative: conns.first, connections: conns))
          .toList();

      emit(state.copyWith(connectionItems: connectionItems));
    });

    on<DeleteConnectionsEvent>((event, emit) async {
      Set<WCPeerMeta> wcPeers = {};
      Set<P2PPeer> bcPeers = {};

      for (var connection in event.connectionItem.connections) {
        await _cloudDB.connectionDao.deleteConnection(connection);

        final wcPeer = connection.wcConnection?.sessionStore.peerMeta;
        if (wcPeer != null) wcPeers.add(wcPeer);

        final bcPeer = connection.beaconConnectConnection?.peer;
        if (bcPeer != null) bcPeers.add(bcPeer);
      }

      for (var peer in wcPeers) {
        _walletConnectService.disconnect(peer);
      }

      for (var peer in bcPeers) {
        _tezosBeaconService.removePeer(peer);
      }
    });
  }
}
