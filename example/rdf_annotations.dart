import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';

/// Base annotation interface for RDF mapper generation.
///
/// This is a marker interface for all RDF mapping annotations.
abstract class RdfAnnotation {
  const RdfAnnotation();
}

// --- Type-safe mapper references ---

/// Base class for type-safe mapper references
class MapperRef<M> {
  /// The name to use for the mapper parameter in the generated code
  final String? name;

  /// The type of the mapper to instantiate
  final Type? type;

  /// A direct mapper instance
  final M? instance;

  /// Creates a mapper reference
  const MapperRef({this.name, this.type, this.instance});
}

// --- Class-level annotations ---

class RdfGlobalResource implements RdfAnnotation {
  /// The RDF class IRI for this resource.
  ///
  /// This defines the RDF type of the resource using the 'a' predicate
  /// (rdf:type). It's typically an IriTerm from a vocabulary like
  /// SchemaBook.classIri.
  final IriTerm? classIri;

  final RdfIri? iri;

  final String? _mapperName;
  final Type? _mapperType;
  final GlobalResourceMapper? _mapperInstance;

  MapperRef<GlobalResourceMapper>? get mapper =>
      (_mapperName != null || _mapperInstance != null || _mapperType != null)
          ? MapperRef(
            name: _mapperName,

            instance: _mapperInstance,
            type: _mapperType,
          )
          : null;

  /// Creates a reference to a class that will be mapped to an RDF IRI node
  const RdfGlobalResource(this.classIri, RdfIri iri)
    : iri = iri,
      _mapperName = null,
      _mapperInstance = null,
      _mapperType = null;

  /// Creates a reference to a named mapper that will be injected at runtime
  const RdfGlobalResource.namedMapper(String name)
    : iri = null,
      classIri = null,
      _mapperName = name,
      _mapperInstance = null,
      _mapperType = null;

  /// Creates a reference to a mapper that will be instantiated from the given type
  const RdfGlobalResource.mapper(Type mapperType)
    : iri = null,
      classIri = null,
      _mapperName = null,
      _mapperInstance = null,
      _mapperType = mapperType;

  /// Creates a reference to a directly provided mapper instance
  const RdfGlobalResource.mapperInstance(GlobalResourceMapper instance)
    : iri = null,
      classIri = null,
      _mapperName = null,
      _mapperInstance = instance,
      _mapperType = null;
}

class RdfLocalResource implements RdfAnnotation {
  /// The RDF class IRI for this blank node.
  ///
  /// This defines the RDF type of the blank node using the 'a' predicate
  /// (rdf:type).
  final IriTerm? classIri;

  final String? _mapperName;
  final Type? _mapperType;
  final LocalResourceMapper? _mapperInstance;

  /// Optional specification for a custom mapper.
  ///
  /// When provided, the generator will use this mapper instead of generating one.
  MapperRef<LocalResourceMapper>? get mapper =>
      (_mapperName != null || _mapperInstance != null || _mapperType != null)
          ? MapperRef(
            name: _mapperName,
            instance: _mapperInstance,
            type: _mapperType,
          )
          : null;

  const RdfLocalResource(this.classIri)
    : _mapperName = null,
      _mapperInstance = null,
      _mapperType = null;

  const RdfLocalResource.namedMapper(String name)
    : classIri = null,
      _mapperName = name,
      _mapperInstance = null,
      _mapperType = null;
  const RdfLocalResource.mapper(Type mapperType)
    : classIri = null,
      _mapperName = null,
      _mapperInstance = null,
      _mapperType = mapperType;
  const RdfLocalResource.mapperInstance(LocalResourceMapper instance)
    : classIri = null,
      _mapperName = null,
      _mapperInstance = instance,
      _mapperType = null;
}

class RdfIri implements RdfAnnotation {
  /// Optional prefix to prepend to the serialized value.
  ///
  /// For example, with prefix 'urn:isbn:{value}' and value '9780618260300',
  /// the resulting IRI would be 'urn:isbn:9780618260300'.
  ///
  /// Unresolved template variables will be required to be provided as a provider function
  /// during initialization. E.g. if the template is `{baseUri}/foo/{value}.ttl`,
  /// then the generated initRdfMapper method will require a named parameter
  /// `String Function() baseUriProvider`.
  final String? template;

  /// Optional specification for a custom mapper.
  ///
  /// When provided, the generator will use this mapper instead of generating one.
  MapperRef<IriTermMapper>? get mapper =>
      (_mapperName != null || _mapperInstance != null || _mapperType != null)
          ? MapperRef(
            name: _mapperName,
            instance: _mapperInstance,
            type: _mapperType,
          )
          : null;

  final String? _mapperName;

  final Type? _mapperType;
  final IriTermMapper? _mapperInstance;

  const RdfIri([this.template])
    : _mapperName = null,
      _mapperInstance = null,
      _mapperType = null;

  const RdfIri.namedMapper(String name)
    : template = null,
      _mapperName = name,
      _mapperInstance = null,
      _mapperType = null;

  const RdfIri.mapper(Type mapperType)
    : template = null,
      _mapperName = null,
      _mapperInstance = null,
      _mapperType = mapperType;

  const RdfIri.mapperInstance(IriTermMapper instance)
    : template = null,
      _mapperName = null,
      _mapperInstance = instance,
      _mapperType = null;
}

class RdfLiteral implements RdfAnnotation {
  /// Optional method name to use for converting the object to a [LiteralTerm].
  ///
  /// By default, the property marked with @RdfValue will be converted to a
  /// LiteralTerm using the SerializationContext and the standard mapper/serializer
  /// registered for that datatype.
  final String? toLiteralTermMethod;

  /// Optional static method name to use for converting a [LiteralTerm] back to the object type.
  ///
  /// By default, the type of the property marked with @RdfValue will be
  /// deserialized with its standard mapper/serializer from the serialization context
  /// and that value will be passed to the constructor of the class.
  final String? fromLiteralTermMethod;

  /// Optional specification for a custom mapper.
  ///
  /// When provided, the generator will use this mapper instead of using methods.
  /// This takes precedence over [toLiteralTermMethod] and [fromLiteralTermMethod].
  MapperRef<LiteralTermMapper>? get mapper =>
      (_mapperName != null || _mapperInstance != null || _mapperType != null)
          ? MapperRef(
            name: _mapperName,
            instance: _mapperInstance,
            type: _mapperType,
          )
          : null;

  final String? _mapperName;
  final Type? _mapperType;
  final LiteralTermMapper? _mapperInstance;

  const RdfLiteral()
    : toLiteralTermMethod = null,
      fromLiteralTermMethod = null,
      _mapperName = null,
      _mapperInstance = null,
      _mapperType = null;

  const RdfLiteral.custom({
    required String toLiteralTermMethod,
    required String fromLiteralTermMethod,
  }) : toLiteralTermMethod = toLiteralTermMethod,
       fromLiteralTermMethod = fromLiteralTermMethod,
       _mapperName = null,
       _mapperInstance = null,
       _mapperType = null;

  const RdfLiteral.namedMapper(String name)
    : toLiteralTermMethod = null,
      fromLiteralTermMethod = null,
      _mapperName = name,
      _mapperInstance = null,
      _mapperType = null;

  const RdfLiteral.mapper(Type mapperType)
    : toLiteralTermMethod = null,
      fromLiteralTermMethod = null,
      _mapperName = null,
      _mapperInstance = null,
      _mapperType = mapperType;

  const RdfLiteral.mapperInstance(LiteralTermMapper instance)
    : toLiteralTermMethod = null,
      fromLiteralTermMethod = null,
      _mapperName = null,
      _mapperInstance = instance,
      _mapperType = null;
}

// --- Property-level annotations ---

/// Marks a property to be mapped to/from an RDF predicate.
///
/// This is the primary annotation for class properties, defining how they
/// should be serialized to RDF and deserialized back to Dart objects.
///
/// Example:
/// ```dart
/// @RdfProperty(SchemaBook.author, required: true)
/// final String author;
/// ```
///
/// Example for a String for which we provide a custom mapper to an iri:
/// ```dart
/// @RdfProperty(
///   Dcterms.creator,
///   iri: RdfIri.namedMapper('appInstanceMapper')
/// )
/// late String lastModifiedBy;
/// ```
///
/// Example with child node where we provide a custom blank node mapper for the child node:
/// ```dart
/// @RdfProperty(
///   SchemaBook.publisher,
///   localResource: RdfLocalResource.namedMapper('publisherMapper')
/// )
/// late Publisher publisher;
/// ```
///
/// Example with collection:
/// ```dart
/// @RdfProperty(
///   TaskOntology.vectorClock,
/// )
/// @RdfCollectionOf(VectorClockEntry)
/// late Map<String, int> vectorClock;
/// ```
class RdfProperty implements RdfAnnotation {
  /// The RDF predicate (IRI) for this property
  final IriTerm predicate;

  /// Whether this property is required during deserialization
  final bool required;

  /// Whether to include this property during serialization
  final bool include;

  /// Optional specification for treating the value as an IRI reference
  final RdfIri? iri;

  /// Optional specification for treating the value as a blank node
  final RdfLocalResource? localResource;

  /// Optional specification for treating the value as a literal with special handling
  final RdfLiteral? literal;

  /// Optional specification for treating the value as a rdf resource
  final RdfGlobalResource? globalResource;

  /// Optional specification for collection handling
  final RdfCollectionType collection;

  const RdfProperty(
    this.predicate, {
    this.required = true,
    this.include = true,
    this.iri,
    this.localResource,
    this.literal,
    this.globalResource,
    this.collection = RdfCollectionType.auto,
  });
}

/// The type of collection to use for RDF property serialization.
enum RdfCollectionType {
  /// Automatically determine collection type from property type. The default.
  auto,

  /// Not a collection - treat as a single value
  none,
}

class RdfIriPart implements RdfAnnotation {
  final String? name;
  final int? pos;
  const RdfIriPart([this.name]) : pos = null;
  const RdfIriPart.position(int position) : pos = position, name = null;
}

/// Marks a property within a class as the value source for RDF conversion.
///
/// This annotation allows automatic datatype detection from the property's type
/// and eliminates the need to override toString() for custom serialization.
/// It is typically used within classes annotated with @RdfLiteral
/// to specify which property should be used as the value source.
///
/// Example:
/// ```dart
/// @RdfLiteral()
/// class Rating {
///   @RdfValue() // datatype inferred automatically from int type
///   final int stars;
///
///   Rating(this.stars) {
///     if (stars < 0 || stars > 5) {
///       throw ArgumentError('Rating must be between 0 and 5 stars');
///     }
///   }
/// }
/// ```
class RdfValue implements RdfAnnotation {
  /// Marks a property as the value source for RDF serialization and will
  /// delegate the conversion to the standard serializer/deserializer of the datatype
  /// of this property.
  const RdfValue();
}

/// Marks a property as providing the language tag for RDF literals.
///
/// This annotation is used to specify which property of a class provides
/// the language tag for language-tagged string literals. Only one property
/// per class should be marked with @RdfLanguageTag, and the property must
/// be of type String.
///
/// Example:
/// ```dart
/// @RdfLiteral()
/// class LocalizedText {
///   @RdfValue()
///   final String text;
///
///   @RdfLanguageTag()
///   final String languageTag;
///
///   LocalizedText(this.text, this.languageTag);
/// }
/// ```
class RdfLanguageTag implements RdfAnnotation {
  const RdfLanguageTag();
}

// Annotation for the field that serves as the key in a mapped Map<K,V>
class RdfCollectionKey extends RdfAnnotation {
  const RdfCollectionKey();
}

// Annotation for the field that serves as the value in a mapped Map<K,V>
class RdfCollectionValue extends RdfAnnotation {
  const RdfCollectionValue();
}

// Revised RdfCollectionOf (simpler!)
class RdfCollectionOf extends RdfAnnotation {
  final Type itemClass; // The Dart Type of the class representing each item
  const RdfCollectionOf(this.itemClass);
}

class RdfProvides extends RdfAnnotation {
  final String? name;
  const RdfProvides(this.name);
}
