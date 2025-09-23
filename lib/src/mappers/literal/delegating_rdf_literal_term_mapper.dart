import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';

/// Abstract base class for creating custom wrapper types that delegate to existing mappers
/// but use different RDF datatypes.
///
/// This class is particularly useful when you need to map a Dart type to a non-standard
/// RDF datatype while reusing the existing conversion logic of a standard mapper.
/// It ensures roundtrip consistency by preserving the custom datatype during serialization.
///
/// ## Use Cases
///
/// - Mapping standard Dart types (int, double, String, etc.) to custom RDF datatypes
/// - Creating domain-specific wrapper types with semantic meaning
/// - Handling legacy RDF data that uses non-standard datatypes
/// - Maintaining strict datatype consistency in RDF stores
///
/// ## Implementation Examples
///
/// ### Basic Custom Double Wrapper
/// ```dart
/// // Custom wrapper class
/// class Temperature {
///   final double celsius;
///   const Temperature(this.celsius);
/// }
///
/// // Custom mapper using Celsius datatype
/// class TemperatureMapper extends DelegatingRdfLiteralTermMapper<Temperature, double> {
///   static final celsiusDatatype = const IriTerm('http://qudt.org/vocab/unit/CEL');
///
///   const TemperatureMapper() : super(const DoubleMapper(), celsiusDatatype);
///
///   @override
///   Temperature convertFrom(double value) => Temperature(value);
///
///   @override
///   double convertTo(Temperature value) => value.celsius;
/// }
///
/// // Registration
/// final rdfMapper = RdfMapper.withMappers((registry) =>
///   registry.registerMapper<Temperature>(TemperatureMapper()));
/// ```
///
/// ## Datatype Strictness
///
/// This mapper enforces datatype strictness by default to ensure roundtrip consistency.
/// When a custom type is serialized back to RDF, it maintains the same datatype as specified
/// in the constructor, preserving semantic meaning and preventing data corruption.
///
/// Use the `bypassDatatypeCheck` parameter only when flexible datatype handling is required,
/// but be aware this may break roundtrip guarantees.
abstract class DelegatingRdfLiteralTermMapper<T, V>
    implements LiteralTermMapper<T> {
  /// The underlying mapper that handles the actual conversion logic
  final LiteralTermMapper<V> mapper;

  /// The custom RDF datatype that this mapper produces and expects
  final IriTerm datatype;

  /// Creates a delegating mapper with the specified underlying mapper and custom datatype.
  ///
  /// [mapper] The mapper to delegate conversion logic to
  /// [datatype] The RDF datatype to use for serialization and expect during deserialization
  const DelegatingRdfLiteralTermMapper(this.mapper, this.datatype);

  /// Converts from the underlying type V to the custom wrapper type T.
  ///
  /// This method is called after the underlying mapper has successfully
  /// converted the RDF literal to type V.
  T convertFrom(V value);

  /// Converts from the custom wrapper type T to the underlying type V.
  ///
  /// This method is called before the underlying mapper converts
  /// the value to an RDF literal string.
  V convertTo(T value);

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
      var value = mapper.fromRdfTerm(term, context, bypassDatatypeCheck: true);
      return convertFrom(value);
    } catch (e) {
      throw DeserializationException(
        'Failed to parse ${T.toString()}: ${term.value}. Error: $e',
      );
    }
  }

  LiteralTerm toRdfTerm(T value, SerializationContext context) {
    var term = mapper.toRdfTerm(convertTo(value), context);
    return LiteralTerm(term.value, datatype: datatype);
  }
}
