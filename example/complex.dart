import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_core/vocab.dart';
import 'package:rdf_mapper/rdf_mapper.dart';

// Namespace constants for better readability
final foaf = FoafPredicates;
final schema = SchemaPersonProperties;

// Model classes
class Address {
  final String street;
  final String city;
  final String postalCode;
  final String country;

  Address({
    required this.street,
    required this.city,
    required this.postalCode,
    required this.country,
  });
}

class Person {
  final String id;
  final String name;
  final int age;
  final Address address;
  final List<Person> friends;

  Person({
    required this.id,
    required this.name,
    required this.age,
    required this.address,
    this.friends = const [],
  });
}

// Mapper for Address class - implements BlankNodeMapper for anonymous resources
class AddressMapper implements BlankNodeMapper<Address> {
  @override
  IriTerm? get typeIri => SchemaClasses.postalAddress;

  @override
  (BlankNodeTerm, List<Triple>) toRdfNode(
    Address value,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    final subject = BlankNodeTerm();
    final builder = context.nodeBuilder(subject);

    builder
        .literal(SchemaAddressProperties.streetAddress, value.street)
        .literal(SchemaAddressProperties.addressLocality, value.city)
        .literal(SchemaAddressProperties.postalCode, value.postalCode)
        .literal(SchemaAddressProperties.addressCountry, value.country);

    return builder.build();
  }

  @override
  Address fromRdfNode(BlankNodeTerm term, DeserializationContext context) {
    final reader = context.reader(term);

    return Address(
      street: reader.require<String>(SchemaAddressProperties.streetAddress),
      city: reader.require<String>(SchemaAddressProperties.addressLocality),
      postalCode: reader.require<String>(SchemaAddressProperties.postalCode),
      country: reader.require<String>(SchemaAddressProperties.addressCountry),
    );
  }
}

// Mapper for Person class
class PersonMapper implements IriNodeMapper<Person> {
  @override
  IriTerm? get typeIri => FoafClasses.person;

  @override
  (IriTerm, List<Triple>) toRdfNode(
    Person value,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    final subject = IriTerm(value.id);
    final builder = context.nodeBuilder(subject);

    // Simple properties
    builder
        .literal(FoafPredicates.familyName, value.name)
        .literal(IriTerm('http://xmlns.com/foaf/0.1/age'), value.age);

    // Nested Address as BlankNode
    builder.childNode(SchemaPersonProperties.address, value.address);

    // List of friends as IRI references
    if (value.friends.isNotEmpty) {
      builder.childNodeList(FoafPredicates.knows, value.friends);
    }

    return builder.build();
  }

  @override
  Person fromRdfNode(IriTerm term, DeserializationContext context) {
    final reader = context.reader(term);

    return Person(
      id: term.iri,
      name: reader.require<String>(FoafPredicates.familyName),
      age: reader.require<int>(IriTerm('http://xmlns.com/foaf/0.1/age')),
      address: reader.require<Address>(SchemaPersonProperties.address),
      friends: reader.getList<Person>(FoafPredicates.knows),
    );
  }
}
