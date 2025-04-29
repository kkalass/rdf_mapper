import 'package:logging/logging.dart';
import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_core/vocab.dart';
import 'package:rdf_mapper/src/api/node_builder.dart';
import 'package:rdf_mapper/src/api/serializer.dart';
import 'package:rdf_mapper/src/api/rdf_mapper_registry.dart';
import 'package:rdf_mapper/src/api/serialization_context.dart';
import 'package:rdf_mapper/src/exceptions/serializer_not_found_exception.dart';

final _log = Logger("rdf_orm.serialization");

class SerializationContextImpl extends SerializationContext {
  final RdfMapperRegistry _registry;

  SerializationContextImpl({required RdfMapperRegistry registry})
    : _registry = registry;

  /// Implementation of the nodeBuilder method to support fluent API.
  @override
  NodeBuilder<S, T> nodeBuilder<S extends RdfSubject, T>(S subject) {
    return NodeBuilder<S, T>(subject, this);
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
      (triple) =>
          triple.subject == childIri && triple.predicate == RdfPredicates.type,
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
        constant(childIri, RdfPredicates.type, typeIri),
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

    var term = ser.toRdfTerm(instance, this);
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
      (triple) =>
          triple.subject == iri && triple.predicate == RdfPredicates.type,
    );

    if (hasTypeTriple) {
      // Check if the type is correct
      final typeTriple = triples.firstWhere(
        (triple) =>
            triple.subject == iri && triple.predicate == RdfPredicates.type,
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
      if (!hasTypeTriple && typeIri != null)
        constant(iri, RdfPredicates.type, typeIri),
      ...triples,
    ];
  }
}
