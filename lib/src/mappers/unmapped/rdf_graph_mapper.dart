import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';

class RdfGraphMapper implements UnmappedTriplesMapper<RdfGraph> {
  const RdfGraphMapper();

  @override
  RdfGraph fromUnmappedTriples(List<Triple> triples) {
    return RdfGraph(triples: triples);
  }

  @override
  List<Triple> toUnmappedTriples(RdfGraph value) {
    return value.triples;
  }
}
