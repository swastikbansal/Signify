import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class BugReportRecord extends FirestoreRecord {
  BugReportRecord._(
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
          ? parent.collection('bugReport')
          : FirebaseFirestore.instance.collectionGroup('bugReport');

  static DocumentReference createDoc(DocumentReference parent, {String? id}) =>
      parent.collection('bugReport').doc(id);

  static Stream<BugReportRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => BugReportRecord.fromSnapshot(s));

  static Future<BugReportRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => BugReportRecord.fromSnapshot(s));

  static BugReportRecord fromSnapshot(DocumentSnapshot snapshot) =>
      BugReportRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static BugReportRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      BugReportRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'BugReportRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is BugReportRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createBugReportRecordData({
  String? description,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'description': description,
    }.withoutNulls,
  );

  return firestoreData;
}

class BugReportRecordDocumentEquality implements Equality<BugReportRecord> {
  const BugReportRecordDocumentEquality();

  @override
  bool equals(BugReportRecord? e1, BugReportRecord? e2) {
    return e1?.description == e2?.description;
  }

  @override
  int hash(BugReportRecord? e) => const ListEquality().hash([e?.description]);

  @override
  bool isValidKey(Object? o) => o is BugReportRecord;
}
