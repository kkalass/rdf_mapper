import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';

/// Abstract base class for mapping Dart objects to RDF IRI terms using URI templates.
///
/// This class provides a flexible way to map enum values or other objects to IRIs
/// using URI templates with placeholders. It supports both static placeholders
/// (provided via providers) and dynamic placeholders (resolved from the object value).
///
/// ## Quick Start
///
/// Simple enum to IRI mapping:
/// ```dart
/// class StatusMapper extends BaseRdfIriTermMapper<Status> {
///   StatusMapper() : super('https://example.org/status/{value}', 'value');
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
///   StatusMapper(String Function() baseUriProvider)
///     : super('{+baseUri}/status/{value}', 'value',
///             providers: {'baseUri': baseUriProvider});
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
/// - All other placeholders must have corresponding providers
///
/// ## Implementation Requirements
///
/// Subclasses must implement:
/// - `convertToString()`: Convert object to string for the value placeholder
/// - `convertFromString()`: Convert string from value placeholder back to object
abstract class BaseRdfIriTermMapper<T> implements IriTermMapper<T> {
  /// The URI template with placeholders
  final String template;

  /// The name of the placeholder that represents the object value
  final String valueVariableName;

  /// Providers for static placeholders in the template
  final Map<String, String Function()> providers;

  /// Compiled regex pattern for extracting values from IRIs
  late final RegExp _extractionPattern;

  /// Placeholder names found in the template
  late final List<String> _placeholderNames;

  /// Creates a mapper for the specified URI template.
  ///
  /// [template] The URI template with placeholders (e.g., 'https://example.org/{category}/{value}')
  /// [valueVariableName] The name of the placeholder that represents the object value
  /// [providers] Optional providers for static placeholders
  BaseRdfIriTermMapper(
    this.template,
    this.valueVariableName, {
    Map<String, String Function()>? providers,
  }) : providers = providers ?? {} {
    _validateAndCompile();
  }

  /// Validates the template and compiles the extraction pattern
  void _validateAndCompile() {
    // Find all placeholders in the template
    final placeholderRegex = RegExp(r'\{(\+?)([^}]+)\}');
    final matches = placeholderRegex.allMatches(template);

    _placeholderNames = matches.map((match) => match.group(2)!).toList();

    // Validate that valueVariableName exists in template
    if (!_placeholderNames.contains(valueVariableName)) {
      throw ArgumentError(
          'Value variable "$valueVariableName" not found in template "$template"');
    }

    // Validate that all non-value placeholders have providers
    final missingProviders = _placeholderNames
        .where((name) => name != valueVariableName)
        .where((name) => !providers.containsKey(name))
        .toList();

    if (missingProviders.isNotEmpty) {
      throw ArgumentError(
          'Missing providers for placeholders: ${missingProviders.join(", ")}');
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

    _extractionPattern = RegExp('^$pattern\$');
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
        final provider = providers[placeholderName];
        if (provider == null) {
          throw StateError(
              'No provider found for placeholder: $placeholderName');
        }
        return provider();
      }
    });

    return IriTerm(iri);
  }

  @override
  T fromRdfTerm(IriTerm term, DeserializationContext context) {
    final iri = term.iri;
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
