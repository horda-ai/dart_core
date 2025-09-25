import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:logging/logging.dart';

import 'error.dart';
import 'id.dart';
import 'message.dart';
import 'query_def.dart';
import 'query_res.dart';

part 'ws.g.dart';

/// Container for WebSocket messages with unique identification.
///
/// Wraps WebSocket messages with an ID for request/response correlation
/// and provides JSON encoding/decoding with error handling.
class WsMessageBox {
  /// Unique identifier for this message.
  final int id;

  /// The actual message payload.
  final WsMessage msg;

  /// Creates a WebSocket message box with ID and message.
  WsMessageBox({required this.id, required this.msg});

  factory WsMessageBox.decodeJson(String str, Logger logger) {
    try {
      var json = jsonDecode(str);

      var id = json['id'];
      if (id is! int) {
        throw FluirError('no "id" field found');
      }

      var type = json['type'];
      if (type is! String) {
        throw FluirError('no "type" field found');
      }

      var fac = switch (type) {
        'welcome' => WelcomeWsMsg.fromJson,
        'query' => QueryWsMsg.fromJson,
        'query_result' => QueryResultWsMsg.fromJson,
        'send' => SendCommandWsMsg.fromJson,
        'sendack' => SendCommandAckWsMsg.fromJson,
        'call' => CallCommandWsMsg.fromJson,
        'callres' => CallCommandResWsMsg.fromJson,
        'dispatch' => DispatchEventWsMsg.fromJson,
        'dispatchres' => DispatchEventResWsMsg.fromJson,
        'subv' => SubscribeViewsWsMsg.fromJson,
        'subvack' => SubscribeViewsAckWsMsg.fromJson,
        'suba' => SubscribeActorWsMsg.fromJson,
        'subares' => SubscribeActorResWsMsg.fromJson,
        'unsuba' => UnsubscribeActorWsMsg.fromJson,
        'unsubares' => UnsubscribeActorResWsMsg.fromJson,
        'unsubv' => UnsubscribeViewsWsMsg.fromJson,
        'unsubvres' => UnsubscribeViewsResWsMsg.fromJson,
        'evt' => ActorEventWsMsg.fromJson,
        'chg' => ViewChangeWsMsg.fromJson,
        'error' => ErrorWsMsg.fromJson,
        _ => throw FluirError('unknown type $type'),
      };

      return WsMessageBox(id: id, msg: fac(json['msg']));
    } catch (e) {
      logger.severe('decode json error: $e');

      return WsMessageBox(id: -1, msg: ErrorWsMsg(str, e.toString()));
    }
  }

  String encodeJson(Logger logger) {
    try {
      return jsonEncode({
        'id': id,
        'type': msg.messageType,
        'msg': msg.toJson(),
      });
    } catch (e) {
      final msg = '$id jsonEncode() error: $e';
      logger.severe(msg);

      return jsonEncode({'id': id, 'type': 'error', 'msg': msg});
    }
  }

  @override
  String toString() {
    return 'WsMessageBox(id: $id, type: ${msg.messageType})';
  }
}

/// Base class for all WebSocket messages in the Horda platform.
///
/// Defines the common interface for messages sent over WebSocket connections
/// between clients and the Horda server.
sealed class WsMessage {
  /// Type identifier for this message used in JSON serialization.
  String get messageType;

  /// Converts the message to JSON for network transmission.
  Map<String, dynamic> toJson();
}

/// Welcome message sent by server after WebSocket connection establishment.
///
/// Provides client identification and server version information.
@JsonSerializable()
class WelcomeWsMsg implements WsMessage {
  /// Creates a welcome message.
  WelcomeWsMsg(this.userId, this.serverVersion);

  /// ID of the authenticated user, or null for anonymous connections.
  final String? userId;

  /// Version of the Horda server.
  final String serverVersion;

  @override
  String get messageType => 'welcome';

  factory WelcomeWsMsg.fromJson(Map<String, dynamic> json) =>
      _$WelcomeWsMsgFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$WelcomeWsMsgToJson(this);

  @override
  String toString() => toJson().toString();
}

/// Message requesting a query on an entity's views.
///
/// Sent by clients to retrieve current view data from specific entities
/// with optional real-time subscriptions.
@JsonSerializable()
class QueryWsMsg implements WsMessage {
  /// Creates a query message for the specified entity and query definition.
  QueryWsMsg({required this.actorId, required this.def});

  @override
  String get messageType => 'query';

  /// ID of the entity to query.
  final String actorId;

  /// Definition specifying which views to query and how.
  @JsonKey(fromJson: _defFromJson, toJson: _defToJson)
  final QueryDef def;

  factory QueryWsMsg.fromJson(Map<String, dynamic> json) =>
      _$QueryWsMsgFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$QueryWsMsgToJson(this);

  static QueryDef _defFromJson(Map<String, dynamic> json) {
    return QueryDef.fromJson(json);
  }

  static Map<String, dynamic> _defToJson(QueryDef def) {
    return def.toJson();
  }

  @override
  String toString() => 'QueryWsMsg(actor: $actorId)';
}

/// Message containing the results of a query request.
///
/// Sent by server in response to QueryWsMsg with the requested view data.
@JsonSerializable()
class QueryResultWsMsg implements WsMessage {
  /// Creates a query result message.
  QueryResultWsMsg({required this.result});

  @override
  String get messageType => 'query_result';

  /// The query results containing view data.
  @JsonKey(fromJson: _resFromJson, toJson: _resToJson)
  final QueryResult result;

  factory QueryResultWsMsg.fromJson(Map<String, dynamic> json) =>
      _$QueryResultWsMsgFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$QueryResultWsMsgToJson(this);

  static QueryResult _resFromJson(Map<String, dynamic> json) {
    return QueryResult.fromJson(json);
  }

  static Map<String, dynamic> _resToJson(QueryResult res) {
    return res.toJson();
  }
}

@JsonSerializable()
class ActorViewSub {
  ActorViewSub(this.entityName, this.id, this.name, this.changeId);

  ActorViewSub.attr(this.id, this.name, this.changeId) : entityName = '';

  final String entityName;

  /// actor id or attribute id
  @JsonKey(name: 'id')
  final String id;

  /// actor's view name or attribute name
  @JsonKey(name: 'name')
  final String name;

  @JsonKey(name: 'ver')
  final String changeId;

  String get subKey {
    if (entityName.isEmpty) {
      return '$id/$name';
    }

    return '$entityName/$id/$name';
  }

  factory ActorViewSub.fromJson(Map<String, dynamic> json) =>
      _$ActorViewSubFromJson(json);

  Map<String, dynamic> toJson() => _$ActorViewSubToJson(this);

  @override
  String toString() {
    return '(id: $id, name: $name, ver: $changeId)';
  }
}

@JsonSerializable()
class SubscribeViewsWsMsg implements WsMessage {
  SubscribeViewsWsMsg(this.subs);

  final List<ActorViewSub> subs;

  @override
  String get messageType => 'subv';

  factory SubscribeViewsWsMsg.fromJson(Map<String, dynamic> json) =>
      _$SubscribeViewsWsMsgFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$SubscribeViewsWsMsgToJson(this);

  @override
  String toString() => 'SubscribeViews(count: ${subs.length})';
}

@JsonSerializable()
class SubscribeViewsAckWsMsg implements WsMessage {
  SubscribeViewsAckWsMsg();

  @override
  String get messageType => 'subvack';

  factory SubscribeViewsAckWsMsg.fromJson(Map<String, dynamic> json) =>
      _$SubscribeViewsAckWsMsgFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$SubscribeViewsAckWsMsgToJson(this);

  @override
  String toString() => 'SubscribeViewsAck()';
}

@JsonSerializable()
class SubscribeActorWsMsg implements WsMessage {
  SubscribeActorWsMsg(this.actorId);

  final EntityId actorId;

  @override
  String get messageType => 'suba';

  factory SubscribeActorWsMsg.fromJson(Map<String, dynamic> json) =>
      _$SubscribeActorWsMsgFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$SubscribeActorWsMsgToJson(this);

  @override
  String toString() => 'SubscribeActor($actorId)';
}

@JsonSerializable()
class SubscribeActorResWsMsg implements WsMessage {
  SubscribeActorResWsMsg();

  @override
  String get messageType => 'subares';

  factory SubscribeActorResWsMsg.fromJson(Map<String, dynamic> json) =>
      _$SubscribeActorResWsMsgFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$SubscribeActorResWsMsgToJson(this);

  @override
  String toString() => 'SubscribeActorRes()';
}

@JsonSerializable()
class UnsubscribeActorWsMsg implements WsMessage {
  UnsubscribeActorWsMsg(this.actorId);

  final EntityId actorId;

  @override
  String get messageType => 'unsuba';

  factory UnsubscribeActorWsMsg.fromJson(Map<String, dynamic> json) =>
      _$UnsubscribeActorWsMsgFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$UnsubscribeActorWsMsgToJson(this);

  @override
  String toString() => 'UnsubscribeActor($actorId)';
}

@JsonSerializable()
class UnsubscribeActorResWsMsg implements WsMessage {
  UnsubscribeActorResWsMsg();

  @override
  String get messageType => 'unsubares';

  factory UnsubscribeActorResWsMsg.fromJson(Map<String, dynamic> json) =>
      _$UnsubscribeActorResWsMsgFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$UnsubscribeActorResWsMsgToJson(this);

  @override
  String toString() => 'UnsubscribeActorRes()';
}

@JsonSerializable()
class UnsubscribeViewsWsMsg implements WsMessage {
  UnsubscribeViewsWsMsg(this.subs);

  final List<ActorViewSub> subs;

  @override
  String get messageType => 'unsubv';

  factory UnsubscribeViewsWsMsg.fromJson(Map<String, dynamic> json) =>
      _$UnsubscribeViewsWsMsgFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$UnsubscribeViewsWsMsgToJson(this);

  @override
  String toString() => 'UnsubscribeViews(count: ${subs.length})';
}

@JsonSerializable()
class UnsubscribeViewsResWsMsg implements WsMessage {
  UnsubscribeViewsResWsMsg();

  @override
  String get messageType => 'unsubvres';

  factory UnsubscribeViewsResWsMsg.fromJson(Map<String, dynamic> json) =>
      _$UnsubscribeViewsResWsMsgFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$UnsubscribeViewsResWsMsgToJson(this);

  @override
  String toString() => 'UnsubscribeViewsRes()';
}

@JsonSerializable()
class ActorEventWsMsg implements WsMessage {
  ActorEventWsMsg(this.env);

  final EventEnvelop env;

  @override
  String get messageType => 'evt';

  factory ActorEventWsMsg.fromJson(Map<String, dynamic> json) =>
      _$ActorEventWsMsgFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ActorEventWsMsgToJson(this);

  @override
  String toString() => 'ActorEvent(${env.toJson()})';
}

@JsonSerializable()
class ViewChangeWsMsg implements WsMessage {
  ViewChangeWsMsg(this.env);

  final ChangeEnvelop env;

  @override
  String get messageType => 'chg';

  factory ViewChangeWsMsg.fromJson(Map<String, dynamic> json) =>
      _$ViewChangeWsMsgFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ViewChangeWsMsgToJson(this);

  @override
  String toString() => 'ViewChange($env)';
}

/// Message for sending commands to entities or services.
///
/// Fire-and-forget command delivery without waiting for response.
class SendCommandWsMsg implements WsMessage {
  /// Creates a send command message.
  SendCommandWsMsg(this.actorName, this.to, this.cmd);

  /// Name of the target entity or service type.
  final String actorName;

  /// ID of the specific entity instance to send to.
  final EntityId to;

  /// Command to send for processing.
  final RemoteCommand cmd;

  @override
  String get messageType => 'send';

  factory SendCommandWsMsg.fromJson(Map<String, dynamic> json) {
    var type = json['type'] as String;
    var fac = kMsgFromJsonFac[type];
    if (fac == null) {
      throw FluirError('unregistered command type $type in $json');
    }

    return SendCommandWsMsg(json['actorName'], json['to'], fac(json['cmd']));
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'actorName': actorName,
      'to': to,
      'type': cmd.runtimeType.toString(),
      'cmd': cmd.toJson(),
    };
  }

  @override
  String toString() => 'SendCmd(${toJson()})';
}

@JsonSerializable()
class SendCommandAckWsMsg implements WsMessage {
  SendCommandAckWsMsg();

  @override
  String get messageType => 'sendack';

  factory SendCommandAckWsMsg.fromJson(Map<String, dynamic> json) =>
      _$SendCommandAckWsMsgFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$SendCommandAckWsMsgToJson(this);

  @override
  String toString() => 'SendCmdAck()';
}

/// Message for calling commands and waiting for responses.
///
/// Request/response pattern for commands that need return values.
class CallCommandWsMsg implements WsMessage {
  /// Creates a call command message.
  CallCommandWsMsg(this.actorName, this.to, this.cmd);

  /// Name of the target entity or service type.
  final String actorName;

  /// ID of the specific entity instance to call.
  final EntityId to;

  /// Command to execute and wait for response.
  final RemoteCommand cmd;

  @override
  String get messageType => 'call';

  factory CallCommandWsMsg.fromJson(Map<String, dynamic> json) {
    var type = json['type'] as String;
    var fac = kMsgFromJsonFac[type];
    if (fac == null) {
      throw FluirError('unregistered command type $type in $json');
    }

    return CallCommandWsMsg(json['actorName'], json['to'], fac(json['cmd']));
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'actorName': actorName,
      'to': to,
      'type': cmd.runtimeType.toString(),
      'cmd': cmd.toJson(),
    };
  }

  @override
  String toString() => 'CallCmd(${toJson()})';
}

@JsonSerializable()
class CallCommandResWsMsg implements WsMessage {
  CallCommandResWsMsg(this.isOk, this.reply);

  final bool isOk;

  final Map<String, dynamic> reply;

  @override
  String get messageType => 'callres';

  factory CallCommandResWsMsg.fromJson(Map<String, dynamic> json) =>
      _$CallCommandResWsMsgFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$CallCommandResWsMsgToJson(this);

  @override
  String toString() => 'CallResCmd(${toJson()})';
}

/// Message for dispatching events to trigger business processes.
///
/// Sends events to the server to initiate business process execution.
class DispatchEventWsMsg implements WsMessage {
  /// Creates a dispatch event message.
  DispatchEventWsMsg(this.event);

  /// Event to dispatch for business process handling.
  final RemoteEvent event;

  @override
  final messageType = 'dispatch';

  factory DispatchEventWsMsg.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    final fac = kMsgFromJsonFac[type];
    if (fac == null) {
      throw FluirError('unregistered event type $type in $json');
    }

    return DispatchEventWsMsg(fac(json['event']));
  }

  @override
  Map<String, dynamic> toJson() {
    return {'type': event.runtimeType.toString(), 'event': event.toJson()};
  }

  @override
  String toString() =>
      'DispatchEvent(${event.runtimeType} | ${event.toJson()})';
}

@JsonSerializable()
class DispatchEventResWsMsg implements WsMessage {
  DispatchEventResWsMsg(this.result);

  @JsonKey(name: 'flowResult')
  final FlowResult result;

  @override
  final messageType = 'dispatchres';

  factory DispatchEventResWsMsg.fromJson(Map<String, dynamic> json) {
    return _$DispatchEventResWsMsgFromJson(json);
  }

  @override
  Map<String, dynamic> toJson() {
    return _$DispatchEventResWsMsgToJson(this);
  }

  @override
  String toString() => 'DispatchEventRes(${result.value} | ${result.isError})';
}

@JsonSerializable()
class ErrorWsMsg implements WsMessage {
  ErrorWsMsg(this.type, this.error);

  final String type;

  final String error;

  @override
  String get messageType => 'error';

  factory ErrorWsMsg.fromJson(Map<String, dynamic> json) =>
      _$ErrorWsMsgFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ErrorWsMsgToJson(this);

  @override
  String toString() => 'ErrorWsMsg(type: $type, e: $error)';
}
