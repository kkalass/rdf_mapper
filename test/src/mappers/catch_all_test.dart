import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:test/test.dart';

class Parent {
  late final String iri;
  late final RdfGraph? child;

  late final RdfGraph remainingTriples;
}

// Example mapper
class Vocab {
  static const namespace = "https://example.com/vocab/";
  static const Parent = const IriTerm("${namespace}Parent");
  static const child = const IriTerm("${namespace}child");
  // not to be referenced in our mappers, those are used by
  // the iri terms in the general catch-all RdfGraph instances
  static const Child = const IriTerm("${namespace}Child");
  static const name = const IriTerm("${namespace}name");
  static const age = const IriTerm("${namespace}age");
  static const foo = const IriTerm("${namespace}foo");
  static const barChild = const IriTerm("${namespace}barChild");
}

class ParentMapper implements GlobalResourceMapper<Parent> {
  @override
  fromRdfResource(IriTerm term, DeserializationContext context) {
    var reader = context.reader(term);
    return Parent()
      ..iri = term.value
      ..child = reader.optional<RdfGraph>(Vocab.child)
      ..remainingTriples = reader.getUnmapped();
  }

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(value, SerializationContext context,
      {RdfSubject? parentSubject}) {
    return context
        .resourceBuilder(context.createIriTerm(value.iri))
        .when(value.child != null, (b) => b.addValue(Vocab.child, value.child!))
        .addUnmapped(value.remainingTriples)
        .build();
  }

  @override
  IriTerm? get typeIri => Vocab.Parent;
}

void main() {
  group("Catch All", () {
    test("Simple p1", () {
      final turtleDoc = '''
@prefix data: <https://example.com/data/> .
@prefix ex: <https://example.com/vocab/> .

data:p1 a ex:Parent .
''';
      final rdf =
          RdfMapper.withMappers((r) => r..registerMapper(ParentMapper()));
      final result = rdf.decodeObjects(turtleDoc);
      final reencoded = rdf.encodeObjects(result);
      expect(reencoded.trim(), equals(turtleDoc.trim()));
      expect(result, hasLength(1));

      final p1 = result.whereType<Parent>().single;
      final c1 = p1.child;
      expect(p1, isNotNull);
      expect(c1, isNull);

      final p1Remaining = p1.remainingTriples;
      expect(p1Remaining.size, 0);
    });
    test("Complex Usecase without remaining", () {
      final turtleDoc = '''
@prefix data: <https://example.com/data/> .
@prefix ex: <https://example.com/vocab/> .

data:c1 ex:age 42;
    ex:child [ ex:name "fas" ];
    ex:name "some child" .

data:p1 a ex:Parent;
    ex:barChild [ ex:name "bar" ; ex:age 43 ];
    ex:child data:c1;
    ex:foo "some value" .

''';
      final rdf =
          RdfMapper.withMappers((r) => r..registerMapper(ParentMapper()));
      final result = rdf.decodeObjects(turtleDoc);
      final reencoded = rdf.encodeObjects(result);
      expect(reencoded.trim(), equals(turtleDoc.trim()));
      // The result should actually not only contain the Parent p1, but also a
      // RdfGraph for p2 (which is not a parent) with two triples.
      // and the p1 instance has a child c1 which is a RdfGraph with four
      // triples (including _:b1).
      // And the remainingTriples graph of p1 has the triple for vocab:foo,
      // and also a blank node including its triples
      expect(result, hasLength(1));
      final p1Subject = const IriTerm("https://example.com/data/p1");
      final c1Subject = const IriTerm("https://example.com/data/c1");

      final p1 = result.whereType<Parent>().single;
      final c1 = p1.child;
      expect(p1, isNotNull);
      expect(c1, isNotNull);
      expect(c1!.size, 4);
      expect(getObject(c1, c1Subject, Vocab.name),
          LiteralTerm.string("some child"));
      expect(getObject(c1, c1Subject, Vocab.age), LiteralTerm.integer(42));
      final childChildTerm =
          getObject(c1, c1Subject, Vocab.child) as RdfSubject;
      expect(
          getObject(c1, childChildTerm, Vocab.name), LiteralTerm.string("fas"));

      final p1Remaining = p1.remainingTriples;
      expect(p1Remaining.size, 4);
      expect(getObject(p1Remaining, p1Subject, Vocab.foo),
          LiteralTerm.string("some value"));
      final p1BarChild =
          getObject(p1Remaining, p1Subject, Vocab.barChild) as RdfSubject;
      expect(getObject(p1Remaining, p1BarChild, Vocab.name),
          LiteralTerm.string("bar"));
      expect(getObject(p1Remaining, p1BarChild, Vocab.age),
          LiteralTerm.integer(43));
    });

    test("Complex Usecase with remaining triples (fails by default)", () {
      final turtleDoc = '''
@prefix data: <https://example.com/data/> .
@prefix ex: <https://example.com/vocab/> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .

data:c1 ex:age 42;
    ex:child [ ex:name "fas" ];
    ex:name "some child" .

data:p1 a ex:Parent;
    ex:barChild [ ex:name "bar" ; ex:age 43 ];
    ex:child data:c1;
    ex:foo "some value" .

data:p2 ex:age 23;
    ex:name "you don't know" .
''';
      final rdf =
          RdfMapper.withMappers((r) => r..registerMapper(ParentMapper()));
      expect(() => rdf.decodeObjects(turtleDoc),
          throwsA(isA<IncompleteDeserializationException>()));
    });

    test("Complex Usecase with remaining triples (passes with lenient mode)",
        () {
      final turtleDoc = '''
@prefix data: <https://example.com/data/> .
@prefix ex: <https://example.com/vocab/> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .

data:c1 ex:age 42;
    ex:child [ ex:name "fas" ];
    ex:name "some child" .

data:p1 a ex:Parent;
    ex:barChild [ ex:name "bar" ; ex:age 43 ];
    ex:child data:c1;
    ex:foo "some value" .

data:p2 ex:age 23;
    ex:name "you don't know" .
''';
      final rdf =
          RdfMapper.withMappers((r) => r..registerMapper(ParentMapper()));
      final result = rdf.decodeObjects(turtleDoc,
          completenessMode: CompletenessMode.lenient);
      final reencoded = rdf.encodeObjects(result);
      // due to the lenient mode, we do not expect the reencoded
      // document to be equal to the original turtleDoc, since it does not
      // contain the p2 instance, which is not a parent.
      expect(reencoded.trim(), isNot(equals(turtleDoc.trim())));
      // The result should still only contain the Parent p1
      expect(result, hasLength(1));
      final p1Subject = const IriTerm("https://example.com/data/p1");
      final c1Subject = const IriTerm("https://example.com/data/c1");

      final p1 = result.whereType<Parent>().single;
      final c1 = p1.child;
      expect(p1, isNotNull);
      expect(c1, isNotNull);
      expect(c1!.size, 4);
      expect(getObject(c1, c1Subject, Vocab.name),
          LiteralTerm.string("some child"));
      expect(getObject(c1, c1Subject, Vocab.age), LiteralTerm.integer(42));
      final childChildTerm =
          getObject(c1, c1Subject, Vocab.child) as RdfSubject;
      expect(
          getObject(c1, childChildTerm, Vocab.name), LiteralTerm.string("fas"));

      final p1Remaining = p1.remainingTriples;
      expect(p1Remaining.size, 4);
      expect(getObject(p1Remaining, p1Subject, Vocab.foo),
          LiteralTerm.string("some value"));
      final p1BarChild =
          getObject(p1Remaining, p1Subject, Vocab.barChild) as RdfSubject;
      expect(getObject(p1Remaining, p1BarChild, Vocab.name),
          LiteralTerm.string("bar"));
      expect(getObject(p1Remaining, p1BarChild, Vocab.age),
          LiteralTerm.integer(43));
    });
    test("Complex Usecase with remaining triples (Lossless)", () {
      final turtleDoc = '''
@prefix data: <https://example.com/data/> .
@prefix ex: <https://example.com/vocab/> .

data:c1 ex:age 42;
    ex:child [ ex:name "fas" ];
    ex:name "some child" .

data:p1 a ex:Parent;
    ex:barChild [ ex:name "bar" ; ex:age 43 ];
    ex:child data:c1;
    ex:foo "some value" .

data:p2 ex:age 23;
    ex:name "you don't know" .
''';
      final rdf =
          RdfMapper.withMappers((r) => r..registerMapper(ParentMapper()));
      final (result, remainder) = rdf.decodeObjectsLossless(turtleDoc);
      final reencoded = rdf.encodeObjectsLossless((result, remainder));

      // This time we use the lossless encoding, so we expect the
      // reencoded document to be equal to the original turtleDoc.
      expect(reencoded.trim(), equals(turtleDoc.trim()));
      // The result should actually not only contain the Parent p1, but also a
      // RdfGraph for p2 (which is not a parent) with two triples.
      // and the p1 instance has a child c1 which is a RdfGraph with four
      // triples (including _:b1).
      // And the remainingTriples graph of p1 has the triple for vocab:foo,
      // and also a blank node including its triples
      expect(result, hasLength(1));
      final p1Subject = const IriTerm("https://example.com/data/p1");
      final p2Subject = const IriTerm("https://example.com/data/p2");
      final c1Subject = const IriTerm("https://example.com/data/c1");

      final p1 = result.whereType<Parent>().single;
      final p2 = remainder;
      final c1 = p1.child;
      expect(p1, isNotNull);
      expect(p2, isNotNull);
      expect(c1, isNotNull);
      expect(c1!.size, 4);
      expect(getObject(c1, c1Subject, Vocab.name),
          LiteralTerm.string("some child"));
      expect(getObject(c1, c1Subject, Vocab.age), LiteralTerm.integer(42));
      final childChildTerm =
          getObject(c1, c1Subject, Vocab.child) as RdfSubject;
      expect(
          getObject(c1, childChildTerm, Vocab.name), LiteralTerm.string("fas"));

      final p1Remaining = p1.remainingTriples;
      expect(p1Remaining.size, 4);
      expect(getObject(p1Remaining, p1Subject, Vocab.foo),
          LiteralTerm.string("some value"));
      final p1BarChild =
          getObject(p1Remaining, p1Subject, Vocab.barChild) as RdfSubject;
      expect(getObject(p1Remaining, p1BarChild, Vocab.name),
          LiteralTerm.string("bar"));
      expect(getObject(p1Remaining, p1BarChild, Vocab.age),
          LiteralTerm.integer(43));

      expect(p2.size, 2);
      expect(getObject(p2, p2Subject, Vocab.name),
          LiteralTerm.string("you don't know"));
      expect(getObject(p2, p2Subject, Vocab.age), LiteralTerm.integer(23));
    });
  });
}

RdfObject getObject(
    RdfGraph graph, RdfSubject c1Subject, RdfPredicate predicate) {
  return graph
      .findTriples(subject: c1Subject, predicate: predicate)
      .single
      .object;
}
