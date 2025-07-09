import 'package:rdf_core/src/graph/rdf_term.dart';
import 'package:rdf_core/src/graph/triple.dart';
import 'package:rdf_mapper/rdf_mapper.dart';

RdfSubject _getSingleRootSubject(List<Triple> triples) {
  if (triples.isEmpty) {
    throw ArgumentError("Cannot get root subject from empty triples list");
  }
  final subjects = triples.map((t) => t.subject).toSet();
  if (subjects.length == 1) {
    return subjects.first;
  }
  final objects = triples.map((t) => t.object).toSet();
  final toplevelCandidates = {...subjects}..removeAll(objects);
  if (toplevelCandidates.isEmpty) {
    // FIXME: is this really always an error? For example, if we know that the
    // subject must be an iri term and there are blank nodes that are referenced by the iri term, but also reference the iri term themselves.
    throw ArgumentError(
        "No toplevel subject found in triples - the graph cannot be deserialized because it is cyclic or malformed");
  }
  if (toplevelCandidates.length == 1) {
    return toplevelCandidates.first;
  }
  // FIXME: we could go further and check children of children
  throw ArgumentError(
      "Multiple toplevel subjects found in triples - the graph cannot be deserialized because it is malformed: $toplevelCandidates");
}

class GlobalResourceUnmappedTriplesDeserializer<T>
    implements GlobalResourceDeserializer<T> {
  final UnmappedTriplesDeserializer<T> _mapper;
  final bool includeBlankNodes;
  GlobalResourceUnmappedTriplesDeserializer(this._mapper,
      {this.includeBlankNodes = true});

  @override
  T fromRdfResource(IriTerm term, DeserializationContext context) {
    final triples = context.getTriplesForSubject(term,
        includeBlankNodes: includeBlankNodes);
    return _mapper.fromUnmappedTriples(triples);
  }

  @override
  // This is a very generic mapper, so we don't have a specific type IRI.
  IriTerm? get typeIri => null;

  @override
  String toString() {
    return 'GlobalResourceUnmappedTriplesWrapper($_mapper, includeBlankNodes: $includeBlankNodes)';
  }
}

class ResourceUnmappedTriplesSerializer<T>
    implements GenericResourceSerializer<T> {
  final UnmappedTriplesSerializer<T> _mapper;
  ResourceUnmappedTriplesSerializer(this._mapper);
  @override
  (RdfSubject, List<Triple>) toRdfResource(
      T value, SerializationContext context,
      {RdfSubject? parentSubject}) {
    final triples = _mapper.toUnmappedTriples(value);
    final subject = _getSingleRootSubject(triples);
    return (
      subject,
      triples,
    );
  }

  @override
  // This is a very generic mapper, so we don't have a specific type IRI.
  IriTerm? get typeIri => null;

  @override
  String toString() {
    return 'GlobalResourceUnmappedTriplesWrapper($_mapper)';
  }
}

class LocalResourceUnmappedTriplesSerializer<T>
    implements LocalResourceSerializer<T> {
  final UnmappedTriplesSerializer<T> _mapper;
  LocalResourceUnmappedTriplesSerializer(this._mapper);
  @override
  (BlankNodeTerm, List<Triple>) toRdfResource(
      T value, SerializationContext context,
      {RdfSubject? parentSubject}) {
    final triples = _mapper.toUnmappedTriples(value);
    final subject = _getSingleRootSubject(triples);
    return (
      subject as BlankNodeTerm,
      triples,
    );
  }

  @override
  // This is a very generic mapper, so we don't have a specific type IRI.
  IriTerm? get typeIri => null;

  @override
  String toString() {
    return 'GlobalResourceUnmappedTriplesWrapper($_mapper)';
  }
}

class LocalResourceUnmappedTriplesDeserializer<T>
    implements LocalResourceDeserializer<T> {
  final UnmappedTriplesDeserializer<T> _mapper;
  final bool includeBlankNodes;
  LocalResourceUnmappedTriplesDeserializer(this._mapper,
      {this.includeBlankNodes = true});

  @override
  T fromRdfResource(BlankNodeTerm term, DeserializationContext context) {
    final triples = context.getTriplesForSubject(term,
        includeBlankNodes: includeBlankNodes);
    return _mapper.fromUnmappedTriples(triples);
  }

  @override
  // This is a very generic mapper, so we don't have a specific type IRI.
  IriTerm? get typeIri => null;

  @override
  String toString() {
    return 'LocalResourceUnmappedTriplesWrapper($_mapper, includeBlankNodes: $includeBlankNodes)';
  }
}
