import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_vocabularies_core/xsd.dart';

/// Mapper for converting between Dart `bool` values and RDF boolean literals.
///
/// This mapper handles the conversion between Dart's `bool` type and RDF literals
/// with `xsd:boolean` datatype by default. It supports both standard boolean
/// representations ('true'/'false') and numeric representations ('1'/'0').
///
/// ## Default Behavior
/// - **Dart Type**: `bool`
/// - **Default RDF Datatype**: `xsd:boolean`
/// - **Accepted Values**: 'true', 'false', '1', '0' (case-insensitive)
/// - **Serialization**: Converts bool to 'true' or 'false' string
///
/// ## Custom Datatype Usage
///
/// For RDF data using custom boolean datatypes:
///
/// ```dart
/// final customDatatype = const IriTerm('http://example.org/custom-boolean');
/// final customMapper = BoolMapper(customDatatype);
///
/// // Register globally or use locally
/// final rdfMapper = RdfMapper.withMappers((registry) =>
///   registry.registerMapper<bool>(customMapper));
/// ```
///
/// ## Example RDF Mapping
///
/// ```turtle
/// @prefix ex: <http://example.org/> .
/// @prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
///
/// ex:isActive "true"^^xsd:boolean .
/// ex:isVisible "1"^^xsd:boolean .     # Also valid
/// ex:isEnabled "false"^^xsd:boolean .
/// ```
final class BoolMapper extends BaseRdfLiteralTermMapper<bool> {
  /// Creates a boolean mapper with the specified datatype.
  ///
  /// [datatype] The RDF datatype to use. Defaults to `xsd:boolean`.
  const BoolMapper([IriTerm? datatype])
      : super(
          datatype: datatype ?? Xsd.boolean,
        );

  @override
  convertFromLiteral(term, _) {
    final value = term.value.toLowerCase();

    if (value == 'true' || value == '1') {
      return true;
    } else if (value == 'false' || value == '0') {
      return false;
    }

    throw DeserializationException(
      'Failed to parse boolean: ${term.value}',
    );
  }

  @override
  convertToString(b) => b.toString();
}
