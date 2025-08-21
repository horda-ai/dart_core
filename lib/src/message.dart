import 'package:json_annotation/json_annotation.dart';
import 'package:logging/logging.dart';

import 'error.dart';
import 'view.dart';
import 'view2.dart';
import 'worker.dart';

part 'message.g.dart';

typedef FromJsonFun<T> = T Function(Map<String, dynamic> json);

final kMsgFromJsonFac = <String, FromJsonFun<dynamic>>{};

abstract class Message {
  String format() => '';

  @override
  String toString() => '$runtimeType(${format()})';
}

abstract class RemoteMessage extends Message {
  Map<String, dynamic> toJson();
}

abstract class RemoteCommand extends RemoteMessage {}

abstract class RemoteEvent extends RemoteMessage {}

class FluirErrorEvent extends RemoteEvent {
  FluirErrorEvent(this.msg);

  final String msg;

  factory FluirErrorEvent.fromJson(Map<String, dynamic> json) {
    return FluirErrorEvent(
      json['msg'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'msg': msg,
    };
  }

  @override
  String format() => msg;
}

typedef CommandId = int;

class CommandEnvelop {
  CommandEnvelop({
    required this.to,
    required this.from,
    required this.commandId,
    required this.command,
  });

  final ActorId to;

  final ActorId from;

  final CommandId commandId;

  final RemoteCommand command;

  factory CommandEnvelop.fromJson(Map<String, dynamic> json) {
    var type = json['type'];

    if (type is! String) {
      throw FluirError('invalid command type in $json');
    }

    var fac = kMsgFromJsonFac[type];
    if (fac == null) {
      throw FluirError('unregistered command type $type in $json');
    }

    return CommandEnvelop(
      to: json['to'],
      from: json['from'],
      commandId: json['cid'],
      command: fac(json['cmd']),
    );
  }

  Map<String, dynamic> toJson() {
    var map = {
      'to': to,
      'from': from,
      'cid': commandId,
      'type': command.runtimeType.toString(),
      'cmd': command.toJson(),
    };
    return map;
  }

  @override
  String toString() => '$command';
}

class CommandEnvelop2 {
  CommandEnvelop2({
    required this.to,
    required this.from,
    required this.commandId,
    required this.type,
    required this.command,
    required this.replyFlow,
    required this.replyClient,
  });

  final ActorId to;

  final ActorId from;

  final String commandId;

  final String type;

  final Map<String, dynamic> command;

  final ReplyFlow replyFlow;

  final ReplyClient replyClient;

  factory CommandEnvelop2.fromJson(Map<String, dynamic> json) {
    final type = json['type'];

    if (type is! String) {
      throw FluirError('invalid command type in $json');
    }

    return CommandEnvelop2(
      to: json['to'],
      from: json['from'],
      commandId: json['cid'],
      type: json['type'],
      command: json['cmd'],
      replyFlow: ReplyFlow.fromJson(json['replyFlow']),
      replyClient: ReplyClient.fromJson(json['replyClient']),
    );
  }

  Map<String, dynamic> toJson() {
    final map = {
      'to': to,
      'from': from,
      'cid': commandId,
      'type': type,
      'cmd': command,
      'replyFlow': replyFlow.toJson(),
      'replyClient': replyClient.toJson(),
    };
    return map;
  }

  @override
  String toString() => '$command';
}

@JsonSerializable(anyMap: true)
final class ReplyFlow {
  ReplyFlow({
    required this.actorName,
    required this.flowName,
    required this.flowId,
    required this.callId,
  });

  ReplyFlow.none()
      : actorName = '',
        flowName = '',
        flowId = '',
        callId = '';

  final String actorName;

  final String flowName;

  final String flowId;

  final String callId;

  factory ReplyFlow.fromJson(Map<String, dynamic> json) =>
      _$ReplyFlowFromJson(json);

  Map<String, dynamic> toJson() => _$ReplyFlowToJson(this);
}

@JsonSerializable(anyMap: true)
final class ReplyClient {
  ReplyClient({
    required this.serverId,
    required this.sessionId,
    required this.callId,
  });

  ReplyClient.none()
      : serverId = '',
        sessionId = '',
        callId = '';

  final String serverId;

  @JsonKey(name: 'sid')
  final String sessionId;

  final String callId;

  factory ReplyClient.fromJson(Map<String, dynamic> json) =>
      _$ReplyClientFromJson(json);

  Map<String, dynamic> toJson() => _$ReplyClientToJson(this);
}

class ChangeEnvelop2 {
  ChangeEnvelop2({
    required this.changeId,
    required this.key,
    required this.name,
    required this.changes,
  }) {
    assert(changes.isNotEmpty, 'Changes array must not be empty.');
    assert(
      changes.every((change) {
        return change.isOverwriting == changes.first.isOverwriting;
      }),
      'Changes should belong to the same view type, so isOverwriting must be equal for all of them.',
    );
  }

  /// Constructor with empty [changeId]
  ChangeEnvelop2.draft({
    required this.key,
    required this.name,
    required this.changes,
  }) : changeId = '' {
    assert(changes.isNotEmpty, 'Changes array must not be empty.');
    assert(
      changes.every((change) {
        return change.isOverwriting == changes.first.isOverwriting;
      }),
      'Changes should belong to the same view type, so isOverwriting must be equal for all of them.',
    );
  }

  /// Empty change envelops are only used to let views report their readiness
  /// in cases when it won't receive changes to project, but can be considered ready.
  ///
  /// They should be provided only by the server to the client and never stored.
  ChangeEnvelop2.empty({
    required this.key,
    required this.name,
  })  : changeId = '',
        changes = <Change>[];

  /// Message id with which this envelop was saved in Pulsar
  final String changeId;

  /// Actor id or attribute id.
  final String key;

  /// Actor's view name or attribute name.
  final String name;

  /// List of changes for a view or an attribute.
  final List<Change> changes;

  /// Whether changes of this envelope:
  /// - `true` - overwrite the previous version
  /// - `false` - add up
  ///
  /// If `true`, only the last change is necessary to project.
  bool get isOverwriting =>
      changes.isEmpty ? false : changes.first.isOverwriting;

  /// Check whether the list of [changes] is empty.
  bool get isEmpty => changes.isEmpty;

  String get sourceId => '$key/$name';

  factory ChangeEnvelop2.fromJson(Map<String, dynamic> json) {
    final deserializedChanges = <Change>[];

    if (json['view'] == null || json['view'] == '') {
      throw FluirError('change viewName must be set and not empty.');
    }

    final name = json['view'];
    final changesJson = json['changes'] as List;

    if (changesJson.isEmpty) {
      return ChangeEnvelop2.empty(
        key: json['aid'],
        name: name,
      );
    }

    for (final changeJson in changesJson) {
      final type = changeJson['type'];

      if (type is! String) {
        throw FluirError('invalid type in $changeJson');
      }

      final fac = kMsgFromJsonFac[type];
      if (fac == null) {
        throw FluirError('unregistered change type $type in $changeJson');
      }

      deserializedChanges.add(
        fac(changeJson['change']),
      );
    }

    return ChangeEnvelop2(
      changeId: json['chid'],
      key: json['aid'],
      name: name,
      changes: deserializedChanges,
    );
  }

  Map<String, dynamic> toJson() {
    final changesJson = [];
    for (final change in changes) {
      // eliminate generic value type string
      String typeName;
      final changeType = change.runtimeType.toString();

      if (changeType.startsWith('ValueViewCreated')) {
        typeName = 'ValueViewCreated';
      } else if (changeType.startsWith('ValueViewChanged')) {
        typeName = 'ValueViewChanged';
      } else {
        typeName = changeType;
      }

      changesJson.add({
        'type': typeName,
        'change': change.toJson(),
      });
    }

    final map = {
      'chid': changeId,
      'aid': key,
      'changes': changesJson,
      'view': name,
    };

    return map;
  }

  @override
  String toString() => 'changes: $changes';
}

class EventEnvelop2 {
  EventEnvelop2({
    required this.actorId,
    required this.eventId,
    required this.commandId,
    required this.type,
    required this.event,
  });

  final String actorId;

  final String eventId;

  final String commandId;

  final String type;

  final Map<String, dynamic> event;

  factory EventEnvelop2.fromJson(Map<String, dynamic> json) {
    var type = json['type'];

    if (type is! String) {
      throw FluirError('invalid event type in $json');
    }

    return EventEnvelop2(
      eventId: json['eid'],
      actorId: json['aid'],
      commandId: json['cid'],
      type: type,
      event: json['event'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'aid': actorId,
      'eid': eventId,
      'cid': commandId,
      'type': type,
      'event': event,
    };
  }

  @override
  String toString() => 'type: $type';
}

class FlowRunEnvelop {
  FlowRunEnvelop({
    required this.serverId,
    required this.sessionId,
    required this.userId,
    required this.eventId,
    required this.dispatchId,
    required this.type,
    required this.event,
  });

  final String serverId;

  final String sessionId;

  final String userId;

  final String eventId;

  final String dispatchId;

  final String type;

  final Map<String, dynamic> event;

  factory FlowRunEnvelop.fromJson(Map<String, dynamic> json) {
    var type = json['type'];

    if (type is! String) {
      throw FluirError('invalid event type in $json');
    }

    return FlowRunEnvelop(
      serverId: json['serverId'],
      sessionId: json['sid'],
      eventId: json['eid'],
      userId: json['uid'],
      dispatchId: json['did'],
      type: type,
      event: json['event'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serverId': serverId,
      'sid': sessionId,
      'uid': userId,
      'eid': eventId,
      'did': dispatchId,
      'type': type,
      'event': event,
    };
  }

  @override
  String toString() => 'type: $type';
}

@JsonSerializable(anyMap: true, createToJson: false)
final class FlowCallReplyEnvelop {
  FlowCallReplyEnvelop({
    required this.replyId,
    required this.flowId,
    required this.flowName,
    required this.callId,
    required this.isOk,
    required this.reply,
  });

  final String replyId;

  final String flowId;

  final String flowName;

  final String callId;

  final bool isOk;

  // either FlowCallReplyOk or FlowCallReplyErr
  final Map<String, dynamic> reply;

  factory FlowCallReplyEnvelop.fromJson(Map json) =>
      _$FlowCallReplyEnvelopFromJson(json);
}

@JsonSerializable(anyMap: true, createToJson: false)
final class FlowCallReplyOk {
  FlowCallReplyOk({
    required this.eventType,
    required this.event,
  });

  final String eventType;

  final Map<String, dynamic> event;

  factory FlowCallReplyOk.fromJson(Map json) => _$FlowCallReplyOkFromJson(json);
}

@JsonSerializable(anyMap: true, createToJson: false)
final class FlowCallReplyErr {
  FlowCallReplyErr({
    required this.errorType,
    required this.message,
  });

  final String errorType;

  final String message;

  factory FlowCallReplyErr.fromJson(Map json) =>
      _$FlowCallReplyErrFromJson(json);
}

class ChangeRecord {
  ChangeRecord({required this.change, required this.stateVersion});

  final Change change;

  /// Monotonically increasing actor or view state version.
  /// Its incremented every time actor or view state gets changed.
  /// Initial state version value is 0
  final int stateVersion;

  @override
  String toString() => 'Change: $change | version: $stateVersion';
}

class ChangeEnvelop {
  ChangeEnvelop({
    required this.id,
    required this.name,
    required this.changes,
  }) {
    assert(changes.isNotEmpty, 'Changes array must not be empty.');
    assert(
      isMonotone,
      'Changes must be sequential and their versions monotone.',
    );
    assert(
      changes.every((record) {
        return record.change.isOverwriting ==
            changes.first.change.isOverwriting;
      }),
      'Changes should belong to the same view type, so isOverwriting must be equal for all of them.',
    );
  }

  /// Empty change envelops are only used to let views report their readiness
  /// in cases when it won't receive changes to project, but can be considered ready.
  ///
  /// They should be provided only by the server to the client and never stored.
  ChangeEnvelop.empty({
    required this.id,
    required this.name,
  }) : changes = <ChangeRecord>[];

  /// Actor id or attribute id.
  final String id;

  /// Actor's view name or attribute name.
  final String name;

  /// List of changes for a view or an attribute.
  final List<ChangeRecord> changes;

  /// Whether changes of this envelope:
  /// - `true` - overwrite the previous version
  /// - `false` - add up
  ///
  /// If `true`, only the last change is necessary to project.
  bool get isOverwriting =>
      changes.isEmpty ? false : changes.first.change.isOverwriting;

  /// stateVersion of the first change
  int get firstVersion => changes.isEmpty ? 0 : changes.first.stateVersion;

  /// The resulting stateVersion after all included changes are projected
  int get lastVersion => changes.isEmpty ? 0 : changes.last.stateVersion;

  /// Check whether the list of [changes] is empty.
  bool get isEmpty => changes.isEmpty;

  /// Check if included [changes] versions increase monotonically: 1,2,3,4...
  bool get isMonotone {
    var version = firstVersion;
    for (final record in changes.skip(1)) {
      final stateVersion = record.stateVersion;

      if (version != stateVersion - 1) return false;
      version = stateVersion;
    }
    return true;
  }

  String get sourceId => '$id/$name';

  factory ChangeEnvelop.fromJson(Map<String, dynamic> json) {
    final deserializedChanges = <ChangeRecord>[];

    if (json['view'] == null || json['view'] == '') {
      throw FluirError('change viewName must be set and not empty.');
    }

    final name = json['view'];
    final changesJson = json['changes'] as List;

    if (changesJson.isEmpty) {
      return ChangeEnvelop.empty(
        id: json['aid'],
        name: name,
      );
    }

    for (final changeJson in changesJson) {
      final type = changeJson['type'];

      if (type is! String) {
        throw FluirError('invalid type in $changeJson');
      }

      final fac = kMsgFromJsonFac[type];
      if (fac == null) {
        throw FluirError('unregistered change type $type in $changeJson');
      }

      if (changeJson['ver'] == null || changeJson['ver'] == 0) {
        throw FluirError('change version must be set and not equal to 0');
      }
      final stateVersion = changeJson['ver'];

      deserializedChanges.add(ChangeRecord(
        change: fac(changeJson['change']),
        stateVersion: stateVersion,
      ));
    }

    return ChangeEnvelop(
      id: json['aid'],
      name: name,
      changes: deserializedChanges,
    );
  }

  Map<String, dynamic> toJson() {
    final changesJson = [];
    for (final record in changes) {
      final ChangeRecord(:change, :stateVersion) = record;

      // eliminate generic value type string
      String typeName;
      final changeType = change.runtimeType.toString();

      if (changeType.startsWith('ValueViewCreated')) {
        typeName = 'ValueViewCreated';
      } else if (changeType.startsWith('ValueViewChanged')) {
        typeName = 'ValueViewChanged';
      } else {
        typeName = changeType;
      }

      changesJson.add({
        'type': typeName,
        'change': change.toJson(),
        'ver': stateVersion,
      });
    }

    final map = {
      'aid': id,
      'changes': changesJson,
      'view': name,
    };

    return map;
  }

  @override
  String toString() => 'changes: $changes';
}

class EventEnvelop {
  EventEnvelop({
    required this.workerId,
    required this.commandId,
    required this.event,
    this.dispatchId,
  });

  final ActorId workerId;

  final CommandId commandId;

  /// Used when dispatching events to associate an Event with a corresponding FlowResult.
  /// Should be null otherwise.
  final int? dispatchId;

  final RemoteEvent event;

  factory EventEnvelop.fromJson(Map<String, dynamic> json) {
    final type = json['type'];

    if (type is! String) {
      throw FluirError('invalid type in $json');
    }

    final fac = kMsgFromJsonFac[type];
    if (fac == null) {
      throw FluirError('unregistered event type $type in $json');
    }

    final event = fac(json['event']);

    return EventEnvelop(
      workerId: json['aid'],
      commandId: json['cid'],
      event: event,
    );
  }

  Map<String, dynamic> toJson() {
    // eliminate generic value type string
    final typeName = event.runtimeType.toString();

    final map = {
      'aid': workerId,
      'cid': commandId,
      'type': typeName,
      'event': event.toJson(),
    };

    return map;
  }

  @override
  String toString() => 'event: $event';
}

class FlowResult extends RemoteMessage {
  FlowResult([this.value]) : isError = false;

  FlowResult.error(this.value) : isError = true;

  final String? value;
  final bool isError;

  factory FlowResult.fromJson(Map<String, dynamic> json) {
    return (json['isError'] as bool)
        ? FlowResult.error(json['value'])
        : FlowResult(json['value']);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'isError': isError,
    };
  }
}

class FlowResult2 {
  FlowResult2.ok([this.value]) : isError = false;

  FlowResult2.error(this.value) : isError = true;

  final String? value;

  final bool isError;

  factory FlowResult2.fromJson(Map<String, dynamic> json) {
    return (json['isError'] as bool)
        ? FlowResult2.error(json['value'])
        : FlowResult2.ok(json['value']);
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'isError': isError,
    };
  }
}

@JsonSerializable()
class FlowResultEnvelop {
  FlowResultEnvelop({
    required this.flowId,
    required this.flowResult,
    required this.dispatchId,
  });

  final String flowId;
  final FlowResult flowResult;

  /// Dispatch id of the event which triggered the flow.
  /// Will be null when [FlowResult] was produced without dispatching.
  final int? dispatchId;

  factory FlowResultEnvelop.fromJson(Map<String, dynamic> json) {
    return _$FlowResultEnvelopFromJson(json);
  }

  Map<String, dynamic> toJson() {
    return _$FlowResultEnvelopToJson(this);
  }
}

class ChangeId {
  ChangeId({
    required this.ledgerId,
    required this.entryId,
    required this.batchIdx,
    required this.partitionIdx,
  });

  /// Parses a change id string in the following format:
  ///
  /// ledgerId:entryId:batchIdx:partitionIdx
  ///
  /// Throws if string is invalid.
  factory ChangeId.fromString(String chIdStr) {
    if (chIdStr.isEmpty) {
      return ChangeId(
        ledgerId: 0,
        entryId: 0,
        batchIdx: 0,
        partitionIdx: 0,
      );
    }

    final split = chIdStr.split(":");
    if (split.length != 4) {
      throw FormatException(
        'Provided change id string does not have 4 elements: $chIdStr',
      );
    }

    final values = split.map((str) => int.parse(str)).toList();
    return ChangeId(
      ledgerId: values[0],
      entryId: values[1],
      batchIdx: values[2],
      partitionIdx: values[3],
    );
  }

  final int ledgerId;
  final int entryId;
  final int batchIdx;
  final int partitionIdx;

  // Should be kept in sync with function in host:message_id.go
  int compareTo(ChangeId rhs) {
    if (ledgerId < rhs.ledgerId) {
      return -1;
    } else if (ledgerId > rhs.ledgerId) {
      return 1;
    }

    if (entryId < rhs.entryId) {
      return -1;
    } else if (entryId > rhs.entryId) {
      return 1;
    }

    if (batchIdx < 0 && rhs.batchIdx < 0) {
      return 0;
    } else if (batchIdx >= 0 && rhs.batchIdx < 0) {
      return -1;
    } else if (batchIdx < 0 && rhs.batchIdx >= 0) {
      return 1;
    }

    if (batchIdx < rhs.batchIdx) {
      return -1;
    } else if (batchIdx > rhs.batchIdx) {
      return 1;
    }

    return 0;
  }

  bool operator <(ChangeId b) {
    return compareTo(b) < 0;
  }

  bool operator <=(ChangeId b) {
    return compareTo(b) <= 0;
  }

  bool operator >(ChangeId b) {
    return compareTo(b) > 0;
  }

  bool operator >=(ChangeId b) {
    return compareTo(b) >= 0;
  }
}

void kRegisterFluirMessage() {
  // error

  kRegisterMessageFactory<FluirErrorEvent>(
    FluirErrorEvent.fromJson,
  );

  // value view

  kRegisterMessageFactory<ValueViewChanged>(
    ValueViewChanged.fromJson,
  );

  // counter view

  kRegisterMessageFactory<CounterViewIncremented>(
    CounterViewIncremented.fromJson,
  );
  kRegisterMessageFactory<CounterViewDecremented>(
    CounterViewDecremented.fromJson,
  );
  kRegisterMessageFactory<CounterViewReset>(
    CounterViewReset.fromJson,
  );

  // ref view

  kRegisterMessageFactory<RefViewChanged>(
    RefViewChanged.fromJson,
  );

  // list view

  kRegisterMessageFactory<ListViewCleared>(
    ListViewCleared.fromJson,
  );
  kRegisterMessageFactory<ListViewItemAdded>(
    ListViewItemAdded.fromJson,
  );
  kRegisterMessageFactory<ListViewItemAddedIfAbsent>(
    ListViewItemAddedIfAbsent.fromJson,
  );
  kRegisterMessageFactory<ListViewItemRemoved>(
    ListViewItemRemoved.fromJson,
  );
  kRegisterMessageFactory<ListViewItemChanged>(
    ListViewItemChanged.fromJson,
  );

  // value attr

  kRegisterMessageFactory<RefValueAttributeChanged>(
    RefValueAttributeChanged.fromJson,
  );

  // counter attr

  kRegisterMessageFactory<CounterAttrIncremented>(
    CounterAttrIncremented.fromJson,
  );
  kRegisterMessageFactory<CounterAttrDecremented>(
    CounterAttrDecremented.fromJson,
  );
  kRegisterMessageFactory<CounterAttrReset>(
    CounterAttrReset.fromJson,
  );

  // value attr v2

  kRegisterMessageFactory<RefValueAttributeChanged2>(
    RefValueAttributeChanged2.fromJson,
  );

  // counter attr v2

  kRegisterMessageFactory<CounterAttrIncremented2>(
    CounterAttrIncremented2.fromJson,
  );
  kRegisterMessageFactory<CounterAttrDecremented2>(
    CounterAttrDecremented2.fromJson,
  );
  kRegisterMessageFactory<CounterAttrReset2>(
    CounterAttrReset2.fromJson,
  );
}

void kRegisterMessageFactory<T extends Message>(FromJsonFun<T> fun) {
  // eliminate generic value type string
  final typeName = switch (T) {
    ValueViewChanged _ => 'ValueViewChanged',
    _ => T.toString(),
  };

  if (kMsgFromJsonFac.containsKey(typeName)) {
    Logger('Fluir.Core').warning('factory fun for $T is already registered');
    return;
  }

  kMsgFromJsonFac[typeName] = fun;
}

dynamic kMessageFromJson(String type, Map<String, dynamic> json) {
  if (!kMsgFromJsonFac.containsKey(type)) {
    throw FluirError('unregistered message type $type in $json');
  }

  return kMsgFromJsonFac[type]!(json);
}
