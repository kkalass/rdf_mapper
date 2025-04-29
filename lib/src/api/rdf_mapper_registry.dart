import 'package:logging/logging.dart';
import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/deserializer.dart';
import 'package:rdf_mapper/src/api/mapper.dart';
import 'package:rdf_mapper/src/api/serializer.dart';

import 'package:rdf_mapper/src/exceptions/deserializer_not_found_exception.dart';
import 'package:rdf_mapper/src/exceptions/serializer_not_found_exception.dart';
import 'package:rdf_mapper/src/mappers/literal/bool_deserializer.dart';
import 'package:rdf_mapper/src/mappers/literal/bool_serializer.dart';
import 'package:rdf_mapper/src/mappers/literal/date_time_deserializer.dart';
import 'package:rdf_mapper/src/mappers/literal/date_time_serializer.dart';
import 'package:rdf_mapper/src/mappers/literal/double_deserializer.dart';
import 'package:rdf_mapper/src/mappers/literal/double_serializer.dart';
import 'package:rdf_mapper/src/mappers/literal/int_deserializer.dart';
import 'package:rdf_mapper/src/mappers/literal/int_serializer.dart';
import 'package:rdf_mapper/src/mappers/iri/iri_full_deserializer.dart';
import 'package:rdf_mapper/src/mappers/iri/iri_full_serializer.dart';
import 'package:rdf_mapper/src/mappers/literal/string_deserializer.dart';
import 'package:rdf_mapper/src/mappers/literal/string_serializer.dart';

final _log = Logger("rdf_orm.registry");

/// Central registry for RDF mappers that handles type-to-mapper associations.
///
/// The RdfMapperRegistry is the core component of the RDF mapping system, managing
/// the registration and lookup of mappers for specific Dart types. It maintains
/// separate registries for different mapper categories:
///
/// 1. Term mappers (IRI and Literal) for simple value conversions
/// 2. Node mappers (IRI and Blank) for complex objects with associated triples
///
/// The registry supports two primary lookup mechanisms:
/// - Type-based lookup using Dart's generic type system
/// - RDF type IRI-based lookup for deserialization based on RDF type triples
///
/// Key responsibilities:
/// - Maintaining type-safe registrations of mappers
/// - Providing efficient lookup of appropriate mappers
/// - Pre-registering standard mappers for common Dart types
/// - Supporting both serialization and deserialization paths
///
/// Usage example:
/// ```dart
/// // Create a registry with standard mappers
/// final registry = RdfMapperRegistry();
///
/// // Register a custom mapper
/// registry.registerMapper<Person>(PersonMapper());
///
/// // Register individual serializer/deserializer
/// registry.registerSerializer<Book>(BookSerializer());
/// registry.registerDeserializer<Book>(BookDeserializer());
/// ```
final class RdfMapperRegistry {
  /// Returns a deep copy of this registry, including all registered mappers.
  ///
  /// Creates a new instance with the same mapper registrations as this one.
  /// This is useful for creating temporary registries with additional mappers
  /// for specific serialization/deserialization operations without affecting
  /// the global registry.
  ///
  /// @return A new registry with the same mappers as this one
  RdfMapperRegistry clone() {
    final copy = RdfMapperRegistry._empty();
    copy._nodeSerializers.addAll(_nodeSerializers);
    copy._iriNodeDeserializersByType.addAll(_iriNodeDeserializersByType);
    copy._iriNodeDeserializers.addAll(_iriNodeDeserializers);
    copy._blankNodeDeserializers.addAll(_blankNodeDeserializers);
    copy._iriTermSerializers.addAll(_iriTermSerializers);
    copy._iriTermDeserializers.addAll(_iriTermDeserializers);
    copy._literalTermSerializers.addAll(_literalTermSerializers);
    copy._literalTermDeserializers.addAll(_literalTermDeserializers);
    return copy;
  }

  /// Internal empty constructor for cloning
  RdfMapperRegistry._empty();

  // Type-based registries
  final Map<Type, IriTermDeserializer<dynamic>> _iriTermDeserializers = {};
  final Map<Type, IriNodeDeserializer<dynamic>> _iriNodeDeserializers = {};
  final Map<Type, IriTermSerializer<dynamic>> _iriTermSerializers = {};
  final Map<Type, BlankNodeDeserializer<dynamic>> _blankNodeDeserializers = {};
  final Map<Type, LiteralTermDeserializer<dynamic>> _literalTermDeserializers =
      {};
  final Map<Type, LiteralTermSerializer<dynamic>> _literalTermSerializers = {};
  final Map<Type, NodeSerializer<dynamic>> _nodeSerializers = {};

  // RDF type IRI-based registries (for dynamic type resolution during deserialization)
  final Map<IriTerm, IriNodeDeserializer<dynamic>> _iriNodeDeserializersByType =
      {};
  final Map<IriTerm, BlankNodeDeserializer<dynamic>>
  _blankNodeDeserializersByType = {};

  /// Creates a new RDF mapper registry with standard mappers pre-registered.
  ///
  /// The standard mappers handle common Dart types:
  /// - String, int, double, bool, DateTime for literal values
  /// - IriTerm for IRI references
  ///
  /// These pre-registered mappers enable out-of-the-box functionality for
  /// basic data types without requiring custom mappers.
  RdfMapperRegistry() {
    // Register standard deserializers
    registerDeserializer(IriFullDeserializer());
    registerDeserializer(StringDeserializer());
    registerDeserializer(IntDeserializer());
    registerDeserializer(DoubleDeserializer());
    registerDeserializer(BoolDeserializer());
    registerDeserializer(DateTimeDeserializer());

    // Register standard serializers
    registerSerializer(IriFullSerializer());
    registerSerializer(StringSerializer());
    registerSerializer(IntSerializer());
    registerSerializer(DoubleSerializer());
    registerSerializer(BoolSerializer());
    registerSerializer(DateTimeSerializer());
  }

  /// Registers a serializer with the appropriate registry based on its type.
  ///
  /// This method determines the correct registry for the serializer based on
  /// its implementation type and registers it for the appropriate Dart type.
  ///
  /// Supported serializer types:
  /// - IriTermSerializer: For serializing objects to IRI terms
  /// - LiteralTermSerializer: For serializing objects to literal terms
  /// - NodeSerializer: For serializing objects to RDF nodes (subjects with triples)
  ///
  /// @param serializer The serializer to register
  void registerSerializer<T>(Serializer<T> serializer) {
    switch (serializer) {
      case IriTermSerializer<T>():
        _registerIriTermSerializer(serializer);
        break;
      case LiteralTermSerializer<T>():
        _registerLiteralTermSerializer(serializer);
        break;
      case NodeSerializer<T>():
        _registerNodeSerializer(serializer);
        break;
    }
  }

  /// Registers a deserializer with the appropriate registry based on its type.
  ///
  /// This method determines the correct registry for the deserializer based on
  /// its implementation type and registers it for the appropriate Dart type.
  ///
  /// Supported deserializer types:
  /// - IriTermDeserializer: For deserializing IRI terms to objects
  /// - LiteralTermDeserializer: For deserializing literal terms to objects
  /// - BlankNodeDeserializer: For deserializing blank nodes to objects
  /// - IriNodeDeserializer: For deserializing IRI subjects with triples to objects
  ///
  /// @param deserializer The deserializer to register
  void registerDeserializer<T>(Deserializer<T> deserializer) {
    switch (deserializer) {
      case IriTermDeserializer<T>():
        _registerIriTermDeserializer(deserializer);
        break;
      case LiteralTermDeserializer<T>():
        _registerLiteralTermDeserializer(deserializer);
        break;
      case BlankNodeDeserializer<T>():
        _registerBlankNodeDeserializer(deserializer);
        break;
      case IriNodeDeserializer<T>():
        _registerIriNodeDeserializer(deserializer);
        break;
    }
  }

  /// Registers a mapper with all appropriate registries based on its implemented interfaces.
  ///
  /// This is a convenience method that handles the registration of combined
  /// serializer/deserializer mappers. It determines which specific mapper interfaces
  /// are implemented and registers the mapper with all relevant registries.
  ///
  /// Supported mapper types:
  /// - IriNodeMapper: Combined IriNodeSerializer/IriNodeDeserializer
  /// - BlankNodeMapper: Combined BlankNodeSerializer/BlankNodeDeserializer
  /// - LiteralTermMapper: Combined LiteralTermSerializer/LiteralTermDeserializer
  /// - IriTermMapper: Combined IriTermSerializer/IriTermDeserializer
  ///
  /// @param mapper The mapper to register
  void registerMapper<T>(Mapper<T> mapper) {
    switch (mapper) {
      case IriNodeMapper<T>():
        _registerIriNodeDeserializer(mapper);
        _registerNodeSerializer(mapper);
        break;
      case BlankNodeMapper<T>():
        _registerBlankNodeDeserializer<T>(mapper);
        _registerNodeSerializer<T>(mapper);
        break;
      case LiteralTermMapper<T>():
        _registerLiteralTermSerializer<T>(mapper);
        _registerLiteralTermDeserializer<T>(mapper);
        break;
      case IriTermMapper<T>():
        _registerIriTermSerializer<T>(mapper);
        _registerIriTermDeserializer<T>(mapper);
        break;
    }
  }

  void _registerIriTermDeserializer<T>(IriTermDeserializer<T> deserializer) {
    _log.fine('Registering IriTerm deserializer for type ${T.toString()}');
    _iriTermDeserializers[T] = deserializer;
  }

  void _registerIriTermSerializer<T>(IriTermSerializer<T> serializer) {
    _log.fine('Registering IriTerm serializer for type ${T.toString()}');
    _iriTermSerializers[T] = serializer;
  }

  void _registerLiteralTermDeserializer<T>(
    LiteralTermDeserializer<T> deserializer,
  ) {
    _log.fine('Registering LiteralTerm deserializer for type ${T.toString()}');
    _literalTermDeserializers[T] = deserializer;
  }

  void _registerLiteralTermSerializer<T>(LiteralTermSerializer<T> serializer) {
    _log.fine('Registering LiteralTerm serializer for type ${T.toString()}');
    _literalTermSerializers[T] = serializer;
  }

  void _registerBlankNodeDeserializer<T>(
    BlankNodeDeserializer<T> deserializer,
  ) {
    _log.fine('Registering BlankNode deserializer for type ${T.toString()}');
    _blankNodeDeserializers[T] = deserializer;
    var typeIri = deserializer.typeIri;
    if (typeIri != null) {
      _blankNodeDeserializersByType[typeIri] = deserializer;
    }
  }

  void _registerIriNodeDeserializer<T>(IriNodeDeserializer<T> deserializer) {
    _log.fine('Registering IriNodeDeserializer for type ${T.toString()}');
    _iriNodeDeserializers[T] = deserializer;
    var typeIri = deserializer.typeIri;
    if (typeIri != null) {
      _iriNodeDeserializersByType[typeIri] = deserializer;
    }
  }

  void _registerNodeSerializer<T>(NodeSerializer<T> serializer) {
    _log.fine('Registering Subject serializer for type ${T.toString()}');
    _nodeSerializers[T] = serializer;
  }

  /// Gets the deserializer for a specific type
  ///
  /// @return The deserializer for type T or null if none is registered
  IriTermDeserializer<T> getIriTermDeserializer<T>() {
    final deserializer = _iriTermDeserializers[T];
    if (deserializer == null) {
      throw DeserializerNotFoundException('IriTermDeserializer', T);
    }
    return deserializer as IriTermDeserializer<T>;
  }

  IriNodeDeserializer<T> getIriNodeDeserializer<T>() {
    final deserializer = _iriNodeDeserializers[T];
    if (deserializer == null) {
      throw DeserializerNotFoundException('IriNodeDeserializer', T);
    }
    return deserializer as IriNodeDeserializer<T>;
  }

  IriNodeDeserializer<dynamic> getIriNodeDeserializerByType(IriTerm typeIri) {
    final deserializer = _iriNodeDeserializersByType[typeIri];
    if (deserializer == null) {
      throw DeserializerNotFoundException.forTypeIri(
        'IriNodeDeserializer',
        typeIri,
      );
    }
    return deserializer;
  }

  IriTermSerializer<T> getIriTermSerializer<T>() {
    final serializer = _iriTermSerializers[T];
    if (serializer == null) {
      throw SerializerNotFoundException('IriTermSerializer', T);
    }
    return serializer as IriTermSerializer<T>;
  }

  /// Gets a IRI serializer by runtime type rather than generic type parameter
  ///
  /// This method is primarily used to handle nullable types, where the serializer
  /// might be registered for a non-nullable type (e.g., STring) but needs to be
  /// retrieved for a nullable type (e.g., String?).
  ///
  /// @param type The runtime Type to look up
  /// @return The serializer for the specified type
  /// @throws SerializerNotFoundException if no serializer is registered for the type
  IriTermSerializer<T> getIriTermSerializerByType<T>(Type type) {
    final serializer = _iriTermSerializers[type];
    if (serializer == null) {
      throw SerializerNotFoundException('IriTermSerializer', type);
    }
    return serializer as IriTermSerializer<T>;
  }

  LiteralTermDeserializer<T> getLiteralTermDeserializer<T>() {
    final deserializer = _literalTermDeserializers[T];
    if (deserializer == null) {
      throw DeserializerNotFoundException('LiteralTermDeserializer', T);
    }
    return deserializer as LiteralTermDeserializer<T>;
  }

  LiteralTermSerializer<T> getLiteralTermSerializer<T>() {
    final serializer = _literalTermSerializers[T];
    if (serializer == null) {
      throw SerializerNotFoundException('LiteralTermSerializer', T);
    }
    return serializer as LiteralTermSerializer<T>;
  }

  /// Gets a literal serializer by runtime type rather than generic type parameter
  ///
  /// This method is primarily used to handle nullable types, where the serializer
  /// might be registered for a non-nullable type (e.g., STring) but needs to be
  /// retrieved for a nullable type (e.g., String?).
  ///
  /// @param type The runtime Type to look up
  /// @return The serializer for the specified type
  /// @throws SerializerNotFoundException if no serializer is registered for the type
  LiteralTermSerializer<T> getLiteralTermSerializerByType<T>(Type type) {
    final serializer = _literalTermSerializers[type];
    if (serializer == null) {
      throw SerializerNotFoundException('LiteralTermSerializer?', type);
    }
    return serializer as LiteralTermSerializer<T>;
  }

  BlankNodeDeserializer<T> getBlankNodeDeserializer<T>() {
    final deserializer = _blankNodeDeserializers[T];
    if (deserializer == null) {
      throw DeserializerNotFoundException('BlankNodeDeserializer', T);
    }
    return deserializer as BlankNodeDeserializer<T>;
  }

  BlankNodeDeserializer<dynamic> getBlankNodeDeserializerByType(
    IriTerm typeIri,
  ) {
    final deserializer = _blankNodeDeserializersByType[typeIri];
    if (deserializer == null) {
      throw DeserializerNotFoundException.forTypeIri(
        'BlankNodeDeserializer',
        typeIri,
      );
    }
    return deserializer;
  }

  NodeSerializer<T> getNodeSerializer<T>() {
    final serializer = _nodeSerializers[T];
    if (serializer == null) {
      throw SerializerNotFoundException('NodeSerializer', T);
    }
    return serializer as NodeSerializer<T>;
  }

  /// Gets a subject serializer by runtime type rather than generic type parameter
  ///
  /// This method is primarily used to handle nullable types, where the serializer
  /// might be registered for a non-nullable type (e.g., Address) but needs to be
  /// retrieved for a nullable type (e.g., Address?).
  ///
  /// @param type The runtime Type to look up
  /// @return The serializer for the specified type
  /// @throws SerializerNotFoundException if no serializer is registered for the type
  NodeSerializer<T> getNodeSerializerByType<T>(Type type) {
    final serializer = _nodeSerializers[type];
    if (serializer == null) {
      throw SerializerNotFoundException('NodeSerializer', type);
    }
    return serializer as NodeSerializer<T>;
  }

  /// Checks if a mapper exists for a type
  ///
  /// @return true if a mapper is registered for type T, false otherwise
  bool hasIriTermDeserializerFor<T>() => _iriTermDeserializers.containsKey(T);
  bool hasIriNodeDeserializerFor<T>() => _iriNodeDeserializers.containsKey(T);
  bool hasIriNodeDeserializerForType(IriTerm typeIri) =>
      _iriNodeDeserializersByType.containsKey(typeIri);
  bool hasLiteralTermDeserializerFor<T>() =>
      _literalTermDeserializers.containsKey(T);
  bool hasBlankNodeDeserializerFor<T>() =>
      _blankNodeDeserializers.containsKey(T);
  bool hasIriTermSerializerFor<T>() => _iriTermSerializers.containsKey(T);
  bool hasLiteralTermSerializerFor<T>() =>
      _literalTermSerializers.containsKey(T);
  bool hasNodeSerializerFor<T>() => _nodeSerializers.containsKey(T);
}
