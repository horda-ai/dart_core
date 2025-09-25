// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ws.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WelcomeWsMsg _$WelcomeWsMsgFromJson(Map<String, dynamic> json) =>
    WelcomeWsMsg(json['userId'] as String?, json['serverVersion'] as String);

Map<String, dynamic> _$WelcomeWsMsgToJson(WelcomeWsMsg instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'serverVersion': instance.serverVersion,
    };

QueryWsMsg _$QueryWsMsgFromJson(Map<String, dynamic> json) => QueryWsMsg(
  actorId: json['actorId'] as String,
  def: QueryWsMsg._defFromJson(json['def'] as Map<String, dynamic>),
);

Map<String, dynamic> _$QueryWsMsgToJson(QueryWsMsg instance) =>
    <String, dynamic>{
      'actorId': instance.actorId,
      'def': QueryWsMsg._defToJson(instance.def),
    };

QueryResultWsMsg _$QueryResultWsMsgFromJson(Map<String, dynamic> json) =>
    QueryResultWsMsg(
      result: QueryResultWsMsg._resFromJson(
        json['result'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$QueryResultWsMsgToJson(QueryResultWsMsg instance) =>
    <String, dynamic>{'result': QueryResultWsMsg._resToJson(instance.result)};

ActorViewSub _$ActorViewSubFromJson(Map<String, dynamic> json) => ActorViewSub(
  json['entityName'] as String,
  json['id'] as String,
  json['name'] as String,
  json['ver'] as String,
);

Map<String, dynamic> _$ActorViewSubToJson(ActorViewSub instance) =>
    <String, dynamic>{
      'entityName': instance.entityName,
      'id': instance.id,
      'name': instance.name,
      'ver': instance.changeId,
    };

SubscribeViewsWsMsg _$SubscribeViewsWsMsgFromJson(Map<String, dynamic> json) =>
    SubscribeViewsWsMsg(
      (json['subs'] as List<dynamic>)
          .map((e) => ActorViewSub.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SubscribeViewsWsMsgToJson(
  SubscribeViewsWsMsg instance,
) => <String, dynamic>{'subs': instance.subs};

SubscribeViewsAckWsMsg _$SubscribeViewsAckWsMsgFromJson(
  Map<String, dynamic> json,
) => SubscribeViewsAckWsMsg();

Map<String, dynamic> _$SubscribeViewsAckWsMsgToJson(
  SubscribeViewsAckWsMsg instance,
) => <String, dynamic>{};

SubscribeActorWsMsg _$SubscribeActorWsMsgFromJson(Map<String, dynamic> json) =>
    SubscribeActorWsMsg(json['actorId'] as String);

Map<String, dynamic> _$SubscribeActorWsMsgToJson(
  SubscribeActorWsMsg instance,
) => <String, dynamic>{'actorId': instance.actorId};

SubscribeActorResWsMsg _$SubscribeActorResWsMsgFromJson(
  Map<String, dynamic> json,
) => SubscribeActorResWsMsg();

Map<String, dynamic> _$SubscribeActorResWsMsgToJson(
  SubscribeActorResWsMsg instance,
) => <String, dynamic>{};

UnsubscribeActorWsMsg _$UnsubscribeActorWsMsgFromJson(
  Map<String, dynamic> json,
) => UnsubscribeActorWsMsg(json['actorId'] as String);

Map<String, dynamic> _$UnsubscribeActorWsMsgToJson(
  UnsubscribeActorWsMsg instance,
) => <String, dynamic>{'actorId': instance.actorId};

UnsubscribeActorResWsMsg _$UnsubscribeActorResWsMsgFromJson(
  Map<String, dynamic> json,
) => UnsubscribeActorResWsMsg();

Map<String, dynamic> _$UnsubscribeActorResWsMsgToJson(
  UnsubscribeActorResWsMsg instance,
) => <String, dynamic>{};

UnsubscribeViewsWsMsg _$UnsubscribeViewsWsMsgFromJson(
  Map<String, dynamic> json,
) => UnsubscribeViewsWsMsg(
  (json['subs'] as List<dynamic>)
      .map((e) => ActorViewSub.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$UnsubscribeViewsWsMsgToJson(
  UnsubscribeViewsWsMsg instance,
) => <String, dynamic>{'subs': instance.subs};

UnsubscribeViewsResWsMsg _$UnsubscribeViewsResWsMsgFromJson(
  Map<String, dynamic> json,
) => UnsubscribeViewsResWsMsg();

Map<String, dynamic> _$UnsubscribeViewsResWsMsgToJson(
  UnsubscribeViewsResWsMsg instance,
) => <String, dynamic>{};

ActorEventWsMsg _$ActorEventWsMsgFromJson(Map<String, dynamic> json) =>
    ActorEventWsMsg(EventEnvelop.fromJson(json['env'] as Map<String, dynamic>));

Map<String, dynamic> _$ActorEventWsMsgToJson(ActorEventWsMsg instance) =>
    <String, dynamic>{'env': instance.env};

ViewChangeWsMsg _$ViewChangeWsMsgFromJson(Map<String, dynamic> json) =>
    ViewChangeWsMsg(
      ChangeEnvelop.fromJson(json['env'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ViewChangeWsMsgToJson(ViewChangeWsMsg instance) =>
    <String, dynamic>{'env': instance.env};

SendCommandAckWsMsg _$SendCommandAckWsMsgFromJson(Map<String, dynamic> json) =>
    SendCommandAckWsMsg();

Map<String, dynamic> _$SendCommandAckWsMsgToJson(
  SendCommandAckWsMsg instance,
) => <String, dynamic>{};

CallCommandResWsMsg _$CallCommandResWsMsgFromJson(Map<String, dynamic> json) =>
    CallCommandResWsMsg(
      json['isOk'] as bool,
      json['reply'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$CallCommandResWsMsgToJson(
  CallCommandResWsMsg instance,
) => <String, dynamic>{'isOk': instance.isOk, 'reply': instance.reply};

DispatchEventResWsMsg _$DispatchEventResWsMsgFromJson(
  Map<String, dynamic> json,
) => DispatchEventResWsMsg(
  FlowResult.fromJson(json['flowResult'] as Map<String, dynamic>),
);

Map<String, dynamic> _$DispatchEventResWsMsgToJson(
  DispatchEventResWsMsg instance,
) => <String, dynamic>{'flowResult': instance.result};

ErrorWsMsg _$ErrorWsMsgFromJson(Map<String, dynamic> json) =>
    ErrorWsMsg(json['type'] as String, json['error'] as String);

Map<String, dynamic> _$ErrorWsMsgToJson(ErrorWsMsg instance) =>
    <String, dynamic>{'type': instance.type, 'error': instance.error};
