import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_vocabularies_core/xsd.dart';

/// Mapper for converting between Dart `double` values and RDF decimal literals.
///
/// This mapper handles the conversion between Dart's `double` type and RDF literals
/// with `xsd:decimal` datatype by default. It can be configured to use custom datatypes
/// for specialized use cases.
///
/// ## Default Behavior
/// - **Dart Type**: `double`
/// - **Default RDF Datatype**: `xsd:decimal`
/// - **Serialization**: Converts double to string representation
/// - **Deserialization**: Parses string to double using `double.parse()`
///
/// ## Custom Datatype Usage
///
/// When working with RDF data that uses non-standard datatypes for numeric values:
///
/// ```dart
/// // For data using xsd:double instead of xsd:decimal
/// final customMapper = DoubleMapper(Xsd.double);
///
/// // Register globally
/// final rdfMapper = RdfMapper.withMappers((registry) =>
///   registry.registerMapper<double>(customMapper));
///
/// // Or use locally for specific predicates
/// reader.require(temperaturePredicate,
///   deserializer: DoubleMapper(Xsd.double));
/// ```
///
/// ## Datatype Strictness
///
/// This mapper enforces datatype consistency by default. If you encounter a
/// `DeserializerDatatypeMismatchException`, it means the RDF data uses a different
/// datatype than expected. The exception provides detailed guidance on resolution options.
///
/// ## Example RDF Mapping
///
/// ```turtle
/// @prefix ex: <http://example.org/> .
/// @prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
///
/// ex:temperature "23.5"^^xsd:decimal .
/// ex:altitude "1234.56"^^xsd:double .  # Requires custom mapper
/// ```
final class DoubleMapper extends BaseRdfLiteralTermMapper<double> {
  /// Creates a double mapper with the specified datatype.
  ///
  /// [datatype] The RDF datatype to use. Defaults to `xsd:decimal`.
  const DoubleMapper([IriTerm? datatype])
      : super(
          datatype: datatype ?? Xsd.decimal,
        );

  @override
  convertFromLiteral(term, context) => double.parse(term.value);

  @override
  convertToString(d) => d.toString();
}
