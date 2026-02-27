import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:staff_app/features/auth/data/models/app_user_model.dart';

class AuthRemoteDataSource {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  static const _salesmenCollection = 'catalog_staff_salesmen';

  const AuthRemoteDataSource(this._auth, this._firestore);

  Future<AppUserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }

    return _buildUser(user);
  }

  Stream<AppUserModel?> authStateChanges() {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      return _buildUser(user);
    });
  }

  Future<AppUserModel> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No user returned after sign in.',
      );
    }
    return _buildUser(user);
  }

  Future<AppUserModel> signUp({
    required String name,
    required String region,
    required String phone,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'registration-failed',
        message: 'Could not create account.',
      );
    }

    await user.updateDisplayName(name);
    final staffCode = await _generateNextStaffCode();
    final cleanedName = name.trim();
    final cleanedEmail = email.trim();

    await _firestore.collection(_salesmenCollection).doc(staffCode).set({
      'id': staffCode,
      'name': cleanedName,
      'nameLower': cleanedName.toLowerCase(),
      'region': region,
      'phone': phone,
      'email': cleanedEmail,
      'role': 'Salesman',
      'status': 'active',
      'imageUrl': null,
      'achievedSalesQar': 0,
      'monthlyTargetQar': 0,
      'dealsClosed': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return _buildUser(user);
  }

  Future<void> signOut() {
    return _auth.signOut();
  }

  Future<AppUserModel> _buildUser(User user) async {
    final email = user.email ?? '';
    Map<String, dynamic> data = <String, dynamic>{};
    if (email.isNotEmpty) {
      final byEmail = await _firestore
          .collection(_salesmenCollection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (byEmail.docs.isNotEmpty) {
        data = byEmail.docs.first.data();
      }
    }

    final name = (data['name'] as String?) ?? (user.displayName ?? '');
    final region = (data['region'] as String?) ?? '';
    final phone = (data['phone'] as String?) ?? '';

    return AppUserModel(
      uid: user.uid,
      email: email,
      name: name,
      region: region,
      phone: phone,
    );
  }

  Future<String> _generateNextStaffCode() async {
    final snapshot = await _firestore.collection(_salesmenCollection).get();
    var maxNumber = 0;

    for (final doc in snapshot.docs) {
      final id = doc.id;
      final match = RegExp(r'^SM-(\d+)$').firstMatch(id);
      if (match == null) continue;
      final value = int.tryParse(match.group(1) ?? '');
      if (value == null) continue;
      if (value > maxNumber) maxNumber = value;
    }

    final next = maxNumber + 1;
    return 'SM-${next.toString().padLeft(3, '0')}';
  }
}
