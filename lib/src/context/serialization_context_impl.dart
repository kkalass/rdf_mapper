import 'package:logging/logging.dart';
import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/resource_builder.dart';
import 'package:rdf_mapper/src/api/serialization_service.dart';
import 'package:rdf_mapper/src/api/serializer.dart';
import 'package:rdf_mapper/src/api/rdf_mapper_registry.dart';
import 'package:rdf_mapper/src/api/serialization_context.dart';
import 'package:rdf_mapper/src/exceptions/serializer_not_found_exception.dart';
import 'package:rdf_vocabularies/rdf.dart';

final _log = Logger("rdf_orm.serialization");

class SerializationContextImpl extends SerializationContext
    implements SerializationService {
  final RdfMapperRegistry _registry;

  SerializationContextImpl({required RdfMapperRegistry registry})
      : _registry = registry;

  /// Implementation of the resourceBuilder method to support fluent API.
  @override
  ResourceBuilder<S> resourceBuilder<S extends RdfSubject>(S subject) {
    return ResourceBuilder<S>(subject, this);
  }

  @override
  LiteralTerm toLiteralTerm<T>(
    T instance, {
    LiteralTermSerializer<T>? serializer,
  }) {
    if (instance == null) {
      throw ArgumentError(
        'Instance cannot be null for literal serialization, the caller should handle null values.',
      );
    }
    final ser = _getSerializerFallbackToRuntimeType(
      serializer,
      instance,
      _registry.getLiteralTermSerializer,
      _registry.getLiteralTermSerializerByType,
    )!;

    return ser.toRdfTerm(instance, this);
  }

  /// This method is used to look up serializers for types.
  /// It first tries to find a serializer for the exact type T.
  /// If that fails (likely because T is nullable), it tries to find a serializer
  /// for the runtime type of the instance.
  /// If the instance is null, it returns null.
  /// This is useful for handling nullable types in Dart.
  R? _getSerializerFallbackToRuntimeType<T, R>(
    R? serializer,
    T instance,
    R Function() lookup,
    R Function(Type) lookupByType,
  ) {
    // Try to get serializer directly for type T if provided or available
    R ser;
    if (serializer != null) {
      ser = serializer;
    } else {
      try {
        // First attempt with exact type T
        ser = lookup();
      } on SerializerNotFoundException catch (_) {
        // If exact type fails (likely because T is nullable), try with the runtime type.
        // We get here because there was no serializer registered for the nullable T,
        // so we implement null behaviour by simply returning an empty list for null.
        if (instance == null) {
          return null;
        }

        final Type runtimeType = instance.runtimeType;
        try {
          ser = lookupByType(runtimeType);
        } on SerializerNotFoundException catch (_) {
          return null;
        }
      }
    }
    return ser;
  }

  /// Adds a value to the subject as the object of a triple.
  ///
  /// This method is a unified approach to creating triples from various value types.
  /// It intelligently selects the appropriate serialization strategy based on:
  /// 1. If the instance is already an RdfObject, it will be used directly
  /// 2. If explicit serializers are provided, they will be used in order of priority
  /// 3. Otherwise, it will try to find a registered serializer for the type
  ///
  /// @param subject The subject of the triple
  /// @param predicate The predicate linking subject to value
  /// @param instance The value to add as an object (can be a Dart object or RDF term)
  /// @param literalTermSerializer Optional custom serializer for literal terms
  /// @param iriTermSerializer Optional custom serializer for IRI terms
  /// @param resourceSerializer Optional custom serializer for resources
  /// @return A list of triples connecting the subject to the serialized value
  @override
  List<Triple> value<T>(
    RdfSubject subject,
    RdfPredicate predicate,
    T instance, {
    LiteralTermSerializer<T>? literalTermSerializer,
    IriTermSerializer<T>? iriTermSerializer,
    ResourceSerializer<T>? resourceSerializer,
  }) {
    final (valueTerm, triples) = serialize(
      instance,
      parentSubject: subject,
      serializer:
          literalTermSerializer ?? iriTermSerializer ?? resourceSerializer,
    );
    return [Triple(subject, predicate, valueTerm as RdfObject), ...triples];
  }

  @override
  (RdfTerm, Iterable<Triple>) serialize<T>(
    T instance, {
    Serializer<T>? serializer,
    RdfSubject? parentSubject,
  }) {
    if (instance == null) {
      throw ArgumentError(
        'Instance cannot be null for serialization, the caller should handle null values.',
      );
    }

    // Check if the instance is already an RDF term
    if (instance is RdfObject) {
      return (instance as RdfObject, const []);
    }

    // Try serializers in priority order if explicitly provided

    // 1. Try IRI serializer if provided
    if (serializer is IriTermSerializer<T>) {
      var term = serializer.toRdfTerm(instance, this);
      return (term, const []);
    }

    // 2. Try literal serializer if provided
    if (serializer is LiteralTermSerializer<T>) {
      var term = serializer.toRdfTerm(instance, this);
      return (term, const []);
    }

    // 3. Try resource serializer if provided
    if (serializer is ResourceSerializer<T>) {
      return _createChildResource(
        instance,
        serializer,
        parentSubject: parentSubject,
      );
    }

    // If no explicit serializers were provided, try to find registered ones

    // 1. try literal serialization
    final literalSer = _getSerializerFallbackToRuntimeType(
      null,
      instance,
      _registry.getLiteralTermSerializer,
      _registry.getLiteralTermSerializerByType,
    );

    if (literalSer != null) {
      // If we have a literal serializer, use it
      // This is the case for String, int, double, etc.
      // We can also use it for other types if we have a custom serializer
      var term = literalSer.toRdfTerm(instance, this);
      return (term, const []);
    }

    // 2. try IRI serialization
    final iriSer = _getSerializerFallbackToRuntimeType(
      null,
      instance,
      _registry.getIriTermSerializer,
      _registry.getIriTermSerializerByType,
    );

    if (iriSer != null) {
      var term = iriSer.toRdfTerm(instance, this);
      return (term, const []);
    }

    // 3. Finally try resource serialization
    final resourceSer = _getSerializerFallbackToRuntimeType(
      null,
      instance,
      _registry.getResourceSerializer,
      _registry.getResourceSerializerByType,
    );

    if (resourceSer != null) {
      return _createChildResource(instance, resourceSer,
          parentSubject: parentSubject);
    }

    throw SerializerNotFoundException('', T);
  }

  /// Adds values from a collection to the subject with the given predicate.
  ///
  /// Processes each item in the collection and creates triples for each non-null value.
  ///
  /// @param subject The subject of the triples
  /// @param predicate The predicate linking subject to values
  /// @param instance Collection of values to add
  /// @param literalTermSerializer Optional custom serializer for literal terms
  /// @param iriTermSerializer Optional custom serializer for IRI terms
  /// @param resourceSerializer Optional custom serializer for resources
  /// @return List of triples connecting the subject to the values
  @override
  List<Triple> values<T>(
    RdfSubject subject,
    RdfPredicate predicate,
    Iterable<T> instance, {
    LiteralTermSerializer<T>? literalTermSerializer,
    IriTermSerializer<T>? iriTermSerializer,
    ResourceSerializer<T>? resourceSerializer,
  }) {
    return valuesFromSource<Iterable<T>, T>(
      subject,
      predicate,
      (it) => it,
      instance,
      literalTermSerializer: literalTermSerializer,
      iriTermSerializer: iriTermSerializer,
      resourceSerializer: resourceSerializer,
    );
  }

  /// Adds multiple values extracted from a source object as objects in triples.
  ///
  /// This method first applies a transformation function to extract values from a source,
  /// then serializes each extracted value into one or more triples.
  ///
  /// @param subject The subject of the triples
  /// @param predicate The predicate linking subject to extracted values
  /// @param toIterable Function to extract values from the source
  /// @param instance Source object containing the values to extract
  /// @param literalTermSerializer Optional custom serializer for literal terms
  /// @param iriTermSerializer Optional custom serializer for IRI terms
  /// @param resourceSerializer Optional custom serializer for resources
  /// @return List of triples connecting the subject to all extracted values
  @override
  List<Triple> valuesFromSource<A, T>(
    RdfSubject subject,
    RdfPredicate predicate,
    Iterable<T> Function(A) toIterable,
    A instance, {
    LiteralTermSerializer<T>? literalTermSerializer,
    IriTermSerializer<T>? iriTermSerializer,
    ResourceSerializer<T>? resourceSerializer,
  }) {
    final result = <Triple>[];

    // Skip processing if instance is null
    if (instance == null) {
      return result;
    }

    // Process each item from the source
    for (final item in toIterable(instance)) {
      if (item == null) continue; // Skip null items

      try {
        // Try to create value with each item
        final valueTriples = value(
          subject,
          predicate,
          item,
          literalTermSerializer: literalTermSerializer,
          iriTermSerializer: iriTermSerializer,
          resourceSerializer: resourceSerializer,
        );

        // Add all triples to our results
        result.addAll(valueTriples);
      } catch (e) {
        // Handle any serialization errors - log or skip depending on requirements
        _log.warning('Error serializing value of type ${item.runtimeType}: $e');
      }
    }

    return result;
  }

  // Private implementation of childResource with support for different resource serializers
  (RdfTerm, Iterable<Triple>) _createChildResource<T>(
      T instance, ResourceSerializer<T> serializer,
      {RdfSubject? parentSubject}) {
    // Check if we have a custom serializer or should use registry
    ResourceSerializer<T>? ser = serializer;

    var (childIri, childTriples) = ser.toRdfResource(
      instance,
      this,
      parentSubject: parentSubject,
    );

    // Check if a type triple already exists for the child
    final hasTypeTriple = childTriples.any(
      (triple) => triple.subject == childIri && triple.predicate == Rdf.type,
    );

    if (hasTypeTriple) {
      _log.fine(
        'Mapper for ${T.toString()} already provided a type triple. '
        'Skipping automatic type triple addition.',
      );
    }

    final typeIri = ser.typeIri;
    return (
      childIri,
      [
        // Add rdf:type for the child only if not already present
        if (!hasTypeTriple && typeIri != null)
          Triple(childIri, Rdf.type, typeIri),
        ...childTriples,
      ]
    );
  }

  @override
  List<Triple> resource<T>(T instance, {ResourceSerializer<T>? serializer}) {
    if (instance == null) {
      throw ArgumentError('Cannot serialize null instance');
    }

    // Use the existing _getSerializerFallbackToRuntimeType method to find the appropriate serializer
    final ser = _getSerializerFallbackToRuntimeType(
      serializer,
      instance,
      _registry.getResourceSerializer<T>,
      _registry.getResourceSerializerByType<T>,
    );

    if (ser == null) {
      throw SerializerNotFoundException('SubjectSerializer', T);
    }

    var (iri, triples) = ser.toRdfResource(instance, this);

    // Check if a type triple already exists
    final hasTypeTriple = triples.any(
      (triple) => triple.subject == iri && triple.predicate == Rdf.type,
    );

    if (hasTypeTriple) {
      // Check if the type is correct
      final typeTriple = triples.firstWhere(
        (triple) => triple.subject == iri && triple.predicate == Rdf.type,
      );

      if (typeTriple.object != ser.typeIri) {
        _log.warning(
          'Mapper for ${T.toString()} provided a type triple with different type than '
          'declared in typeIri property. Expected: ${ser.typeIri}, '
          'but found: ${typeTriple.object}',
        );
      } else {
        _log.fine(
          'Mapper for ${T.toString()} already provided a type triple. '
          'Skipping automatic type triple addition.',
        );
      }
    }

    final typeIri = ser.typeIri;
    return [
      // Add rdf:type only if not already present in triples
      if (!hasTypeTriple && typeIri != null) Triple(iri, Rdf.type, typeIri),
      ...triples,
    ];
  }

  @override
  List<Triple> valueMap<K, V>(
    RdfSubject subject,
    RdfPredicate predicate,
    Map<K, V> instance, {
    LiteralTermSerializer<MapEntry<K, V>>? literalTermSerializer,
    IriTermSerializer<MapEntry<K, V>>? iriTermSerializer,
    ResourceSerializer<MapEntry<K, V>>? resourceSerializer,
  }) =>
      valuesFromSource<Map<K, V>, MapEntry<K, V>>(
        subject,
        predicate,
        (it) => it.entries,
        instance,
        resourceSerializer: resourceSerializer,
        iriTermSerializer: iriTermSerializer,
        literalTermSerializer: literalTermSerializer,
      );

  @override
  Iterable<Triple> unmappedTriples<T>(RdfSubject subject, T value,
      {UnmappedTriplesSerializer<T>? unmappedTriplesSerializer}) {
    var ser = unmappedTriplesSerializer ??
        _getSerializerFallbackToRuntimeType(
          null,
          value,
          _registry.getUnmappedTriplesSerializer,
          _registry.getUnmappedTriplesSerializerByType,
        );
    if (ser == null) {
      throw SerializerNotFoundException('UnmappedTriplesSerializer', T);
    }
    return ser.toUnmappedTriples(subject, value);
  }

  (RdfSubject, Iterable<Triple>) buildRdfList<V>(Iterable<V> values,
      {RdfSubject? headNode, Serializer<V>? serializer}) {
    if (values.isEmpty) {
      return (Rdf.nil, const []);
    }

    headNode ??= BlankNodeTerm();
    return (
      headNode,
      _buildRdfListTriples(values.iterator, headNode, serializer: serializer)
    );
  }

  Iterable<Triple> _buildRdfListTriples<V>(
      Iterator<V> iterator, RdfSubject headNode,
      {Serializer<V>? serializer}) sync* {
    if (!iterator.moveNext()) {
      return;
    }

    var currentNode = headNode;

    do {
      final value = iterator.current;

      // Serialize the current value
      final (valueTerm, valueTriples) = serialize<V>(value,
          parentSubject: currentNode, serializer: serializer);

      // Yield all triples from the serialized value
      yield* valueTriples;

      // Add rdf:first triple
      yield Triple(currentNode, Rdf.first, valueTerm as RdfObject);

      // Check if there are more elements
      final hasNext = iterator.moveNext();

      if (hasNext) {
        // Not last element: create next node and point to it
        final nextNode = BlankNodeTerm();
        yield Triple(currentNode, Rdf.rest, nextNode);
        currentNode = nextNode;
      } else {
        // Last element: point to rdf:nil
        yield Triple(currentNode, Rdf.rest, Rdf.nil);
        break;
      }
    } while (true);
  }
}
