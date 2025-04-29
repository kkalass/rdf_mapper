import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/src/exceptions/serialization_exception.dart';
import 'package:rdf_mapper/src/serializers/iri_term_serializer.dart';
import 'package:rdf_mapper/src/api/serialization_context.dart';

class IriIdSerializer implements IriTermSerializer<String> {
  final IriTerm Function(String, SerializationContext context) _expand;

  IriIdSerializer({
    required IriTerm Function(String, SerializationContext context) expand,
  }) : _expand = expand;

  @override
  toRdfTerm(String id, SerializationContext context) {
    assert(!id.contains("/"));
    if (id.contains("/")) {
      throw SerializationException('Expected an Id, not a full IRI: $id ');
    }
    return _expand(id, context);
  }
}
