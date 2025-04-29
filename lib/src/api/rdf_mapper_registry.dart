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

/// Central registry for RDF type mappers
///
/// Provides a way to register and retrieve mappers for specific types.
/// This is the core of the mapping system, managing type-to-mapper associations.
final class RdfMapperRegistry {
  /// Returns a deep copy of this registry, including all registered mappers.
  RdfMapperRegistry clone() {
    final copy = RdfMapperRegistry._empty();
    copy._subjectSerializers.addAll(_subjectSerializers);
    copy._subjectDeserializersByTypeIri.addAll(_subjectDeserializersByTypeIri);
    copy._subjectDeserializers.addAll(_subjectDeserializers);
    copy._blankNodeTermDeserializers.addAll(_blankNodeTermDeserializers);
    copy._iriTermSerializers.addAll(_iriTermSerializers);
    copy._iriTermDeserializers.addAll(_iriTermDeserializers);
    copy._literalTermSerializers.addAll(_literalTermSerializers);
    copy._literalTermDeserializers.addAll(_literalTermDeserializers);
    return copy;
  }

  /// Internal empty constructor for cloning
  RdfMapperRegistry._empty();
  final Map<Type, IriTermDeserializer<dynamic>> _iriTermDeserializers = {};
  final Map<IriTerm, SubjectDeserializer<dynamic>>
  _subjectDeserializersByTypeIri = {};
  final Map<Type, SubjectDeserializer<dynamic>> _subjectDeserializers = {};
  final Map<Type, IriTermSerializer<dynamic>> _iriTermSerializers = {};
  final Map<Type, BlankNodeTermDeserializer<dynamic>>
  _blankNodeTermDeserializers = {};
  final Map<Type, LiteralTermDeserializer<dynamic>> _literalTermDeserializers =
      {};
  final Map<Type, LiteralTermSerializer<dynamic>> _literalTermSerializers = {};
  final Map<Type, SubjectSerializer<dynamic>> _subjectSerializers = {};

  /// Creates a new RDF mapper registry
  ///
  /// @param loggerService Optional logger for diagnostic information
  RdfMapperRegistry() {
    registerDeserializer(IriFullDeserializer());
    registerDeserializer(StringDeserializer());
    registerDeserializer(IntDeserializer());
    registerDeserializer(DoubleDeserializer());
    registerDeserializer(BoolDeserializer());
    registerDeserializer(DateTimeDeserializer());

    registerSerializer(IriFullSerializer());
    registerSerializer(StringSerializer());
    registerSerializer(IntSerializer());
    registerSerializer(DoubleSerializer());
    registerSerializer(BoolSerializer());
    registerSerializer(DateTimeSerializer());
  }

  void registerSerializer<T>(Serializer<T> serializer) {
    switch (serializer) {
      case IriTermSerializer<T>():
        _registerIriTermSerializer(serializer);
        break;
      case LiteralTermSerializer<T>():
        _registerLiteralTermSerializer(serializer);
        break;
      case SubjectSerializer<T>():
        _registerSubjectSerializer(serializer);
        break;
    }
  }

  void registerDeserializer<T>(Deserializer<T> deserializer) {
    switch (deserializer) {
      case IriTermDeserializer<T>():
        _registerIriTermDeserializer(deserializer);
        break;
      case LiteralTermDeserializer<T>():
        _registerLiteralTermDeserializer(deserializer);
        break;
      case BlankNodeTermDeserializer<T>():
        _registerBlankNodeTermDeserializer(deserializer);
        break;
      case SubjectDeserializer<T>():
        _registerSubjectDeserializer(deserializer);
        break;
    }
  }

  void registerMapper<T>(Mapper<T> mapper) {
    switch (mapper) {
      case SubjectMapper<T>():
        _registerSubjectDeserializer(mapper);
        _registerSubjectSerializer(mapper);
        break;
      case BlankSubjectMapper<T>():
        _registerBlankNodeTermDeserializer<T>(mapper);
        _registerSubjectSerializer<T>(mapper);
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

  void _registerBlankNodeTermDeserializer<T>(
    BlankNodeTermDeserializer<T> deserializer,
  ) {
    _log.fine(
      'Registering BlankNodeTerm deserializer for type ${T.toString()}',
    );
    _blankNodeTermDeserializers[T] = deserializer;
  }

  void _registerSubjectDeserializer<T>(SubjectDeserializer<T> deserializer) {
    _log.fine('Registering Subject deserializer for type ${T.toString()}');
    _subjectDeserializers[T] = deserializer;
    _subjectDeserializersByTypeIri[deserializer.typeIri] = deserializer;
  }

  void _registerSubjectSerializer<T>(SubjectSerializer<T> serializer) {
    _log.fine('Registering Subject serializer for type ${T.toString()}');
    _subjectSerializers[T] = serializer;
  }

  /// Gets the deserializer for a specific type
  ///
  /// @return The deserializer for type T or null if none is registered
  IriTermDeserializer<T> getIriTermDeserializer<T>() {
    final deserializer = _iriTermDeserializers[T];
    if (deserializer == null) {
      throw DeserializerNotFoundException('RdfIriTermDeserializer', T);
    }
    return deserializer as IriTermDeserializer<T>;
  }

  SubjectDeserializer<T> getSubjectDeserializer<T>() {
    final deserializer = _subjectDeserializers[T];
    if (deserializer == null) {
      throw DeserializerNotFoundException('RdfSubjectDeserializer', T);
    }
    return deserializer as SubjectDeserializer<T>;
  }

  SubjectDeserializer<dynamic> getSubjectDeserializerByTypeIri(
    IriTerm typeIri,
  ) {
    final deserializer = _subjectDeserializersByTypeIri[typeIri];
    if (deserializer == null) {
      throw DeserializerNotFoundException.forTypeIri(
        'RdfSubjectDeserializer',
        typeIri,
      );
    }
    return deserializer;
  }

  IriTermSerializer<T> getIriTermSerializer<T>() {
    final serializer = _iriTermSerializers[T];
    if (serializer == null) {
      throw SerializerNotFoundException('RdfIriTermSerializer', T);
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
      throw SerializerNotFoundException('RdfIriTermSerializer?', type);
    }
    return serializer as IriTermSerializer<T>;
  }

  LiteralTermDeserializer<T> getLiteralTermDeserializer<T>() {
    final deserializer = _literalTermDeserializers[T];
    if (deserializer == null) {
      throw DeserializerNotFoundException('RdfLiteralTermDeserializer', T);
    }
    return deserializer as LiteralTermDeserializer<T>;
  }

  LiteralTermSerializer<T> getLiteralTermSerializer<T>() {
    final serializer = _literalTermSerializers[T];
    if (serializer == null) {
      throw SerializerNotFoundException('RdfLiteralTermSerializer', T);
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
      throw SerializerNotFoundException('RdfLiteralTermSerializer?', type);
    }
    return serializer as LiteralTermSerializer<T>;
  }

  BlankNodeTermDeserializer<T> getBlankNodeTermDeserializer<T>() {
    final deserializer = _blankNodeTermDeserializers[T];
    if (deserializer == null) {
      throw DeserializerNotFoundException('RdfBlankNodeTermDeserializer', T);
    }
    return deserializer as BlankNodeTermDeserializer<T>;
  }

  SubjectSerializer<T> getSubjectSerializer<T>() {
    final serializer = _subjectSerializers[T];
    if (serializer == null) {
      throw SerializerNotFoundException('RdfSubjectSerializer', T);
    }
    return serializer as SubjectSerializer<T>;
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
  SubjectSerializer<T> getSubjectSerializerByType<T>(Type type) {
    final serializer = _subjectSerializers[type];
    if (serializer == null) {
      throw SerializerNotFoundException('RdfSubjectSerializer', type);
    }
    return serializer as SubjectSerializer<T>;
  }

  /// Checks if a mapper exists for a type
  ///
  /// @return true if a mapper is registered for type T, false otherwise
  bool hasIriTermDeserializerFor<T>() => _iriTermDeserializers.containsKey(T);
  bool hasSubjectDeserializerFor<T>() => _subjectDeserializers.containsKey(T);
  bool hasSubjectDeserializerForType(IriTerm typeIri) =>
      _subjectDeserializersByTypeIri.containsKey(typeIri);
  bool hasLiteralTermDeserializerFor<T>() =>
      _literalTermDeserializers.containsKey(T);
  bool hasBlankNodeTermDeserializerFor<T>() =>
      _blankNodeTermDeserializers.containsKey(T);
  bool hasIriTermSerializerFor<T>() => _iriTermSerializers.containsKey(T);
  bool hasLiteralTermSerializerFor<T>() =>
      _literalTermSerializers.containsKey(T);
  bool hasSubjectSerializerFor<T>() => _subjectSerializers.containsKey(T);
}
