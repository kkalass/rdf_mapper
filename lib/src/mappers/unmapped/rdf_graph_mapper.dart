import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';

/// Default implementation of [UnmappedTriplesMapper] for [RdfGraph].
///
/// This mapper provides the standard way to handle unmapped RDF triples in lossless
/// mapping scenarios. It converts between raw triple collections and [RdfGraph] instances,
/// which are the recommended container type for unmapped data.
///
/// This mapper is automatically registered by default in [RdfMapper], making [RdfGraph]
/// the primary choice for capturing unmapped triples in your domain objects.
///
/// Usage in domain objects:
/// ```dart
/// class Person {
///   final String id;
///   final String name;
///   final RdfGraph unmappedGraph; // Uses this mapper automatically
///
///   Person({required this.id, required this.name, RdfGraph? unmappedGraph})
///     : unmappedGraph = unmappedGraph ?? RdfGraph({});
/// }
/// ```
class RdfGraphMapper implements UnmappedTriplesMapper<RdfGraph> {
  @override
  final bool deep;

  const RdfGraphMapper({this.deep = true});

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
