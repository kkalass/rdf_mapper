import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_core/rdf_core.dart';

/// Example demonstrating convenience IRI mappers with realistic domain objects.
/// Shows how fragment and path element mappers work in practice for different
/// types of resources with proper RDF encoding/decoding.
void main() {
  print('=== Convenience IRI Mappers Example ===\n');

  // 1. Document sections using fragment mapping
  _demonstrateDocumentSections();

  // 2. User profiles using path element mapping
  _demonstrateUserProfiles();

  // 3. Mixed scenario with both types
  _demonstrateMixedScenario();
}

void _demonstrateDocumentSections() {
  print('📄 Document Sections Example');
  print('Using FragmentIriTermMapper for section references\n');

  // Create mapper with custom section mapping
  final rdf = RdfMapper.withDefaultRegistry()
    ..registerMapper<DocumentSection>(DocumentSectionMapper());

  // Create some document sections
  final sections = [
    DocumentSection('introduction', 'Introduction', 'Welcome to our guide'),
    DocumentSection('getting-started', 'Getting Started', 'How to begin'),
    DocumentSection('advanced-topics', 'Advanced Topics', 'Expert techniques'),
  ];

  for (final section in sections) {
    // Encode to RDF
    final rdfString = rdf.encodeObject(section);
    print('Section: ${section.title}');
    print('${'─' * 50}');
    print(rdfString);
    print('${'─' * 50}');

    // Decode back to verify roundtrip
    final decoded = rdf.decodeObject<DocumentSection>(rdfString);
    print('Roundtrip verification: ✅ ${decoded.id == section.id}\n');
  }
}

void _demonstrateUserProfiles() {
  print('👤 User Profiles Example');
  print('Using LastPathElementIriTermMapper for user IDs\n');

  // Create mapper with custom user mapping
  final rdf = RdfMapper.withDefaultRegistry()
    ..registerMapper<UserProfile>(UserProfileMapper());

  // Create some user profiles
  final users = [
    UserProfile('alice', 'Alice Smith', 'alice@example.com'),
    UserProfile('bob-42', 'Bob Johnson', 'bob@example.com'),
    UserProfile('user_admin', 'Admin User', 'admin@example.com'),
  ];

  for (final user in users) {
    // Encode to RDF
    final rdfString = rdf.encodeObject(user);
    print('User: ${user.name}');
    print('${'─' * 50}');
    print(rdfString);
    print('${'─' * 50}');

    // Decode back to verify roundtrip
    final decoded = rdf.decodeObject<UserProfile>(rdfString);
    print('Roundtrip verification: ✅ ${decoded.userId == user.userId}\n');
  }
}

void _demonstrateMixedScenario() {
  print('🔄 Mixed Scenario Example');
  print('Document with sections and user assignments\n');

  // Create mapper supporting both types
  final rdf = RdfMapper.withDefaultRegistry()
    ..registerMapper<DocumentSection>(DocumentSectionMapper())
    ..registerMapper<UserProfile>(UserProfileMapper())
    ..registerMapper<DocumentWithAssignments>(DocumentWithAssignmentsMapper());

  // Create a document with sections and assigned users
  final document = DocumentWithAssignments(
    title: 'API Documentation',
    sections: [
      DocumentSection('auth', 'Authentication', 'How to authenticate'),
      DocumentSection('endpoints', 'API Endpoints', 'Available endpoints'),
    ],
    assignedReviewers: [
      UserProfile('alice', 'Alice Smith', 'alice@example.com'),
      UserProfile('bob-42', 'Bob Johnson', 'bob@example.com'),
    ],
  );

  // Encode to RDF
  final rdfString =
      rdf.encodeObject(document, baseUri: 'http://docs.example.org/');
  print('Complete Document:');
  print('${'═' * 60}');
  print(rdfString);
  print('${'═' * 60}');

  // Decode back
  final decoded = rdf.decodeObject<DocumentWithAssignments>(rdfString);
  print('Decoded sections: ${decoded.sections.map((s) => s.id).join(', ')}');
  print(
      'Decoded reviewers: ${decoded.assignedReviewers.map((u) => u.userId).join(', ')}');
  print('✅ Roundtrip successful!\n');
}

// Domain classes

class DocumentSection {
  final String id;
  final String title;
  final String content;

  const DocumentSection(this.id, this.title, this.content);
}

class UserProfile {
  final String userId;
  final String name;
  final String email;

  const UserProfile(this.userId, this.name, this.email);
}

class DocumentWithAssignments {
  final String title;
  final List<DocumentSection> sections;
  final List<UserProfile> assignedReviewers;

  const DocumentWithAssignments({
    required this.title,
    required this.sections,
    required this.assignedReviewers,
  });
}

// Custom mappers using convenience IRI mappers

class DocumentSectionMapper implements GlobalResourceMapper<DocumentSection> {
  const DocumentSectionMapper();

  static const _fragmentMapper =
      FragmentIriTermMapper('http://docs.example.org/sections');

  @override
  IriTerm? get typeIri => null; // No specific type

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
    DocumentSection section,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    final subject = _fragmentMapper.toRdfTerm(section.id, context);

    return context
        .resourceBuilder(subject)
        .addValue(
            const IriTerm('http://purl.org/dc/terms/title'), section.title)
        .addValue(const IriTerm('http://purl.org/dc/terms/description'),
            section.content)
        .build();
  }

  @override
  DocumentSection fromRdfResource(
      IriTerm subject, DeserializationContext context) {
    final id = _fragmentMapper.fromRdfTerm(subject, context);
    final reader = context.reader(subject);
    final title =
        reader.require<String>(const IriTerm('http://purl.org/dc/terms/title'));
    final content = reader
        .require<String>(const IriTerm('http://purl.org/dc/terms/description'));

    return DocumentSection(id, title, content);
  }
}

class UserProfileMapper implements GlobalResourceMapper<UserProfile> {
  const UserProfileMapper();

  static const _pathMapper =
      LastPathElementIriTermMapper('http://api.example.org/users/');

  @override
  IriTerm? get typeIri => null; // No specific type

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
    UserProfile user,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    final subject = _pathMapper.toRdfTerm(user.userId, context);

    return context
        .resourceBuilder(subject)
        .addValue(const IriTerm('http://xmlns.com/foaf/0.1/name'), user.name)
        .addValue(const IriTerm('http://xmlns.com/foaf/0.1/mbox'), user.email)
        .build();
  }

  @override
  UserProfile fromRdfResource(IriTerm subject, DeserializationContext context) {
    final userId = _pathMapper.fromRdfTerm(subject, context);
    final reader = context.reader(subject);
    final name =
        reader.require<String>(const IriTerm('http://xmlns.com/foaf/0.1/name'));
    final email =
        reader.require<String>(const IriTerm('http://xmlns.com/foaf/0.1/mbox'));

    return UserProfile(userId, name, email);
  }
}

class DocumentWithAssignmentsMapper
    implements GlobalResourceMapper<DocumentWithAssignments> {
  const DocumentWithAssignmentsMapper();

  @override
  IriTerm? get typeIri => const IriTerm('http://purl.org/dc/dcmitype/Text');

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
    DocumentWithAssignments doc,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    // Use parentSubject if provided, otherwise create a deterministic IRI
    final subject = parentSubject is IriTerm
        ? parentSubject
        : context.createIriTerm(
            'http://docs.example.org/documents/${doc.title.toLowerCase().replaceAll(' ', '-')}');

    return context
        .resourceBuilder(subject)
        .addValue(const IriTerm('http://purl.org/dc/terms/title'), doc.title)
        .addValues(
            const IriTerm('http://purl.org/dc/terms/hasPart'), doc.sections)
        .addValues(const IriTerm('http://purl.org/dc/terms/contributor'),
            doc.assignedReviewers)
        .build();
  }

  @override
  DocumentWithAssignments fromRdfResource(
      IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    final title =
        reader.require<String>(const IriTerm('http://purl.org/dc/terms/title'));
    final sections = reader
        .getValues<DocumentSection>(
            const IriTerm('http://purl.org/dc/terms/hasPart'))
        .toList();
    final reviewers = reader
        .getValues<UserProfile>(
            const IriTerm('http://purl.org/dc/terms/contributor'))
        .toList();

    return DocumentWithAssignments(
      title: title,
      sections: sections,
      assignedReviewers: reviewers,
    );
  }
}
