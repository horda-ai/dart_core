import 'error.dart';

/// Definition of a query to retrieve entity view data.
///
/// Specifies which views to query from entities, enabling clients to
/// request specific data projections with optional real-time subscriptions.
class QueryDef {
  /// Creates a query definition with the specified view queries.
  QueryDef(this.entityName, this.views);

  final String entityName;

  /// Map of view names to their query definitions.
  final Map<String, ViewQueryDef> views;

  factory QueryDef.fromJson(Map<String, dynamic> json) {
    final entityName = json['entityName'] as String?;

    if (entityName == null) {
      throw FluirError(
        'entity name is null when deserializing a query def json',
      );
    }

    final viewsJson = json['views'] as Map<String, dynamic>;

    var views = <String, ViewQueryDef>{};

    for (var entry in viewsJson.entries) {
      var type = entry.value['type'];
      switch (type) {
        case 'val':
          views[entry.key] = ValueQueryDef.fromJson(entry.value);
          break;
        case 'cnt':
          views[entry.key] = CounterQueryDef.fromJson(entry.value);
          break;
        case 'ref':
          views[entry.key] = RefQueryDef.fromJson(entry.value);
          break;
        case 'list':
          views[entry.key] = ListQueryDef.fromJson(entry.value);
          break;
        default:
          throw FluirError('unknown query def type: $type');
      }
    }

    return QueryDef(entityName, views);
  }

  Map<String, dynamic> toJson() {
    final viewsJson = <String, dynamic>{};

    for (var entry in views.entries) {
      viewsJson[entry.key] = entry.value.toJson();
    }

    return {
      'entityName': entityName,
      'views': viewsJson,
    };
  }
}

/// Base class for defining queries on specific view types.
///
/// Provides common subscription functionality and serves as the base
/// for type-specific view query definitions.
abstract class ViewQueryDef {
  /// Creates a view query definition with optional subscription.
  ViewQueryDef({this.subscribe = false});

  /// Whether to subscribe to real-time updates for this view.
  final bool subscribe;

  /// Converts the query definition to JSON for network transmission.
  Map<String, dynamic> toJson();
}

/// Query definition for value views.
///
/// Queries single typed values from entity views, such as strings,
/// numbers, booleans, or DateTime objects.
class ValueQueryDef extends ViewQueryDef {
  /// Creates a value view query definition.
  ValueQueryDef({super.subscribe});

  factory ValueQueryDef.fromJson(Map<String, dynamic> json) {
    assert(json['type'] == 'val');

    return ValueQueryDef();
  }

  @override
  Map<String, dynamic> toJson() {
    return {'type': 'val'};
  }
}

/// Query definition for counter views.
///
/// Queries integer counters from entity views that track quantities,
/// counts, or other numeric metrics.
class CounterQueryDef extends ViewQueryDef {
  /// Creates a counter view query definition.
  CounterQueryDef({super.subscribe});

  factory CounterQueryDef.fromJson(Map<String, dynamic> json) {
    assert(json['type'] == 'cnt');

    return CounterQueryDef();
  }

  @override
  Map<String, dynamic> toJson() {
    return {'type': 'cnt'};
  }
}

/// Query definition for reference views.
///
/// Queries entity references with optional nested queries and attributes,
/// enabling traversal of entity relationships.
class RefQueryDef extends ViewQueryDef {
  /// Creates a reference view query definition.
  RefQueryDef({required this.query, required this.attrs, super.subscribe});

  /// Nested query to execute on the referenced entity.
  final QueryDef query;

  /// List of attribute names to include in the query result.
  List<String> attrs;

  factory RefQueryDef.fromJson(Map<String, dynamic> json) {
    assert(json['type'] == 'ref');

    Map<String, dynamic> queryJson = json['query'];
    final query = QueryDef.fromJson(queryJson);
    List<String> attrs = List.from(json['attrs'] ?? []);

    return RefQueryDef(query: query, attrs: attrs);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'ref',
      'query': query.toJson(),
      if (attrs.isNotEmpty) 'attrs': attrs,
    };
  }
}

/// Query definition for list views.
///
/// Queries lists of entity references with pagination, nested queries,
/// and per-item attributes for efficient handling of large collections.
class ListQueryDef extends ViewQueryDef {
  /// Creates a list view query definition with pagination.
  ListQueryDef({
    required this.query,
    required this.attrs,
    super.subscribe,
    required this.startAt,
    required this.length,
  });

  /// Nested query to execute on each item in the list.
  QueryDef query;

  /// List of attribute names to include for each list item.
  List<String> attrs;

  /// Zero-based starting index for pagination.
  final int startAt;

  /// Maximum number of items to return (0 for no limit).
  final int length;

  factory ListQueryDef.fromJson(Map<String, dynamic> json) {
    assert(json['type'] == 'list');

    Map<String, dynamic> queryJson = json['query'];
    List<String> attrs = List.from(json['attrs'] ?? []);
    int start = json['start'] ?? 0;
    int len = json['len'] ?? 0;

    return ListQueryDef(
      query: QueryDef.fromJson(queryJson),
      attrs: attrs,
      startAt: start,
      length: len,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'list',
      'query': query.toJson(),
      if (attrs.isNotEmpty) 'attrs': attrs,
      if (startAt != 0) 'start': startAt,
      if (length != 0) 'len': length,
    };
  }
}

// query definition builder

/// Builder for constructing QueryDef objects programmatically.
///
/// Provides a fluent interface for building complex queries with
/// multiple view definitions and nested relationships.
class QueryDefBuilder {
  QueryDefBuilder(this.entityName);

  final String entityName;

  /// Adds a view query builder to this query definition.
  void add(ViewQueryDefBuilder qb) {
    _queryViewBuilders.add(qb);
  }

  /// Builds the final QueryDef from all added view query builders.
  QueryDef build() {
    var subqueryViews = <String, ViewQueryDef>{};

    for (var b in _queryViewBuilders) {
      subqueryViews[b.name] = b.build();
    }

    return QueryDef(entityName, subqueryViews);
  }

  final _queryViewBuilders = <ViewQueryDefBuilder>[];
}

/// Base class for building view-specific query definitions.
///
/// Provides common functionality for building queries on different
/// types of entity views.
abstract class ViewQueryDefBuilder {
  /// Creates a view query builder with name and subscription option.
  ViewQueryDefBuilder(this.name, {this.subscribe = false});

  /// Name of the view to query.
  final String name;

  /// Whether to subscribe to real-time updates.
  final bool subscribe;

  /// Builds the specific ViewQueryDef implementation.
  ViewQueryDef build();
}

/// Builder for value view query definitions.
///
/// Constructs queries for single typed values in entity views.
class ValueQueryDefBuilder extends ViewQueryDefBuilder {
  /// Creates a value query builder.
  ValueQueryDefBuilder(super.name, {super.subscribe});

  @override
  ViewQueryDef build() {
    return ValueQueryDef(subscribe: subscribe);
  }
}

/// Builder for reference view query definitions.
///
/// Constructs queries for entity references with nested queries and attributes.
class RefQueryDefBuilder extends ViewQueryDefBuilder {
  /// Creates a reference query builder with attribute list.
  RefQueryDefBuilder(
    this.entityName,
    super.name,
    this.attrs, {
    super.subscribe = false,
  });

  final String entityName;

  /// List of attribute names to include in the query.
  final List<String> attrs;

  void add(ViewQueryDefBuilder qb) {
    _subqueryViewBuilders.add(qb);
  }

  @override
  ViewQueryDef build() {
    var subqueryViews = <String, ViewQueryDef>{};

    for (var b in _subqueryViewBuilders) {
      subqueryViews[b.name] = b.build();
    }

    return RefQueryDef(
      query: QueryDef(entityName, subqueryViews),
      subscribe: subscribe,
      attrs: attrs,
    );
  }

  final _subqueryViewBuilders = <ViewQueryDefBuilder>[];
}

/// Builder for list view query definitions.
///
/// Constructs queries for lists of entity references with pagination support.
class ListQueryDefBuilder extends ViewQueryDefBuilder {
  /// Creates a list query builder with attributes and pagination.
  ListQueryDefBuilder(
    this.entityName,
    super.name,
    this.attrs, {
    super.subscribe = false,
    this.startAt = 0,
    this.length = 0,
  });

  final String entityName;

  /// List of attribute names to include for each item.
  final List<String> attrs;

  /// Starting index for pagination.
  final int startAt;

  /// Maximum number of items to return.
  final int length;

  void add(ViewQueryDefBuilder qb) {
    _subqueryViewBuilders.add(qb);
  }

  @override
  ViewQueryDef build() {
    var queryViews = <String, ViewQueryDef>{};

    for (var b in _subqueryViewBuilders) {
      queryViews[b.name] = b.build();
    }

    return ListQueryDef(
      query: QueryDef(entityName, queryViews),
      attrs: attrs,
      subscribe: subscribe,
      startAt: startAt,
      length: length,
    );
  }

  final _subqueryViewBuilders = <ViewQueryDefBuilder>[];
}

// query definition builder extensions

/// Extension providing convenient methods for building query definitions.
///
/// Offers shorthand methods for adding common view types to query builders.
extension QueryDefBuilderManual on QueryDefBuilder {
  /// Adds a value view query to the builder.
  void val(String name) {
    add(ValueQueryDefBuilder(name));
  }

  /// Adds a reference view query with nested builder configuration.
  void ref(
    String entityName,
    String name,
    List<String> attrs,
    void Function(RefQueryDefBuilder qb) fun,
  ) {
    final qb = RefQueryDefBuilder(entityName, name, attrs);
    fun(qb);
    add(qb);
  }

  /// Adds a list view query with nested builder configuration.
  void list(
    String entityName,
    String name,
    List<String> attrs,
    void Function(ListQueryDefBuilder qb) fun,
  ) {
    final qb = ListQueryDefBuilder(entityName, name, attrs);
    fun(qb);
    add(qb);
  }
}

/// Extension providing convenient methods for reference query builders.
///
/// Enables adding nested view queries to reference view definitions.
extension RefQueryDefBuilderManual on RefQueryDefBuilder {
  /// Adds a value view query to the nested query definition.
  void val(String name) {
    add(ValueQueryDefBuilder(name));
  }
}

/// Extension providing convenient methods for list query builders.
///
/// Enables adding nested view queries to list view definitions.
extension ListQueryDefBuilderManual on ListQueryDefBuilder {
  /// Adds a value view query to the per-item query definition.
  void val(String name) {
    add(ValueQueryDefBuilder(name));
  }
}
