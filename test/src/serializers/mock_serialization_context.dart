import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/resource_builder.dart';
import 'package:rdf_mapper/src/api/serialization_context.dart';
import 'package:rdf_mapper/src/api/serializer.dart';

// Mock implementation of SerializationContext for testing
class MockSerializationContext extends SerializationContext {
  @override
  ResourceBuilder<S> resourceBuilder<S extends RdfSubject>(S subject) {
    throw UnimplementedError();
  }

  @override
  List<Triple> resource<T>(T instance, {ResourceSerializer<T>? serializer}) {
    throw UnimplementedError();
  }

  @override
  LiteralTerm toLiteralTerm<T>(
    T value, {
    LiteralTermSerializer<T>? serializer,
  }) {
    throw UnimplementedError();
  }

  @override
  (RdfSubject, Iterable<Triple>) buildRdfList<V>(Iterable<V> values,
      {RdfSubject? headNode, Serializer<V>? serializer}) {
    throw UnimplementedError();
  }

  @override
  (RdfTerm, Iterable<Triple>) serialize<T>(T value,
      {Serializer<T>? serializer, RdfSubject? parentSubject}) {
    throw UnimplementedError();
  }
}
