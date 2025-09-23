import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';

/// A literal term mapper that overrides the default datatype with a custom one.
///
/// This mapper acts as a decorator around existing literal term mappers, allowing
/// you to assign custom RDF datatypes to values while delegating the actual
/// value conversion to the underlying mapper system.
///
/// ## Primary Use Case - Annotation Generator
///
/// This class is **primarily designed for use by the annotation generator** to implement
/// `@RdfProperty(predicate, literal: LiteralMapping.withType(customDatatype))` annotations.
///
/// The annotation generator automatically creates instances of this mapper when you specify
/// custom datatypes in your annotations, handling the correct usage patterns internally.
///
/// ## Manual Usage Scenarios
///
/// While primarily used by the annotation system, you may also use this mapper directly for:
/// - **Custom Semantic Types**: Create domain-specific datatypes for better semantic meaning
/// - **Legacy System Integration**: Map to datatypes expected by existing RDF vocabularies
/// - **Type Safety**: Ensure specific datatypes are used for certain value types
/// - **Interoperability**: Match datatypes required by external systems or standards
///
/// ## Behavior
///
/// During **serialization** (`toRdfTerm`):
/// 1. Delegates value conversion to the existing mapper for type `T`
/// 2. Overrides the resulting literal's datatype with the custom [datatype]
/// 3. Preserves the string representation of the value
///
/// During **deserialization** (`fromRdfTerm`):
/// 1. Validates that the input literal has the expected custom [datatype]
/// 2. Delegates parsing to the existing mapper with datatype checking bypassed
/// 3. Returns the parsed value of type `T`
///
/// ## Example - Annotation Usage (Typical)
///
/// ```dart
/// class Measurement {
///   // Annotation generator creates DatatypeOverrideMapper internally
///   @RdfProperty(Schema.temperature, literal: LiteralMapping.withType('http://qudt.org/vocab/unit/CEL'))
///   final double celsius;
///
///   const Measurement(this.celsius);
/// }
///
/// // The annotation system handles the mapping automatically:
/// // - Serialization: 23.5 -> "23.5"^^<http://qudt.org/vocab/unit/CEL>
/// // - Deserialization: validates datatype and parses back to double
/// ```
///
/// ## Example - Manual Usage (Advanced)
///
/// ```dart
/// // Define a custom datatype for temperature values
/// final celsiusType = const IriTerm('http://qudt.org/vocab/unit/CEL');
///
/// // Create a mapper that treats doubles as Celsius temperatures
/// final temperatureMapper = DatatypeOverrideMapper<double>(celsiusType);
///
/// // Use with ResourceBuilder (manual serialization)
/// builder.addValue(Schema.temperature, 23.5, serializer: temperatureMapper);
/// // Results in: "23.5"^^<http://qudt.org/vocab/unit/CEL>
///
/// // Use with ResourceReader (manual deserialization)
/// final celsius = reader.require<double>(Schema.temperature, deserializer: temperatureMapper);
/// // Validates datatype and returns: 23.5 (as double)
/// ```
///
/// ## Error Handling
///
/// - Throws [DeserializerDatatypeMismatchException] if the input literal's datatype
///   doesn't match the expected custom datatype (unless `bypassDatatypeCheck` is true)
/// - Throws [DeserializationException] if the underlying value parsing fails
///
/// ## Notes
///
/// - The mapper requires that a suitable mapper for type `T` is already registered
/// - Type `T` should be a simple value type (String, int, double, bool, DateTime, etc.)
/// - Complex object types should use [GlobalResourceMapper] or [LocalResourceMapper] instead
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
/// builder.addValue(predicate, value, serializer: customMapper);
///
/// // With ResourceReader for deserialization
/// final reader = context.reader(subject);
/// final value = reader.require<String>(predicate, deserializer: customMapper);
///
/// // Direct context usage (less common)
/// context.fromLiteralTerm<String>(term, deserializer: customMapper);
/// context.toLiteralTerm(value, serializer: customMapper);
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
final class DatatypeOverrideMapper<T> implements LiteralTermMapper<T> {
  /// The custom RDF datatype IRI that this mapper produces and expects.
  ///
  /// This datatype will be applied to all literal terms produced by [toRdfTerm]
  /// and is required to match for successful deserialization in [fromRdfTerm].
  final IriTerm datatype;

  /// Creates a datatype override mapper with the specified custom [datatype].
  ///
  /// The [datatype] should be a valid IRI term representing the custom RDF datatype
  /// that will be applied to literal values of type [T].
  const DatatypeOverrideMapper(this.datatype);

  /// Deserializes a literal term to a Dart value of type [T].
  ///
  /// Validates that the [term]'s datatype matches the expected custom [datatype],
  /// then delegates the actual value parsing to the registered mapper for type [T].
  ///
  /// Parameters:
  /// * [term] - The RDF literal term to deserialize
  /// * [context] - The deserialization context providing access to other mappers
  /// * [bypassDatatypeCheck] - If true, skips datatype validation (use with caution)
  ///
  /// Returns the parsed value of type [T].
  ///
  /// Throws:
  /// * [DeserializerDatatypeMismatchException] if datatype doesn't match and checking is enabled
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

  /// Serializes a Dart value to an RDF literal term with the custom datatype.
  ///
  /// Converts the [value] to its string representation using the registered mapper
  /// for type [T], then creates a new literal term with the custom [datatype].
  ///
  /// Parameters:
  /// * [value] - The Dart value to serialize
  /// * [context] - The serialization context providing access to other mappers
  ///
  /// Returns a [LiteralTerm] with the value's string representation and custom datatype.
  LiteralTerm toRdfTerm(T value, SerializationContext context) {
    var term = context.toLiteralTerm(
      value,
    );
    return LiteralTerm(term.value, datatype: datatype);
  }
}
