import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';

/// Simple test context implementation
class MockDeserializationContext extends DeserializationContext {
  @override
  ResourceReader reader(RdfSubject subject) {
    throw UnimplementedError('Not needed for delegating mapper tests');
  }

  @override
  T fromLiteralTerm<T>(
    LiteralTerm term, {
    LiteralTermDeserializer<T>? deserializer,
    bool bypassDatatypeCheck = false,
  }) {
    throw UnimplementedError('Not needed for delegating mapper tests');
  }

  @override
  T deserialize<T>(RdfTerm term, {BaseDeserializer<T>? deserializer}) {
    throw UnimplementedError();
  }

  @override
  void trackTriplesRead(RdfSubject subject, Iterable<Triple> triples) {}

  @override
  Iterable<Triple> getTriplesForSubject(RdfSubject subject,
      {bool includeBlankNodes = true, bool trackRead = true}) {
    throw UnimplementedError();
  }
}
