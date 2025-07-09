import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';

class RdfGraphMapper implements UnmappedTriplesMapper<RdfGraph> {
  const RdfGraphMapper();

  @override
  RdfGraph fromUnmappedTriples(Iterable<Triple> triples) {
    return RdfGraph(
        triples: triples is List<Triple> ? triples : triples.toList());
  }

  @override
  Iterable<Triple> toUnmappedTriples(RdfGraph value) {
    return value.triples;
  }
}
