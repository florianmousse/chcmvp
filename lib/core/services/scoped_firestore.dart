import 'package:cloud_firestore/cloud_firestore.dart';

String scopedFirestorePath(String path, String? space) =>
    space == null ? path : 'review_spaces/$space/$path';

/// Only application data is scoped. Firebase Authentication stays on the real
/// account so a test profile can never change production permissions.
class ScopedFirestore {
  ScopedFirestore(this.raw, [this.reviewSpaceUid]);
  final FirebaseFirestore raw;
  final String? reviewSpaceUid;
  String path(String path) => scopedFirestorePath(path, reviewSpaceUid);
  CollectionReference<Map<String, dynamic>> collection(String name) =>
      raw.collection(path(name));
  DocumentReference<Map<String, dynamic>> doc(String name) =>
      raw.doc(path(name));
}
