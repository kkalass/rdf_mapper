import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';

class PredicatesMapMapper
    implements UnmappedTriplesMapper<Map<RdfPredicate, List<RdfObject>>> {
  /**
   * We do not support deep mapping for predicates map.
   */
  @override
  bool get deep => false;

  const PredicatesMapMapper();

  @override
  Map<RdfPredicate, List<RdfObject>> fromUnmappedTriples(
      Iterable<Triple> triples) {
    final result = <RdfPredicate, List<RdfObject>>{};
    for (final triple in triples) {
      final predicate = triple.predicate;
      final object = triple.object;
      result.putIfAbsent(predicate, () => []).add(object);
    }
    return result;
  }

  @override
  Iterable<Triple> toUnmappedTriples(
      RdfSubject subject, Map<RdfPredicate, List<RdfObject>> value) {
    return value.entries
        .expand((e) => e.value.map((o) => Triple(subject, e.key, o)));
  }
}

class IriTermMapMapper
    implements UnmappedTriplesMapper<Map<IriTerm, List<RdfObject>>> {
  /**
   * We do not support deep mapping for predicates map.
   */
  @override
  bool get deep => false;

  const IriTermMapMapper();

  @override
  Map<IriTerm, List<RdfObject>> fromUnmappedTriples(Iterable<Triple> triples) {
    final result = <IriTerm, List<RdfObject>>{};
    for (final triple in triples) {
      final predicate = triple.predicate;
      final object = triple.object;
      if (predicate is! IriTerm) {
        throw ArgumentError(
            'Expected predicate to be of type IriTerm, but got $predicate');
      }
      result.putIfAbsent(predicate, () => []).add(object);
    }
    return result;
  }

  @override
  Iterable<Triple> toUnmappedTriples(
      RdfSubject subject, Map<RdfPredicate, List<RdfObject>> value) {
    return value.entries
        .expand((e) => e.value.map((o) => Triple(subject, e.key, o)));
  }
}
