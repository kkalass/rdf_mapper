import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';

/// Abstract base class for mapping Dart objects to RDF literal terms with strict datatype validation.
///
/// This class provides type-safe mapping between Dart values and RDF literals, enforcing datatype
/// consistency to ensure roundtrip reliability and semantic preservation.
///
/// ## Quick Start
///
/// Extend this class to create custom literal mappers:
///
/// ```dart
/// final class CustomDateMapper extends BaseRdfLiteralTermMapper<CustomDate> {
///   const CustomDateMapper([IriTerm? datatype])
///       : super(datatype: datatype ?? Xsd.date);
///
///   @override
///   CustomDate convertFromLiteral(LiteralTerm term, DeserializationContext context) {
///     return CustomDate.parse(term.value);
///   }
///
///   @override
///   String convertToString(CustomDate value) => value.toIsoString();
/// }
/// ```
///
/// ## Why Datatype Strictness?
///
/// Datatype strictness ensures roundtrip consistency - your Dart objects will serialize back
/// to the same RDF datatype, preserving semantic meaning and preventing data corruption.
///
/// ## Handling Different RDF Datatypes
///
/// When your RDF data uses non-standard datatypes, you have several options:
///
/// ### 1. Global Registration (affects ALL instances of the type)
/// ```dart
/// final rdfMapper = RdfMapper.withMappers((registry) =>
///   registry.registerMapper<double>(DoubleMapper(Xsd.double)));
/// ```
///
/// ### 2. Create Custom Wrapper Types (recommended for type safety)
///
/// **Annotations approach:**
/// ```dart
/// @RdfLiteral(Xsd.double)
/// class Temperature {
///   @RdfValue()
///   final double celsius;
///   const Temperature(this.celsius);
/// }
/// ```
///
/// **Manual approach:**
/// ```dart
/// class Temperature {
///   final double celsius;
///   const Temperature(this.celsius);
/// }
///
/// class TemperatureMapper extends DelegatingRdfLiteralTermMapper<Temperature, double> {
///   const TemperatureMapper() : super(const DoubleMapper(), Xsd.double);
///
///   @override
///   Temperature convertFrom(double value) => Temperature(value);
///
///   @override
///   double convertTo(Temperature value) => value.celsius;
/// }
/// ```
///
/// ### 3. Local Scope Solutions (for specific predicates)
///
/// **Annotations approach (simpler option):**
/// ```dart
/// @RdfProperty(myPredicate, literal: const LiteralMapping.withType(Xsd.double))
/// double? myProperty;
/// ```
///
/// **Annotations approach (mapper instance):**
/// ```dart
/// @RdfProperty(myPredicate,
///     literal: LiteralMapping.mapperInstance(DoubleMapper(Xsd.double)))
/// double? myProperty;
/// ```
///
/// **Manual approach:**
/// ```dart
/// reader.require(myPredicate, deserializer: DoubleMapper(Xsd.double));
/// builder.addValue(myPredicate, myValue, serializer: DoubleMapper(Xsd.double));
/// ```
///
/// ### 4. Bypass Datatype Check (use carefully)
/// ```dart
/// context.fromLiteralTerm(term, bypassDatatypeCheck: true);
/// ```
///
/// ## Implementation Requirements
///
/// Subclasses must implement:
/// - `convertFromLiteral()`: Parse RDF literal string to Dart object
/// - `convertToString()`: Convert Dart object to RDF literal string
abstract class BaseRdfLiteralTermMapper<T> implements LiteralTermMapper<T> {
  /// The RDF datatype this mapper handles
  final IriTerm datatype;

  /// Creates a mapper for the specified RDF datatype.
  ///
  /// [datatype] The RDF datatype IRI that this mapper produces and expects
  const BaseRdfLiteralTermMapper({
    required IriTerm datatype,
  }) : this.datatype = datatype;

  /// Converts an RDF literal term to a Dart value of type T.
  ///
  /// Subclasses must implement this method to handle the actual conversion logic.
  /// This method is called after datatype validation has passed.
  ///
  /// [term] The RDF literal term to convert
  /// [context] The deserialization context for accessing additional services
  ///
  /// Returns the converted Dart value
  /// Throws [DeserializationException] if conversion fails
  T convertFromLiteral(LiteralTerm term, DeserializationContext context);

  /// Converts an RDF literal term to a value of type T.
  ///
  /// This implementation:
  /// 1. Verifies that the literal's datatype matches the expected datatype
  /// 2. Attempts to convert the literal value using the provided conversion function
  /// 3. Wraps any conversion errors in a descriptive DeserializationException
  ///
  /// @param term The literal term to convert
  /// @param context The deserialization context
  /// @return The converted value of type T
  /// @throws DeserializationException if the datatype doesn't match or conversion fails
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
      return convertFromLiteral(term, context);
    } catch (e) {
      throw DeserializationException(
        'Failed to parse ${T.toString()}: ${term.value}. Error: $e',
      );
    }
  }

  /// Converts a Dart value of type T to its RDF literal string representation.
  ///
  /// Subclasses must implement this method to handle the actual string conversion logic.
  /// This method is called during serialization after type validation and before creating
  /// the final RDF literal term with the appropriate datatype.
  ///
  /// The string representation should:
  /// - Follow the lexical format expected by the associated RDF datatype
  /// - Be parseable by the corresponding `convertFromLiteral` method for roundtrip consistency
  /// - Conform to RDF/XML and Turtle serialization requirements
  ///
  /// ## Implementation Guidelines
  ///
  /// - **Preserve Precision**: Ensure numeric values maintain their precision
  /// - **Handle Edge Cases**: Consider null, empty, or special values appropriately
  /// - **Follow Standards**: Use standard lexical representations when available
  /// - **Optimize Performance**: Keep conversions efficient for large datasets
  ///
  /// ## Examples
  ///
  /// ```dart
  /// // For DoubleMapper
  /// @override
  /// String convertToString(double value) => value.toString();
  ///
  /// // For BoolMapper
  /// @override
  /// String convertToString(bool value) => value.toString(); // "true" or "false"
  ///
  /// // For DateTimeMapper
  /// @override
  /// String convertToString(DateTime value) => value.toUtc().toIso8601String();
  ///
  /// // For custom types with specific formatting
  /// @override
  /// String convertToString(Temperature value) => value.celsius.toStringAsFixed(2);
  /// ```
  ///
  /// [value] The Dart value to convert to string representation
  ///
  /// Returns the string representation suitable for RDF literal values
  /// Should not throw exceptions - handle edge cases gracefully
  String convertToString(T value);

  /// Converts a value to an RDF literal term.
  ///
  /// This implementation:
  /// 1. Converts the value to a string using the provided conversion function
  /// 2. Creates a literal term with that string value and the configured datatype
  ///
  /// @param value The value to convert
  /// @param context The serialization context (unused in this implementation)
  /// @return A literal term representing the value
  @override
  LiteralTerm toRdfTerm(T value, SerializationContext context) {
    return LiteralTerm(convertToString(value), datatype: datatype);
  }
}
