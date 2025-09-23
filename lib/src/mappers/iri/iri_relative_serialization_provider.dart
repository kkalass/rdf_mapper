import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';

/// Serialization provider for IRI-relative string mapping with contextual base URI resolution.
///
/// This provider creates IRI relative serializers and deserializers that automatically
/// use the subject IRI as the base URI for relative IRI resolution. It's primarily designed
/// for **code generation scenarios** and generic factory patterns where the base URI is not
/// known at compile time.
///
/// **For hand-written code**, directly using `IriRelativeSerializer(subject.value)` and
/// `IriRelativeDeserializer(subject.value)` is usually simpler and more straightforward.
///
/// ## Key Features
///
/// - **Automatic Base URI Resolution**: Uses the subject IRI as base URI for each serialization/deserialization
/// - **Code Generation Friendly**: Perfect for generated mappers that need to adapt to different contexts
/// - **Type-Safe Contextual Mapping**: Works with any parent type [D] while maintaining type safety
/// - **Zero Configuration**: No need to manually pass base URIs - automatically inferred from context
///
/// ## Common Use Cases
///
/// ### Code Generation and Generic Factories
/// This provider is primarily designed for **code generation scenarios** where mappers
/// need to be created dynamically based on context. It's especially useful when:
/// - Generating mappers that adapt to different document contexts automatically
/// - Building generic factories that don't know the base URI at compile time
/// - Creating reusable mapping patterns for document-based RDF structures
///
/// ```dart
/// // Example: Code-generated mapper that adapts to any document context
/// class GeneratedPersonMapper implements GlobalResourceMapper<Person> {
///   static const _photoProvider = IriRelativeSerializationProvider<Person>();
///
///   @override
///   Person fromRdfResource(IriTerm subject, DeserializationContext context) {
///     final reader = context.reader(subject);
///     return Person(
///       id: subject.value,
///       name: reader.require<String>(FoafPerson.name),
///       // Automatically uses subject IRI as base - no hardcoded URIs!
///       photoPath: reader.optional<String>(
///         FoafPerson.image,
///         deserializer: _photoProvider.deserializer(subject, context)
///       ),
///     );
///   }
///
///   @override
///   (IriTerm, Iterable<Triple>) toRdfResource(Person person, SerializationContext context, {RdfSubject? parentSubject}) {
///     final subject = const IriTerm(person.id);
///     return context
///         .resourceBuilder(subject)
///         .addValue(FoafPerson.name, person.name)
///         .addValueIfNotNull(
///           FoafPerson.image,
///           person.photoPath,
///           serializer: _photoProvider.serializer(person, subject, context)
///         )
///         .build();
///   }
/// }
/// ```
///
/// ### Alternative: Direct Usage (Simpler for Hand-Written Code)
/// For hand-written mappers where you know the context, direct instantiation is simpler:
/// ```dart
/// // Simpler approach for hand-written code:
/// photoPath: reader.optional<String>(
///   FoafPerson.image,
///   deserializer: IriRelativeDeserializer(subject.value)
/// ),
/// ```
///
/// ## Behavior
///
/// - **Serialization**: Converts relative IRI strings to absolute IRI terms using subject IRI as base
/// - **Deserialization**: Converts absolute IRI terms to relative IRI strings when possible
/// - **Base URI**: Always uses the current subject IRI as the base URI for resolution
/// - **Fallback**: If an IRI cannot be relativized, returns the absolute IRI string
///
/// ## Example RDF Mapping
///
/// With person IRI `https://alice.example/profile#me`:
/// ```turtle
/// <https://alice.example/profile#me> a foaf:Person ;
///     foaf:name "Alice Smith" ;
///     foaf:img <https://alice.example/photos/avatar.jpg> .  # Absolute in RDF
/// ```
///
/// The `photoPath` field in the Person object would contain `"photos/avatar.jpg"` (relative string),
/// while the RDF contains the absolute IRI `<https://alice.example/photos/avatar.jpg>`.
///
/// This allows your Dart objects to use clean, portable relative paths while maintaining
/// absolute IRIs in the RDF representation for proper semantic web compatibility.
///
/// ## Type Parameters
/// - [D] The parent/document type that provides context for the serialization
final class IriRelativeSerializationProvider<D>
    implements SerializationProvider<D, String> {
  /// Creates a new IRI relative serialization provider.
  ///
  /// This provider automatically uses the subject IRI as the base URI for
  /// IRI relative serialization and deserialization operations.
  const IriRelativeSerializationProvider();

  /// Creates a deserializer that relativizes IRIs against the subject IRI.
  ///
  /// The returned deserializer will attempt to express absolute IRI terms
  /// as relative strings using the [subject] IRI as the base URI.
  ///
  /// Parameters:
  /// - [subject]: The subject IRI that serves as the base URI for relativization
  /// - [context]: The deserialization context (passed through but not used)
  ///
  /// Returns an [IriRelativeDeserializer] configured with the subject IRI as base.
  @override
  Deserializer<String> deserializer(
      IriTerm subject, DeserializationContext context) {
    return IriRelativeDeserializer(subject.value);
  }

  /// Creates a serializer that resolves relative IRIs against the subject IRI.
  ///
  /// The returned serializer will resolve relative IRI strings to absolute
  /// IRI terms using the [subject] IRI as the base URI.
  ///
  /// Parameters:
  /// - [parent]: The parent object providing context (passed through but not used)
  /// - [subject]: The subject IRI that serves as the base URI for resolution
  /// - [context]: The serialization context (passed through but not used)
  ///
  /// Returns an [IriRelativeSerializer] configured with the subject IRI as base.
  @override
  Serializer<String> serializer(
      D parent, IriTerm subject, SerializationContext context) {
    return IriRelativeSerializer(subject.value);
  }
}
