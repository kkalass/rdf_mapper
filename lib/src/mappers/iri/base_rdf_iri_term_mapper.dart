import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';

/// Abstract base class for mapping Dart objects to RDF IRI terms using URI templates.
///
/// This class provides a flexible way to map enum values or other objects to IRIs
/// using URI templates with placeholders. It supports placeholders
/// (provided via resolvePlaceholder or resolved from the object value).
///
/// ## Quick Start
///
/// Simple enum to IRI mapping:
/// ```dart
/// class StatusMapper extends BaseRdfIriTermMapper<Status> {
///   const StatusMapper() : super('https://example.org/status/{value}', 'value');
///
///   @override
///   String convertToString(Status status) => status.name;
///
///   @override
///   Status convertFromString(String value) => Status.values.byName(value);
/// }
/// ```
///
/// Template with multiple placeholders:
/// ```dart
/// class StatusMapper extends BaseRdfIriTermMapper<Status> {
///   final String Function() baseUriProvider;
///
///   StatusMapper(this.baseUriProvider)
///     : super('{+baseUri}/status/{value}', 'value');
///
///   @override
///   String resolvePlaceholder(String placeholderName) {
///     switch (placeholderName) {
///       case 'baseUri': return baseUriProvider();
///       default: return super.resolvePlaceholder(placeholderName);
///     }
///   }
///
///   @override
///   String convertToString(Status status) => status.name;
///
///   @override
///   Status convertFromString(String value) => Status.values.byName(value);
/// }
/// ```
///
/// ## Template Syntax
///
/// - `{variableName}`: Simple placeholder for path segments (no slashes allowed)
/// - `{+variableName}`: Full URI placeholder (slashes allowed)
/// - The `valueVariableName` parameter specifies which placeholder represents the object value
/// - All other placeholders must be provided via `resolvePlaceholder()`
///
/// ## Implementation Requirements
///
/// Subclasses must implement:
/// - `convertToString()`: Convert object to string for the value placeholder
/// - `convertFromString()`: Convert string from value placeholder back to object
/// - `resolvePlaceholder()`: Provide values for extra placeholders (optional, has default implementation)
abstract class BaseRdfIriTermMapper<T> implements IriTermMapper<T> {
  /// The URI template with placeholders
  final String template;

  /// The name of the placeholder that represents the object value
  final String valueVariableName;

  /// Creates a mapper for the specified URI template.
  ///
  /// [template] The URI template with placeholders (e.g., 'https://example.org/{category}/{value}')
  /// [valueVariableName] The name of the placeholder that represents the object value
  const BaseRdfIriTermMapper(
    this.template,
    this.valueVariableName,
  );

  /// Provides values for extra placeholders in the template.
  ///
  /// This method is called for each placeholder in the template (except for the value placeholder).
  /// Subclasses should override this method to provide values for any extra placeholders they use.
  ///
  /// The default implementation throws an ArgumentError with a helpful message.
  ///
  /// [placeholderName] The name of the placeholder that needs a value
  /// Returns the string value to substitute for the placeholder
  /// Throws [ArgumentError] if the placeholder is not supported
  String resolvePlaceholder(String placeholderName) {
    throw ArgumentError(
      'No value provided for placeholder "$placeholderName". '
      'Override resolvePlaceholder() to provide values for extra placeholders.',
    );
  }

  /// Global cache for compiled extraction patterns to optimize performance.
  ///
  /// Uses template + valueVariableName as key since the pattern depends on both.
  static final Map<String, RegExp> _patternCache = <String, RegExp>{};

  /// Gets the extraction pattern, using cache for optimal performance.
  RegExp get _extractionPattern {
    final cacheKey = '$template|$valueVariableName';
    return _patternCache.putIfAbsent(cacheKey, _buildExtractionPattern);
  }

  /// Builds the regex pattern for extracting values from IRIs.
  RegExp _buildExtractionPattern() {
    final placeholderRegex = RegExp(r'\{(\+?)([^}]+)\}');
    final matches = placeholderRegex.allMatches(template);

    // Validate that valueVariableName exists in template
    final placeholderNames = matches.map((match) => match.group(2)!).toList();
    if (!placeholderNames.contains(valueVariableName)) {
      throw ArgumentError(
          'Value variable "$valueVariableName" not found in template "$template"');
    }

    // Build regex pattern for extracting values
    String pattern = RegExp.escape(template);

    for (final match in matches.toList().reversed) {
      final isFullUri = match.group(1) == '+';
      final placeholderName = match.group(2)!;
      final fullMatch = match.group(0)!;

      // Replace placeholder with appropriate capture group
      final captureGroup = placeholderName == valueVariableName
          ? isFullUri
              ? '(.*)'
              : '([^/]*)' // Named capture for value
          : isFullUri
              ? '.*'
              : '[^/]*'; // Non-capturing for static values

      pattern = pattern.replaceFirst(RegExp.escape(fullMatch), captureGroup);
    }

    return RegExp('^$pattern\$');
  }

  /// Converts a Dart object to a string representation for the value placeholder.
  ///
  /// This method is called during serialization to get the string that will
  /// be substituted for the value placeholder in the URI template.
  ///
  /// [value] The Dart object to convert
  /// Returns the string representation to use in the IRI
  String convertToString(T value);

  /// Converts a string from the value placeholder back to a Dart object.
  ///
  /// This method is called during deserialization to reconstruct the Dart object
  /// from the string extracted from the value placeholder in the IRI.
  ///
  /// [valueString] The string extracted from the IRI's value placeholder
  /// Returns the reconstructed Dart object
  T convertFromString(String valueString);

  @override
  IriTerm toRdfTerm(T value, SerializationContext context) {
    String iri = template;

    // Replace all placeholders
    final placeholderRegex = RegExp(r'\{(\+?)([^}]+)\}');
    iri = iri.replaceAllMapped(placeholderRegex, (match) {
      final placeholderName = match.group(2)!;

      if (placeholderName == valueVariableName) {
        return convertToString(value);
      } else {
        return resolvePlaceholder(placeholderName);
      }
    });

    return context.createIriTerm(iri);
  }

  @override
  T fromRdfTerm(IriTerm term, DeserializationContext context) {
    final iri = term.value;
    final match = _extractionPattern.firstMatch(iri);

    if (match == null) {
      throw ArgumentError('IRI "$iri" does not match template pattern');
    }

    // Extract the value from the appropriate capture group
    // Since we only create capture groups for the value placeholder,
    // we can assume group(1) contains our value
    final valueString = match.group(1);
    if (valueString == null) {
      throw ArgumentError('Could not extract value from IRI: $iri');
    }

    return convertFromString(valueString);
  }
}
