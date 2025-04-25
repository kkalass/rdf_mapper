import 'package:rdf_core/graph/rdf_term.dart';
import 'package:rdf_mapper/exceptions/serialization_exception.dart';
import 'package:rdf_mapper/rdf_iri_term_serializer.dart';
import 'package:rdf_mapper/serialization_context.dart';

class IriIdSerializer implements RdfIriTermSerializer<String> {
  final IriTerm Function(String, SerializationContext context) _expand;

  IriIdSerializer({
    required IriTerm Function(String, SerializationContext context) expand,
  }) : _expand = expand;

  @override
  toIriTerm(String id, SerializationContext context) {
    assert(!id.contains("/"));
    if (id.contains("/")) {
      throw SerializationException('Expected an Id, not a full IRI: $id ');
    }
    return _expand(id, context);
  }
}
