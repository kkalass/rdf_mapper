import 'dart:convert';

import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';

class RdfObjectsStringCodec<T> extends Codec<Iterable<T>, String> {
  final RdfObjectsCodec<T> _objectsCodec;

  final RdfGraphCodec _graphCodec;

  RdfObjectsStringCodec({
    required RdfObjectsCodec<T> objectsCodec,
    required RdfGraphCodec graphCodec,
  })  : _objectsCodec = objectsCodec,
        _graphCodec = graphCodec;

  @override
  RdfObjectsStringEncoder<T> get encoder =>
      RdfObjectsStringEncoder<T>(_objectsCodec.encoder, _graphCodec.encoder);

  String encode(Iterable<T> input, {String? baseUri}) {
    return encoder.convert(input, baseUri: baseUri);
  }

  @override
  RdfObjectsStringDecoder<T> get decoder =>
      RdfObjectsStringDecoder<T>(_graphCodec.decoder, _objectsCodec.decoder);

  Iterable<T> decode(String input, {String? documentUrl}) {
    return decoder.convert(input, documentUrl: documentUrl);
  }
}

class RdfObjectsLosslessStringEncoder<T>
    extends Converter<(Iterable<T>, RdfGraph), String> {
  final RdfObjectsLosslessEncoder<T> _objectsEncoder;
  final RdfGraphEncoder _graphEncoder;

  RdfObjectsLosslessStringEncoder(this._objectsEncoder, this._graphEncoder);

  @override
  String convert((Iterable<T>, RdfGraph) input, {String? baseUri}) {
    // Step 1: Convert object to graph
    final graph = _objectsEncoder.convert(input);

    // Step 2: Convert graph to string
    return _graphEncoder.convert(graph, baseUri: baseUri);
  }
}

/// Decoder for converting RDF strings to objects.
class RdfObjectsLosslessStringDecoder<T>
    extends Converter<String, (Iterable<T>, RdfGraph)> {
  final RdfGraphDecoder _rdfGraphDecoder;
  final RdfObjectsLosslessDecoder<T> _objectsDecoder;

  RdfObjectsLosslessStringDecoder(this._rdfGraphDecoder, this._objectsDecoder);

  @override
  (Iterable<T>, RdfGraph) convert(String input, {String? documentUrl}) {
    // Step 1: Convert string to graph
    final graph = _rdfGraphDecoder.convert(input, documentUrl: documentUrl);

    // Step 2: Convert graph to object
    return _objectsDecoder.convert(graph);
  }
}

class RdfObjectsLosslessStringCodec<T>
    extends Codec<(Iterable<T>, RdfGraph), String> {
  final RdfObjectsLosslessCodec<T> _objectsCodec;

  final RdfGraphCodec _graphCodec;

  RdfObjectsLosslessStringCodec({
    required RdfObjectsLosslessCodec<T> objectsCodec,
    required RdfGraphCodec graphCodec,
  })  : _objectsCodec = objectsCodec,
        _graphCodec = graphCodec;

  @override
  RdfObjectsLosslessStringEncoder<T> get encoder =>
      RdfObjectsLosslessStringEncoder<T>(
          _objectsCodec.encoder, _graphCodec.encoder);

  String encode((Iterable<T>, RdfGraph) input, {String? baseUri}) {
    return encoder.convert(input, baseUri: baseUri);
  }

  @override
  RdfObjectsLosslessStringDecoder<T> get decoder =>
      RdfObjectsLosslessStringDecoder<T>(
          _graphCodec.decoder, _objectsCodec.decoder);

  (Iterable<T>, RdfGraph) decode(String input, {String? documentUrl}) {
    return decoder.convert(input, documentUrl: documentUrl);
  }
}

/// Encoder for converting objects to RDF strings.
class RdfObjectsStringEncoder<T> extends Converter<Iterable<T>, String> {
  final RdfObjectsEncoder<T> _objectsEncoder;
  final RdfGraphEncoder _graphEncoder;

  RdfObjectsStringEncoder(this._objectsEncoder, this._graphEncoder);

  @override
  String convert(Iterable<T> input, {String? baseUri}) {
    // Step 1: Convert object to graph
    final graph = _objectsEncoder.convert(input);

    // Step 2: Convert graph to string
    return _graphEncoder.convert(graph, baseUri: baseUri);
  }
}

/// Decoder for converting RDF strings to objects.
class RdfObjectsStringDecoder<T> extends Converter<String, Iterable<T>> {
  final RdfGraphDecoder _rdfGraphDecoder;
  final RdfObjectsDecoder<T> _objectsDecoder;

  RdfObjectsStringDecoder(this._rdfGraphDecoder, this._objectsDecoder);

  @override
  Iterable<T> convert(String input, {String? documentUrl}) {
    // Step 1: Convert string to graph
    final graph = _rdfGraphDecoder.convert(input, documentUrl: documentUrl);

    // Step 2: Convert graph to object
    return _objectsDecoder.convert(graph);
  }
}

class RdfObjectStringCodec<T> extends Codec<T, String> {
  final RdfObjectCodec<T> _objectCodec;

  final RdfGraphCodec _graphCodec;

  RdfObjectStringCodec({
    required RdfObjectCodec<T> objectCodec,
    required RdfGraphCodec graphCodec,
  })  : _objectCodec = objectCodec,
        _graphCodec = graphCodec;

  factory RdfObjectStringCodec.forMappers({
    String? contentType,
    RdfCore? core,
    void Function(RdfMapperRegistry registry)? register,
    RdfMapper? rdfMapper,
    CompletenessMode completeness = CompletenessMode.strict,
    IriTermFactory iriTermFactory = IriTerm.validated,
  }) {
    var objectCodec = RdfObjectCodec<T>.forMappers(
        register: register,
        rdfMapper: rdfMapper,
        completeness: completeness,
        iriTermFactory: iriTermFactory);
    var graphCodec = (core ?? rdf).codec(contentType: contentType);

    return RdfObjectStringCodec<T>(
      objectCodec: objectCodec,
      graphCodec: graphCodec,
    );
  }

  @override
  RdfObjectStringEncoder<T> get encoder =>
      RdfObjectStringEncoder<T>(_objectCodec.encoder, _graphCodec.encoder);

  String encode(T input, {String? baseUri}) {
    return encoder.convert(input, baseUri: baseUri);
  }

  @override
  RdfObjectStringDecoder<T> get decoder =>
      RdfObjectStringDecoder<T>(_graphCodec.decoder, _objectCodec.decoder);

  T decode(String input, {RdfSubject? subject, String? documentUrl}) {
    return decoder.convert(input, documentUrl: documentUrl, subject: subject);
  }
}

class RdfObjectStringDecoder<T> extends Converter<String, T> {
  final RdfGraphDecoder _rdfGraphDecoder;
  final RdfObjectDecoder<T> _objectDecoder;

  RdfObjectStringDecoder(this._rdfGraphDecoder, this._objectDecoder);

  @override
  T convert(String input, {RdfSubject? subject, String? documentUrl}) {
    // Step 1: Convert string to graph
    final graph = _rdfGraphDecoder.convert(input, documentUrl: documentUrl);

    // Step 2: Convert graph to object
    return _objectDecoder.convert(graph, subject: subject);
  }
}

class RdfObjectStringEncoder<T> extends Converter<T, String> {
  final RdfGraphEncoder _rdfGraphEncoder;
  final RdfObjectEncoder<T> _objectEncoder;

  RdfObjectStringEncoder(this._objectEncoder, this._rdfGraphEncoder);

  @override
  String convert(T input, {String? baseUri}) {
    // Step 1: Convert object to graph
    final graph = _objectEncoder.convert(input);

    // Step 2: Convert graph to string
    return _rdfGraphEncoder.convert(graph, baseUri: baseUri);
  }
}

class RdfObjectLosslessStringCodec<T> extends Codec<(T, RdfGraph), String> {
  final RdfObjectLosslessCodec<T> _objectCodec;

  final RdfGraphCodec _graphCodec;

  RdfObjectLosslessStringCodec({
    required RdfObjectLosslessCodec<T> objectCodec,
    required RdfGraphCodec graphCodec,
  })  : _objectCodec = objectCodec,
        _graphCodec = graphCodec;

  factory RdfObjectLosslessStringCodec.forMappers({
    String? contentType,
    RdfCore? core,
    void Function(RdfMapperRegistry registry)? register,
    RdfMapper? rdfMapper,
  }) {
    var objectCodec = RdfObjectLosslessCodec<T>.forMappers(
      register: register,
      rdfMapper: rdfMapper,
    );
    var graphCodec = (core ?? rdf).codec(contentType: contentType);

    return RdfObjectLosslessStringCodec<T>(
      objectCodec: objectCodec,
      graphCodec: graphCodec,
    );
  }

  @override
  RdfObjectLosslessStringEncoder<T> get encoder =>
      RdfObjectLosslessStringEncoder<T>(
          _objectCodec.encoder, _graphCodec.encoder);

  String encode((T, RdfGraph) input, {String? baseUri}) {
    return encoder.convert(input, baseUri: baseUri);
  }

  @override
  RdfObjectLosslessStringDecoder<T> get decoder =>
      RdfObjectLosslessStringDecoder<T>(
          _graphCodec.decoder, _objectCodec.decoder);

  (T, RdfGraph) decode(String input,
      {RdfSubject? subject, String? documentUrl}) {
    return decoder.convert(input, documentUrl: documentUrl, subject: subject);
  }
}

class RdfObjectLosslessStringDecoder<T>
    extends Converter<String, (T, RdfGraph)> {
  final RdfGraphDecoder _rdfGraphDecoder;
  final RdfObjectLosslessDecoder<T> _objectDecoder;

  RdfObjectLosslessStringDecoder(this._rdfGraphDecoder, this._objectDecoder);

  @override
  (T, RdfGraph) convert(String input,
      {RdfSubject? subject, String? documentUrl}) {
    // Step 1: Convert string to graph
    final graph = _rdfGraphDecoder.convert(input, documentUrl: documentUrl);

    // Step 2: Convert graph to object
    return _objectDecoder.convert(graph, subject: subject);
  }
}

class RdfObjectLosslessStringEncoder<T>
    extends Converter<(T, RdfGraph), String> {
  final RdfGraphEncoder _rdfGraphEncoder;
  final RdfObjectLosslessEncoder<T> _objectEncoder;

  RdfObjectLosslessStringEncoder(this._objectEncoder, this._rdfGraphEncoder);

  @override
  String convert((T, RdfGraph) input, {String? baseUri}) {
    // Step 1: Convert object to graph
    final graph = _objectEncoder.convert(input);

    // Step 2: Convert graph to string
    return _rdfGraphEncoder.convert(graph, baseUri: baseUri);
  }
}
