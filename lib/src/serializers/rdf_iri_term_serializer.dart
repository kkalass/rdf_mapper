import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/api/serialization_context.dart';

abstract interface class RdfIriTermSerializer<T> {
  IriTerm toIriTerm(T value, SerializationContext context);
}
