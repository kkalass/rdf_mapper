import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';

/// Example demonstrating the difference between RDF Lists and multiple values.
///
/// This example shows when to use:
/// - `addRdfList()` / `optionalRdfList()` for ORDERED collections (preserves element order)
/// - `addValues()` / `getValues()` for UNORDERED collections (no guaranteed order)
void main() {
  final rdf = RdfMapper.withDefaultRegistry()
    ..registerMapper<Article>(ArticleMapper())
    ..registerMapper<Author>(AuthorMapper())
    ..registerMapper<Section>(SectionMapper());

  // Create an article with both ordered and unordered collections
  final article = Article(
    id: 'https://example.org/articles/123',
    title: 'Understanding RDF Collections',

    // ORDERED: Article sections must be in sequence (1, 2, 3...)
    // Uses RDF List structure to preserve order
    sections: [
      Section('Introduction', 1),
      Section('Main Content', 2),
      Section('Conclusion', 3),
    ],

    // UNORDERED: Multiple authors (collaboration)
    // Order doesn't matter, just multiple independent values
    authors: [
      Author('Alice Smith', 'alice@example.org'),
      Author('Bob Jones', 'bob@example.org'),
    ],

    // UNORDERED: Tags/keywords for categorization
    // Order doesn't matter, just multiple independent values
    tags: ['rdf', 'semantic-web', 'tutorial', 'collections'],

    // UNORDERED: Related articles (no specific order)
    relatedArticles: [
      'https://example.org/articles/rdf-basics',
      'https://example.org/articles/semantic-web-intro',
    ],
  );

  // Serialize to RDF
  final turtle = rdf.encodeObject(article);
  print('=== Serialized Article ===');
  print(turtle);
  print('\n');

  // Deserialize back
  final deserializedArticle = rdf.decodeObject<Article>(turtle);

  print('=== Deserialized Article ===');
  print('Title: ${deserializedArticle.title}');

  print('\nSections (ORDERED - preserved sequence):');
  for (var section in deserializedArticle.sections) {
    print('  ${section.number}. ${section.title}');
  }

  print('\nAuthors (UNORDERED - no guaranteed order):');
  for (var author in deserializedArticle.authors) {
    print('  ${author.name} (${author.email})');
  }

  print('\nTags (UNORDERED - no guaranteed order):');
  print('  ${deserializedArticle.tags.join(', ')}');

  print('\nRelated Articles (UNORDERED - no guaranteed order):');
  for (var url in deserializedArticle.relatedArticles) {
    print('  $url');
  }

  // Verify the section order is preserved
  assert(deserializedArticle.sections[0].number == 1);
  assert(deserializedArticle.sections[1].number == 2);
  assert(deserializedArticle.sections[2].number == 3);

  print('\n✅ All assertions passed - order preserved for sections!');
}

// Domain Model

class Article {
  final String id;
  final String title;
  final List<Section> sections; // ORDERED: sequence matters
  final List<Author> authors; // UNORDERED: multiple independent values
  final List<String> tags; // UNORDERED: multiple independent values
  final List<String> relatedArticles; // UNORDERED: multiple independent values

  Article({
    required this.id,
    required this.title,
    required this.sections,
    required this.authors,
    required this.tags,
    required this.relatedArticles,
  });
}

class Section {
  final String title;
  final int number;

  Section(this.title, this.number);
}

class Author {
  final String name;
  final String email;

  Author(this.name, this.email);
}

// Vocabulary
class ExampleVocab {
  static const String _ns = 'https://example.org/vocab/';

  // Types
  static final article = const IriTerm('${_ns}Article');
  static final section = const IriTerm('${_ns}Section');
  static final author = const IriTerm('${_ns}Author');

  // Properties
  static final title = const IriTerm('${_ns}title');
  static final sections = const IriTerm('${_ns}sections');
  static final authors = const IriTerm('${_ns}authors');
  static final tags = const IriTerm('${_ns}tags');
  static final relatedArticles = const IriTerm('${_ns}relatedArticles');
  static final name = const IriTerm('${_ns}name');
  static final email = const IriTerm('${_ns}email');
  static final number = const IriTerm('${_ns}number');
}

// Mappers

class ArticleMapper implements GlobalResourceMapper<Article> {
  @override
  IriTerm? get typeIri => ExampleVocab.article;

  @override
  Article fromRdfResource(IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);

    return Article(
      id: subject.value,
      title: reader.require<String>(ExampleVocab.title),

      // ORDERED: Use optionalRdfList for sections that must maintain sequence
      sections:
          reader.optionalRdfList<Section>(ExampleVocab.sections) ?? const [],

      // UNORDERED: Use getValues for multiple independent authors
      authors: reader.getValues<Author>(ExampleVocab.authors).toList(),

      // UNORDERED: Use getValues for multiple independent tags
      tags: reader.getValues<String>(ExampleVocab.tags).toList(),

      // UNORDERED: Use getValues for multiple independent related articles
      relatedArticles:
          reader.getValues<String>(ExampleVocab.relatedArticles).toList(),
    );
  }

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
    Article article,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    return context
        .resourceBuilder(context.createIriTerm(article.id))
        .addValue(ExampleVocab.title, article.title)

        // ORDERED: Use addRdfList for sections to preserve sequence
        // Note: Using .when() here avoids creating an empty RDF list (rdf:nil) when there are no sections.
        // Direct .addRdfList([]) is perfectly valid, but conditional creation is sometimes preferred.
        .when(
          article.sections.isNotEmpty,
          (builder) => builder.addRdfList<Section>(
              ExampleVocab.sections, article.sections),
        )

        // UNORDERED: Use addValues for multiple independent authors
        .addValues<Author>(ExampleVocab.authors, article.authors)

        // UNORDERED: Use addValues for multiple independent tags
        .addValues<String>(ExampleVocab.tags, article.tags)

        // UNORDERED: Use addValues for multiple independent related articles
        .addValues<String>(
            ExampleVocab.relatedArticles, article.relatedArticles)
        .build();
  }
}

class SectionMapper implements LocalResourceMapper<Section> {
  @override
  IriTerm? get typeIri => ExampleVocab.section;

  @override
  Section fromRdfResource(
      BlankNodeTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    return Section(
      reader.require<String>(ExampleVocab.title),
      reader.require<int>(ExampleVocab.number),
    );
  }

  @override
  (BlankNodeTerm, Iterable<Triple>) toRdfResource(
    Section section,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    return context
        .resourceBuilder(BlankNodeTerm())
        .addValue(ExampleVocab.title, section.title)
        .addValue(ExampleVocab.number, section.number)
        .build();
  }
}

class AuthorMapper implements LocalResourceMapper<Author> {
  @override
  IriTerm? get typeIri => ExampleVocab.author;

  @override
  Author fromRdfResource(
      BlankNodeTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    return Author(
      reader.require<String>(ExampleVocab.name),
      reader.require<String>(ExampleVocab.email),
    );
  }

  @override
  (BlankNodeTerm, Iterable<Triple>) toRdfResource(
    Author author,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    return context
        .resourceBuilder(BlankNodeTerm())
        .addValue(ExampleVocab.name, author.name)
        .addValue(ExampleVocab.email, author.email)
        .build();
  }
}
