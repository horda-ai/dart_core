import 'package:json_annotation/json_annotation.dart';
import 'package:logging/logging.dart';

import 'error.dart';
import 'id.dart';
import 'view.dart';

part 'message.g.dart';

/// Function signature for deserializing JSON objects to typed instances.
///
/// Used throughout the Horda platform for converting JSON data received
/// from the network or storage back into strongly-typed Dart objects.
typedef FromJsonFun<T> = T Function(Map<String, dynamic> json);

/// Global registry of message deserialization factories.
///
/// Maps message type names to their corresponding fromJson functions,
/// enabling dynamic deserialization of messages based on type information.
final kMsgFromJsonFac = <String, FromJsonFun<dynamic>>{};

/// Base class for all messages in the Horda platform.
///
/// Provides common formatting and string representation functionality
/// for commands, events, and other message types.
abstract class Message {
  /// Returns a formatted string representation of the message content.
  ///
  /// Subclasses can override this to provide meaningful string representations
  /// of their data for debugging and logging purposes.
  String format() => '';

  @override
  String toString() => '$runtimeType(${format()})';
}

/// Base class for messages that can be serialized and transmitted over the network.
///
/// Extends Message with JSON serialization capability, enabling messages
/// to be sent between entities, services, and business processes.
abstract class RemoteMessage extends Message {
  /// Converts the message to a JSON representation for network transmission.
  Map<String, dynamic> toJson();
}

/// Base class for command messages in the entity-command-event architecture.
///
/// Commands represent requests for work using VerbNoun naming (e.g., CreateUser,
/// ProcessPayment). They contain all necessary data for task completion and
/// are processed by entities or services to produce events.
abstract class RemoteCommand extends RemoteMessage {}

/// Base class for event messages in the entity-command-event architecture.
///
/// Events represent completed work using NounVerb naming (e.g., UserCreated,
/// PaymentProcessed). They are produced by entities and services after
/// successful command processing and contain complete outcome information.
abstract class RemoteEvent extends RemoteMessage {}

/// Error event representing a failure in the Horda platform.
///
/// Produced when command processing fails or system errors occur,
/// providing error information to business processes and clients.
class FluirErrorEvent extends RemoteEvent {
  /// Creates an error event with the specified message.
  FluirErrorEvent(this.msg);

  /// Human-readable error message describing what went wrong.
  final String msg;

  factory FluirErrorEvent.fromJson(Map<String, dynamic> json) {
    return FluirErrorEvent(json['msg']);
  }

  @override
  Map<String, dynamic> toJson() {
    return {'msg': msg};
  }

  @override
  String format() => msg;
}

/// Unique identifier for command messages.
///
/// Used to track commands through the system and correlate them
/// with their resulting events for request/response patterns.
typedef CommandId = int;

/// Envelope containing a command and its routing metadata.
///
/// Wraps commands with information needed to route them through the
/// distributed system, including sender/receiver identities and reply channels.
class CommandEnvelop {
  /// Creates a command envelope with routing information.
  CommandEnvelop({
    required this.to,
    required this.from,
    required this.commandId,
    required this.type,
    required this.command,
    required this.replyFlow,
    required this.replyClient,
  });

  /// Target entity or service that should process this command.
  final EntityId to;

  /// Entity, service, or business process that sent this command.
  final EntityId from;

  /// Unique identifier for tracking this specific command.
  final String commandId;

  /// Command type name for deserialization (e.g., 'CreateUser', 'ProcessPayment').
  final String type;

  /// JSON representation of the command payload.
  final Map<String, dynamic> command;

  /// Information for routing replies back to business processes.
  final ReplyFlow replyFlow;

  /// Information for routing replies back to clients.
  final ReplyClient replyClient;

  factory CommandEnvelop.fromJson(Map<String, dynamic> json) {
    final type = json['type'];

    if (type is! String) {
      throw FluirError('invalid command type in $json');
    }

    return CommandEnvelop(
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

/// Information for routing command replies back to business processes.
///
/// Contains identifiers needed to deliver events from command processing
/// back to the business process that initiated the command.
@JsonSerializable(anyMap: true)
final class ReplyFlow {
  /// Creates reply flow information for business process communication.
  ReplyFlow({
    required this.actorName,
    required this.flowName,
    required this.flowId,
    required this.callId,
  });

  /// Creates empty reply flow when no business process reply is needed.
  ReplyFlow.none() : actorName = '', flowName = '', flowId = '', callId = '';

  /// Name of the entity or service that should receive the reply.
  final String actorName;

  /// Name of the business process flow handling this command.
  final String flowName;

  /// Unique identifier for the business process instance.
  final String flowId;

  /// Identifier for the specific call within the business process.
  final String callId;

  factory ReplyFlow.fromJson(Map<String, dynamic> json) =>
      _$ReplyFlowFromJson(json);

  Map<String, dynamic> toJson() => _$ReplyFlowToJson(this);
}

/// Information for routing command replies back to clients.
///
/// Contains identifiers needed to deliver events from command processing
/// back to the client application that originated the request.
@JsonSerializable(anyMap: true)
final class ReplyClient {
  /// Creates reply client information for client communication.
  ReplyClient({
    required this.serverId,
    required this.sessionId,
    required this.callId,
  });

  /// Creates empty reply client when no client reply is needed.
  ReplyClient.none() : serverId = '', sessionId = '', callId = '';

  /// Identifier of the server instance handling the client connection.
  final String serverId;

  /// Client session identifier for routing replies.
  @JsonKey(name: 'sid')
  final String sessionId;

  /// Unique identifier for the specific client call.
  final String callId;

  factory ReplyClient.fromJson(Map<String, dynamic> json) =>
      _$ReplyClientFromJson(json);

  Map<String, dynamic> toJson() => _$ReplyClientToJson(this);
}

/// Envelope containing view changes and their routing metadata.
///
/// Wraps view changes with information about which entity view is being
/// modified, enabling real-time updates to client applications.
class ChangeEnvelop {
  /// Creates a change envelope with view modification data.
  ChangeEnvelop({
    required this.entityName,
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

  /// Creates a draft change envelope without a message ID.
  ///
  /// Used for building changes before they are committed to the message system.
  ChangeEnvelop.draft({
    required this.entityName,
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

  /// Creates an empty change envelope to signal view readiness.
  ///
  /// Used when a view has no changes to project but should be marked as ready
  /// for client synchronization. Only used by the server and never persisted.
  ChangeEnvelop.empty({
    required this.entityName,
    required this.key,
    required this.name,
  }) : changeId = '',
       changes = <Change>[];

  /// Message ID assigned when this envelope was persisted to the message system.
  final String changeId;

  /// Name of the entity that owns the view being modified.
  final String entityName;

  /// Entity ID or attribute ID that owns the view being changed.
  final String key;

  /// Name of the view or attribute being modified.
  final String name;

  /// List of changes to be applied to the view or attribute.
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

  factory ChangeEnvelop.fromJson(Map<String, dynamic> json) {
    final deserializedChanges = <Change>[];

    if (json['view'] == null || json['view'] == '') {
      throw FluirError('change viewName must be set and not empty.');
    }

    final name = json['view'];
    final changesJson = json['changes'] as List;

    if (changesJson.isEmpty) {
      return ChangeEnvelop.empty(
        entityName: json['entityName'],
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

      deserializedChanges.add(fac(changeJson['change']));
    }

    return ChangeEnvelop(
      changeId: json['chid'],
      entityName: json['entityName'],
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

      changesJson.add({'type': typeName, 'change': change.toJson()});
    }

    final map = {
      'chid': changeId,
      'entityName': entityName,
      'aid': key,
      'changes': changesJson,
      'view': name,
    };

    return map;
  }

  @override
  String toString() => 'changes: $changes';
}

/// Envelope containing an event and its metadata.
///
/// Wraps events produced by entities and services with tracking information
/// that correlates them with the commands that triggered them.
class EventEnvelop {
  /// Creates an event envelope with metadata.
  EventEnvelop({
    required this.actorId,
    required this.eventId,
    required this.commandId,
    required this.type,
    required this.event,
  });

  /// ID of the entity or service that produced this event.
  final String actorId;

  /// Unique identifier for this event instance.
  final String eventId;

  /// ID of the command that triggered this event.
  final String commandId;

  /// Event type name for deserialization (e.g., 'UserCreated', 'PaymentProcessed').
  final String type;

  /// JSON representation of the event payload.
  final Map<String, dynamic> event;

  factory EventEnvelop.fromJson(Map<String, dynamic> json) {
    var type = json['type'];

    if (type is! String) {
      throw FluirError('invalid event type in $json');
    }

    return EventEnvelop(
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

/// Envelope for triggering business process execution.
///
/// Contains an event that should trigger a business process along with
/// session and user context needed for process execution.
class FlowRunEnvelop {
  /// Creates a flow run envelope for business process execution.
  FlowRunEnvelop({
    required this.serverId,
    required this.sessionId,
    required this.userId,
    required this.eventId,
    required this.dispatchId,
    required this.type,
    required this.event,
  });

  /// ID of the server instance handling this business process.
  final String serverId;

  /// Client session ID that triggered this process.
  final String sessionId;

  /// ID of the user initiating the business process.
  final String userId;

  /// Unique identifier for the triggering event.
  final String eventId;

  /// Identifier for this specific process dispatch.
  final String dispatchId;

  /// Event type name that triggers the business process.
  final String type;

  /// JSON representation of the triggering event.
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

/// Envelope containing a reply from a business process call.
///
/// Wraps the result of calling an entity or service from within a business
/// process, indicating success or failure with the resulting event or error.
@JsonSerializable(anyMap: true, createToJson: false)
final class FlowCallReplyEnvelop {
  /// Creates a flow call reply envelope.
  FlowCallReplyEnvelop({
    required this.replyId,
    required this.flowId,
    required this.flowName,
    required this.callId,
    required this.isOk,
    required this.reply,
  });

  /// Unique identifier for this reply message.
  final String replyId;

  /// ID of the business process that made the call.
  final String flowId;

  /// Name of the business process flow.
  final String flowName;

  /// ID of the specific call within the process.
  final String callId;

  /// Whether the call succeeded (true) or failed (false).
  final bool isOk;

  /// Reply payload - either FlowCallReplyOk or FlowCallReplyErr data.
  final Map<String, dynamic> reply;

  factory FlowCallReplyEnvelop.fromJson(Map json) =>
      _$FlowCallReplyEnvelopFromJson(json);
}

/// Successful reply from a business process call.
///
/// Contains the event produced by successful command processing,
/// allowing the business process to continue with the next steps.
@JsonSerializable(anyMap: true, createToJson: false)
final class FlowCallReplyOk {
  /// Creates a successful flow call reply.
  FlowCallReplyOk({required this.eventType, required this.event});

  /// Type name of the event that was produced.
  final String eventType;

  /// JSON representation of the event data.
  final Map<String, dynamic> event;

  factory FlowCallReplyOk.fromJson(Map json) => _$FlowCallReplyOkFromJson(json);
}

/// Error reply from a business process call.
///
/// Contains error information when command processing fails,
/// allowing the business process to handle the failure appropriately.
@JsonSerializable(anyMap: true, createToJson: false)
final class FlowCallReplyErr {
  /// Creates an error flow call reply.
  FlowCallReplyErr({required this.errorType, required this.message});

  /// Classification of the error that occurred.
  final String errorType;

  /// Human-readable error message describing the failure.
  final String message;

  factory FlowCallReplyErr.fromJson(Map json) =>
      _$FlowCallReplyErrFromJson(json);
}

/// Record of a view change with its state version.
///
/// Links a specific change to the version of the view state when it was applied,
/// enabling optimistic concurrency control and change ordering.
class ChangeRecord {
  /// Creates a change record with version information.
  ChangeRecord({required this.change, required this.stateVersion});

  /// The view change that was applied.
  final Change change;

  /// Monotonically increasing version number for the view state.
  ///
  /// Incremented each time the view state changes. Used for optimistic
  /// concurrency control and ensuring changes are applied in order.
  /// Initial version is 0.
  final int stateVersion;

  @override
  String toString() => 'Change: $change | version: $stateVersion';
}

/// Result of business process execution.
///
/// Indicates whether a business process completed successfully or failed,
/// with an optional value providing additional information about the outcome.
class FlowResult {
  /// Creates a successful flow result with optional value.
  FlowResult.ok([this.value]) : isError = false;

  /// Creates an error flow result with error information.
  FlowResult.error(this.value) : isError = true;

  /// Optional result value or error message.
  final String? value;

  /// Whether this result represents an error (true) or success (false).
  final bool isError;

  factory FlowResult.fromJson(Map<String, dynamic> json) {
    return (json['isError'] as bool)
        ? FlowResult.error(json['value'])
        : FlowResult.ok(json['value']);
  }

  Map<String, dynamic> toJson() {
    return {'value': value, 'isError': isError};
  }
}

/// Unique identifier for changes in the distributed message system.
///
/// Provides a hierarchical identification scheme that enables ordering
/// and comparison of changes across the distributed Horda platform.
class ChangeId {
  /// Creates a change ID with distributed system coordinates.
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
      return ChangeId(ledgerId: 0, entryId: 0, batchIdx: 0, partitionIdx: 0);
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

  /// Identifier of the message ledger containing this change.
  final int ledgerId;

  /// Position of the entry within the ledger.
  final int entryId;

  /// Index within a batch of changes (if batched).
  final int batchIdx;

  /// Partition index for distributed storage.
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

  kRegisterMessageFactory<FluirErrorEvent>(FluirErrorEvent.fromJson);

  // value view

  kRegisterMessageFactory<ValueViewChanged>(ValueViewChanged.fromJson);

  // counter view

  kRegisterMessageFactory<CounterViewIncremented>(
    CounterViewIncremented.fromJson,
  );
  kRegisterMessageFactory<CounterViewDecremented>(
    CounterViewDecremented.fromJson,
  );
  kRegisterMessageFactory<CounterViewReset>(CounterViewReset.fromJson);

  // ref view

  kRegisterMessageFactory<RefViewChanged>(RefViewChanged.fromJson);

  // list view

  kRegisterMessageFactory<ListViewCleared>(ListViewCleared.fromJson);
  kRegisterMessageFactory<ListViewItemAdded>(ListViewItemAdded.fromJson);
  kRegisterMessageFactory<ListViewItemAddedIfAbsent>(
    ListViewItemAddedIfAbsent.fromJson,
  );
  kRegisterMessageFactory<ListViewItemRemoved>(ListViewItemRemoved.fromJson);
  kRegisterMessageFactory<ListViewItemChanged>(ListViewItemChanged.fromJson);

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
  kRegisterMessageFactory<CounterAttrReset>(CounterAttrReset.fromJson);
}

void kRegisterMessageFactory<T extends Message>(FromJsonFun<T> fun) {
  // eliminate generic value type string
  final typeName = switch (T) {
    const (ValueViewChanged) => 'ValueViewChanged',
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
