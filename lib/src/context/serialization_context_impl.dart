import 'package:logging/logging.dart';
import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/resource_builder.dart';
import 'package:rdf_mapper/src/api/serialization_service.dart';
import 'package:rdf_mapper/src/api/rdf_mapper_interfaces.dart';
import 'package:rdf_mapper/src/api/rdf_mapper_registry.dart';
import 'package:rdf_mapper/src/api/serialization_context.dart';
import 'package:rdf_mapper/src/exceptions/serializer_not_found_exception.dart';
import 'package:rdf_vocabularies_core/rdf.dart';

final _log = Logger("rdf_orm.serialization");

/// Implementation of [SerializationContext] that provides core serialization
/// functionality for converting Dart objects to RDF triples.
///
/// This class handles the serialization of various object types by intelligently
/// selecting appropriate serializers based on the object type and available
/// serializers in the registry. It supports literal terms, IRI terms, and
/// complex resources.
///
/// The serialization process follows a priority order:
/// 1. Direct RDF objects are used as-is
/// 2. Explicitly provided serializers are used first
/// 3. Registry-based serializers are used as fallback
///
/// The implementation ensures proper type handling, including automatic type
/// triple generation for resources when not already provided by the serializer.
class SerializationContextImpl extends SerializationContext
    implements SerializationService {
  final RdfMapperRegistry _registry;
  final IriTermFactory _iriTermFactory;

  SerializationContextImpl(
      {required RdfMapperRegistry registry,
      IriTermFactory iriTermFactory = IriTerm.validated})
      : _registry = registry,
        _iriTermFactory = iriTermFactory;

  @override
  IriTerm createIriTerm(String value) => _iriTermFactory(value);

  /// Implementation of the resourceBuilder method to support fluent API.
  @override
  ResourceBuilder<S> resourceBuilder<S extends RdfSubject>(S subject) {
    return ResourceBuilder<S>(
      subject,
      this,
    );
  }

  /// Converts a Dart object to an RDF literal term.
  ///
  /// The [instance] is the object to convert to a literal term.
  /// The optional [serializer] is a custom serializer for the literal term.
  ///
  /// Returns the RDF literal term representation of the instance.
  ///
  /// Throws [ArgumentError] if the instance is null.
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
      _registry.getLiteralTermSerializer<T>,
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
  /// 2. If an explicit serializer is provided, it will be used
  /// 3. Otherwise, it will try to find a registered serializer for the type
  ///
  /// The [subject] is the subject of the triple.
  /// The [predicate] is the predicate linking subject to value.
  /// The [instance] is the value to add as an object (can be a Dart object or RDF term).
  /// The optional [serializer] is a custom serializer for the value.
  ///
  /// Returns a list of triples connecting the subject to the serialized value.
  @override
  Iterable<Triple> value<T>(
      RdfSubject subject, RdfPredicate predicate, T instance,
      {Serializer<T>? serializer}) {
    final (valueTerms, triples) = serialize(
      instance,
      parentSubject: subject,
      serializer: serializer,
    );
    return [
      for (var valueTerm in valueTerms)
        Triple(subject, predicate, valueTerm as RdfObject),
      ...triples
    ];
  }

  /// Serializes a Dart object to an RDF term and associated triples.
  ///
  /// This method handles the core serialization logic, determining the appropriate
  /// serialization strategy based on the type of object and available serializers.
  ///
  /// The [instance] is the object to serialize.
  /// The optional [serializer] is a custom serializer to use.
  /// The optional [parentSubject] is the parent subject for nested resources.
  ///
  /// Returns a tuple containing the RDF term and any associated triples.
  ///
  /// Throws [ArgumentError] if the instance is null.
  /// Throws [SerializerNotFoundException] if no suitable serializer is found.
  @override
  (Iterable<RdfTerm>, Iterable<Triple>) serialize<T>(
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
      return ([instance as RdfObject], const []);
    }

    // Try serializers in priority order if explicitly provided
    switch (serializer) {
      case null:
        break;
      case IriTermSerializer<T>():
        var term = serializer.toRdfTerm(instance, this);
        return ([term], const []);
      case LiteralTermSerializer<T>():
        var term = serializer.toRdfTerm(instance, this);
        return ([term], const []);
      case ResourceSerializer<T>():
        return _createChildResource(
          instance,
          serializer,
          parentSubject: parentSubject,
        );
      case MultiObjectsSerializer<T>():
        return serializer.toRdfObjects(instance, this);
    }

    // If no explicit serializers were provided, try to find registered ones

    // 1. try literal serialization
    final literalSer = _getSerializerFallbackToRuntimeType(
      null,
      instance,
      _registry.getLiteralTermSerializer<T>,
      _registry.getLiteralTermSerializerByType,
    );

    if (literalSer != null) {
      // If we have a literal serializer, use it
      // This is the case for String, int, double, etc.
      // We can also use it for other types if we have a custom serializer
      var term = literalSer.toRdfTerm(instance, this);
      return ([term], const []);
    }

    // 2. try IRI serialization
    final iriSer = _getSerializerFallbackToRuntimeType(
      null,
      instance,
      _registry.getIriTermSerializer<T>,
      _registry.getIriTermSerializerByType,
    );

    if (iriSer != null) {
      var term = iriSer.toRdfTerm(instance, this);
      return ([term], const []);
    }

    // 3. Try resource serialization
    final resourceSer = _getSerializerFallbackToRuntimeType(
      null,
      instance,
      _registry.getResourceSerializer<T>,
      _registry.getResourceSerializerByType,
    );

    if (resourceSer != null) {
      return _createChildResource(instance, resourceSer,
          parentSubject: parentSubject);
    }

    // 4. Finally try multi-object serialization
    final multiObjectsSer = _getSerializerFallbackToRuntimeType(
      null,
      instance,
      _registry.getMultiObjectsSerializer<T>,
      _registry.getMultiObjectsSerializerByType,
    );

    if (multiObjectsSer != null) {
      return multiObjectsSer.toRdfObjects(instance, this);
    }
    throw SerializerNotFoundException('', T);
  }

  /// Adds values from a collection to the subject with the given predicate.
  ///
  /// Processes each item in the collection and creates triples for each non-null value.
  ///
  /// The [subject] is the subject of the triples.
  /// The [predicate] is the predicate linking subject to values.
  /// The [instance] is the collection of values to add.
  /// The optional [serializer] is a custom serializer for the values.
  ///
  /// Returns a list of triples connecting the subject to the values.
  @override
  Iterable<Triple> values<T>(
    RdfSubject subject,
    RdfPredicate predicate,
    Iterable<T> instance, {
    Serializer<T>? serializer,
  }) {
    return valuesFromSource<Iterable<T>, T>(
      subject,
      predicate,
      (it) => it,
      instance,
      serializer: serializer,
    );
  }

  /// Adds multiple values extracted from a source object as objects in triples.
  ///
  /// This method first applies a transformation function to extract values from a source,
  /// then serializes each extracted value into one or more triples.
  ///
  /// The [subject] is the subject of the triples.
  /// The [predicate] is the predicate linking subject to extracted values.
  /// The [toIterable] function extracts values from the source.
  /// The [instance] is the source object containing the values to extract.
  /// The optional [serializer] is a custom serializer for the extracted values.
  ///
  /// Returns a list of triples connecting the subject to all extracted values.
  @override
  Iterable<Triple> valuesFromSource<A, T>(
    RdfSubject subject,
    RdfPredicate predicate,
    Iterable<T> Function(A) toIterable,
    A instance, {
    Serializer<T>? serializer,
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
          serializer: serializer,
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

  /// Creates a child resource using the specified resource serializer.
  ///
  /// This private method handles the creation of child resources, including
  /// automatic type triple addition if not already provided by the serializer.
  ///
  /// The [instance] is the object to serialize as a child resource.
  /// The [serializer] is the resource serializer to use.
  /// The optional [parentSubject] is the parent subject for context.
  ///
  /// Returns a tuple containing the child RDF term and associated triples.
  (Iterable<RdfTerm>, Iterable<Triple>) _createChildResource<T>(
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
      [childIri],
      [
        // Add rdf:type for the child only if not already present
        if (!hasTypeTriple && typeIri != null)
          Triple(childIri, Rdf.type, typeIri),
        ...childTriples,
      ]
    );
  }

  /// Serializes an object to RDF triples as a resource.
  ///
  /// The [instance] is the object to serialize as a resource.
  /// The optional [serializer] is a custom resource serializer to use.
  ///
  /// Returns a list of triples representing the resource.
  ///
  /// Throws [ArgumentError] if the instance is null.
  /// Throws [SerializerNotFoundException] if no suitable serializer is found.
  @override
  Iterable<Triple> resource<T>(T instance,
      {ResourceSerializer<T>? serializer}) {
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

  /// Serializes a map as key-value pairs using the given predicate.
  ///
  /// Each map entry is serialized as a separate triple with the same predicate.
  ///
  /// The [subject] is the subject of the triples.
  /// The [predicate] is the predicate for each key-value pair.
  /// The [instance] is the map to serialize.
  /// The optional [serializer] is a custom serializer for map entries.
  ///
  /// Returns a list of triples representing the map entries.
  @override
  Iterable<Triple> valueMap<K, V>(
    RdfSubject subject,
    RdfPredicate predicate,
    Map<K, V> instance, {
    Serializer<MapEntry<K, V>>? serializer,
  }) =>
      valuesFromSource<Map<K, V>, MapEntry<K, V>>(
        subject,
        predicate,
        (it) => it.entries,
        instance,
        serializer: serializer,
      );

  /// Serializes unmapped triples from an object.
  ///
  /// This method extracts triples that were not mapped to specific properties
  /// during the original serialization process.
  ///
  /// The [subject] is the subject for the unmapped triples.
  /// The [value] is the object containing unmapped data.
  /// The optional [unmappedTriplesSerializer] is a custom serializer for unmapped triples.
  ///
  /// Returns an iterable of unmapped triples.
  ///
  /// Throws [SerializerNotFoundException] if no suitable serializer is found.
  @override
  Iterable<Triple> unmappedTriples<T>(RdfSubject subject, T value,
      {UnmappedTriplesSerializer<T>? unmappedTriplesSerializer}) {
    var ser = unmappedTriplesSerializer ??
        _getSerializerFallbackToRuntimeType<T, UnmappedTriplesSerializer<T>>(
          null,
          value,
          _registry.getUnmappedTriplesSerializer<T>,
          _registry.getUnmappedTriplesSerializerByType,
        );
    if (ser == null) {
      throw SerializerNotFoundException('UnmappedTriplesSerializer', T);
    }
    return ser.toUnmappedTriples(subject, value);
  }

  /// Serializes a collection using a factory-created serializer.
  ///
  /// The [subject] is the subject of the triple.
  /// The [predicate] is the predicate linking to the collection.
  /// The [collection] is the collection to serialize.
  /// The [collectionSerializerFactory] creates the appropriate collection serializer.
  /// The optional [itemSerializer] is a custom serializer for collection items.
  ///
  /// Returns an iterable of triples representing the collection.
  @override
  Iterable<Triple> collection<C, T>(
      RdfSubject subject,
      RdfPredicate predicate,
      C collection,
      CollectionSerializerFactory<C, T> collectionSerializerFactory,
      {Serializer<T>? itemSerializer}) {
    final serializer = itemSerializer == null
        ? collectionSerializerFactory()
        : collectionSerializerFactory(itemSerializer: itemSerializer);
    return value(subject, predicate, collection, serializer: serializer);
  }
}
