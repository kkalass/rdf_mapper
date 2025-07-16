import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';

/// Mixin providing serialization functionality for unordered collections.
/// Encapsulates the common logic for converting collections to RDF objects.
mixin UnorderedItemsSerializationMixin<T> {
  /// Item mapper used for serializing individual collection elements
  Serializer<T>? get itemSerializer;

  /// Serializes a collection of items to RDF objects and triples
  (Iterable<RdfObject>, Iterable<Triple>) toRdfObjects(
      Iterable<T> values, SerializationContext context) {
    final rdfObjects = values
        .map((v) => context.serialize(v, serializer: itemSerializer))
        .toList();
    return (
      rdfObjects.expand((r) => r.$1).cast<RdfObject>(),
      rdfObjects.expand((r) => r.$2)
    );
  }
}

/// Mixin providing deserialization functionality for unordered collections.
/// Encapsulates the common logic for converting RDF objects to collections.
mixin UnorderedItemsDeserializationMixin<T> {
  /// Item mapper used for deserializing individual collection elements
  Deserializer<T>? get itemDeserializer;

  /// Deserializes RDF objects to a collection of items
  Iterable<T> fromRdfObjects(
          Iterable<RdfObject> objects, DeserializationContext context) =>
      objects.map(
          (obj) => context.deserialize<T>(obj, deserializer: itemDeserializer));
}

class UnorderedItemsSerializer<T>
    with UnorderedItemsSerializationMixin<T>
    implements MultiObjectsSerializer<Iterable<T>> {
  @override
  final Serializer<T>? itemSerializer;

  UnorderedItemsSerializer([this.itemSerializer]);
}

class UnorderedItemsDeserializer<T>
    with UnorderedItemsDeserializationMixin<T>
    implements MultiObjectsDeserializer<Iterable<T>> {
  @override
  final Deserializer<T>? itemDeserializer;

  UnorderedItemsDeserializer([this.itemDeserializer]);
}

class UnorderedItemsCollectorDeserializer<T, R>
    implements MultiObjectsDeserializer<R> {
  final MultiObjectsDeserializer<Iterable<T>> _deserializer;
  final R Function(Iterable<T>) collector;
  UnorderedItemsCollectorDeserializer(this.collector,
      [Deserializer<T>? itemDeserializer])
      : _deserializer = UnorderedItemsDeserializer(itemDeserializer);

  @override
  R fromRdfObjects(
      Iterable<RdfObject> objects, DeserializationContext context) {
    final it = _deserializer.fromRdfObjects(objects, context);
    return collector(it);
  }
}

class UnorderedItemsMapper<T>
    with
        UnorderedItemsSerializationMixin<T>,
        UnorderedItemsDeserializationMixin<T>
    implements MultiObjectsMapper<Iterable<T>> {
  @override
  final Serializer<T>? itemSerializer;
  final Deserializer<T>? itemDeserializer;

  UnorderedItemsMapper([Mapper<T>? itemMapper])
      : itemDeserializer = itemMapper,
        itemSerializer = itemMapper;
}

class UnorderedItemsListSerializer<T>
    with UnorderedItemsSerializationMixin<T>
    implements MultiObjectsSerializer<List<T>> {
  @override
  final Serializer<T>? itemSerializer;

  UnorderedItemsListSerializer([this.itemSerializer]);
}

class UnorderedItemsSetSerializer<T>
    with UnorderedItemsSerializationMixin<T>
    implements MultiObjectsSerializer<Set<T>> {
  @override
  final Serializer<T>? itemSerializer;

  UnorderedItemsSetSerializer([this.itemSerializer]);
}

class UnorderedItemsListDeserializer<T>
    with UnorderedItemsDeserializationMixin<T>
    implements MultiObjectsDeserializer<List<T>> {
  @override
  final Deserializer<T>? itemDeserializer;

  UnorderedItemsListDeserializer([this.itemDeserializer]);
  @override
  List<T> fromRdfObjects(
          Iterable<RdfObject> objects, DeserializationContext context) =>
      super.fromRdfObjects(objects, context).toList();
}

class UnorderedItemsSetDeserializer<T>
    with UnorderedItemsDeserializationMixin<T>
    implements MultiObjectsDeserializer<Set<T>> {
  @override
  final Deserializer<T>? itemDeserializer;

  UnorderedItemsSetDeserializer([this.itemDeserializer]);

  @override
  Set<T> fromRdfObjects(
          Iterable<RdfObject> objects, DeserializationContext context) =>
      super.fromRdfObjects(objects, context).toSet();
}

class UnorderedItemsListMapper<T>
    with
        UnorderedItemsSerializationMixin<T>,
        UnorderedItemsDeserializationMixin<T>
    implements MultiObjectsMapper<List<T>> {
  @override
  final Serializer<T>? itemSerializer;
  @override
  final Deserializer<T>? itemDeserializer;

  UnorderedItemsListMapper([Mapper<T>? itemMapper])
      : itemSerializer = itemMapper,
        itemDeserializer = itemMapper;

  @override
  List<T> fromRdfObjects(
          Iterable<RdfObject> objects, DeserializationContext context) =>
      super.fromRdfObjects(objects, context).toList();
}

class UnorderedItemsSetMapper<T>
    with
        UnorderedItemsSerializationMixin<T>,
        UnorderedItemsDeserializationMixin<T>
    implements MultiObjectsMapper<Set<T>> {
  @override
  final Serializer<T>? itemSerializer;
  @override
  final Deserializer<T>? itemDeserializer;

  UnorderedItemsSetMapper([Mapper<T>? itemMapper])
      : itemSerializer = itemMapper,
        itemDeserializer = itemMapper;

  @override
  Set<T> fromRdfObjects(
          Iterable<RdfObject> objects, DeserializationContext context) =>
      super.fromRdfObjects(objects, context).toSet();
}
