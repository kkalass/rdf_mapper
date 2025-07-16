import 'package:rdf_mapper/rdf_mapper.dart';

/// Example demonstrating RDF container mapper usage
///
/// This example shows how to use the RdfSeqMapper, RdfAltMapper, and RdfBagMapper
/// classes for mapping Dart collections to RDF containers.
///
/// IMPORTANT: This example shows direct mapper usage for educational purposes.
/// In production code, container mappers should NOT be registered globally.
/// Instead, use context methods in your resource mappers:
/// - context.addRdfSeq() / context.requireRdfSeq()
/// - context.addRdfAlt() / context.requireRdfAlt()
/// - context.addRdfBag() / context.requireRdfBag()
///
/// This avoids type conflicts and provides clearer semantic intent.
void main() {
  // NOTE: This registration approach is for demonstration only!
  // In real applications, use context methods instead of global registration
  final mapper = RdfMapper.withMappers((registry) {
    registry.registerMapper(RdfSeqMapper<String>()); // Default: ordered lists
    // Note: NOT registering Alt/Bag mappers globally to avoid conflicts
  });

  // Example data
  final bookChapters = [
    'Introduction',
    'Getting Started',
    'Advanced Topics',
    'Conclusion'
  ];
  final alternativeTitles = [
    'The Dart Guide',
    'Learning Dart',
    'Dart Programming'
  ];
  final tags = ['programming', 'dart', 'tutorial', 'language'];

  print('=== RDF Container Mappers Example ===\n');

  // Demonstrate RDF Sequence mapping (ordered lists)
  print('1. RDF Sequence (rdf:Seq) - Ordered lists:');
  // Uses the globally registered RdfSeqMapper<String>
  final seqGraph = mapper.graph.encodeObject(bookChapters);
  print('   Original: $bookChapters');
  print('   RDF triples count: ${seqGraph.triples.length}');

  // Roundtrip test
  final restoredChapters = mapper.graph.decodeObject<List<String>>(seqGraph);
  print('   Restored: $restoredChapters');
  print(
      '   Order preserved: ${bookChapters.toString() == restoredChapters.toString()}\n');

  // Demonstrate RDF Alternative mapping (preference-ordered alternatives)
  print('2. RDF Alternative (rdf:Alt) - Preference-ordered alternatives:');
  // Use local registration to avoid global conflict with Seq mapper
  final altGraph = mapper.graph.encodeObject(alternativeTitles,
      register: (registry) => registry.registerMapper(RdfAltMapper<String>()));
  print('   Original: $alternativeTitles');
  print('   RDF triples count: ${altGraph.triples.length}');

  // Roundtrip test - must use same local registration
  final restoredTitles = mapper.graph.decodeObject<List<String>>(altGraph,
      register: (registry) => registry.registerMapper(RdfAltMapper<String>()));
  print('   Restored: $restoredTitles');
  print(
      '   Preference order preserved: ${alternativeTitles.toString() == restoredTitles.toString()}\n');

  // Demonstrate RDF Bag mapping (unordered collections)
  print('3. RDF Bag (rdf:Bag) - Unordered collections:');
  // Use local registration to avoid global conflict with Seq mapper
  final bagGraph = mapper.graph.encodeObject(tags,
      register: (registry) => registry.registerMapper(RdfBagMapper<String>()));
  print('   Original: $tags');
  print('   RDF triples count: ${bagGraph.triples.length}');

  // Roundtrip test - must use same local registration
  final restoredTags = mapper.graph.decodeObject<List<String>>(bagGraph,
      register: (registry) => registry.registerMapper(RdfBagMapper<String>()));
  print('   Restored: $restoredTags');
  print(
      '   Elements preserved: ${tags.toSet().toString() == restoredTags.toSet().toString()}\n');

  // Show RDF serialization for one example
  print('4. Sample RDF output for book chapters (Turtle format):');
  // Uses the globally registered RdfSeqMapper<String>
  final turtle = mapper.encodeObject(bookChapters, contentType: 'text/turtle');
  print(turtle);

  print('\n=== Best Practice Recommendations ===');
  print('RECOMMENDED: Do NOT register collection/container mappers globally!');
  print('Instead, use context methods in your resource mappers:');
  print('');
  print('class BookMapper extends ResourceMapper<Book> {');
  print('  @override');
  print(
      '  Book fromRdfResource(RdfSubject subject, DeserializationContext context) {');
  print('    return Book(');
  print(
      '      chapters: context.requireRdfSeq<String>(subject, bookVocab.chapters),');
  print(
      '      alternativeTitles: context.optionalRdfAlt<String>(subject, bookVocab.altTitles),');
  print('      tags: context.optionalRdfBag<String>(subject, bookVocab.tags),');
  print('    );');
  print('  }');
  print('');
  print('  @override');
  print(
      '  (RdfSubject, Iterable<RdfTriple>) toRdfResource(Book book, SerializationContext context) {');
  print('    final subject = context.blankNode();');
  print('    return (subject, [');
  print(
      '      ...context.addRdfSeq(subject, bookVocab.chapters, book.chapters),');
  print(
      '      ...context.addRdfAlt(subject, bookVocab.altTitles, book.alternativeTitles),');
  print('      ...context.addRdfBag(subject, bookVocab.tags, book.tags),');
  print('    ]);');
  print('  }');
  print('}');
  print('');
  print('This approach provides:');
  print('- Clear semantic intent (Seq vs Alt vs Bag)');
  print('- No mapper registration conflicts');
  print('- Better integration with resource mapping');
}
