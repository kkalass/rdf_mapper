# RDF Mapper for Dart

[![Dart](https://img.shields.io/badge/Dart-2.17%2B-blue.svg)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Eine leistungsstarke Bibliothek für die bidirektionale Abbildung zwischen Dart-Objekten und RDF (Resource Description Framework), basierend auf [`rdf_core`](https://pub.dev/packages/rdf_core).

## Übersicht

`rdf_mapper` bietet eine elegante Lösung für die Umwandlung zwischen Dart-Objektmodellen und RDF-Graphen, ähnlich wie ein ORM für Datenbanken. Dies ermöglicht es Entwicklern, mit semantischen Daten in einer objektorientierten Weise zu arbeiten, ohne die Komplexität der RDF-Serialisierung und -Deserialisierung manuell zu verwalten.

### Hauptmerkmale

- **Bidirektionales Mapping**: Nahtlose Konvertierung zwischen Dart-Objekten und RDF-Repräsentationen
- **Typsicher**: Vollständig typisiertes API für sicheres RDF-Mapping
- **Erweiterbar**: Einfaches Erstellen eigener Mapper für benutzerdefinierte Typen
- **Flexibel**: Unterstützung für alle RDF-Hauptkonzepte: IRI-Knoten, Blank-Knoten und Literale
- **String & Graph API**: Arbeiten mit RDF-Strings oder direkt mit Graphen

## Was ist RDF?

Das Resource Description Framework (RDF) ist ein Standard-Datenmodell für den Datenaustausch im Web. Es erweitert die Linkstruktur des Webs, indem es URIs verwendet, um Beziehungen zwischen Dingen zu benennen.

RDF basiert auf Aussagen in Form von "Tripeln": Subjekt-Prädikat-Objekt:

- **Subjekt**: Die Ressource, die beschrieben wird (identifiziert durch eine IRI oder einen Blank-Knoten)
- **Prädikat**: Die Eigenschaft oder Beziehung (immer eine IRI)
- **Objekt**: Der Wert oder die verbundene Ressource (eine IRI, ein Blank-Knoten oder ein Literalwert)

## Installation

Füge folgendes zu deiner `pubspec.yaml` hinzu:

```yaml
dependencies:
  rdf_mapper:
    git:
      url: https://github.com/yourusername/rdf_mapper.git
```

## Schnellstart

### Basis-Setup

```dart
import 'package:rdf_mapper/rdf_mapper.dart';

// Erstelle eine Mapper-Instanz mit Standard-Registrierung
final rdfMapper = RdfMapper.withDefaultRegistry();
```

### Serialisierung

```dart
// Definiere eine einfache Modellklasse
class Person {
  final String id;
  final String name;
  final int age;
  
  Person({required this.id, required this.name, required this.age});
}

// Erstelle einen benutzerdefinierten Mapper
class PersonMapper implements IriNodeMapper<Person> {
  @override
  IriTerm? get typeIri => IriTerm('http://xmlns.com/foaf/0.1/Person');
  
  @override
  (IriTerm, List<Triple>) toRdfNode(Person value, SerializationContext context, {RdfSubject? parentSubject}) {
    final subject = IriTerm(value.id);
    final builder = context.nodeBuilder(subject);
    
    // Füge Eigenschaften mit dem fluent API hinzu
    builder
      .literal(IriTerm('http://xmlns.com/foaf/0.1/name'), value.name)
      .literal(IriTerm('http://xmlns.com/foaf/0.1/age'), value.age);
    
    return builder.build();
  }
  
  @override
  Person fromRdfNode(IriTerm term, DeserializationContext context) {
    final reader = context.reader(term);
    
    return Person(
      id: term.lexicalForm,
      name: reader.require<String>(IriTerm('http://xmlns.com/foaf/0.1/name')),
      age: reader.require<int>(IriTerm('http://xmlns.com/foaf/0.1/age')),
    );
  }
}

// Registriere den Mapper
rdfMapper.registerMapper<Person>(PersonMapper());

// Serialisiere ein Objekt
final person = Person(
  id: 'http://example.org/person/1',
  name: 'Max Mustermann',
  age: 30,
);

final turtle = rdfMapper.serialize(person);
print(turtle);
```

### Deserialisierung

```dart
// RDF Turtle-Eingabe
final turtleInput = '''
@prefix foaf: <http://xmlns.com/foaf/0.1/> .

<http://example.org/person/1> a foaf:Person ;
  foaf:name "Max Mustermann" ;
  foaf:age 30 .
''';

// Deserialisiere ein Objekt
final person = rdfMapper.deserialize<Person>(turtleInput);
print('Name: ${person.name}, Alter: ${person.age}');
```

## Architektur

Die Bibliothek ist um einige Kernkonzepte herum aufgebaut:

### Mapper-Hierarchie

- **Term-Mapper**: Für einfache Werte (IRI-Terme oder Literale)
  - `IriTermMapper`: Für IRIs (z.B. URIs, URLs)
  - `LiteralTermMapper`: Für Literalwerte (Strings, Zahlen, Daten)

- **Knoten-Mapper**: Für komplexe Objekte mit mehreren Eigenschaften
  - `IriNodeMapper`: Für Objekte mit global eindeutigen Identifikatoren
  - `BlankNodeMapper`: Für anonyme Objekte oder Hilfsstrukturen

### Kontext-Klassen

- `SerializationContext`: Bietet Zugriff auf den NodeBuilder und andere Hilfsmittel
- `DeserializationContext`: Bietet Zugriff auf den NodeReader und den RDF-Graphen

### Fluent-APIs

- `NodeBuilder`: Für die bequeme Erstellung von RDF-Knoten mit einer Fluent-API
- `NodeReader`: Für den einfachen Zugriff auf RDF-Knoteneigenschaften

## Fortgeschrittene Verwendung

### Arbeiten mit Graphen

Direktes Arbeiten mit RDF-Graphen (statt Strings):

```dart
// Graph-basierte Serialisierung
final graph = rdfMapper.graph.serialize(person);

// Graph-basierte Deserialisierung
final personFromGraph = rdfMapper.graph.deserialize<Person>(graph);
```

### Mehrere Objekte deserialisieren

```dart
// Alle Objekte im Graph deserialisieren
final objects = rdfMapper.deserializeAll(turtleInput);

// Nur Objekte eines bestimmten Typs
final people = rdfMapper.deserializeAllOfType<Person>(turtleInput);
```

### Temporäre Mapper registrieren

```dart
// Temporärer Mapper für eine einzelne Operation
final result = rdfMapper.deserialize<CustomType>(
  input, 
  register: (registry) {
    registry.registerMapper<CustomType>(CustomTypeMapper());
  },
);
```

## Komplexes Beispiel

Das folgende Beispiel zeigt, wie komplexere Modelle mit Beziehungen zwischen Objekten und verschachtelten Strukturen behandelt werden können:

```dart
import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';

// Namespace-Konstanten für bessere Lesbarkeit
final foaf = Namespace('http://xmlns.com/foaf/0.1/');
final schema = Namespace('http://schema.org/');

// Modellklassen
class Address {
  final String street;
  final String city;
  final String postalCode;
  final String country;
  
  Address({
    required this.street, 
    required this.city, 
    required this.postalCode, 
    required this.country
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
    this.friends = const []
  });
}

// Mapper für die Adressklasse - implementiert BlankNodeMapper für anonyme Ressourcen
class AddressMapper implements BlankNodeMapper<Address> {
  @override
  IriTerm? get typeIri => schema('Address');
  
  @override
  (BlankNodeTerm, List<Triple>) toRdfNode(
    Address value, 
    SerializationContext context, 
    {RdfSubject? parentSubject}
  ) {
    final subject = BlankNodeTerm();
    final builder = context.nodeBuilder(subject);
    
    builder
      .literal(schema('streetAddress'), value.street)
      .literal(schema('addressLocality'), value.city)
      .literal(schema('postalCode'), value.postalCode)
      .literal(schema('addressCountry'), value.country);
      
    return builder.build();
  }
  
  @override
  Address fromRdfNode(BlankNodeTerm term, DeserializationContext context) {
    final reader = context.reader(term);
    
    return Address(
      street: reader.require<String>(schema('streetAddress')),
      city: reader.require<String>(schema('addressLocality')),
      postalCode: reader.require<String>(schema('postalCode')),
      country: reader.require<String>(schema('addressCountry')),
    );
  }
}

// Mapper für die Person-Klasse
class PersonMapper implements IriNodeMapper<Person> {
  @override
  IriTerm? get typeIri => foaf('Person');
  
  @override
  (IriTerm, List<Triple>) toRdfNode(
    Person value, 
    SerializationContext context, 
    {RdfSubject? parentSubject}
  ) {
    final subject = IriTerm(value.id);
    final builder = context.nodeBuilder(subject);
    
    // Einfache Eigenschaften
    builder
      .literal(foaf('name'), value.name)
      .literal(foaf('age'), value.age);
    
    // Verschachtelte Adresse als BlankNode
    builder.childNode(schema('address'), value.address);
    
    // Liste von Freunden als IRI-Referenzen
    if (value.friends.isNotEmpty) {
      builder.childNodeList(foaf('knows'), value.friends);
    }
    
    return builder.build();
  }
  
  @override
  Person fromRdfNode(IriTerm term, DeserializationContext context) {
    final reader = context.reader(term);
    
    return Person(
      id: term.lexicalForm,
      name: reader.require<String>(foaf('name')),
      age: reader.require<int>(foaf('age')),
      address: reader.require<Address>(schema('address')),
      friends: reader.getList<Person>(foaf('knows')),
    );
  }
}

void main() {
  // Erstelle RDF-Mapper und registriere unsere benutzerdefinierten Mapper
  final rdfMapper = RdfMapper.withDefaultRegistry();
  rdfMapper.registerMapper<Address>(AddressMapper());
  rdfMapper.registerMapper<Person>(PersonMapper());

  // Erstelle einige Beispieldaten
  final alice = Person(
    id: 'http://example.org/people/alice',
    name: 'Alice Schmidt',
    age: 28,
    address: Address(
      street: 'Hauptstraße 1',
      city: 'Berlin',
      postalCode: '10115',
      country: 'Deutschland'
    ),
    friends: []  // Wird später aktualisiert
  );
  
  final bob = Person(
    id: 'http://example.org/people/bob',
    name: 'Bob Meyer',
    age: 32,
    address: Address(
      street: 'Lindenallee 42',
      city: 'München',
      postalCode: '80333',
      country: 'Deutschland'
    ),
    friends: []  // Wird später aktualisiert
  );
  
  // Stelle Freundschaftsbeziehungen her (bidirektional)
  alice.friends.add(bob);
  bob.friends.add(alice);

  // Serialisiere zu RDF
  final turtle = rdfMapper.serialize(alice);
  print(turtle);
  
  // Die Ausgabe wird komplexe Verschachtelungen und Beziehungen zeigen:
  // - Personen als IRI-Ressourcen
  // - Adressen als anonyme Blank-Knoten
  // - Freundschaftsbeziehungen als Verweise zwischen Personen
  
  // Deserialisierung funktioniert genauso einfach
  final deserializedAlice = rdfMapper.deserialize<Person>(turtle);
  print('Deserialisiert: ${deserializedAlice.name}');
  print('Freunde: ${deserializedAlice.friends.map((f) => f.name).join(', ')}');
}
```

Im obigen Beispiel haben wir:

1. Eine `Address`-Klasse, die als Blank-Knoten (anonyme Ressource) modelliert ist
2. Eine `Person`-Klasse mit einem IRI-Identifier und einer Beziehung zu Adressen und anderen Personen
3. Verwendung des Blank-Node-Mappers für verschachtelte Objekte ohne eigene Identität
4. Darstellung von Beziehungen zwischen benannten Ressourcen

### Namespace-Hilfsklasse

Um IRIs in RDF sauber zu verwalten, empfiehlt sich die Verwendung einer Namespace-Klasse:

```dart
/// Hilfsklasse zur Verwaltung von RDF-Namespaces
class Namespace {
  final String _base;
  
  Namespace(this._base);
  
  /// Erstellt eine IRI-Term durch Anhängen des lokalen Namens an die Namespace-Basis
  IriTerm call(String localName) => IriTerm('$_base$localName');
  
  /// Gibt die Basis-URL des Namespaces zurück
  String get uri => _base;
}

// Beispielverwendung:
final foaf = Namespace('http://xmlns.com/foaf/0.1/');
final schema = Namespace('http://schema.org/');

// Verwendung:
builder.literal(foaf('name'), 'Alice');  // Erzeugt http://xmlns.com/foaf/0.1/name
```

## Beitragen

Beiträge sind willkommen! Bitte lies die [Beitragsrichtlinien](CONTRIBUTING.md) für weitere Informationen.

## Lizenz

Dieses Projekt steht unter der [MIT-Lizenz](LICENSE).
