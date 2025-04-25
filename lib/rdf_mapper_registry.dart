import 'package:logging/logging.dart';
import 'package:rdf_core/graph/rdf_term.dart';
import 'package:rdf_mapper/exceptions/deserializer_not_found_exception.dart';
import 'package:rdf_mapper/exceptions/serializer_not_found_exception.dart';
import 'package:rdf_mapper/rdf_blank_node_term_deserializer.dart';
import 'package:rdf_mapper/rdf_iri_term_deserializer.dart';
import 'package:rdf_mapper/rdf_iri_term_serializer.dart';
import 'package:rdf_mapper/rdf_literal_term_deserializer.dart';
import 'package:rdf_mapper/rdf_literal_term_serializer.dart';
import 'package:rdf_mapper/rdf_subject_deserializer.dart';
import 'package:rdf_mapper/rdf_subject_mapper.dart';
import 'package:rdf_mapper/rdf_subject_serializer.dart';
import 'package:rdf_mapper/standard_mappers/bool_deserializer.dart';
import 'package:rdf_mapper/standard_mappers/bool_serializer.dart';
import 'package:rdf_mapper/standard_mappers/date_time_deserializer.dart';
import 'package:rdf_mapper/standard_mappers/date_time_serializer.dart';
import 'package:rdf_mapper/standard_mappers/double_deserializer.dart';
import 'package:rdf_mapper/standard_mappers/double_serializer.dart';
import 'package:rdf_mapper/standard_mappers/int_deserializer.dart';
import 'package:rdf_mapper/standard_mappers/int_serializer.dart';
import 'package:rdf_mapper/standard_mappers/iri_full_deserializer.dart';
import 'package:rdf_mapper/standard_mappers/iri_full_serializer.dart';
import 'package:rdf_mapper/standard_mappers/string_deserializer.dart';
import 'package:rdf_mapper/standard_mappers/string_serializer.dart';

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
  final Map<Type, RdfIriTermDeserializer<dynamic>> _iriDeserializers = {};
  final Map<IriTerm, RdfSubjectDeserializer<dynamic>>
  _subjectDeserializersByTypeIri = {};
  final Map<Type, RdfSubjectDeserializer<dynamic>> _subjectDeserializers = {};
  final Map<Type, RdfIriTermSerializer<dynamic>> _iriSerializers = {};
  final Map<Type, RdfBlankNodeTermDeserializer<dynamic>>
  _blankNodeDeserializers = {};
  final Map<Type, RdfLiteralTermDeserializer<dynamic>> _literalDeserializers =
      {};
  final Map<Type, RdfLiteralTermSerializer<dynamic>> _literalSerializers = {};
  final Map<Type, RdfSubjectSerializer<dynamic>> _subjectSerializers = {};

  /// Creates a new RDF mapper registry
  ///
  /// @param loggerService Optional logger for diagnostic information
  RdfMapperRegistry() {
    // commonly used deserializers
    registerIriDeserializer(IriFullDeserializer());
    registerIriSerializer(IriFullSerializer());

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

  void registerIriDeserializer<T>(RdfIriTermDeserializer<T> deserializer) {
    _log.fine('Registering IriTerm deserializer for type ${T.toString()}');
    _iriDeserializers[T] = deserializer;
  }

  void registerIriSerializer<T>(RdfIriTermSerializer<T> serializer) {
    _log.fine('Registering IriTerm serializer for type ${T.toString()}');
    _iriSerializers[T] = serializer;
  }

  void registerLiteralDeserializer<T>(
    RdfLiteralTermDeserializer<T> deserializer,
  ) {
    _log.fine('Registering LiteralTerm deserializer for type ${T.toString()}');
    _literalDeserializers[T] = deserializer;
  }

  void registerLiteralSerializer<T>(RdfLiteralTermSerializer<T> serializer) {
    _log.fine('Registering LiteralTerm serializer for type ${T.toString()}');
    _literalSerializers[T] = serializer;
  }

  void registerBlankNodeDeserializer<T>(
    RdfBlankNodeTermDeserializer<T> deserializer,
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

  void registerSubjectDeserializer<T>(RdfSubjectDeserializer<T> deserializer) {
    _log.fine('Registering IriTerm serializer for type ${T.toString()}');
    _subjectDeserializers[T] = deserializer;
    _subjectDeserializersByTypeIri[deserializer.typeIri] = deserializer;
  }

  void registerSubjectSerializer<T>(RdfSubjectSerializer<T> serializer) {
    _log.fine('Registering ToTriples deserializer for type ${T.toString()}');
    _subjectSerializers[T] = serializer;
  }

  /// Gets the deserializer for a specific type
  ///
  /// @return The deserializer for type T or null if none is registered
  RdfIriTermDeserializer<T> getIriDeserializer<T>() {
    final deserializer = _iriDeserializers[T];
    if (deserializer == null) {
      throw DeserializerNotFoundException('RdfIriTermDeserializer', T);
    }
    return deserializer as RdfIriTermDeserializer<T>;
  }

  RdfSubjectDeserializer<T> getSubjectDeserializer<T>() {
    final deserializer = _subjectDeserializers[T];
    if (deserializer == null) {
      throw DeserializerNotFoundException('RdfSubjectDeserializer', T);
    }
    return deserializer as RdfSubjectDeserializer<T>;
  }

  RdfSubjectDeserializer<dynamic> getSubjectDeserializerByTypeIri(
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

  RdfIriTermSerializer<T> getIriSerializer<T>() {
    final serializer = _iriSerializers[T];
    if (serializer == null) {
      throw SerializerNotFoundException('RdfIriTermSerializer', T);
    }
    return serializer as RdfIriTermSerializer<T>;
  }

  RdfLiteralTermDeserializer<T> getLiteralDeserializer<T>() {
    final deserializer = _literalDeserializers[T];
    if (deserializer == null) {
      throw DeserializerNotFoundException('RdfLiteralTermDeserializer', T);
    }
    return deserializer as RdfLiteralTermDeserializer<T>;
  }

  RdfLiteralTermSerializer<T> getLiteralSerializer<T>() {
    final serializer = _literalSerializers[T];
    if (serializer == null) {
      throw SerializerNotFoundException('RdfLiteralTermSerializer', T);
    }
    return serializer as RdfLiteralTermSerializer<T>;
  }

  RdfBlankNodeTermDeserializer<T> getBlankNodeDeserializer<T>() {
    final deserializer = _blankNodeDeserializers[T];
    if (deserializer == null) {
      throw DeserializerNotFoundException('RdfBlankNodeTermDeserializer', T);
    }
    return deserializer as RdfBlankNodeTermDeserializer<T>;
  }

  RdfSubjectSerializer<T> getSubjectSerializer<T>() {
    final serializer = _subjectSerializers[T];
    if (serializer == null) {
      throw SerializerNotFoundException('RdfToTriplesSerializer', T);
    }
    return serializer as RdfSubjectSerializer<T>;
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
