import 'package:logging/logging.dart';
import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';

final _log = Logger("rdf_orm.registry");

/// Central registry for RDF mappers that handles type-to-mapper associations.
///
/// The RdfMapperRegistry is the core component of the RDF mapping system, managing
/// the registration and lookup of mappers for specific Dart types. It maintains
/// separate registries for different mapper categories:
///
/// 1. Term mappers (IRI and Literal) for simple value conversions
/// 2. Resource mappers (IRI and Blank) for complex objects with associated triples
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
  /// Returns a new registry with the same mappers as this one
  RdfMapperRegistry clone() {
    final copy = RdfMapperRegistry._empty();
    copy._resourceSerializers.addAll(_resourceSerializers);
    copy._globalResourceDeserializersByType
        .addAll(_globalResourceDeserializersByType);
    copy._globalResourceDeserializers.addAll(_globalResourceDeserializers);
    copy._localResourceDeserializers.addAll(_localResourceDeserializers);
    copy._iriTermSerializers.addAll(_iriTermSerializers);
    copy._iriTermDeserializers.addAll(_iriTermDeserializers);
    copy._allIriTermDeserializers.addAll(_allIriTermDeserializers);
    copy._literalTermSerializers.addAll(_literalTermSerializers);
    copy._literalTermDeserializers.addAll(_literalTermDeserializers);
    copy._unmappedTriplesDeserializers.addAll(_unmappedTriplesDeserializers);
    copy._unmappedTriplesSerializers.addAll(_unmappedTriplesSerializers);
    return copy;
  }

  /// Internal empty constructor for cloning
  RdfMapperRegistry._empty();

  // Type-based registries
  final Map<Type, IriTermDeserializer<dynamic>> _iriTermDeserializers = {};

  /// Keep original order of IriTermDeserializers for when we need to find
  /// a roughly matching deserializer by type.
  final List<IriTermDeserializer<dynamic>> _allIriTermDeserializers = [];
  final Map<Type, GlobalResourceDeserializer<dynamic>>
      _globalResourceDeserializers = {};
  final Map<Type, IriTermSerializer<dynamic>> _iriTermSerializers = {};
  final Map<Type, LocalResourceDeserializer<dynamic>>
      _localResourceDeserializers = {};
  final Map<Type, LiteralTermDeserializer<dynamic>> _literalTermDeserializers =
      {};

  final Map<Type, LiteralTermSerializer<dynamic>> _literalTermSerializers = {};
  final Map<Type, ResourceSerializer<dynamic>> _resourceSerializers = {};
  final Map<Type, UnmappedTriplesDeserializer<dynamic>>
      _unmappedTriplesDeserializers = {};
  final Map<Type, UnmappedTriplesSerializer<dynamic>>
      _unmappedTriplesSerializers = {};
  final Map<Type, MultiObjectsDeserializer<dynamic>>
      _multiObjectsDeserializers = {};
  final Map<Type, MultiObjectsSerializer<dynamic>> _multiObjectsSerializers =
      {};

  // RDF type IRI-based registries (for dynamic type resolution during deserialization)
  final Map<IriTerm, GlobalResourceDeserializer<dynamic>>
      _globalResourceDeserializersByType = {};
  final Map<IriTerm, LocalResourceDeserializer<dynamic>>
      _localResourceDeserializersByType = {};
  final Map<IriTerm, List<LiteralTermDeserializer<dynamic>>>
      _literalTermDeserializersByType = {};
  final Map<IriTerm, Type> _globalResourceDartTypeByIriType = {};
  final Map<IriTerm, Type> _localResourceDartTypeByIriType = {};

  /// Creates a new RDF mapper registry with standard mappers pre-registered.
  ///
  /// The standard mappers handle common Dart types:
  /// - String, int, double, bool, DateTime for literal values
  /// - IriTerm for IRI references
  ///
  /// These pre-registered mappers enable out-of-the-box functionality for
  /// basic data types without requiring custom mappers.
  RdfMapperRegistry() {
    // Register standard mappers
    registerMapper(const UriIriMapper());

    // Register mappers for common literal types
    registerMapper(const StringMapper());
    registerMapper(const IntMapper());
    registerMapper(const DoubleMapper());
    registerMapper(const BoolMapper());

    // Note: while it may be tempting to register DateMapper globally, that
    // will not work because the dart DateTime type is used for both DateMapper
    // and DateTimeMapper. Users must specify the DateMapper in their calls to Reader/Builder explicitly.
    // registerMapper(const DateMapper());
    registerMapper(const DateTimeMapper());

    // Register mappers for unmapped triples
    registerMapper(const RdfGraphUnmappedTriplesMapper());
    registerMapper(const PredicatesMapMapper());
    registerMapper(const IriTermMapMapper());

    // Register generic mappers for resources
    registerMapper(const RDFGraphResourceMapper());
  }

  /// Registers a serializer with the appropriate registry based on its type.
  ///
  /// This method determines the correct registry for the serializer based on
  /// its implementation type and registers it for the appropriate Dart type.
  ///
  /// Supported serializer types:
  /// - IriTermSerializer: For serializing objects to IRI terms
  /// - LiteralTermSerializer: For serializing objects to literal terms
  /// - ResourceSerializer: For serializing objects to RDF resources (subjects with triples)
  ///
  /// [serializer] The serializer to register
  void registerSerializer<T>(BaseSerializer<T> serializer) {
    switch (serializer) {
      case IriTermSerializer<T>():
        _registerIriTermSerializer(serializer);
        break;
      case LiteralTermSerializer<T>():
        _registerLiteralTermSerializer(serializer);
        break;
      case ResourceSerializer<T>():
        _registerResourceSerializer(serializer);
        break;
      case UnmappedTriplesSerializer<T>():
        _registerUnmappedTriplesSerializer(serializer);
        break;
      case MultiObjectsSerializer<T>():
        _registerMultiObjectsSerializer(serializer);
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
  /// - LocalResourceDeserializer: For deserializing local resources to objects
  /// - GlobalResourceDeserializer: For deserializing global resources with triples to objects
  ///
  /// [deserializer] The deserializer to register
  void registerDeserializer<T>(BaseDeserializer<T> deserializer) {
    switch (deserializer) {
      case IriTermDeserializer<T>():
        _registerIriTermDeserializer(deserializer);
        break;
      case LiteralTermDeserializer<T>():
        _registerLiteralTermDeserializer(deserializer);
        break;
      case LocalResourceDeserializer<T>():
        _registerLocalResourceDeserializer(deserializer);
        break;
      case GlobalResourceDeserializer<T>():
        _registerGlobalResourceDeserializer(deserializer);
        break;
      case UnifiedResourceDeserializer<T>():
        _registerGlobalResourceDeserializer(
            _GlobalResourceDeserializer(deserializer));
        _registerLocalResourceDeserializer(
            _LocalResourceDeserializer(deserializer));
        break;
      case UnmappedTriplesDeserializer<T>():
        _registerUnmappedTriplesDeserializer(deserializer);
        break;
      case MultiObjectsDeserializer<T>():
        _registerMultiObjectsDeserializer(deserializer);
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
  /// - GlobalResourceMapper: Combined GlobalResourceSerializer/GlobalResourceDeserializer
  /// - LocalResourceMapper: Combined LocalResourceSerializer/LocalResourceDeserializer
  /// - LiteralTermMapper: Combined LiteralTermSerializer/LiteralTermDeserializer
  /// - IriTermMapper: Combined IriTermSerializer/IriTermDeserializer
  /// - UnmappedTriplesMapper: Combined UnmappedTriplesSerializer/UnmappedTriplesDeserializer
  ///
  /// Note: UnmappedTriplesMapper registration only registers the mapper for unmapped
  /// triples handling. To use unmapped types as resources (subjects), separate
  /// GlobalResourceMapper and LocalResourceMapper implementations must be registered.
  /// For RdfGraph, these are provided as RdfGraphGlobalResourceMapper and
  /// RdfGraphLocalResourceMapper, but they require a clear single root subject for
  /// serialization to work correctly.
  ///
  /// [mapper] The mapper to register
  void registerMapper<T>(BaseMapper<T> mapper) {
    switch (mapper) {
      case GlobalResourceMapper<T>():
        _registerGlobalResourceDeserializer(mapper);
        _registerResourceSerializer(mapper);
        break;
      case LocalResourceMapper<T>():
        _registerLocalResourceDeserializer<T>(mapper);
        _registerResourceSerializer<T>(mapper);
        break;
      case LiteralTermMapper<T>():
        _registerLiteralTermSerializer<T>(mapper);
        _registerLiteralTermDeserializer<T>(mapper);
        break;
      case IriTermMapper<T>():
        _registerIriTermSerializer<T>(mapper);
        _registerIriTermDeserializer<T>(mapper);
        break;
      case UnmappedTriplesMapper<T>():
        _registerUnmappedTriplesDeserializer<T>(mapper);
        _registerUnmappedTriplesSerializer<T>(mapper);
      case UnifiedResourceMapper<T>():
        _registerGlobalResourceDeserializer(
            _GlobalResourceDeserializer(mapper));
        _registerLocalResourceDeserializer(_LocalResourceDeserializer(mapper));
        _registerResourceSerializer(mapper);
        break;
      case MultiObjectsMapper<T>():
        _registerMultiObjectsDeserializer<T>(mapper);
        _registerMultiObjectsSerializer<T>(mapper);
    }
  }

  void _registerUnmappedTriplesDeserializer<T>(
    UnmappedTriplesDeserializer<T> deserializer,
  ) {
    _log.fine(
        'Registering UnmappedTriples deserializer for type ${T.toString()}');
    _unmappedTriplesDeserializers[T] = deserializer;
  }

  void _registerUnmappedTriplesSerializer<T>(
    UnmappedTriplesSerializer<T> serializer,
  ) {
    _log.fine(
        'Registering UnmappedTriples serializer for type ${T.toString()}');
    _unmappedTriplesSerializers[T] = serializer;
  }

  void _registerMultiObjectsDeserializer<T>(
    MultiObjectsDeserializer<T> deserializer,
  ) {
    _log.fine('Registering MultiObjects deserializer for type ${T.toString()}');
    _multiObjectsDeserializers[T] = deserializer;
  }

  void _registerMultiObjectsSerializer<T>(
    MultiObjectsSerializer<T> serializer,
  ) {
    _log.fine('Registering MultiObjects serializer for type ${T.toString()}');
    _multiObjectsSerializers[T] = serializer;
  }

  void _registerIriTermDeserializer<T>(IriTermDeserializer<T> deserializer) {
    _log.fine('Registering IriTerm deserializer for type ${T.toString()}');
    _iriTermDeserializers[T] = deserializer;
    _allIriTermDeserializers.add(deserializer);
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
    final datatype = deserializer.datatype;
    if (datatype != null) {
      _literalTermDeserializersByType.putIfAbsent(
          datatype, () => <LiteralTermDeserializer<dynamic>>[])
        ..add(deserializer);
    }
  }

  void _registerLiteralTermSerializer<T>(LiteralTermSerializer<T> serializer) {
    _log.fine('Registering LiteralTerm serializer for type ${T.toString()}');
    _literalTermSerializers[T] = serializer;
  }

  void _registerLocalResourceDeserializer<T>(
    LocalResourceDeserializer<T> deserializer,
  ) {
    _log.fine('Registering BlankNode deserializer for type ${T.toString()}');
    _localResourceDeserializers[T] = deserializer;
    var typeIri = deserializer.typeIri;
    if (typeIri != null) {
      _localResourceDeserializersByType[typeIri] = deserializer;
      _localResourceDartTypeByIriType[typeIri] = T;
    }
  }

  void _registerGlobalResourceDeserializer<T>(
      GlobalResourceDeserializer<T> deserializer) {
    _log.fine(
        'Registering GlobalResourceDeserializer for type ${T.toString()}');
    _globalResourceDeserializers[T] = deserializer;
    var typeIri = deserializer.typeIri;
    if (typeIri != null) {
      _globalResourceDeserializersByType[typeIri] = deserializer;
      _globalResourceDartTypeByIriType[typeIri] = T;
    }
  }

  void _registerResourceSerializer<T>(ResourceSerializer<T> serializer) {
    _log.fine('Registering Subject serializer for type ${T.toString()}');
    _resourceSerializers[T] = serializer;
  }

  /// Gets the deserializer for a specific type.
  ///
  /// Returns the deserializer for type T, throwing an exception if none is registered.
  IriTermDeserializer<T> getIriTermDeserializer<T>() {
    final deserializer = _iriTermDeserializers[T];
    if (deserializer == null) {
      throw DeserializerNotFoundException('IriTermDeserializer', T);
    }
    return deserializer as IriTermDeserializer<T>;
  }

  IriTermDeserializer<T> getFirstIriTermDeserializer<T>() {
    return _allIriTermDeserializers.lastWhere(
      (deserializer) => deserializer is IriTermDeserializer<T>,
      orElse: () =>
          throw DeserializerNotFoundException('IriTermDeserializer', T),
    ) as IriTermDeserializer<T>;
  }

  GlobalResourceDeserializer<T> getGlobalResourceDeserializer<T>() {
    final deserializer = _globalResourceDeserializers[T];
    if (deserializer == null) {
      throw DeserializerNotFoundException('GlobalResourceDeserializer', T);
    }
    return deserializer as GlobalResourceDeserializer<T>;
  }

  GlobalResourceDeserializer<dynamic> getGlobalResourceDeserializerByType(
      IriTerm typeIri) {
    final deserializer = _globalResourceDeserializersByType[typeIri];
    if (deserializer == null) {
      throw DeserializerNotFoundException.forTypeIri(
        'GlobalResourceDeserializer',
        typeIri,
      );
    }
    return deserializer;
  }

  Type? getGlobalResourceDartTypeByIriType(IriTerm typeIri) {
    return _globalResourceDartTypeByIriType[typeIri];
  }

  Type? getLocalResourceDartTypeByIriType(IriTerm typeIri) {
    return _localResourceDartTypeByIriType[typeIri];
  }

  IriTermSerializer<T> getIriTermSerializer<T>() {
    final serializer = _iriTermSerializers[T];
    if (serializer == null) {
      throw SerializerNotFoundException('IriTermSerializer', T);
    }
    return serializer as IriTermSerializer<T>;
  }

  MultiObjectsDeserializer<T> getMultiObjectsDeserializer<T>() {
    final deserializer = _multiObjectsDeserializers[T];
    if (deserializer == null) {
      throw DeserializerNotFoundException('MultiObjectsDeserializer', T);
    }
    return deserializer as MultiObjectsDeserializer<T>;
  }

  MultiObjectsSerializer<T> getMultiObjectsSerializer<T>() {
    final serializer = _multiObjectsSerializers[T];
    if (serializer == null) {
      throw SerializerNotFoundException('MultiObjectsSerializer', T);
    }
    return serializer as MultiObjectsSerializer<T>;
  }

  MultiObjectsSerializer<T> getMultiObjectsSerializerByType<T>(Type type) {
    final serializer = _multiObjectsSerializers[type];
    if (serializer == null) {
      throw SerializerNotFoundException('MultiObjectsSerializer', type);
    }
    return serializer as MultiObjectsSerializer<T>;
  }

  UnmappedTriplesDeserializer<T> getUnmappedTriplesDeserializer<T>() {
    final deserializer = _unmappedTriplesDeserializers[T];
    if (deserializer == null) {
      throw DeserializerNotFoundException('UnmappedTriplesDeserializer', T);
    }
    return deserializer as UnmappedTriplesDeserializer<T>;
  }

  UnmappedTriplesSerializer<T> getUnmappedTriplesSerializer<T>() {
    final serializer = _unmappedTriplesSerializers[T];
    if (serializer == null) {
      throw SerializerNotFoundException('UnmappedTriplesSerializer', T);
    }
    return serializer as UnmappedTriplesSerializer<T>;
  }

  UnmappedTriplesSerializer<T> getUnmappedTriplesSerializerByType<T>(
    Type type,
  ) {
    final serializer = _unmappedTriplesSerializers[type];
    if (serializer == null) {
      throw SerializerNotFoundException('UnmappedTriplesSerializer', type);
    }
    return serializer as UnmappedTriplesSerializer<T>;
  }

  /// Gets a IRI serializer by runtime type rather than generic type parameter.
  ///
  /// This method is primarily used to handle nullable types, where the serializer
  /// might be registered for a non-nullable type (e.g., String) but needs to be
  /// retrieved for a nullable type (e.g., String?).
  ///
  /// [type] The runtime Type to look up
  ///
  /// Returns the serializer for the specified type
  ///
  /// Throws [SerializerNotFoundException] if no serializer is registered for the type
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

  LiteralTermDeserializer<T> getLiteralTermDeserializerByType<T>(
      IriTerm typeIri) {
    final deserializers = _literalTermDeserializersByType[typeIri];
    if (deserializers == null) {
      throw DeserializerNotFoundException(
          'LiteralTermDeserializer by datatype IRI $typeIri', T);
    }
    return deserializers.firstWhere((d) => d is LiteralTermDeserializer<T>,
        orElse: () => throw DeserializerNotFoundException(
            'LiteralTermDeserializer by datatype IRI $typeIri - found deserializers, but none matched type $T',
            T)) as LiteralTermDeserializer<T>;
  }

  LiteralTermSerializer<T> getLiteralTermSerializer<T>() {
    final serializer = _literalTermSerializers[T];
    if (serializer == null) {
      throw SerializerNotFoundException('LiteralTermSerializer', T);
    }
    return serializer as LiteralTermSerializer<T>;
  }

  /// Gets a literal serializer by runtime type rather than generic type parameter.
  ///
  /// This method is primarily used to handle nullable types, where the serializer
  /// might be registered for a non-nullable type (e.g., String) but needs to be
  /// retrieved for a nullable type (e.g., String?).
  ///
  /// [type] The runtime Type to look up
  ///
  /// Returns the serializer for the specified type
  ///
  /// Throws [SerializerNotFoundException] if no serializer is registered for the type
  LiteralTermSerializer<T> getLiteralTermSerializerByType<T>(Type type) {
    final serializer = _literalTermSerializers[type];
    if (serializer == null) {
      throw SerializerNotFoundException('LiteralTermSerializer?', type);
    }
    return serializer as LiteralTermSerializer<T>;
  }

  LocalResourceDeserializer<T> getLocalResourceDeserializer<T>() {
    final deserializer = _localResourceDeserializers[T];
    if (deserializer == null) {
      throw DeserializerNotFoundException('LocalResourceDeserializer', T);
    }
    return deserializer as LocalResourceDeserializer<T>;
  }

  LocalResourceDeserializer<dynamic> getLocalResourceDeserializerByType(
    IriTerm typeIri,
  ) {
    final deserializer = _localResourceDeserializersByType[typeIri];
    if (deserializer == null) {
      throw DeserializerNotFoundException.forTypeIri(
        'LocalResourceDeserializer',
        typeIri,
      );
    }
    return deserializer;
  }

  ResourceSerializer<T> getResourceSerializer<T>() {
    final serializer = _resourceSerializers[T];
    if (serializer == null) {
      throw SerializerNotFoundException('ResourceSerializer', T);
    }
    return serializer as ResourceSerializer<T>;
  }

  /// Gets a subject serializer by runtime type rather than generic type parameter.
  ///
  /// This method is primarily used to handle nullable types, where the serializer
  /// might be registered for a non-nullable type (e.g., Address) but needs to be
  /// retrieved for a nullable type (e.g., Address?).
  ///
  /// [type] The runtime Type to look up
  ///
  /// Returns the serializer for the specified type
  ///
  /// Throws [SerializerNotFoundException] if no serializer is registered for the type
  ResourceSerializer<T> getResourceSerializerByType<T>(Type type) {
    final serializer = _resourceSerializers[type];
    if (serializer == null) {
      throw SerializerNotFoundException('ResourceSerializer', type);
    }
    return serializer as ResourceSerializer<T>;
  }

  BaseDeserializer<T>? findDeserializerByType<T>() {
    return (_iriTermDeserializers[T] ??
        _literalTermDeserializers[T] ??
        _localResourceDeserializers[T] ??
        _globalResourceDeserializers[T] ??
        _unmappedTriplesDeserializers[T]) as BaseDeserializer<T>?;
  }

  Serializer<T>? findSerializerByType<T>() {
    return (_iriTermSerializers[T] ??
        _literalTermSerializers[T] ??
        _resourceSerializers[T] ??
        _unmappedTriplesSerializers[T]) as Serializer<T>?;
  }

  /// Checks if a mapper exists for a type.
  ///
  /// Returns true if a mapper is registered for type T, false otherwise
  bool hasIriTermDeserializerFor<T>() => _iriTermDeserializers.containsKey(T);
  bool hasIriTermDeserializerForDartType(Type type) =>
      _iriTermDeserializers.containsKey(type);
  bool hasGlobalResourceDeserializerFor<T>() =>
      _globalResourceDeserializers.containsKey(T);
  bool hasGlobalResourceDeserializerForDartType(Type type) =>
      _globalResourceDeserializers.containsKey(type);
  bool hasGlobalResourceDeserializerForType(IriTerm typeIri) =>
      _globalResourceDeserializersByType.containsKey(typeIri);
  bool hasLiteralTermDeserializerFor<T>() =>
      _literalTermDeserializers.containsKey(T);
  bool hasLiteralTermDeserializerForDartType(Type type) =>
      _literalTermDeserializers.containsKey(type);
  bool hasLocalResourceDeserializerFor<T>() =>
      _localResourceDeserializers.containsKey(T);
  bool hasLocalResourceDeserializerForDartType(Type type) =>
      _localResourceDeserializers.containsKey(type);
  bool hasIriTermSerializerFor<T>() => _iriTermSerializers.containsKey(T);
  bool hasIriTermSerializerForDartType(Type type) =>
      _iriTermSerializers.containsKey(type);
  bool hasLiteralTermSerializerFor<T>() =>
      _literalTermSerializers.containsKey(T);
  bool hasLiteralTermSerializerForDartType(Type type) =>
      _literalTermSerializers.containsKey(type);
  bool hasResourceSerializerFor<T>() => _resourceSerializers.containsKey(T);
  bool hasResourceSerializerForDartType(Type type) =>
      _resourceSerializers.containsKey(type);
  bool hasUnmappedTriplesDeserializerFor<T>() =>
      _unmappedTriplesDeserializers.containsKey(T);
  bool hasUnmappedTriplesDeserializerForDartType(Type type) =>
      _unmappedTriplesDeserializers.containsKey(type);
  bool hasUnmappedTriplesSerializerFor<T>() =>
      _unmappedTriplesSerializers.containsKey(T);
  bool hasUnmappedTriplesSerializerForDartType(Type type) =>
      _unmappedTriplesSerializers.containsKey(type);
  bool hasMultiObjectsDeserializerFor<T>() =>
      _multiObjectsDeserializers.containsKey(T);
  bool hasMultiObjectsDeserializerForDartType(Type type) =>
      _multiObjectsDeserializers.containsKey(type);
  bool hasMultiObjectsSerializerFor<T>() =>
      _multiObjectsSerializers.containsKey(T);
  bool hasMultiObjectsSerializerForDartType(Type type) =>
      _multiObjectsSerializers.containsKey(type);
}

// These are internal adapter classes, typically used only by CommonResourceMapper.
class _GlobalResourceDeserializer<T> implements GlobalResourceDeserializer<T> {
  final UnifiedResourceDeserializer<T> _mapper;

  _GlobalResourceDeserializer(UnifiedResourceDeserializer<T> mapper)
      : _mapper = mapper;

  @override
  T fromRdfResource(IriTerm subject, DeserializationContext context) =>
      _mapper.fromRdfResource(subject, context);

  @override
  IriTerm? get typeIri => _mapper.typeIri;

  @override
  String toString() => 'GlobalDeserializer: ${_mapper.toString()}';
}

class _LocalResourceDeserializer<T> implements LocalResourceDeserializer<T> {
  final UnifiedResourceDeserializer<T> _mapper;

  _LocalResourceDeserializer(UnifiedResourceDeserializer<T> mapper)
      : _mapper = mapper;

  @override
  T fromRdfResource(BlankNodeTerm subject, DeserializationContext context) =>
      _mapper.fromRdfResource(subject, context);

  @override
  IriTerm? get typeIri => _mapper.typeIri;

  @override
  String toString() => 'LocalDeserializer: ${_mapper.toString()}';
}
