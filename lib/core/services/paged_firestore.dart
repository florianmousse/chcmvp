import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chc_mvp/core/services/paged_stream.dart';

/// Document IDs provide stable page boundaries when match dates/names change.
Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> watchPagedQuery(
  Query<Map<String, dynamic>> query,
) => watchPages((cursor) {
  var page = query.orderBy(FieldPath.documentId).limit(100);
  if (cursor != null) page = page.startAfter([cursor]);
  return page.snapshots().map(
    (snapshot) => DataPage(
      snapshot.docs,
      snapshot.docs.length == 100 ? snapshot.docs.last.id : null,
    ),
  );
});
