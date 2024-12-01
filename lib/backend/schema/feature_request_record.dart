import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class FeatureRequestRecord extends FirestoreRecord {
  FeatureRequestRecord._(
    super.reference,
    super.data,
  ) {
    _initializeFields();
  }

  // "description" field.
  String? _description;
  String get description => _description ?? '';
  bool hasDescription() => _description != null;

  DocumentReference get parentReference => reference.parent.parent!;

  void _initializeFields() {
    _description = snapshotData['description'] as String?;
  }

  static Query<Map<String, dynamic>> collection([DocumentReference? parent]) =>
      parent != null
          ? parent.collection('featureRequest')
          : FirebaseFirestore.instance.collectionGroup('featureRequest');

  static DocumentReference createDoc(DocumentReference parent, {String? id}) =>
      parent.collection('featureRequest').doc(id);

  static Stream<FeatureRequestRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => FeatureRequestRecord.fromSnapshot(s));

  static Future<FeatureRequestRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => FeatureRequestRecord.fromSnapshot(s));

  static FeatureRequestRecord fromSnapshot(DocumentSnapshot snapshot) =>
      FeatureRequestRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static FeatureRequestRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      FeatureRequestRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'FeatureRequestRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is FeatureRequestRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createFeatureRequestRecordData({
  String? description,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'description': description,
    }.withoutNulls,
  );

  return firestoreData;
}

class FeatureRequestRecordDocumentEquality
    implements Equality<FeatureRequestRecord> {
  const FeatureRequestRecordDocumentEquality();

  @override
  bool equals(FeatureRequestRecord? e1, FeatureRequestRecord? e2) {
    return e1?.description == e2?.description;
  }

  @override
  int hash(FeatureRequestRecord? e) =>
      const ListEquality().hash([e?.description]);

  @override
  bool isValidKey(Object? o) => o is FeatureRequestRecord;
}
