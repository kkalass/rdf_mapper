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
class RdfGraphUnmappedTriplesMapper implements UnmappedTriplesMapper<RdfGraph> {
  @override
  final bool deep;

  const RdfGraphUnmappedTriplesMapper({this.deep = true});

  @override
  RdfGraph fromUnmappedTriples(Iterable<Triple> triples) {
    return RdfGraph.fromTriples(triples);
  }

  @override
  Iterable<Triple> toUnmappedTriples(RdfSubject subject, RdfGraph value) {
    return value.triples;
  }
}

class RDFGraphResourceMapper implements UnifiedResourceMapper<RdfGraph> {
  final bool deep;
  const RDFGraphResourceMapper({this.deep = true});

  RdfGraph fromRdfResource(RdfSubject subject, DeserializationContext context) {
    final triples =
        context.getTriplesForSubject(subject, includeBlankNodes: deep);
    final rootSubject = _getSingleRootSubject(triples);
    if (rootSubject != subject) {
      throw ArgumentError(
          "Root subject of the graph does not match the provided subject: $subject != $rootSubject");
    }
    // If the subject is not the root, we cannot deserialize it as an RdfGraph
    // because it would not have a single root subject.
    // This is a design choice to ensure that RdfGraph always has a clear root.
    // If you need to deserialize a graph with multiple root subjects, consider
    // using a different approach or structure.
    return RdfGraph.fromTriples(triples);
  }

  (RdfSubject, Iterable<Triple>) toRdfResource(
      RdfGraph value, SerializationContext context,
      {RdfSubject? parentSubject}) {
    final triples = value.triples;
    final subject = _getSingleRootSubject(triples);
    return (subject, triples);
  }

  IriTerm? get typeIri => null;

  /// Determines the single root subject from a collection of triples.
  ///
  /// This method implements a heuristic approach to identify the most appropriate
  /// root subject in RDF graphs that should have a single entry point.
  ///
  /// Algorithm:
  /// 1. If only one subject exists, return it immediately
  /// 2. Find all subjects that don't appear as objects (toplevel candidates)
  /// 3. If exactly one toplevel candidate exists, return it
  /// 4. If no toplevel candidates exist (all subjects are cyclic), apply heuristics:
  ///    - Prefer IRI terms over blank nodes
  ///    - If multiple IRIs exist, fail (ambiguous)
  ///    - If only blank nodes exist, fail (no clear root)
  /// 5. If multiple toplevel candidates exist, fail (multiple roots)
  ///
  /// Limitations:
  /// - Does not perform deep cycle analysis
  /// - Conservative approach may reject valid graphs with resolvable cycles
  /// - No semantic analysis of predicates to determine hierarchy
  ///
  /// Throws [ArgumentError] if:
  /// - Triple collection is empty
  /// - Multiple toplevel subjects exist (ambiguous root)
  /// - Cyclic graph with no clear root can be determined
  RdfSubject _getSingleRootSubject(Iterable<Triple> triples) {
    if (triples.isEmpty) {
      throw ArgumentError("Cannot get root subject from empty triples list");
    }

    final subjects = triples.map((t) => t.subject).toSet();

    // Simple case: single subject
    if (subjects.length == 1) {
      return subjects.first;
    }

    // Find subjects that are not objects (potential roots)
    final objects = triples.map((t) => t.object).toSet();
    final toplevelCandidates = {...subjects}..removeAll(objects);

    // Ideal case: exactly one toplevel subject
    if (toplevelCandidates.length == 1) {
      return toplevelCandidates.first;
    }

    // Handle cyclic graphs with heuristics
    if (toplevelCandidates.isEmpty) {
      // All subjects appear as objects - apply heuristics
      final iriSubjects = subjects.whereType<IriTerm>().toList();

      if (iriSubjects.length == 1) {
        // Single IRI in a cyclic graph - use as root
        return iriSubjects.first;
      }

      if (iriSubjects.length > 1) {
        // Multiple IRIs in cyclic graph - ambiguous
        throw ArgumentError(
            "Multiple IRI subjects found in cyclic graph - cannot determine root: $iriSubjects");
      }

      // Only blank nodes in cyclic graph - no clear root
      throw ArgumentError(
          "No toplevel subject found in triples - the graph cannot be deserialized because it contains only cyclic blank nodes");
    }

    // Multiple toplevel subjects - ambiguous root
    throw ArgumentError(
        "Multiple toplevel subjects found in triples - the graph cannot be deserialized because it is malformed: $toplevelCandidates");
  }

  @override
  String toString() => 'RDFGraphResourceMapper';
}
