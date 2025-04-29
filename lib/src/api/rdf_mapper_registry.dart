import 'package:logging/logging.dart';
import 'package:rdf_core/rdf_core.dart';

import 'package:rdf_mapper/src/exceptions/deserializer_not_found_exception.dart';
import 'package:rdf_mapper/src/exceptions/serializer_not_found_exception.dart';
import 'package:rdf_mapper/src/deserializers/blank_node_term_deserializer.dart';
import 'package:rdf_mapper/src/mappers/rdf_blank_subject_mapper.dart';
import 'package:rdf_mapper/src/deserializers/iri_term_deserializer.dart';
import 'package:rdf_mapper/src/mappers/rdf_iri_term_mapper.dart';
import 'package:rdf_mapper/src/serializers/iri_term_serializer.dart';
import 'package:rdf_mapper/src/deserializers/literal_term_deserializer.dart';
import 'package:rdf_mapper/src/mappers/rdf_literal_term_mapper.dart';
import 'package:rdf_mapper/src/serializers/literal_term_serializer.dart';
import 'package:rdf_mapper/src/deserializers/subject_deserializer.dart';
import 'package:rdf_mapper/src/mappers/rdf_subject_mapper.dart';
import 'package:rdf_mapper/src/serializers/subject_serializer.dart';
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
    copy._iriDeserializers.addAll(_iriDeserializers);
    copy._subjectDeserializersByTypeIri.addAll(_subjectDeserializersByTypeIri);
    copy._subjectDeserializers.addAll(_subjectDeserializers);
    copy._iriSerializers.addAll(_iriSerializers);
    copy._blankNodeDeserializers.addAll(_blankNodeDeserializers);
    copy._literalDeserializers.addAll(_literalDeserializers);
    copy._literalSerializers.addAll(_literalSerializers);
    copy._subjectSerializers.addAll(_subjectSerializers);
    return copy;
  }

  /// Internal empty constructor for cloning
  RdfMapperRegistry._empty();
  final Map<Type, IriTermDeserializer<dynamic>> _iriDeserializers = {};
  final Map<IriTerm, SubjectDeserializer<dynamic>>
  _subjectDeserializersByTypeIri = {};
  final Map<Type, SubjectDeserializer<dynamic>> _subjectDeserializers = {};
  final Map<Type, IriTermSerializer<dynamic>> _iriSerializers = {};
  final Map<Type, BlankNodeTermDeserializer<dynamic>> _blankNodeDeserializers =
      {};
  final Map<Type, LiteralTermDeserializer<dynamic>> _literalDeserializers = {};
  final Map<Type, LiteralTermSerializer<dynamic>> _literalSerializers = {};
  final Map<Type, SubjectSerializer<dynamic>> _subjectSerializers = {};

  /// Creates a new RDF mapper registry
  ///
  /// @param loggerService Optional logger for diagnostic information
  RdfMapperRegistry() {
    // commonly used deserializers
    registerIriTermDeserializer(IriFullDeserializer());
    registerIriTermSerializer(IriFullSerializer());

    registerLiteralDeserializer(StringDeserializer());
    registerLiteralDeserializer(IntDeserializer());
    registerLiteralDeserializer(DoubleDeserializer());
    registerLiteralDeserializer(BoolDeserializer());
    registerLiteralDeserializer(DateTimeDeserializer());

    registerLiteralSerializer(StringSerializer());
    registerLiteralSerializer(IntSerializer());
    registerLiteralSerializer(DoubleSerializer());
    registerLiteralSerializer(BoolSerializer());
    registerLiteralSerializer(DateTimeSerializer());
  }

  void registerIriTermDeserializer<T>(IriTermDeserializer<T> deserializer) {
    _log.fine('Registering IriTerm deserializer for type ${T.toString()}');
    _iriDeserializers[T] = deserializer;
  }

  void registerIriTermSerializer<T>(IriTermSerializer<T> serializer) {
    _log.fine('Registering IriTerm serializer for type ${T.toString()}');
    _iriSerializers[T] = serializer;
  }

  void registerLiteralDeserializer<T>(LiteralTermDeserializer<T> deserializer) {
    _log.fine('Registering LiteralTerm deserializer for type ${T.toString()}');
    _literalDeserializers[T] = deserializer;
  }

  void registerLiteralSerializer<T>(LiteralTermSerializer<T> serializer) {
    _log.fine('Registering LiteralTerm serializer for type ${T.toString()}');
    _literalSerializers[T] = serializer;
  }

  void registerBlankNodeTermDeserializer<T>(
    BlankNodeTermDeserializer<T> deserializer,
  ) {
    _log.fine(
      'Registering BlankNodeTerm deserializer for type ${T.toString()}',
    );
    _blankNodeDeserializers[T] = deserializer;
  }

  void registerSubjectMapper<T>(RdfSubjectMapper<T> mapper) {
    registerSubjectDeserializer(mapper);
    registerSubjectSerializer(mapper);
  }

  void registerSubjectDeserializer<T>(SubjectDeserializer<T> deserializer) {
    _log.fine('Registering Subject deserializer for type ${T.toString()}');
    _subjectDeserializers[T] = deserializer;
    _subjectDeserializersByTypeIri[deserializer.typeIri] = deserializer;
  }

  void registerSubjectSerializer<T>(SubjectSerializer<T> serializer) {
    _log.fine('Registering Subject serializer for type ${T.toString()}');
    _subjectSerializers[T] = serializer;
  }

  void registerBlankSubjectMapper<T>(RdfBlankSubjectMapper<T> mapper) {
    registerBlankNodeTermDeserializer<T>(mapper);
    registerSubjectSerializer<T>(mapper);
  }

  void registerLiteralMapper<T>(RdfLiteralTermMapper<T> mapper) {
    registerLiteralSerializer<T>(mapper);
    registerLiteralDeserializer<T>(mapper);
  }

  void registerIriTermMapper<T>(RdfIriTermMapper<T> mapper) {
    registerIriTermSerializer<T>(mapper);
    registerIriTermDeserializer<T>(mapper);
  }

  /// Gets the deserializer for a specific type
  ///
  /// @return The deserializer for type T or null if none is registered
  IriTermDeserializer<T> getIriDeserializer<T>() {
    final deserializer = _iriDeserializers[T];
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

  IriTermSerializer<T> getIriSerializer<T>() {
    final serializer = _iriSerializers[T];
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
  IriTermSerializer<T> getIriSerializerByType<T>(Type type) {
    final serializer = _iriSerializers[type];
    if (serializer == null) {
      throw SerializerNotFoundException('RdfIriTermSerializer?', type);
    }
    return serializer as IriTermSerializer<T>;
  }

  LiteralTermDeserializer<T> getLiteralDeserializer<T>() {
    final deserializer = _literalDeserializers[T];
    if (deserializer == null) {
      throw DeserializerNotFoundException('RdfLiteralTermDeserializer', T);
    }
    return deserializer as LiteralTermDeserializer<T>;
  }

  LiteralTermSerializer<T> getLiteralSerializer<T>() {
    final serializer = _literalSerializers[T];
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
  LiteralTermSerializer<T> getLiteralSerializerByType<T>(Type type) {
    final serializer = _literalSerializers[type];
    if (serializer == null) {
      throw SerializerNotFoundException('RdfLiteralTermSerializer?', type);
    }
    return serializer as LiteralTermSerializer<T>;
  }

  BlankNodeTermDeserializer<T> getBlankNodeDeserializer<T>() {
    final deserializer = _blankNodeDeserializers[T];
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
  bool hasIriDeserializerFor<T>() => _iriDeserializers.containsKey(T);
  bool hasSubjectDeserializerFor<T>() => _subjectDeserializers.containsKey(T);
  bool hasSubjectDeserializerForType(IriTerm typeIri) =>
      _subjectDeserializersByTypeIri.containsKey(typeIri);
  bool hasLiteralDeserializerFor<T>() => _literalDeserializers.containsKey(T);
  bool hasBlankNodeDeserializerFor<T>() =>
      _blankNodeDeserializers.containsKey(T);
  bool hasIriSerializerFor<T>() => _iriSerializers.containsKey(T);
  bool hasLiteralSerializerFor<T>() => _literalSerializers.containsKey(T);
  bool hasSubjectSerializerFor<T>() => _subjectSerializers.containsKey(T);
}
