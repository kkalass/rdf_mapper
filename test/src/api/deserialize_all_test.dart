import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_core/vocab.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:test/test.dart';

// Test models for various scenarios
class Person {
  final String id;
  final String name;
  final Address? address;
  final List<Contact> contacts;

  Person({
    required this.id,
    required this.name,
    this.address,
    this.contacts = const [],
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Person &&
          id == other.id &&
          name == other.name &&
          address == other.address;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ address.hashCode;

  @override
  String toString() => 'Person($id, $name)';
}

class Address {
  final String street;
  final String city;

  Address({required this.street, required this.city});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Address && street == other.street && city == other.city;

  @override
  int get hashCode => street.hashCode ^ city.hashCode;

  @override
  String toString() => 'Address($street, $city)';
}

class Contact {
  final String id;
  final String type;
  final String value;

  Contact({required this.id, required this.type, required this.value});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Contact &&
          id == other.id &&
          type == other.type &&
          value == other.value;

  @override
  int get hashCode => id.hashCode ^ type.hashCode ^ value.hashCode;

  @override
  String toString() => 'Contact($id, $type, $value)';
}

// Mappers
class PersonMapper implements IriNodeMapper<Person> {
  @override
  final IriTerm typeIri = IriTerm('http://example.org/Person');

  static final namePredicate = IriTerm('http://example.org/name');
  static final addressPredicate = IriTerm('http://example.org/address');
  static final contactPredicate = IriTerm('http://example.org/contact');

  @override
  Person fromRdfNode(IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    // Use require to ensure these properties are present
    final name = reader.require<String>(namePredicate);
    final address = reader.get<Address>(addressPredicate);
    final contacts = reader.getList<Contact>(contactPredicate);

    return Person(
      id: subject.iri,
      name: name,
      address: address,
      contacts: contacts,
    );
  }

  @override
  (IriTerm, List<Triple>) toRdfNode(
    Person value,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    return context
        .nodeBuilder(IriTerm(value.id))
        .literal(namePredicate, value.name)
        .childNodeIfNotNull(addressPredicate, value.address)
        .childNodeList(contactPredicate, value.contacts)
        .build();
  }
}

class AddressMapper implements BlankNodeMapper<Address> {
  @override
  final IriTerm typeIri = IriTerm('http://example.org/Address');

  static final streetPredicate = IriTerm('http://example.org/street');
  static final cityPredicate = IriTerm('http://example.org/city');

  @override
  Address fromRdfNode(BlankNodeTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    final street = reader.require<String>(streetPredicate);
    final city = reader.require<String>(cityPredicate);

    return Address(street: street, city: city);
  }

  @override
  (BlankNodeTerm, List<Triple>) toRdfNode(
    Address value,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    return context
        .nodeBuilder(BlankNodeTerm())
        .literal(streetPredicate, value.street)
        .literal(cityPredicate, value.city)
        .build();
  }
}

class ContactMapper implements IriNodeMapper<Contact> {
  @override
  final IriTerm typeIri = IriTerm('http://example.org/Contact');

  static final typePredicate = IriTerm('http://example.org/contactType');
  static final valuePredicate = IriTerm('http://example.org/contactValue');

  @override
  Contact fromRdfNode(IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    final type = reader.require<String>(typePredicate);
    final value = reader.require<String>(valuePredicate);

    return Contact(id: subject.iri, type: type, value: value);
  }

  @override
  (IriTerm, List<Triple>) toRdfNode(
    Contact value,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    return context
        .nodeBuilder(IriTerm(value.id))
        .literal(typePredicate, value.type)
        .literal(valuePredicate, value.value)
        .build();
  }
}

// Standalone address mapper for IRI-based addresses (not blank nodes)
class StandaloneAddressMapper implements IriNodeMapper<Address> {
  @override
  final IriTerm typeIri = IriTerm('http://example.org/Address');

  static final streetPredicate = IriTerm('http://example.org/street');
  static final cityPredicate = IriTerm('http://example.org/city');

  @override
  Address fromRdfNode(IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    final street = reader.require<String>(streetPredicate);
    final city = reader.require<String>(cityPredicate);

    return Address(street: street, city: city);
  }

  @override
  (IriTerm, List<Triple>) toRdfNode(
    Address value,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    return context
        .nodeBuilder(IriTerm('http://example.org/address/1'))
        .literal(streetPredicate, value.street)
        .literal(cityPredicate, value.city)
        .build();
  }
}

void main() {
  late RdfMapper rdfMapper;

  setUp(() {
    rdfMapper = RdfMapper.withDefaultRegistry();

    // Register mappers for our test models
    rdfMapper.registerMapper<Person>(PersonMapper());
    rdfMapper.registerMapper<Address>(AddressMapper());
    rdfMapper.registerMapper<Contact>(ContactMapper());
  });

  group('deserializeAll filtering tests', () {
    test(
      'should return only root objects and filter out nested blank nodes',
      () {
        final turtle = '''
        @prefix ex: <http://example.org/> .
        
        <http://example.org/person/1> a ex:Person ;
          ex:name "John Doe" ;
          ex:address [
            a ex:Address ;
            ex:street "123 Main St" ;
            ex:city "Anytown"
          ] .
      ''';

        final objects = rdfMapper.deserializeAll(turtle);

        // Should get only the person, not the address
        expect(objects.length, equals(1));
        expect(objects.first, isA<Person>());

        final person = objects.first as Person;
        expect(person.id, equals('http://example.org/person/1'));
        expect(person.name, equals('John Doe'));
        expect(person.address, isNotNull);
        expect(person.address!.street, equals('123 Main St'));
      },
    );

    test(
      'should filter out IRI-based objects that are referenced by others',
      () {
        // Register the IRI-based address mapper
        rdfMapper.registerMapper<Address>(StandaloneAddressMapper());

        final turtle = '''
        @prefix ex: <http://example.org/> .
        
        <http://example.org/person/1> a ex:Person ;
          ex:name "John Doe" ;
          ex:address <http://example.org/address/1> .
          
        <http://example.org/address/1> a ex:Address ;
          ex:street "123 Main St" ;
          ex:city "Anytown" .
      ''';

        final objects = rdfMapper.deserializeAll(turtle);

        // Should get only the person, as the address is referenced
        expect(objects.length, equals(1));
        expect(objects.first, isA<Person>());

        final person = objects.first as Person;
        expect(person.address, isNotNull);
        expect(person.address!.street, equals('123 Main St'));
      },
    );

    test(
      'should return separate IRI subjects that are not referenced by others',
      () {
        final turtle = '''
        @prefix ex: <http://example.org/> .
        
        <http://example.org/person/1> a ex:Person ;
          ex:name "John Doe" .
          
        <http://example.org/person/2> a ex:Person ;
          ex:name "Jane Smith" .
      ''';

        final objects = rdfMapper.deserializeAll(turtle);

        // Should get both persons
        expect(objects.length, equals(2));
        expect(objects.every((obj) => obj is Person), isTrue);

        // Verify we have both names
        final names = objects.map((obj) => (obj as Person).name).toList();
        expect(names, containsAll(['John Doe', 'Jane Smith']));
      },
    );

    test('should handle complex scenarios with mixed references', () {
      // Register the IRI-based address mapper alongside the blank node one
      rdfMapper.registerMapper<Address>(StandaloneAddressMapper());

      final turtle = '''
        @prefix ex: <http://example.org/> .
        
        # Person 1 with inline blank node address
        <http://example.org/person/1> a ex:Person ;
          ex:name "John Doe" ;
          ex:address [
            a ex:Address ;
            ex:street "123 Home St" ;
            ex:city "Hometown"
          ] ;
          ex:contact <http://example.org/contact/1> .
          
        # Person 2 referencing standalone address  
        <http://example.org/person/2> a ex:Person ;
          ex:name "Jane Smith" ;
          ex:address <http://example.org/address/1> .
          
        # Standalone address  
        <http://example.org/address/1> a ex:Address ;
          ex:street "456 Office Blvd" ;
          ex:city "Worktown" .
          
        # Standalone contact
        <http://example.org/contact/1> a ex:Contact ;
          ex:contactType "email" ;
          ex:contactValue "john@example.org" .
      ''';

      final objects = rdfMapper.deserializeAll(turtle);

      // Should get persons , but not the standalone address nor the contact (it's referenced)
      expect(objects.length, equals(2));
      expect(objects.whereType<Person>().length, equals(2));
      expect(objects.whereType<Contact>().length, equals(0));
      expect(
        objects.whereType<Address>().length,
        equals(0),
      ); // Address should be filtered out

      // Verify that both persons have their addresses correctly
      final persons =
          objects.whereType<Person>().toList()
            ..sort((a, b) => a.name.compareTo(b.name));

      expect(persons[0].name, equals('Jane Smith'));
      expect(persons[0].address!.city, equals('Worktown'));

      expect(persons[1].name, equals('John Doe'));
      expect(persons[1].address!.city, equals('Hometown'));
      // Verify the contact
      expect(persons[1].contacts, hasLength(1));
      expect(persons[1].contacts[0].type, equals('email'));
    });

    test(
      'should not filter blank nodes when they appear as standalone subjects',
      () {
        rdfMapper.registerMapper<Address>(AddressMapper());
        // This test checks that blank nodes are not filtered

        // Create a graph with a blank node that is not referenced by any other subject
        final blankNode = BlankNodeTerm();
        final graph = RdfGraph(
          triples: [
            Triple(
              blankNode,
              RdfPredicates.type,
              IriTerm('http://example.org/Address'),
            ),
            Triple(
              blankNode,
              IriTerm('http://example.org/street'),
              LiteralTerm.string('123 Isolated St'),
            ),
            Triple(
              blankNode,
              IriTerm('http://example.org/city'),
              LiteralTerm.string('Ghost Town'),
            ),
          ],
        );

        final objects = rdfMapper.graph.deserializeAll(graph);

        // Should get zero objects as blank nodes are always filtered
        expect(objects.length, equals(1));
        expect(objects[0], isA<Address>());
      },
    );
  });
}
