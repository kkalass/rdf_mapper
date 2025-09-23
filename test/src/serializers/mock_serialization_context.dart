import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/resource_builder.dart';
import 'package:rdf_mapper/src/api/serialization_context.dart';
import 'package:rdf_mapper/src/api/rdf_mapper_interfaces.dart';

// Mock implementation of SerializationContext for testing
class MockSerializationContext extends SerializationContext {
  @override
  IriTerm createIriTerm(String value) => IriTerm.validated(value);

  @override
  ResourceBuilder<S> resourceBuilder<S extends RdfSubject>(S subject) {
    throw UnimplementedError();
  }

  @override
  Iterable<Triple> resource<T>(T instance,
      {ResourceSerializer<T>? serializer}) {
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
  (Iterable<RdfTerm>, Iterable<Triple>) serialize<T>(T value,
      {Serializer<T>? serializer, RdfSubject? parentSubject}) {
    throw UnimplementedError();
  }
}
