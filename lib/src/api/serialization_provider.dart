import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';

/// Provides contextual serialization and deserialization for nested objects.
///
/// This interface enables context-aware mapping where serializers and deserializers
/// need access to parent context, subject IRIs, or other contextual information.
/// It's particularly useful for implementing the Document Pattern where nested
/// objects require knowledge of their container's properties.
///
/// ## Common Use Cases
///
/// ### Document Pattern with Primary Topic
/// ```dart
/// class Document<T> {
///   final String documentIri;
///   final T primaryTopic;
///   final RdfGraph unmapped;
///
///   Document({
///     required this.documentIri,
///     required this.primaryTopic,
///     required this.unmapped
///   });
/// }
///
/// class DocumentMapper<T> implements GlobalResourceMapper<Document<T>> {
///   final SerializationProvider<Document<T>, T> _primaryTopicProvider;
///
///   const DocumentMapper({
///     required SerializationProvider<Document<T>, T> primaryTopic,
///   }) : _primaryTopicProvider = primaryTopic;
///
///   @override
///   Document<T> fromRdfResource(IriTerm subject, DeserializationContext context) {
///     final reader = context.reader(subject);
///     final documentIri = subject.iri;
///     final primaryTopic = reader.require(
///       FoafDocument.primaryTopic,
///       deserializer: _primaryTopicProvider.deserializer(subject, context),
///     );
///     final unmapped = reader.getUnmapped<RdfGraph>();
///
///     return Document<T>(
///       documentIri: documentIri,
///       primaryTopic: primaryTopic,
///       unmapped: unmapped,
///     );
///   }
///
///   @override
///   (IriTerm, Iterable<Triple>) toRdfResource(
///     Document<T> document,
///     SerializationContext context, {
///     RdfSubject? parentSubject,
///   }) {
///     final subject = const IriTerm(document.documentIri);
///     return context
///         .resourceBuilder(subject)
///         .addValue(
///           FoafDocument.primaryTopic,
///           document.primaryTopic,
///           serializer: _primaryTopicProvider.serializer(
///             document,
///             subject,
///             context,
///           ),
///         )
///         .addUnmapped(document.unmapped)
///         .build();
///   }
/// }
/// ```
///
/// ### Registration Example
/// ```dart
/// // For Person documents where Person mapper needs document IRI context
/// RdfMapper mapper = RdfMapper.withMappers((r) =>
///     r.registerMapper<Document<Person>>(DocumentMapper(
///         primaryTopic: SerializationProvider.iriContextual(
///             (IriTerm iri) => PersonMapper(documentIriProvider: () => iri.iri)
///         ))));
/// ```
///
/// ### FOAF Profile Document Example
/// This pattern is especially useful for mapping Solid WebID profiles or other
/// FOAF documents where the person's properties are defined relative to the
/// document IRI:
///
/// ```turtle
/// @prefix : <#>.
/// @prefix foaf: <http://xmlns.com/foaf/0.1/>.
/// @prefix schema: <http://schema.org/>.
///
/// <> a foaf:PersonalProfileDocument;
///       foaf:maker :me;
///       foaf:primaryTopic :me.
///
/// :me a schema:Person, foaf:Person;
///     foaf:name "John Doe";
///     schema:birthDate "1990-01-01"^^xsd:date.
/// ```
///
/// ## Type Parameters
/// - [P] The parent/container type that provides context for serialization
/// - [T] The nested type being serialized/deserialized
abstract interface class SerializationProvider<P, T> {
  /// Creates a serializer for type [T] with access to parent context.
  ///
  /// This method is called during serialization and receives:
  /// - [parent]: The containing object that provides context
  /// - [subject]: The IRI of the subject being serialized
  /// - [context]: The serialization context with access to the mapper registry
  ///
  /// The returned serializer should use this context to make mapping decisions.
  Serializer<T> serializer(
      P parent, IriTerm subject, SerializationContext context);

  /// Creates a deserializer for type [T] with access to subject context.
  ///
  /// This method is called during deserialization and receives:
  /// - [subject]: The IRI of the subject being deserialized
  /// - [context]: The deserialization context with access to the mapper registry
  ///
  /// The returned deserializer should use this context to make mapping decisions.
  Deserializer<T> deserializer(IriTerm subject, DeserializationContext context);

  /// Creates a non-contextual provider that always returns the same mapper.
  ///
  /// This is the simplest form where the nested object doesn't need any
  /// contextual information. The same mapper instance is used for both
  /// serialization and deserialization regardless of parent or subject context.
  ///
  /// Example:
  /// ```dart
  /// SerializationProvider.nonContextual(SimpleValueMapper())
  /// ```
  static SerializationProvider<P, T> nonContextual<P, T>(Mapper<T> mapper) =>
      _NonContextualSerializationProvider(mapper);

  /// Creates a provider where mappers are created based on the subject IRI.
  ///
  /// This is useful when the nested object's mapping behavior depends on
  /// the IRI context, such as when the object needs to know its container's
  /// IRI for relative references or validation.
  ///
  /// The factory function receives the subject IRI and should return a
  /// mapper configured for that specific context.
  ///
  /// Example:
  /// ```dart
  /// SerializationProvider.iriContextual(
  ///   (IriTerm iri) => PersonMapper(documentIriProvider: () => iri.iri)
  /// )
  /// ```
  static SerializationProvider<P, T> iriContextual<P, T>(
          Mapper<T> Function(IriTerm) factory) =>
      _IriSerializationProvider(factory);

  /// Creates a custom provider with full control over serializer/deserializer creation.
  ///
  /// This provides maximum flexibility when you need different logic for
  /// serialization vs deserialization, or when you need access to all
  /// available context parameters.
  ///
  /// Example:
  /// ```dart
  /// SerializationProvider.custom<Document<Person>, Person>(
  ///   serializer: (document, subject, context) {
  ///     // Custom serialization logic based on document and subject
  ///     return PersonMapper(profileIri: document.documentIri);
  ///   },
  ///   deserializer: (subject, context) {
  ///     // Custom deserialization logic based on subject
  ///     return PersonMapper(profileIri: subject.iri);
  ///   },
  /// )
  /// ```
  static SerializationProvider<P, T> custom<P, T>({
    required Serializer<T> Function(P, IriTerm, SerializationContext)
        serializer,
    required Deserializer<T> Function(IriTerm, DeserializationContext)
        deserializer,
  }) =>
      _CustomSerializationMapper(serializer, deserializer);
}

/// Implementation for custom serialization providers with full control.
class _CustomSerializationMapper<P, T> implements SerializationProvider<P, T> {
  final Serializer<T> Function(P, IriTerm, SerializationContext) _serializer;
  final Deserializer<T> Function(IriTerm, DeserializationContext) _deserializer;

  const _CustomSerializationMapper(this._serializer, this._deserializer);

  @override
  Serializer<T> serializer(
          P parent, IriTerm subject, SerializationContext context) =>
      _serializer(parent, subject, context);

  @override
  Deserializer<T> deserializer(
          IriTerm subject, DeserializationContext context) =>
      _deserializer(subject, context);
}

/// Implementation for IRI-contextual serialization providers.
class _IriSerializationProvider<P, T> implements SerializationProvider<P, T> {
  final Mapper<T> Function(IriTerm) _factory;

  const _IriSerializationProvider(this._factory);

  @override
  Serializer<T> serializer(
          P parent, IriTerm subject, SerializationContext context) =>
      _factory(subject);

  @override
  Deserializer<T> deserializer(
          IriTerm subject, DeserializationContext context) =>
      _factory(subject);
}

/// Implementation for non-contextual serialization providers.
class _NonContextualSerializationProvider<P, T>
    implements SerializationProvider<P, T> {
  final Mapper<T> _mapper;

  const _NonContextualSerializationProvider(this._mapper);

  @override
  Serializer<T> serializer(
          P parent, IriTerm subject, SerializationContext context) =>
      _mapper;

  @override
  Deserializer<T> deserializer(
          IriTerm subject, DeserializationContext context) =>
      _mapper;
}
