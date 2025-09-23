import 'dart:convert';

import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';

/// Base class for RDF mapping codecs that convert between Dart objects and RDF graphs.
///
/// This abstract class defines the common interface for all RDF mapping codecs,
/// extending the standard Dart [Codec] pattern for bidirectional conversion.
///
/// Type [T] represents the Dart object type that will be converted to and from RDF.
abstract class RdfMapperCodec<T> extends Codec<T, RdfGraph> {
  @override
  RdfMapperEncoder<T> get encoder;

  @override
  RdfMapperDecoder<T> get decoder;

  /// Converts a Dart object of type [T] to an RDF graph.
  ///
  /// The [register] parameter allows for temporarily registering additional mappers
  /// for the conversion process without modifying the codec's global registry.
  RdfGraph encode(
    T input, {
    void Function(RdfMapperRegistry registry)? register,
  });

  /// Converts an RDF graph to a Dart object of type [T].
  ///
  /// The [register] parameter allows for temporarily registering additional mappers
  /// for the conversion process without modifying the codec's global registry.
  T decode(
    RdfGraph input, {
    void Function(RdfMapperRegistry registry)? register,
  });
}

/// Encoder component of the RDF mapper codec system.
///
/// This abstract class defines the contract for encoders that convert
/// Dart objects of type [T] to RDF graph representations.
abstract class RdfMapperEncoder<T> extends Converter<T, RdfGraph> {
  @override
  RdfGraph convert(
    T input, {
    void Function(RdfMapperRegistry registry)? register,
  });
}

/// Decoder component of the RDF mapper codec system.
///
/// This abstract class defines the contract for decoders that convert
/// RDF graphs back to Dart objects of type [T].
abstract class RdfMapperDecoder<T> extends Converter<RdfGraph, T> {
  /// Converts an RDF graph to an object of type [T].
  ///
  /// The [register] parameter allows for temporarily registering additional mappers
  /// for the conversion process without modifying the decoder's global registry.
  T convert(
    RdfGraph input, {
    void Function(RdfMapperRegistry registry)? register,
  });
}

/// A codec for converting between Dart objects and RDF graphs.
///
/// This codec serves as the bridge between the object-oriented world of Dart and
/// the semantic web world of RDF. It allows bidirectional conversion between any
/// Dart object type and its RDF graph representation.
///
/// Unlike traditional string-based codecs, RdfObjectCodec works with in-memory
/// RDF graph structures rather than serialized strings. This allows for efficient
/// pipeline processing where multiple transformations can be applied without
/// repeated serialization and parsing.
///
/// To convert between RDF graphs and string representations, this codec can be
/// combined with the RdfGraphCodec implementations from rdf_core.
///
/// Example:
/// ```dart
/// // Create a codec for Person objects
/// final personCodec = RdfObjectCodec<Person>(
///   service: mapperService,  // Service with PersonMapper registered
/// );
///
/// // Convert a Person to an RDF graph
/// final person = Person(name: 'Alice', age: 30);
/// final graph = personCodec.encode(person);
///
/// // Convert back to a Person
/// final personAgain = personCodec.decode(graph);
/// ```
class RdfObjectCodec<T> extends Codec<T, RdfGraph> {
  /// The service containing serializers and deserializers for this codec
  final RdfMapperService _service;
  final void Function(RdfMapperRegistry registry)? _register;
  final CompletenessMode completeness;

  /// Creates a new object codec with the given service.
  ///
  /// The service must contain serializers and deserializers for type [T].
  RdfObjectCodec({
    required RdfMapperService service,
    void Function(RdfMapperRegistry registry)? register,
    this.completeness = CompletenessMode.strict,
  })  : _service = service,
        _register = register;

  /// Creates a new codec from an optional [RdfMapper] instance or a register function.
  ///
  /// This factory provides a convenient way to create a codec with a custom mapper
  /// configuration without having to manually create the mapper service.
  ///
  /// Either [register] or [rdfMapper] must be provided:
  /// - If only [register] is provided, a new registry will be created and the
  ///   function will be called to register the necessary mappers.
  /// - If only [rdfMapper] is provided, the codec will use its registry.
  /// - If both are provided, the [register] function will be called with
  ///   the [rdfMapper]'s registry.
  ///
  /// Example:
  /// ```dart
  /// final codec = RdfObjectCodec<Person>.forMappers(
  ///   register: (registry) {
  ///     registry.registerMapper<Person>(PersonMapper());
  ///   },
  /// );
  /// ```
  ///
  /// Throws [ArgumentError] if neither [register] nor [rdfMapper] is provided.
  factory RdfObjectCodec.forMappers({
    void Function(RdfMapperRegistry registry)? register,
    RdfMapper? rdfMapper,
    CompletenessMode completeness = CompletenessMode.strict,
    IriTermFactory iriTermFactory = IriTerm.validated,
  }) {
    if (rdfMapper == null && register == null) {
      throw ArgumentError(
        'Either a mapper or a register function must be provided.',
      );
    }

    var registry = rdfMapper == null ? RdfMapperRegistry() : rdfMapper.registry;
    if (register != null && rdfMapper != null) {
      // we need to clone the registry to avoid modifying the original
      registry = registry.clone();
    }
    if (register != null) {
      register(registry);
    }
    return RdfObjectCodec<T>(
        service: RdfMapperService(
            registry: registry, iriTermFactory: iriTermFactory),
        completeness: completeness);
  }

  @override
  RdfObjectEncoder<T> get encoder => RdfObjectEncoder<T>(_service, _register);

  /// Encodes a Dart object to an RDF graph.
  ///
  /// This is a convenience method that delegates to the encoder.
  RdfGraph encode(T input) => encoder.convert(input);

  @override
  RdfObjectDecoder<T> get decoder =>
      RdfObjectDecoder<T>(_service, _register, completeness: completeness);

  /// Decodes an RDF graph to a Dart object.
  ///
  /// This is a convenience method that delegates to the decoder.
  ///
  /// The optional [subject] parameter allows for specifying a particular subject
  /// in the graph to decode. If not provided, the decoder will attempt to find
  /// a suitable subject automatically.
  T decode(RdfGraph input, {RdfSubject? subject}) =>
      decoder.convert(input, subject: subject);
}

/// Encoder for converting Dart objects to RDF graphs.
///
/// This class implements the conversion of a single Dart object of type [T]
/// to an RDF graph using the RDF mapper service.
class RdfObjectEncoder<T> extends Converter<T, RdfGraph> {
  final RdfMapperService _service;
  final void Function(RdfMapperRegistry registry)? _register;

  /// Creates a new encoder with the given mapper service and optional register function.
  RdfObjectEncoder(this._service, this._register);

  @override

  /// Converts a Dart object to an RDF graph.
  ///
  /// Uses the mapper service to serialize the object according to its registered mappers.
  RdfGraph convert(T input) => _service.serialize(input, register: _register);
}

/// Decoder for converting RDF graphs to Dart objects.
///
/// This class implements the conversion of an RDF graph to a single Dart object
/// of type [T] using the RDF mapper service.
class RdfObjectDecoder<T> extends Converter<RdfGraph, T> {
  final RdfMapperService _service;
  final void Function(RdfMapperRegistry registry)? _register;
  final CompletenessMode completeness;

  /// Creates a new decoder with the given mapper service and optional register function.
  RdfObjectDecoder(this._service, this._register,
      {this.completeness = CompletenessMode.strict});

  @override

  /// Converts an RDF graph to a Dart object.
  ///
  /// If [subject] is provided, only that specific subject from the graph will be
  /// deserialized. Otherwise, the decoder will attempt to find a suitable subject.
  T convert(RdfGraph input, {RdfSubject? subject}) {
    if (subject != null) {
      return _service.deserializeBySubject(input, subject,
          register: _register, completeness: completeness);
    }
    return _service.deserialize(input,
        register: _register, completeness: completeness);
  }
}

/// A codec for converting between collections of Dart objects and RDF graphs.
///
/// Similar to [RdfObjectCodec], but specialized for handling collections of objects.
/// This codec handles the conversion of multiple objects of type [T] to a single
/// RDF graph and vice versa.
///
/// This is particularly useful for working with RDF datasets that contain multiple
/// related entities, such as a list of people or a collection of interlinked resources.
class RdfObjectsCodec<T> extends Codec<Iterable<T>, RdfGraph> {
  /// The service containing serializers and deserializers for this codec
  final RdfMapperService _service;
  final void Function(RdfMapperRegistry registry)? _register;
  final CompletenessMode completeness;

  /// Creates a new object codec with the given service.
  ///
  /// The service must contain serializers and deserializers for type [T].
  RdfObjectsCodec({
    required RdfMapperService service,
    void Function(RdfMapperRegistry registry)? register,
    CompletenessMode completeness = CompletenessMode.strict,
  })  : _service = service,
        _register = register,
        completeness = completeness;

  @override

  /// Returns the encoder component of this codec.
  RdfObjectsEncoder<T> get encoder => RdfObjectsEncoder(
        _service,
        _register,
      );

  /// Encodes a collection of Dart objects to an RDF graph.
  ///
  /// This convenience method delegates to the encoder, combining all objects
  /// into a single RDF graph with all their relationships preserved.
  RdfGraph encode(
    Iterable<T> input, {
    void Function(RdfMapperRegistry registry)? register,
  }) {
    return encoder.convert(input);
  }

  @override

  /// Returns the decoder component of this codec.
  RdfObjectsDecoder<T> get decoder =>
      RdfObjectsDecoder(_service, _register, completeness: completeness);

  /// Decodes an RDF graph to a collection of Dart objects.
  ///
  /// This convenience method delegates to the decoder, extracting all subjects
  /// of type [T] from the graph and converting them to Dart objects.
  Iterable<T> decode(
    RdfGraph input, {
    void Function(RdfMapperRegistry registry)? register,
  }) {
    return decoder.convert(input);
  }
}

/// Encoder for converting Dart objects to RDF graphs.
class RdfObjectsEncoder<T> extends Converter<Iterable<T>, RdfGraph> {
  final RdfMapperService _service;
  final void Function(RdfMapperRegistry registry)? _register;
  RdfObjectsEncoder(this._service, this._register);

  @override
  RdfGraph convert(Iterable<T> input) {
    return _service.serializeList(input, register: _register);
  }
}

/// Decoder for converting RDF graphs to Dart objects.
class RdfObjectsDecoder<T> extends Converter<RdfGraph, Iterable<T>> {
  final RdfMapperService _service;
  final void Function(RdfMapperRegistry registry)? _register;
  final CompletenessMode completeness;

  RdfObjectsDecoder(this._service, this._register,
      {this.completeness = CompletenessMode.strict});

  @override
  Iterable<T> convert(RdfGraph input) {
    return _service.deserializeAll<T>(input,
        register: _register, completeness: completeness);
  }
}

class RdfObjectsLosslessCodec<T>
    extends Codec<(Iterable<T>, RdfGraph), RdfGraph> {
  /// The service containing serializers and deserializers for this codec
  final RdfMapperService _service;
  final void Function(RdfMapperRegistry registry)? _register;

  /// Creates a new object codec with the given service.
  ///
  /// The service must contain serializers and deserializers for type [T].
  RdfObjectsLosslessCodec({
    required RdfMapperService service,
    void Function(RdfMapperRegistry registry)? register,
  })  : _service = service,
        _register = register;

  @override

  /// Returns the encoder component of this codec.
  RdfObjectsLosslessEncoder<T> get encoder =>
      RdfObjectsLosslessEncoder(_service, _register);

  /// Encodes a collection of Dart objects to an RDF graph.
  ///
  /// This convenience method delegates to the encoder, combining all objects
  /// into a single RDF graph with all their relationships preserved.
  RdfGraph encode(
    (Iterable<T>, RdfGraph) input, {
    void Function(RdfMapperRegistry registry)? register,
  }) {
    return encoder.convert(input);
  }

  @override

  /// Returns the decoder component of this codec.
  RdfObjectsLosslessDecoder<T> get decoder =>
      RdfObjectsLosslessDecoder(_service, _register);

  /// Decodes an RDF graph to a collection of Dart objects.
  ///
  /// This convenience method delegates to the decoder, extracting all subjects
  /// of type [T] from the graph and converting them to Dart objects.
  (Iterable<T>, RdfGraph) decode(
    RdfGraph input, {
    void Function(RdfMapperRegistry registry)? register,
  }) {
    return decoder.convert(input);
  }
}

/// Encoder for converting Dart objects to RDF graphs.
class RdfObjectsLosslessEncoder<T>
    extends Converter<(Iterable<T>, RdfGraph), RdfGraph> {
  final RdfMapperService _service;
  final void Function(RdfMapperRegistry registry)? _register;
  RdfObjectsLosslessEncoder(this._service, this._register);

  @override
  RdfGraph convert((Iterable<T>, RdfGraph) input) {
    return _service.serializeListLossless(input, register: _register);
  }
}

/// Decoder for converting RDF graphs to Dart objects.
class RdfObjectsLosslessDecoder<T>
    extends Converter<RdfGraph, (Iterable<T>, RdfGraph)> {
  final RdfMapperService _service;
  final void Function(RdfMapperRegistry registry)? _register;

  RdfObjectsLosslessDecoder(this._service, this._register);

  @override
  (Iterable<T>, RdfGraph) convert(RdfGraph input) {
    return _service.deserializeAllLossless<T>(input, register: _register);
  }
}

class RdfObjectLosslessCodec<T> extends Codec<(T, RdfGraph), RdfGraph> {
  /// The service containing serializers and deserializers for this codec
  final RdfMapperService _service;
  final void Function(RdfMapperRegistry registry)? _register;

  /// Creates a new object codec with the given service.
  ///
  /// The service must contain serializers and deserializers for type [T].
  RdfObjectLosslessCodec({
    required RdfMapperService service,
    void Function(RdfMapperRegistry registry)? register,
  })  : _service = service,
        _register = register;

  /// Creates a new codec from an optional [RdfMapper] instance or a register function.
  ///
  /// This factory provides a convenient way to create a codec with a custom mapper
  /// configuration without having to manually create the mapper service.
  ///
  /// Either [register] or [rdfMapper] must be provided:
  /// - If only [register] is provided, a new registry will be created and the
  ///   function will be called to register the necessary mappers.
  /// - If only [rdfMapper] is provided, the codec will use its registry.
  /// - If both are provided, the [register] function will be called with
  ///   the [rdfMapper]'s registry.
  ///
  /// Example:
  /// ```dart
  /// final codec = RdfObjectCodec<Person>.forMappers(
  ///   register: (registry) {
  ///     registry.registerMapper<Person>(PersonMapper());
  ///   },
  /// );
  /// ```
  ///
  /// Throws [ArgumentError] if neither [register] nor [rdfMapper] is provided.
  factory RdfObjectLosslessCodec.forMappers({
    void Function(RdfMapperRegistry registry)? register,
    RdfMapper? rdfMapper,
    IriTermFactory iriTermFactory = IriTerm.validated,
  }) {
    if (rdfMapper == null && register == null) {
      throw ArgumentError(
        'Either a mapper or a register function must be provided.',
      );
    }

    var registry = rdfMapper == null ? RdfMapperRegistry() : rdfMapper.registry;
    if (register != null && rdfMapper != null) {
      // we need to clone the registry to avoid modifying the original
      registry = registry.clone();
    }
    if (register != null) {
      register(registry);
    }
    return RdfObjectLosslessCodec<T>(
        service: RdfMapperService(
            registry: registry, iriTermFactory: iriTermFactory));
  }

  @override
  RdfObjectLosslessEncoder<T> get encoder =>
      RdfObjectLosslessEncoder<T>(_service, _register);

  /// Encodes a Dart object to an RDF graph.
  ///
  /// This is a convenience method that delegates to the encoder.
  RdfGraph encode((T, RdfGraph) input) => encoder.convert(input);

  @override
  RdfObjectLosslessDecoder<T> get decoder =>
      RdfObjectLosslessDecoder<T>(_service, _register);

  /// Decodes an RDF graph to a Dart object.
  ///
  /// This is a convenience method that delegates to the decoder.
  ///
  /// The optional [subject] parameter allows for specifying a particular subject
  /// in the graph to decode. If not provided, the decoder will attempt to find
  /// a suitable subject automatically.
  (T, RdfGraph) decode(RdfGraph input, {RdfSubject? subject}) =>
      decoder.convert(input, subject: subject);
}

/// Encoder for converting Dart objects to RDF graphs.
///
/// This class implements the conversion of a single Dart object of type [T]
/// to an RDF graph using the RDF mapper service.
class RdfObjectLosslessEncoder<T> extends Converter<(T, RdfGraph), RdfGraph> {
  final RdfMapperService _service;
  final void Function(RdfMapperRegistry registry)? _register;

  /// Creates a new encoder with the given mapper service and optional register function.
  RdfObjectLosslessEncoder(this._service, this._register);

  @override

  /// Converts a Dart object to an RDF graph.
  ///
  /// Uses the mapper service to serialize the object according to its registered mappers.
  RdfGraph convert((T, RdfGraph) input) =>
      _service.serializeLossless(input, register: _register);
}

/// Decoder for converting RDF graphs to Dart objects.
///
/// This class implements the conversion of an RDF graph to a single Dart object
/// of type [T] using the RDF mapper service.
class RdfObjectLosslessDecoder<T> extends Converter<RdfGraph, (T, RdfGraph)> {
  final RdfMapperService _service;
  final void Function(RdfMapperRegistry registry)? _register;

  /// Creates a new decoder with the given mapper service and optional register function.
  RdfObjectLosslessDecoder(this._service, this._register);

  @override

  /// Converts an RDF graph to a Dart object.
  ///
  /// If [subject] is provided, only that specific subject from the graph will be
  /// deserialized. Otherwise, the decoder will attempt to find a suitable subject.
  (T, RdfGraph) convert(RdfGraph input, {RdfSubject? subject}) {
    if (subject != null) {
      return _service.deserializeBySubjectLossless(input, subject,
          register: _register);
    }
    return _service.deserializeLossless(input, register: _register);
  }
}
