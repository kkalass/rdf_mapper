import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';

/// Example demonstrating RDF Containers (rdf:Seq, rdf:Bag, rdf:Alt).
///
/// This example shows when to use the three standard RDF container types:
/// - `addRdfSeq()` / `optionalRdfSeq()` for ORDERED sequences (semantic ordering)
/// - `addRdfBag()` / `optionalRdfBag()` for UNORDERED collections (no semantic ordering)
/// - `addRdfAlt()` / `optionalRdfAlt()` for ALTERNATIVES with preference ordering
void main() {
  final rdf = RdfMapper.withDefaultRegistry()
    ..registerMapper<MediaResource>(MediaResourceMapper())
    ..registerMapper<TutorialCourse>(TutorialCourseMapper())
    ..registerMapper<MultilingualDocument>(MultilingualDocumentMapper());

  print('=== RDF Containers Example ===\n');

  // Example 1: Media Resource with different container types
  final mediaResource = MediaResource(
      id: 'https://example.org/media/tutorial-video',
      title: 'RDF Programming Tutorial',

      // rdf:Seq - Ordered sequence where position has semantic meaning
      // Chapters must be in exact order (1, 2, 3...)
      chapters: [
        'Introduction to RDF',
        'RDF Syntax and Formats',
        'SPARQL Queries',
        'RDF Schema and OWL',
        'Practical Applications'
      ],

      // rdf:Bag - Unordered collection where order doesn't matter
      // Keywords for categorization - no semantic ordering
      keywords: [
        'semantic-web',
        'linked-data',
        'tutorial',
        'programming',
        'rdf',
        'sparql'
      ],

      // rdf:Alt - Alternative formats with preference ordering
      // First is most preferred, others are fallbacks
      formats: [
        'video/webm', // Most preferred (best compression)
        'video/mp4', // Widely supported fallback
        'video/avi' // Legacy format (last resort)
      ]);

  print('1. Media Resource with RDF Containers:');
  final mediaTurtle = rdf.encodeObject(mediaResource);
  print(mediaTurtle);
  print('');

  // Example 2: Tutorial Course (ordered lessons)
  final course = TutorialCourse(
      id: 'https://example.org/courses/advanced-rdf',
      title: 'Advanced RDF Techniques',

      // rdf:Seq - Lessons must be completed in order
      lessons: [
        'Setting up your environment',
        'Basic RDF operations',
        'Advanced SPARQL queries',
        'Performance optimization',
        'Best practices and patterns'
      ],

      // rdf:Bag - Learning objectives (no specific order)
      learningObjectives: [
        'Understand RDF data models',
        'Write efficient SPARQL queries',
        'Optimize RDF store performance',
        'Apply semantic web best practices'
      ]);

  print('2. Tutorial Course (Ordered lessons vs Unordered objectives):');
  final courseTurtle = rdf.encodeObject(course);
  print(courseTurtle);
  print('');

  // Example 3: Multilingual Document (language alternatives)
  final document = MultilingualDocument(
      id: 'https://example.org/docs/getting-started',

      // rdf:Alt - Language versions with preference order
      titles: [
        'Getting Started with RDF', // English (preferred)
        'Erste Schritte mit RDF', // German (alternative)
        'Commencer avec RDF' // French (alternative)
      ],

      // rdf:Alt - Available language codes
      languages: [
        'en', // English (primary)
        'de', // German (secondary)
        'fr' // French (tertiary)
      ],

      // rdf:Bag - Document categories (unordered)
      categories: [
        'documentation',
        'tutorial',
        'beginner-friendly',
        'getting-started'
      ]);

  print('3. Multilingual Document (Language alternatives):');
  final docTurtle = rdf.encodeObject(document);
  print(docTurtle);
  print('');

  // Demonstrate deserialization
  print('=== Deserialization Example ===');
  final deserializedMedia = rdf.decodeObject<MediaResource>(mediaTurtle);

  print('Deserialized media resource:');
  print('Title: ${deserializedMedia.title}');
  print('Chapters (${deserializedMedia.chapters.length}):');
  for (int i = 0; i < deserializedMedia.chapters.length; i++) {
    print('  ${i + 1}. ${deserializedMedia.chapters[i]}');
  }

  print('Keywords: ${deserializedMedia.keywords.join(', ')}');
  print('Preferred format: ${deserializedMedia.formats.first}');
  print('All formats: ${deserializedMedia.formats.join(' > ')}');

  print('\n=== Container Type Summary ===');
  print(
      'rdf:Seq - Use for semantically ordered sequences (chapters, steps, rankings)');
  print('rdf:Bag - Use for unordered collections (tags, keywords, categories)');
  print(
      'rdf:Alt - Use for alternatives with preference (formats, languages, options)');
}

/// Media resource with different types of collections
class MediaResource {
  final String id;
  final String title;
  final List<String> chapters; // Ordered sequence (rdf:Seq)
  final List<String> keywords; // Unordered collection (rdf:Bag)
  final List<String> formats; // Alternative formats (rdf:Alt)

  MediaResource({
    required this.id,
    required this.title,
    required this.chapters,
    required this.keywords,
    required this.formats,
  });
}

class MediaResourceMapper implements GlobalResourceMapper<MediaResource> {
  // Simple vocabulary for this example
  static const _ns = 'https://example.org/vocab/';
  static final hasChapter = const IriTerm('${_ns}hasChapter');
  static final hasKeyword = const IriTerm('${_ns}hasKeyword');
  static final hasFormat = const IriTerm('${_ns}hasFormat');
  static final title = const IriTerm('${_ns}title');

  @override
  IriTerm? get typeIri => const IriTerm('${_ns}MediaResource');

  @override
  MediaResource fromRdfResource(
      IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);

    return MediaResource(
      id: subject.value,
      title: reader.require<String>(title),

      // Deserialize RDF containers to Dart Lists
      chapters: reader.optionalRdfSeq<String>(hasChapter) ?? const [],
      keywords: reader.optionalRdfBag<String>(hasKeyword) ?? const [],
      formats: reader.optionalRdfAlt<String>(hasFormat) ?? const [],
    );
  }

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
      MediaResource resource, SerializationContext context,
      {RdfSubject? parentSubject}) {
    final subject = context.createIriTerm(resource.id);

    return context
        .resourceBuilder(subject)
        .addValue(title, resource.title)

        // Serialize Dart Lists to RDF containers
        .addRdfSeq<String>(hasChapter, resource.chapters)
        .addRdfBag<String>(hasKeyword, resource.keywords)
        .addRdfAlt<String>(hasFormat, resource.formats)
        .build();
  }
}

/// Tutorial course with ordered lessons
class TutorialCourse {
  final String id;
  final String title;
  final List<String> lessons; // Must be in order (rdf:Seq)
  final List<String> learningObjectives; // No specific order (rdf:Bag)

  TutorialCourse({
    required this.id,
    required this.title,
    required this.lessons,
    required this.learningObjectives,
  });
}

class TutorialCourseMapper implements GlobalResourceMapper<TutorialCourse> {
  static const _ns = 'https://example.org/course/';
  static final hasLesson = const IriTerm('${_ns}hasLesson');
  static final hasObjective = const IriTerm('${_ns}hasObjective');
  static final title = const IriTerm('${_ns}title');

  @override
  IriTerm? get typeIri => const IriTerm('${_ns}Course');

  @override
  TutorialCourse fromRdfResource(
      IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);

    return TutorialCourse(
      id: subject.value,
      title: reader.require<String>(title),
      lessons:
          reader.requireRdfSeq<String>(hasLesson), // Required ordered sequence
      learningObjectives: reader.optionalRdfBag<String>(hasObjective) ??
          const [], // Optional unordered bag
    );
  }

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
      TutorialCourse course, SerializationContext context,
      {RdfSubject? parentSubject}) {
    final subject = context.createIriTerm(course.id);

    return context
        .resourceBuilder(subject)
        .addValue(title, course.title)
        .addRdfSeq<String>(hasLesson, course.lessons)
        .addRdfBag<String>(hasObjective, course.learningObjectives)
        .build();
  }
}

/// Multilingual document with language alternatives
class MultilingualDocument {
  final String id;
  final List<String> titles; // Language alternatives (rdf:Alt)
  final List<String> languages; // Language codes by preference (rdf:Alt)
  final List<String> categories; // Document categories (rdf:Bag)

  MultilingualDocument({
    required this.id,
    required this.titles,
    required this.languages,
    required this.categories,
  });
}

class MultilingualDocumentMapper
    implements GlobalResourceMapper<MultilingualDocument> {
  static const _ns = 'https://example.org/doc/';
  static final hasTitle = const IriTerm('${_ns}hasTitle');
  static final hasLanguage = const IriTerm('${_ns}hasLanguage');
  static final hasCategory = const IriTerm('${_ns}hasCategory');

  @override
  IriTerm? get typeIri => const IriTerm('${_ns}Document');

  @override
  MultilingualDocument fromRdfResource(
      IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);

    return MultilingualDocument(
      id: subject.value,
      titles: reader.requireRdfAlt<String>(hasTitle), // Required alternatives
      languages:
          reader.requireRdfAlt<String>(hasLanguage), // Required alternatives
      categories: reader.optionalRdfBag<String>(hasCategory) ??
          const [], // Optional bag
    );
  }

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
      MultilingualDocument doc, SerializationContext context,
      {RdfSubject? parentSubject}) {
    final subject = context.createIriTerm(doc.id);

    return context
        .resourceBuilder(subject)
        .addRdfAlt<String>(hasTitle, doc.titles)
        .addRdfAlt<String>(hasLanguage, doc.languages)
        .addRdfBag<String>(hasCategory, doc.categories)
        .build();
  }
}
