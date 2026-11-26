import 'package:cloud_firestore/cloud_firestore.dart';

/// Stores dashboard state in a document owned by the signed-in Firebase user.
class FirebaseDataService {
  FirebaseDataService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _document(String uid) =>
      _firestore.collection('users').doc(uid).collection('app').doc('dashboard');

  Future<Map<String, dynamic>?> loadDashboard(String uid) async {
    final snapshot = await _document(uid).get();
    return snapshot.data();
  }

  Future<void> saveDashboard(String uid, Map<String, dynamic> data) async {
    await _document(uid).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
