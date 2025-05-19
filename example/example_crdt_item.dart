import 'dart:math';

import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_vocabularies/dcterms.dart';
import 'rdf_annotations.dart';

// -- Our model class --
@RdfGlobalResource(
  SolidTaskTask.classIri,
  RdfIri('{storageRoot}/solidtask/task/{id}.ttl'),
)
class Item {
  @RdfIriPart()
  @RdfProvides("taskId")
  late String id;

  @RdfProperty(SolidTaskTask.text)
  late String text;

  @RdfProperty(Dcterms.created)
  late DateTime createdAt;

  @RdfProperty(SolidTaskTask.vectorClock)
  @RdfCollectionOf(VectorClockEntry)
  late Map<String, int> vectorClock;

  @RdfProperty(SolidTaskTask.isDeleted)
  late bool isDeleted;

  @RdfProperty(
    Dcterms.creator,
    iri: RdfIri('{storageRoot}/solidtask/appinstance/{lastModifiedBy}.ttl'),
  )
  late String lastModifiedBy;

  Item({required this.text, required this.lastModifiedBy}) {
    // Generate a UUID v4 for guaranteed uniqueness
    id = Random().nextInt(1000000).toString();
    createdAt = DateTime.now();
    vectorClock = {lastModifiedBy: 1};
    isDeleted = false;
  }
}

@RdfGlobalResource(
  SolidTaskVectorClockEntry.classIri,
  RdfIri('{storageRoot}/solidtask/task/{taskId}/vectorclock/{clientId}.ttl'),
)
class VectorClockEntry {
  @RdfIriPart()
  @RdfProperty(
    SolidTaskVectorClockEntry.clientId,
    iri: RdfIri('{storageRoot}/solidtask/appinstance/{clientId}.ttl'),
  )
  @RdfCollectionKey()
  final String clientId;

  @RdfProperty(SolidTaskVectorClockEntry.clockValue)
  @RdfCollectionValue()
  final int clockValue;

  /// Creates a new vector clock entry
  VectorClockEntry(this.clientId, this.clockValue);
}

// -- Our ontology class provided by us --
class SolidTask {
  /// Private constructor to prevent instantiation
  const SolidTask._();

  /// Base IRI for task ontology
  static const String namespace = 'http://solidtask.org/ontology#';

  /// IRI for the Task class
  static const Task = IriTerm.prevalidated('${namespace}Task');

  /// IRI for VectorClockEntry class
  static const VectorClockEntry = IriTerm.prevalidated(
    '${namespace}VectorClockEntry',
  );

  /// IRI for task text property
  static const text = IriTerm.prevalidated('${namespace}text');

  /// IRI for task isDeleted property
  static const isDeleted = IriTerm.prevalidated('${namespace}isDeleted');

  /// IRI for task vectorClock property
  static const vectorClock = IriTerm.prevalidated('${namespace}vectorClock');

  /// IRI for clientId property in vector clock entries
  static const clientId = IriTerm.prevalidated('${namespace}clientId');

  /// IRI for clockValue property in vector clock entries
  static const clockValue = IriTerm.prevalidated('${namespace}clockValue');
}

class SolidTaskTask {
  /// Private constructor to prevent instantiation
  const SolidTaskTask._();

  /// Base IRI for task ontology
  static const classIri = SolidTask.Task;

  /// IRI for task text property
  static const text = SolidTask.text;

  /// IRI for task isDeleted property
  static const isDeleted = SolidTask.isDeleted;

  /// IRI for task vectorClock property
  static const vectorClock = SolidTask.vectorClock;
}

class SolidTaskVectorClockEntry {
  /// Private constructor to prevent instantiation
  const SolidTaskVectorClockEntry._();

  /// Base IRI for task ontology
  static const classIri = SolidTask.VectorClockEntry;

  static const clientId = SolidTask.clientId;

  static const clockValue = SolidTask.clockValue;
}
