import 'package:rdf_core/rdf_core.dart';

/// Utility class for managing RDF namespaces and creating IRI terms.
///
/// This class simplifies working with RDF IRIs by providing a concise way to
/// create fully qualified IRIs from namespace prefixes and local names. It
/// follows the common pattern used in RDF frameworks of defining namespace
/// prefixes once and then combining them with local names.
///
/// The class uses Dart's callable class feature to provide a clean syntax
/// for creating IRIs:
///
/// ```dart
/// // Define namespaces
/// final foaf = Namespace('http://xmlns.com/foaf/0.1/');
/// final schema = Namespace('http://schema.org/');
///
/// // Create IRIs using the callable syntax
/// final personType = foaf('Person');        // http://xmlns.com/foaf/0.1/Person
/// final nameProperty = foaf('name');        // http://xmlns.com/foaf/0.1/name
/// final addressProperty = schema('address'); // http://schema.org/address
/// ```
class Namespace {
  final String _base;
  final IriTermFactory _iriTermFactory;

  /// Creates a new namespace with the specified base IRI.
  ///
  /// The base IRI should typically end with a delimiter character like '/' or '#',
  /// but this is not enforced to allow for flexibility in namespace conventions.
  ///
  /// @param base The base IRI for this namespace (e.g., "http://schema.org/")
  const Namespace(this._base,
      {IriTermFactory iriTermFactory = IriTerm.validated})
      : _iriTermFactory = iriTermFactory;

  /// Creates an IRI term by combining the namespace base with a local name.
  ///
  /// This operator makes the Namespace class callable, allowing a clean syntax
  /// for creating IRIs.
  ///
  /// @param localName The local part of the IRI (e.g., "Person", "name")
  /// @return An IriTerm representing the complete IRI
  IriTerm call(String localName) => _iriTermFactory('$_base$localName');

  /// Returns the base IRI of this namespace.
  ///
  /// Useful when you need to reference the namespace itself rather than
  /// combining it with a local name.
  ///
  /// @return The base IRI string
  String get uri => _base;

  /// Returns a string representation of this namespace.
  ///
  /// @return The base IRI string
  @override
  String toString() => _base;

  /// Checks if this namespace is equal to another object.
  ///
  /// Two namespaces are considered equal if they have the same base IRI.
  ///
  /// @param other The object to compare with
  /// @return true if the other object is a Namespace with the same base IRI
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Namespace && other._base == _base;
  }

  /// Returns a hash code for this namespace.
  ///
  /// @return A hash code based on the base IRI
  @override
  int get hashCode => _base.hashCode;
}
