import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Owns the Firebase SDK instances.
///
/// Nothing outside of the service layer should touch `FirebaseFirestore.instance`,
/// `FirebaseAuth.instance` or `FirebaseStorage.instance` directly.
class FirebaseService {
  FirebaseAuth get auth => FirebaseAuth.instance;

  FirebaseFirestore get firestore => FirebaseFirestore.instance;

  FirebaseStorage get storage => FirebaseStorage.instance;
}
