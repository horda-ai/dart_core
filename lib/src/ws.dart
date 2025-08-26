import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:logging/logging.dart';

import 'error.dart';
import 'id.dart';
import 'message.dart';
import 'query_def.dart';
import 'query_res.dart';

part 'ws.g.dart';

class WsMessageBox {
  final int id;

  final WsMessage msg;

  WsMessageBox({
    required this.id,
    required this.msg,
  });

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

      return WsMessageBox(
        id: id,
        msg: fac(json['msg']),
      );
    } catch (e) {
      logger.severe('decode json error: $e');

      return WsMessageBox(
        id: -1,
        msg: ErrorWsMsg(str, e.toString()),
      );
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

      return jsonEncode({
        'id': id,
        'type': 'error',
        'msg': msg,
      });
    }
  }

  @override
  String toString() {
    return 'WsMessageBox(id: $id, type: ${msg.messageType})';
  }
}

sealed class WsMessage {
  String get messageType;

  Map<String, dynamic> toJson();
}

@JsonSerializable()
class WelcomeWsMsg implements WsMessage {
  WelcomeWsMsg(this.userId, this.serverVersion);

  final String? userId;
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

@JsonSerializable()
class QueryWsMsg implements WsMessage {
  QueryWsMsg({
    required this.actorId,
    required this.def,
  });

  @override
  String get messageType => 'query';

  final String actorId;

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

@JsonSerializable()
class QueryResultWsMsg implements WsMessage {
  QueryResultWsMsg({
    required this.result,
  });

  @override
  String get messageType => 'query_result';

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
  ActorViewSub(this.id, this.name, this.changeId);

  /// actor id or attribute id
  @JsonKey(name: 'id')
  final String id;

  /// actor's view name or attribute name
  @JsonKey(name: 'name')
  final String name;

  @JsonKey(name: 'ver')
  final String changeId;

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

class SendCommandWsMsg implements WsMessage {
  SendCommandWsMsg(this.actorName, this.to, this.cmd);

  final String actorName;

  final EntityId to;

  final RemoteCommand cmd;

  @override
  String get messageType => 'send';

  factory SendCommandWsMsg.fromJson(Map<String, dynamic> json) {
    var type = json['type'] as String;
    var fac = kMsgFromJsonFac[type];
    if (fac == null) {
      throw FluirError('unregistered command type $type in $json');
    }

    return SendCommandWsMsg(
      json['actorName'],
      json['to'],
      fac(json['cmd']),
    );
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

class CallCommandWsMsg implements WsMessage {
  CallCommandWsMsg(this.actorName, this.to, this.cmd);

  final String actorName;

  final EntityId to;

  final RemoteCommand cmd;

  @override
  String get messageType => 'call';

  factory CallCommandWsMsg.fromJson(Map<String, dynamic> json) {
    var type = json['type'] as String;
    var fac = kMsgFromJsonFac[type];
    if (fac == null) {
      throw FluirError('unregistered command type $type in $json');
    }

    return CallCommandWsMsg(
      json['actorName'],
      json['to'],
      fac(json['cmd']),
    );
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

class DispatchEventWsMsg implements WsMessage {
  DispatchEventWsMsg(this.event);

  final RemoteEvent event;

  @override
  final messageType = 'dispatch';

  factory DispatchEventWsMsg.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    final fac = kMsgFromJsonFac[type];
    if (fac == null) {
      throw FluirError('unregistered event type $type in $json');
    }

    return DispatchEventWsMsg(
      fac(json['event']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': event.runtimeType.toString(),
      'event': event.toJson(),
    };
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
