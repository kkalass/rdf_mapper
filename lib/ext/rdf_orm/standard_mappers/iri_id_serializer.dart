import 'package:rdf_core/graph/rdf_term.dart';
import 'package:solid_task/ext/rdf_orm/exceptions/serialization_exception.dart';
import 'package:solid_task/ext/rdf_orm/rdf_iri_term_serializer.dart';
import 'package:solid_task/ext/rdf_orm/serialization_context.dart';

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
