/// Example demonstrating how to use rdf_mapper with enum properties
///
/// This example shows:
/// 1. How to create custom LiteralTermMappers for enum types
/// 2. How to create custom IriTermMappers using URI templates
/// 3. Two different mapping strategies:
///    - Literal mapping (enum -> string literal)
///    - IRI mapping (enum -> structured IRI using templates)
/// 4. How to register and use enum mappers
/// 5. Serialization and deserialization of objects with enum properties
///
/// The example uses a Document class with two enum properties:
/// - DocumentStatus: mapped to string literals (simple approach)
/// - DocumentCategory: mapped to IRIs using URI templates (semantic approach)
///
/// This demonstrates both literal and IRI-based enum mapping approaches.

library;

import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_vocabularies_schema/schema.dart';
import 'package:rdf_vocabularies_core/xsd.dart';

void main() {
  // Create mapper with default registry and register our custom enum mappers
  final rdf = RdfMapper.withDefaultRegistry()
    ..registerMapper<Document>(const DocumentMapper())
    ..registerMapper<DocumentStatus>(
        const DocumentStatusMapper()) // Literal-based mapping
    ..registerMapper<DocumentCategory>(
        const DocumentCategoryMapper()); // IRI-based mapping

  // Create a document with enum properties
  final document = Document(
    id: 'document-123',
    title: 'Important Document',
    content: 'This is the content of the document.',
    status: DocumentStatus.published, // Will become "published"^^xsd:string
    category: DocumentCategory
        .technical, // Will become <http://example.org/vocab/category/technical>
    createdAt: DateTime(2025, 6, 25),
  );

  print('=== Serialization Example ===');

  // Convert the document to RDF Turtle format
  final turtle = rdf.encodeObject(document, baseUri: 'http://example.org/doc/');
  print('Document as RDF Turtle:');
  print(turtle);

  print('\n=== Deserialization Example ===');

  // Deserialize back to a Document object
  final deserializedDocument = rdf.decodeObject<Document>(turtle);
  print('Successfully deserialized:');
  print('- Title: ${deserializedDocument.title}');
  print('- Status: ${deserializedDocument.status.name} (enum value)');
  print('- Category: ${deserializedDocument.category.name} (enum value)');
  print('- Created: ${deserializedDocument.createdAt}');

  print('\n=== Multiple Enum Values Example ===');

  // Demonstrate different enum values
  final documents = [
    Document(
      id: 'draft-doc',
      title: 'Draft Document',
      content: 'Work in progress...',
      status: DocumentStatus.draft,
      category: DocumentCategory.personal,
      createdAt: DateTime.now(),
    ),
    Document(
      id: 'archived-doc',
      title: 'Archived Document',
      content: 'Old document...',
      status: DocumentStatus.archived,
      category: DocumentCategory.business,
      createdAt: DateTime(2024, 1, 1),
    ),
  ];

  for (final doc in documents) {
    final docTurtle = rdf.encodeObject(doc, baseUri: 'http://example.org/doc/');
    final deserializedDoc = rdf.decodeObject<Document>(docTurtle);
    print(
        '${doc.title} -> Status: ${deserializedDoc.status.name}, Category: ${deserializedDoc.category.name}');
  }

  print('\n=== Parsing External RDF with Enum Values ===');

  // Example of deserializing RDF that contains enum values (mixed literal and IRI)
  final externalRdf = '''
@prefix schema: <https://schema.org/> .
@prefix ex: <http://example.org/vocab/> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .

<http://example.org/doc/external> a schema:CreativeWork;
    schema:name "External Document";
    schema:text "Content from external source";
    schema:creativeWorkStatus "underReview"^^xsd:string;
    ex:category <http://example.org/vocab/category/business>;
    schema:dateCreated "2025-06-25T10:00:00.000Z"^^xsd:dateTime .
''';

  final externalDoc = rdf.decodeObject<Document>(externalRdf);
  print('Parsed external document: ${externalDoc.title}');
  print('- Status: ${externalDoc.status.name} (from "underReview" literal)');
  print('- Category: ${externalDoc.category.name} (from IRI)');

  print('\n=== Alternative IRI Mapper Example ===');
  print('// The AdvancedDocumentCategoryMapper class shows how to create');
  print(
      '// an IRI mapper with configurable base URI and multiple placeholders:');
  print('//');
  print('// AdvancedDocumentCategoryMapper(() => "https://myorg.com")');
  print(
      '// Would generate IRIs like: https://myorg.com/vocab/category/technical');
  print('//');
  print('// Template: "{+baseUri}/vocab/{type}/{value}"');
  print('// - baseUri: provided by function (e.g., from config)');
  print('// - type: static provider that returns "category"');
  print('// - value: dynamic, comes from enum name');
}

// --- Domain Model ---

/// Represents document status as an enum with custom RDF mapping
enum DocumentStatus {
  draft,
  underReview,
  published,
  archived;
}

/// Represents document category as an enum
enum DocumentCategory {
  personal,
  business,
  technical;
}

/// Document entity with enum properties
class Document {
  final String id;
  final String title;
  final String content;
  final DocumentStatus status;
  final DocumentCategory category;
  final DateTime createdAt;

  Document({
    required this.id,
    required this.title,
    required this.content,
    required this.status,
    required this.category,
    required this.createdAt,
  });
}

// --- Mappers ---

/// Simple literal-based mapper for DocumentStatus enum
/// Maps enum values directly to their string names
class DocumentStatusMapper extends BaseRdfLiteralTermMapper<DocumentStatus> {
  const DocumentStatusMapper()
      : super(datatype: Xsd.string); // Use string datatype

  @override
  DocumentStatus convertFromLiteral(
      LiteralTerm term, DeserializationContext context) {
    // Simple mapping: literal value matches enum name
    switch (term.value) {
      case 'draft':
        return DocumentStatus.draft;
      case 'underReview':
        return DocumentStatus.underReview;
      case 'published':
        return DocumentStatus.published;
      case 'archived':
        return DocumentStatus.archived;
      default:
        throw ArgumentError('Unknown document status: ${term.value}');
    }
  }

  @override
  String convertToString(DocumentStatus status) {
    // Use enum name directly
    return status.name;
  }
}

/// IRI-based mapper for DocumentCategory enum using URI templates
/// Demonstrates how to map enums to structured IRIs
class DocumentCategoryMapper extends BaseRdfIriTermMapper<DocumentCategory> {
  const DocumentCategoryMapper()
      : super('http://example.org/vocab/category/{value}', 'value');

  @override
  String convertToString(DocumentCategory category) {
    // Use enum name directly as the IRI path segment
    return category.name;
  }

  @override
  DocumentCategory convertFromString(String value) {
    // Find enum by name
    try {
      return DocumentCategory.values.firstWhere((e) => e.name == value);
    } catch (e) {
      throw ArgumentError('Unknown document category: $value');
    }
  }
}

/// Advanced IRI-based mapper demonstrating URI template with providers
/// Shows how to use configurable base URIs and multiple placeholders
class AdvancedDocumentCategoryMapper
    extends BaseRdfIriTermMapper<DocumentCategory> {
  final String Function() baseUriProvider;

  AdvancedDocumentCategoryMapper(this.baseUriProvider)
      : super('{+baseUri}/vocab/{type}/{value}', 'value');

  @override
  String resolvePlaceholder(String placeholderName) {
    switch (placeholderName) {
      case 'baseUri':
        return baseUriProvider();
      case 'type':
        return 'category';
      default:
        return super.resolvePlaceholder(placeholderName);
    }
  }

  @override
  String convertToString(DocumentCategory category) {
    return category.name;
  }

  @override
  DocumentCategory convertFromString(String value) {
    try {
      return DocumentCategory.values.firstWhere((e) => e.name == value);
    } catch (e) {
      throw ArgumentError('Unknown document category: $value');
    }
  }
}

/// Document resource mapper
class DocumentMapper implements GlobalResourceMapper<Document> {
  static const String documentBaseUri = 'http://example.org/doc/';

  // Use Schema.org properties for better semantic meaning
  static final titlePredicate = SchemaCreativeWork.name;
  static final contentPredicate = SchemaCreativeWork.text;
  static final statusPredicate = SchemaCreativeWork.creativeWorkStatus;
  static final createdAtPredicate = SchemaCreativeWork.dateCreated;

  // Custom predicate for category (not in Schema.org)
  static final categoryPredicate =
      const IriTerm('http://example.org/vocab/category');

  const DocumentMapper();

  @override
  final IriTerm typeIri = SchemaCreativeWork.classIri;

  @override
  Document fromRdfResource(IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);

    return Document(
      id: _extractIdFromIri(subject.value),
      title: reader.require<String>(titlePredicate),
      content: reader.require<String>(contentPredicate),
      status: reader.require<DocumentStatus>(statusPredicate),
      category: reader.require<DocumentCategory>(categoryPredicate),
      createdAt: reader.require<DateTime>(createdAtPredicate),
    );
  }

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
    Document document,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    return context
        .resourceBuilder(context.createIriTerm(_createIriFromId(document.id)))
        .addValue(titlePredicate, document.title)
        .addValue(contentPredicate, document.content)
        // The enum mappers we registered will handle the conversion automatically
        .addValue(statusPredicate, document.status)
        .addValue(categoryPredicate, document.category)
        .addValue(createdAtPredicate, document.createdAt)
        .build();
  }

  /// Creates IRI from document ID
  String _createIriFromId(String id) => '$documentBaseUri$id';

  /// Extracts document ID from IRI
  String _extractIdFromIri(String iri) {
    if (!iri.startsWith(documentBaseUri)) {
      throw ArgumentError('Invalid Document IRI format: $iri');
    }
    return iri.substring(documentBaseUri.length);
  }
}
