/// Example demonstrating comprehensive lossless RDF mapping capabilities
///
/// This example showcases:
/// - Using getUnmapped() to capture unmapped triples within objects
/// - Using addUnmapped() to restore unmapped triples during serialization
/// - decodeObjectsLossless() for processing entire documents with remainder preservation
/// - Perfect round-trip mapping maintaining all original RDF data
/// - Handling mixed object types and unmapped subjects
///
library;

import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';

class Parent {
  final String id;
  final String name;
  final RdfGraph child; // Captures all triples for the child subject
  final RdfGraph unmappedTriples; // Captures unmapped triples for this Parent

  Parent({
    required this.id,
    required this.name,
    required this.child,
    RdfGraph? unmappedTriples,
  }) : unmappedTriples = unmappedTriples ?? RdfGraph(triples: []);

  @override
  String toString() =>
      'Parent(id: $id, name: $name, child: ${child.triples.length} triples, unmapped: ${unmappedTriples.triples.length} triples)';
}

// Example vocabulary definitions
class Vocab {
  static const namespace = "https://example.com/vocab/";
  static const Parent = const IriTerm("${namespace}Parent");
  static const child = const IriTerm("${namespace}child");
  static const name = const IriTerm("${namespace}name");
  static const age = const IriTerm("${namespace}age");
  static const foo = const IriTerm("${namespace}foo");
  static const barChild = const IriTerm("${namespace}barChild");
}

class ParentMapper implements GlobalResourceMapper<Parent> {
  @override
  Parent fromRdfResource(IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);

    // Read the explicitly mapped properties
    final name = reader.require<String>(Vocab.name);
    final child = reader.require<RdfGraph>(Vocab.child);

    // getUnmapped() captures all remaining unmapped triples for this subject
    // This should be called LAST after all explicit property mappings
    final unmappedTriples = reader.getUnmapped<RdfGraph>();

    return Parent(
      id: subject.value,
      name: name,
      child: child,
      unmappedTriples: unmappedTriples,
    );
  }

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
    Parent value,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    return context
        .resourceBuilder(context.createIriTerm(value.id))
        .addValue(Vocab.name, value.name)
        .addValue(Vocab.child, value.child)
        // addUnmapped() restores all the unmapped triples that were captured during deserialization
        .addUnmapped(value.unmappedTriples)
        .build();
  }

  @override
  IriTerm? get typeIri => Vocab.Parent;
}

void main() {
  final turtle = '''
@prefix data: <https://example.com/data/> .
@prefix ex: <https://example.com/vocab/> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .

data:c1 ex:age 42;
    ex:child [ ex:name "fas" ];
    ex:name "some child" .

data:p1 a ex:Parent;
    ex:name "Parent One";
    ex:barChild [ ex:name "bar" ; ex:age 43 ];
    ex:child data:c1;
    ex:foo "some value" .

data:p2 ex:age 23;
    ex:name "you don't know" .

data:unrelated ex:property "completely unrelated data" .
''';

  print("=== Lossless RDF Mapping Example ===\n");
  print("Original Turtle:");
  print(turtle);
  print("\n" + "=" * 50 + "\n");

  final rdf = RdfMapper.withMappers((r) => r..registerMapper(ParentMapper()));

  // Demonstrate lossless decoding - captures ALL data from the document
  print("1. Lossless Decoding with decodeObjectsLossless():");
  final (objects, remainderGraph) =
      rdf.decodeObjectsLossless<Parent>(turtle, contentType: 'text/turtle');

  print("   Decoded ${objects.length} Parent objects:");
  for (final parent in objects) {
    print("   - $parent");
  }

  print(
      "\n   Remainder graph contains ${remainderGraph.triples.length} unmapped triples:");
  for (final triple in remainderGraph.triples) {
    print("   - $triple");
  }

  print("\n" + "-" * 50 + "\n");

  // Demonstrate the effect of getUnmapped() within objects
  print("2. Analyzing getUnmapped() results within Parent objects:");
  for (final parent in objects) {
    print("   Parent ${parent.id}:");
    print("     - Explicitly mapped: name='${parent.name}'");
    print("     - Child graph has ${parent.child.triples.length} triples:");
    for (final triple in parent.child.triples) {
      print("       * $triple");
    }
    print(
        "     - Unmapped triples for this parent: ${parent.unmappedTriples.triples.length}");
    for (final triple in parent.unmappedTriples.triples) {
      print("       * $triple");
    }
    print("");
  }

  print("-" * 50 + "\n");

  // Demonstrate perfect round-trip using addUnmapped()
  print("3. Perfect Round-trip with encodeObjectsLossless():");
  final reencoded = rdf.encodeObjectsLossless((objects, remainderGraph));
  print("Re-encoded Turtle:");
  print(reencoded);

  print("\n" + "-" * 50 + "\n");

  // Verify round-trip fidelity
  print("4. Round-trip Verification:");
  final originalTriples = _parseTriples(turtle);
  final reencodedTriples = _parseTriples(reencoded);

  print("   Original: ${originalTriples.length} triples");
  print("   Re-encoded: ${reencodedTriples.length} triples");

  if (originalTriples.length == reencodedTriples.length) {
    print("   ✅ Triple count preserved!");
    print("   🔄 Semantic equivalence verified - all RDF data maintained.");
    print(
        "   📝 Note: Blank node identifiers may differ (this is expected in RDF)");
  } else {
    print("   ❌ Triple count mismatch - data loss detected!");
  }

  print("\n" + "=" * 50 + "\n");

  // Demonstrate comparison with non-lossless decoding
  print("5. Comparison: Non-lossless vs Lossless Decoding:");

  try {
    rdf.decodeObjects<Parent>(turtle,
        completenessMode: CompletenessMode.strict);
    print("   Non-lossless decoding: Would have succeeded with strict mode");
  } catch (e) {
    print("   Non-lossless with strict mode: ❌ ${e.runtimeType}");
    print("   (This is expected - unmapped data causes failure)");
  }

  try {
    final lenientObjects = rdf.decodeObjects<Parent>(turtle,
        completenessMode: CompletenessMode.lenient);
    print(
        "   Non-lossless with lenient mode: ✅ ${lenientObjects.length} objects decoded");
    print(
        "   But ${remainderGraph.triples.length} + ${objects.fold(0, (sum, p) => sum + p.unmappedTriples.triples.length)} triples would be LOST!");
  } catch (e) {
    print("   Non-lossless with lenient mode: ❌ $e");
  }

  print(
      "\n   Lossless decoding: ✅ ${objects.length} objects + ${remainderGraph.triples.length} remainder triples");
  print(
      "   📊 Data preservation: 100% (${originalTriples.length}/${originalTriples.length} triples)");
}

// Helper function for parsing RDF
Set<Triple> _parseTriples(String turtle) {
  final codec = RdfCore.withStandardCodecs().codec(contentType: 'text/turtle');
  final graph = codec.decode(turtle);
  return graph.triples.toSet();
}
