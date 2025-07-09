/// Example for using "catch all" mappers, that contain either
/// all triples of a child subject or all non-mapped triples of the parent
///
library;

import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';

class Parent {
  late final RdfGraph child;

  late final RdfGraph remainingTriples;
}

// Example mapper
class Vocab {
  static const namespace = "https://example.org/vocab/";
  static const Parent = IriTerm.prevalidated("${namespace}Parent");
  static const child = IriTerm.prevalidated("${namespace}child");
  // not to be referenced in our mappers, those are used by
  // the iri terms in the general catch-all RdfGraph instances
  static const Child = IriTerm.prevalidated("${namespace}Child");
  static const name = IriTerm.prevalidated("${namespace}name");
  static const age = IriTerm.prevalidated("${namespace}age");
  static const foo = IriTerm.prevalidated("${namespace}foo");
  static const bar = IriTerm.prevalidated("${namespace}barChild");
}

class ParentMapper implements LocalResourceMapper<Parent> {
  @override
  fromRdfResource(BlankNodeTerm term, DeserializationContext context) {
    var reader = context.reader(term);
    return Parent()
      ..child = reader.require(Vocab.child)
      ..remainingTriples = reader.getUnmapped();
  }

  @override
  (BlankNodeTerm, List<Triple>) toRdfResource(
          value, SerializationContext context, {RdfSubject? parentSubject}) =>
      context
          .resourceBuilder(BlankNodeTerm())
          .addValue(Vocab.child, value.child)
          .addUnmapped(value.remainingTriples)
          .build();

  @override
  IriTerm? get typeIri => Vocab.Parent;
}

void main() {
  final turtle = '''
@prefix ex: <https://example.com/data/>
@prefix vocab: <https://example.com/vocab/>

ex:p1 a vocab:Parent.
ex:p1 vocab:foo 'some value'
ex:p1 vocab:child ex:c1
ex:c1 vocab:name "some child"
ex:c1 vocab:age 42
ex:c1 vocab:child _:b1
_:b1 voxab:name "fas"
ex:p1 vocab:barChild _:b2
_:b2 vocab:name "bar"
_:b2 vocab:age 43


exp:p2 vocab:name "you don't know"
exp:p2 vocab:age 23
''';
  final rdf = RdfMapper.withMappers((r) => r..registerMapper(ParentMapper()));

  final result = rdf.decodeObjects(turtle);
  final reencoded = rdf.encodeObject(result);
  if (turtle != reencoded) {
    throw Exception(
        "the reencoded result should be exactly like the original one");
  }
  // The result should actually not only contain the Parent p1, but also a
  // RdfGraph for p2 (which is not a parent) with two triples.
  // and the p1 instance has a child c1 which is a RdfGraph with four
  // triples (including _:b1).
  // And the remainingTriples graph of p1 has the triple for vocab:foo,
  // and also a blank node including its triples
}
