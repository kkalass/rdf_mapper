import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_vocabularies_core/rdf.dart';

/// A literal term mapper that applies a language tag to string values.
///
/// This mapper acts as a decorator around existing literal term mappers, allowing
/// you to assign language tags to string values while delegating the actual
/// value conversion to the underlying mapper system. All language-tagged literals
/// use the `rdf:langString` datatype as per RDF specifications.
///
/// ## Primary Use Case - Annotation Generator
///
/// This class is **primarily designed for use by the annotation generator** to implement
/// `@RdfProperty(predicate, literal: LiteralMapping.withLanguage('en'))` annotations.
///
/// The annotation generator automatically creates instances of this mapper when you specify
/// language tags in your annotations, handling the correct usage patterns internally.
///
/// ## Manual Usage Scenarios
///
/// While primarily used by the annotation system, you may also use this mapper directly for:
/// - **Internationalization**: Create localized string values with proper language tags
/// - **Multilingual Content**: Support content in multiple languages within the same dataset
/// - **Standards Compliance**: Follow RDF best practices for language-specific content
/// - **Search Optimization**: Enable language-specific queries and filtering
///
/// ## Behavior
///
/// During **serialization** (`toRdfTerm`):
/// 1. Delegates value conversion to the existing mapper for type `T`
/// 2. Creates a language-tagged literal with the specified [language]
/// 3. Sets the datatype to `rdf:langString` as per RDF standards
///
/// During **deserialization** (`fromRdfTerm`):
/// 1. Validates that the input literal has datatype `rdf:langString`
/// 2. Delegates parsing to the existing mapper with datatype checking bypassed
/// 3. Returns the parsed value of type `T` (language information is handled separately)
///
/// ## Example - Annotation Usage (Typical)
///
/// ```dart
/// class LocalizedContent {
///   // Annotation generator creates LanguageOverrideMapper internally
///   @RdfProperty(Schema.name, literal: LiteralMapping.withLanguage('en'))
///   final String englishName;
///
///   @RdfProperty(Schema.name, literal: LiteralMapping.withLanguage('de'))
///   final String germanName;
///
///   const LocalizedContent(this.englishName, this.germanName);
/// }
///
/// // The annotation system handles the mapping automatically:
/// // - Serialization: "Hello" -> "Hello"@en, "Hallo" -> "Hallo"@de
/// // - Deserialization: validates rdf:langString datatype and parses back to String
/// ```
///
/// ## Example - Manual Usage (Advanced)
///
/// ```dart
/// // Create mappers for different languages
/// final englishMapper = LanguageOverrideMapper<String>('en');
/// final germanMapper = LanguageOverrideMapper<String>('de');
///
/// // Use with ResourceBuilder (manual serialization)
/// builder.addValue(Schema.name, "Hello World", serializer: englishMapper);
/// // Results in: "Hello World"@en
///
/// builder.addValue(Schema.name, "Hallo Welt", serializer: germanMapper);
/// // Results in: "Hallo Welt"@de
///
/// // Use with ResourceReader (manual deserialization)
/// final englishText = reader.require<String>(Schema.name, deserializer: englishMapper);
/// // Validates rdf:langString datatype and returns: "Hello World" (as String)
/// ```
///
/// ## Language Tag Format
///
/// Language tags should follow RFC 5646 (BCP 47) specifications:
/// - `'en'` - English
/// - `'en-US'` - American English
/// - `'de'` - German
/// - `'fr-CA'` - Canadian French
/// - `'zh-Hans'` - Simplified Chinese
///
/// ## Error Handling
///
/// - Throws [DeserializerDatatypeMismatchException] if the input literal's datatype
///   is not `rdf:langString` (unless `bypassDatatypeCheck` is true)
/// - Throws [DeserializationException] if the underlying value parsing fails
///
/// ## Notes
///
/// - The mapper requires that a suitable mapper for type `T` is already registered
/// - Type `T` is typically String but can be any type that makes sense with language tags
/// - Language information from the input literal is not preserved in the output value
/// - Use separate mappers for different languages rather than trying to extract language from input
///
/// ## ⚠️ CRITICAL WARNING - Do NOT Register in ANY Registry
///
/// **NEVER** register this mapper in ANY `RdfMapperRegistry` including:
/// - `RdfMapper.registerMapper()` ❌
/// - `RdfMapperRegistry.registerMapper()` ❌
/// - `RdfMapper.withMappers()` ❌
/// - Local registry instances (even after `.clone()`) ❌
///
/// This mapper delegates to the registry system via `context.fromLiteralTerm<T>()` and
/// `context.toLiteralTerm<T>()`, so ANY registry registration creates infinite recursion!
///
/// **✅ CORRECT Usage - Explicit Serializer/Deserializer Parameters Only:**
/// ```dart
/// // With ResourceBuilder for serialization
/// final builder = context.resourceBuilder(subject);
/// builder.addValue(predicate, value, serializer: languageMapper);
///
/// // With ResourceReader for deserialization
/// final reader = context.reader(subject);
/// final value = reader.require<String>(predicate, deserializer: languageMapper);
///
/// // Direct context usage (less common)
/// context.fromLiteralTerm<String>(term, deserializer: languageMapper);
/// context.toLiteralTerm(value, serializer: languageMapper);
/// ```
///
/// **❌ INCORRECT Usage - Will Cause Stack Overflow:**
/// ```dart
/// // ALL of these cause infinite recursion!
/// rdfMapper.registerMapper<String>(mapper);                    // ❌
/// registry.registerMapper<String>(mapper);                     // ❌
/// RdfMapper.withMappers((r) => r.registerMapper<String>(mapper)); // ❌
/// localRegistry.registerMapper<String>(mapper);                // ❌
/// ```
final class LanguageOverrideMapper<T> implements LiteralTermMapper<T> {
  /// The language tag to apply to literal terms.
  ///
  /// This should be a valid language tag following RFC 5646 (BCP 47) format,
  /// such as 'en', 'de', 'en-US', 'fr-CA', etc.
  final String language;

  final IriTerm datatype = Rdf.langString;

  /// Creates a language override mapper with the specified [language] tag.
  ///
  /// The [language] should be a valid RFC 5646 language tag that will be
  /// applied to all literal terms produced by [toRdfTerm].
  const LanguageOverrideMapper(this.language);

  /// Deserializes a language-tagged literal term to a Dart value of type [T].
  ///
  /// Validates that the [term]'s datatype is `rdf:langString`, then delegates
  /// the actual value parsing to the registered mapper for type [T]. The language
  /// tag information is handled by this mapper and not passed to the underlying parser.
  ///
  /// Parameters:
  /// * [term] - The RDF literal term to deserialize (should have datatype `rdf:langString`)
  /// * [context] - The deserialization context providing access to other mappers
  /// * [bypassDatatypeCheck] - If true, skips `rdf:langString` validation (use with caution)
  ///
  /// Returns the parsed value of type [T].
  ///
  /// Throws:
  /// * [DeserializerDatatypeMismatchException] if datatype is not `rdf:langString` and checking is enabled
  /// * [DeserializationException] if the underlying value parsing fails
  @override
  T fromRdfTerm(LiteralTerm term, DeserializationContext context,
      {bool bypassDatatypeCheck = false}) {
    if (!bypassDatatypeCheck && term.datatype != datatype) {
      throw DeserializerDatatypeMismatchException(
          'Failed to parse ${T.toString()}: ${term.value}. ',
          actual: term.datatype,
          expected: datatype,
          targetType: T,
          mapperRuntimeType: this.runtimeType);
    }
    try {
      // we handle the datatype ourselves
      return context.fromLiteralTerm<T>(
        term,
        bypassDatatypeCheck: true,
      );
    } catch (e) {
      throw DeserializationException(
        'Failed to parse ${T.toString()}: ${term.value}. Error: $e',
      );
    }
  }

  /// Serializes a Dart value to a language-tagged RDF literal term.
  ///
  /// Converts the [value] to its string representation using the registered mapper
  /// for type [T], then creates a language-tagged literal with the specified [language].
  /// The resulting literal will have datatype `rdf:langString`.
  ///
  /// Parameters:
  /// * [value] - The Dart value to serialize
  /// * [context] - The serialization context providing access to other mappers
  ///
  /// Returns a [LiteralTerm] with the value's string representation and language tag.
  LiteralTerm toRdfTerm(T value, SerializationContext context) {
    var term = context.toLiteralTerm(
      value,
    );
    return LiteralTerm.withLanguage(term.value, language);
  }
}
