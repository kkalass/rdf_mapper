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
    final ser =
        _getSerializerFallbackToRuntimeType(
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
      } catch (_) {
        // If exact type fails (likely because T is nullable), try with the runtime type.
        // We get here because there was no serializer registered for the nullable T,
        // so we implement null behaviour by simply returning an empty list for null.
        if (instance == null) {
          return null;
        }

        final Type runtimeType = instance.runtimeType;
        ser = lookupByType(runtimeType);
      }
    }
    return ser;
  }

  @override
  List<Triple> childNode<T>(
    RdfSubject subject,
    RdfPredicate predicate,
    T instance, {
    NodeSerializer<T>? serializer,
  }) {
    // Try to get serializer directly for type T if provided or available
    NodeSerializer<T>? ser = _getSerializerFallbackToRuntimeType(
      serializer,
      instance,
      _registry.getNodeSerializer,
      _registry.getNodeSerializerByType,
    );
    if (ser == null) {
      return [];
    }

    var (childIri, childTriples) = ser.toRdfNode(
      instance,
      this,
      parentSubject: subject,
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
    return [
      // Add rdf:type for the child only if not already present
      if (!hasTypeTriple && typeIri != null)
        constant(childIri, Rdf.type, typeIri),
      ...childTriples,
      // connect the parent to the child
      constant(subject, predicate, childIri),
    ];
  }

  @override
  Triple constant(
    RdfSubject subject,
    RdfPredicate predicate,
    RdfObject object,
  ) => Triple(subject, predicate, object);

  @override
  Triple iri<T>(
    RdfSubject subject,
    RdfPredicate predicate,
    T instance, {
    IriTermSerializer<T>? serializer,
  }) {
    if (instance == null) {
      throw ArgumentError(
        'Instance cannot be null for IRI serialization, the caller should handle null values.',
      );
    }
    // Try to get serializer directly for type T if provided or available
    final ser =
        _getSerializerFallbackToRuntimeType(
          serializer,
          instance,
          _registry.getIriTermSerializer,
          _registry.getIriTermSerializerByType,
        )!;

    var term = ser.toRdfTerm(instance, this);
    return Triple(subject, predicate, term);
  }

  @override
  Triple literal<T>(
    RdfSubject subject,
    RdfPredicate predicate,
    T instance, {
    LiteralTermSerializer<T>? serializer,
  }) {
    var term = toLiteralTerm(instance, serializer: serializer);
    return Triple(subject, predicate, term);
  }

  @override
  List<Triple> node<T>(T instance, {NodeSerializer<T>? serializer}) {
    if (instance == null) {
      throw ArgumentError('Cannot serialize null instance');
    }

    // Use the existing _getSerializerFallbackToRuntimeType method to find the appropriate serializer
    final ser = _getSerializerFallbackToRuntimeType(
      serializer,
      instance,
      _registry.getNodeSerializer<T>,
      _registry.getNodeSerializerByType<T>,
    );

    if (ser == null) {
      throw SerializerNotFoundException('SubjectSerializer', T);
    }

    var (iri, triples) = ser.toRdfNode(instance, this);

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
      if (!hasTypeTriple && typeIri != null) constant(iri, Rdf.type, typeIri),
      ...triples,
    ];
  }

  /// Creates triples for multiple literal objects derived from a source object.
  List<Triple> literals<A, T>(
    RdfSubject subject,
    RdfPredicate predicate,
    Iterable<T> Function(A) toIterable,
    A instance, {
    LiteralTermSerializer<T>? serializer,
  }) =>
      toIterable(instance)
          .map(
            (item) => literal(subject, predicate, item, serializer: serializer),
          )
          .toList();

  /// Creates triples for a collection of literal objects.
  List<Triple> literalList<T>(
    RdfSubject subject,
    RdfPredicate predicate,
    Iterable<T> instance, {
    LiteralTermSerializer<T>? serializer,
  }) => literals<Iterable<T>, T>(
    subject,
    predicate,
    (it) => it,
    instance,
    serializer: serializer,
  );
  List<Triple> iris<A, T>(
    RdfSubject subject,
    RdfPredicate predicate,
    Iterable<T> Function(A) toIterable,
    A instance, {
    IriTermSerializer<T>? serializer,
  }) =>
      toIterable(instance)
          .map((item) => iri(subject, predicate, item, serializer: serializer))
          .toList();

  /// Creates triples for a collection of IRI objects.
  List<Triple> iriList<T>(
    RdfSubject subject,
    RdfPredicate predicate,
    Iterable<T> instance, {
    IriTermSerializer<T>? serializer,
  }) => iris<Iterable<T>, T>(
    subject,
    predicate,
    (it) => it,
    instance,
    serializer: serializer,
  );
  List<Triple> childNodes<A, T>(
    RdfSubject subject,
    RdfPredicate predicate,
    Iterable<T> Function(A p1) toIterable,
    A instance, {
    NodeSerializer<T>? serializer,
  }) =>
      toIterable(instance)
          .expand<Triple>(
            (item) =>
                childNode(subject, predicate, item, serializer: serializer),
          )
          .toList();

  /// Creates triples for a collection of child nodes.
  List<Triple> childNodeList<T>(
    RdfSubject subject,
    RdfPredicate predicate,
    Iterable<T> instance, {
    NodeSerializer<T>? serializer,
  }) => childNodes(
    subject,
    predicate,
    (it) => it,
    instance,
    serializer: serializer,
  );

  /// Creates triples for a map of child nodes.
  List<Triple> childNodeMap<K, V>(
    RdfSubject subject,
    RdfPredicate predicate,
    Map<K, V> instance,
    NodeSerializer<MapEntry<K, V>> entrySerializer,
  ) => childNodes<Map<K, V>, MapEntry<K, V>>(
    subject,
    predicate,
    (it) => it.entries,
    instance,
    serializer: entrySerializer,
  );
}
