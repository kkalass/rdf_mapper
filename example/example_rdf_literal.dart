import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_vocabularies/xsd.dart';
import 'rdf_annotations.dart';

// --- Example classes with RdfValue annotation ---

/// Rating class using @RdfValue - everything is delegated to the stars property
@RdfLiteral()
class EnhancedRating {
  @RdfValue()
  final int stars;

  EnhancedRating(this.stars) {
    if (stars < 0 || stars > 5) {
      throw ArgumentError('Rating must be between 0 and 5 stars');
    }
  }
}

/// Example for a class that uses custom conversion methods
@RdfLiteral.custom(
  toLiteralTermMethod: 'formatCelsius',
  fromLiteralTermMethod: 'parse',
)
class Temperature {
  final double celsius;

  Temperature(this.celsius);

  // Custom formatting method used by the @RdfLiteral annotation
  LiteralTerm formatCelsius() => LiteralTerm(
    '$celsius°C',
    // For maximum compatibility you would typically not specify
    // a datatype here (thus defaulting to xsd:string), but we can also
    // specify a custom datatype.
    datatype: IriTerm('http://example.org/temperature'),
  );

  // Static method for parsing text back into a Temperature instance
  static Temperature parse(LiteralTerm term) {
    return Temperature(double.parse(term.value.replaceAll('°C', '')));
  }
}

// --- Example with Language Tag ---

@RdfLiteral()
class LocalizedText {
  @RdfValue()
  final String text;

  @RdfLanguageTag()
  final String languageTag;

  LocalizedText(this.text, this.languageTag);

  // Convenience constructors for common languages
  LocalizedText.en(String text) : this(text, 'en');
  LocalizedText.de(String text) : this(text, 'de');
  LocalizedText.fr(String text) : this(text, 'fr');
}

// --- Generated Mappers (for demonstration) ---

/// This class would be automatically generated based on EnhancedRating annotations
class GeneratedEnhancedRatingMapper
    implements LiteralTermMapper<EnhancedRating> {
  @override
  LiteralTerm toRdfTerm(EnhancedRating rating, SerializationContext context) {
    // The stars property is recognized based on the @RdfValue annotation
    return context.toLiteralTerm(rating.stars);
  }

  @override
  EnhancedRating fromRdfTerm(LiteralTerm term, DeserializationContext context) {
    return EnhancedRating(context.fromLiteralTerm<int>(term));
  }
}

/// This class would be automatically generated based on Temperature annotations
class GeneratedTemperatureMapper implements LiteralTermMapper<Temperature> {
  @override
  LiteralTerm toRdfTerm(Temperature temp, SerializationContext context) {
    // The toStringMethod is used from the @RdfLiteral annotation
    return temp.formatCelsius();
  }

  @override
  Temperature fromRdfTerm(LiteralTerm term, DeserializationContext context) {
    // Convert back to a Temperature instance with the static parse method
    return Temperature.parse(term);
  }
}

/// This class would be automatically generated based on LocalizedText annotations
class GeneratedLocalizedTextMapper implements LiteralTermMapper<LocalizedText> {
  @override
  LiteralTerm toRdfTerm(LocalizedText localized, SerializationContext context) {
    // Use the @RdfValue property for the value and @RdfLanguageTag for the language
    var value = localized.text;
    var languageTag = localized.languageTag;

    var term = context.toLiteralTerm(value);
    assert(
      term.datatype == Xsd.string,
      'LocalizedText should be serialized as xsd:string',
    );
    return LiteralTerm.withLanguage(term.value, languageTag);
  }

  @override
  LocalizedText fromRdfTerm(LiteralTerm term, DeserializationContext context) {
    // Note that we are using <String> because the term.value is a String -
    // if it was a custom type, we would specify that type here, basically
    // allowing us to use classes like Name, Description etc. if we wanted to
    var value = context.fromLiteralTerm<String>(LiteralTerm(term.value));
    var language = term.language!;
    // Extract both the value and language tag from the RDF term
    return LocalizedText(value, language);
  }
}
