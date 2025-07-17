import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';

/// Mixin providing serialization functionality for unordered collections.
/// Encapsulates the common logic for converting collections to RDF objects.
abstract mixin class UnorderedItemsSerializerMixin<T> {
  /// Serializes a collection of items to RDF objects and triples
  (Iterable<RdfObject>, Iterable<Triple>) buildRdfObjects(Iterable<T> values,
      SerializationContext context, Serializer<T>? itemSerializer) {
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
abstract mixin class UnorderedItemsDeserializerMixin<T> {
  /// Deserializes RDF objects to a collection of items
  Iterable<T> readRdfObjects(Iterable<RdfObject> objects,
          DeserializationContext context, Deserializer<T>? itemDeserializer) =>
      objects.map(
          (obj) => context.deserialize<T>(obj, deserializer: itemDeserializer));
}

class UnorderedItemsSerializer<T>
    with UnorderedItemsSerializerMixin<T>
    implements MultiObjectsSerializer<Iterable<T>> {
  final Serializer<T>? _itemSerializer;

  UnorderedItemsSerializer([this._itemSerializer]);

  @override
  (Iterable<RdfObject>, Iterable<Triple>) toRdfObjects(
          Iterable<T> value, SerializationContext context) =>
      buildRdfObjects(value, context, _itemSerializer);
}

class UnorderedItemsDeserializer<T>
    with UnorderedItemsDeserializerMixin<T>
    implements MultiObjectsDeserializer<Iterable<T>> {
  final Deserializer<T>? _itemDeserializer;

  UnorderedItemsDeserializer([this._itemDeserializer]);

  @override
  Iterable<T> fromRdfObjects(
          Iterable<RdfObject> objects, DeserializationContext context) =>
      readRdfObjects(objects, context, _itemDeserializer);
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
    with UnorderedItemsSerializerMixin<T>, UnorderedItemsDeserializerMixin<T>
    implements MultiObjectsMapper<Iterable<T>> {
  final Mapper<T>? _itemMapper;

  UnorderedItemsMapper([this._itemMapper]);

  @override
  (Iterable<RdfObject>, Iterable<Triple>) toRdfObjects(
          Iterable<T> value, SerializationContext context) =>
      buildRdfObjects(value, context, _itemMapper);

  @override
  Iterable<T> fromRdfObjects(
          Iterable<RdfObject> objects, DeserializationContext context) =>
      readRdfObjects(objects, context, _itemMapper);
}

class UnorderedItemsListSerializer<T>
    with UnorderedItemsSerializerMixin<T>
    implements MultiObjectsSerializer<List<T>> {
  final Serializer<T>? _itemSerializer;

  UnorderedItemsListSerializer([this._itemSerializer]);

  @override
  (Iterable<RdfObject>, Iterable<Triple>) toRdfObjects(
          List<T> value, SerializationContext context) =>
      buildRdfObjects(value, context, _itemSerializer);
}

class UnorderedItemsSetSerializer<T>
    with UnorderedItemsSerializerMixin<T>
    implements MultiObjectsSerializer<Set<T>> {
  final Serializer<T>? _itemSerializer;

  UnorderedItemsSetSerializer([this._itemSerializer]);

  @override
  (Iterable<RdfObject>, Iterable<Triple>) toRdfObjects(
          Set<T> value, SerializationContext context) =>
      buildRdfObjects(value, context, _itemSerializer);
}

class UnorderedItemsListDeserializer<T>
    with UnorderedItemsDeserializerMixin<T>
    implements MultiObjectsDeserializer<List<T>> {
  final Deserializer<T>? itemDeserializer;

  UnorderedItemsListDeserializer({this.itemDeserializer});
  @override
  List<T> fromRdfObjects(
          Iterable<RdfObject> objects, DeserializationContext context) =>
      readRdfObjects(objects, context, itemDeserializer).toList();
}

class UnorderedItemsSetDeserializer<T>
    with UnorderedItemsDeserializerMixin<T>
    implements MultiObjectsDeserializer<Set<T>> {
  final Deserializer<T>? _itemDeserializer;

  UnorderedItemsSetDeserializer([this._itemDeserializer]);

  @override
  Set<T> fromRdfObjects(
          Iterable<RdfObject> objects, DeserializationContext context) =>
      readRdfObjects(objects, context, _itemDeserializer).toSet();
}

class UnorderedItemsListMapper<T>
    with UnorderedItemsSerializerMixin<T>, UnorderedItemsDeserializerMixin<T>
    implements MultiObjectsMapper<List<T>> {
  final Mapper<T>? _itemMapper;

  UnorderedItemsListMapper([this._itemMapper]);

  @override
  (Iterable<RdfObject>, Iterable<Triple>) toRdfObjects(
          List<T> value, SerializationContext context) =>
      buildRdfObjects(value, context, _itemMapper);

  @override
  List<T> fromRdfObjects(
          Iterable<RdfObject> objects, DeserializationContext context) =>
      readRdfObjects(objects, context, _itemMapper).toList();
}

class UnorderedItemsSetMapper<T>
    with UnorderedItemsSerializerMixin<T>, UnorderedItemsDeserializerMixin<T>
    implements MultiObjectsMapper<Set<T>> {
  final Mapper<T>? _itemMapper;

  UnorderedItemsSetMapper([this._itemMapper]);

  @override
  (Iterable<RdfObject>, Iterable<Triple>) toRdfObjects(
          Set<T> value, SerializationContext context) =>
      buildRdfObjects(value, context, _itemMapper);

  @override
  Set<T> fromRdfObjects(
          Iterable<RdfObject> objects, DeserializationContext context) =>
      readRdfObjects(objects, context, _itemMapper).toSet();
}
