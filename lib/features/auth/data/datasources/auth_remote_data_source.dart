import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:staff_app/features/auth/data/models/app_user_model.dart';

class AuthRemoteDataSource {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  static const _salesmenCollection = 'catalog_staff_salesmen';
  static const _usersCollection = 'catalog_users';

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

    final cleanedEmail = email.trim();
    // Display name defaults to the email prefix; admins can edit real
    // details later from the admin panel's Staffs tab.
    final derivedName = cleanedEmail.split('@').first;
    await user.updateDisplayName(derivedName);
    final now = FieldValue.serverTimestamp();

    await _firestore.collection(_usersCollection).doc(user.uid).set({
      'uid': user.uid,
      'fullName': derivedName,
      'email': cleanedEmail,
      'phone': '',
      'region': '',
      'role': 'Salesman',
      'approvalStatus': 'approved',
      'isActive': true,
      'permissions': <String, dynamic>{},
      'createdAt': now,
      'updatedAt': now,
    });

    // Self-owned salesman profile so the admin panel's Staffs tab lists the
    // new salesman immediately.
    await _firestore.collection(_salesmenCollection).doc(user.uid).set({
      'id': user.uid,
      'uid': user.uid,
      'name': derivedName,
      'nameLower': derivedName.toLowerCase(),
      'role': 'Salesman',
      'region': '',
      'phone': '',
      'email': cleanedEmail,
      'emailLower': cleanedEmail.toLowerCase(),
      'imageUrl': null,
      'dealsClosed': 0,
      'monthlyTargetQar': 0,
      'achievedSalesQar': 0,
      'status': 'active',
      'salesMarketAccess': 'both',
      'createdAt': now,
      'updatedAt': now,
    });

    return _buildUser(user);
  }

  Future<void> sendPasswordResetEmail({required String email}) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() {
    return _auth.signOut();
  }

  Future<AppUserModel> _buildUser(User user) async {
    final email = user.email ?? '';
    Map<String, dynamic> userData = const <String, dynamic>{};
    try {
      final userDoc = await _firestore
          .collection(_usersCollection)
          .doc(user.uid)
          .get();
      userData = userDoc.data() ?? const <String, dynamic>{};
    } on FirebaseException catch (e) {
      if (!_isPermissionDenied(e)) rethrow;
    }

    Map<String, dynamic> staffData = const <String, dynamic>{};
    try {
      final staffDoc = await _findSalesmanDoc(user);
      if (staffDoc != null) {
        staffData = staffDoc.data;
      } else {
        // Pre-existing Auth accounts (created before self-registration wrote a
        // salesman profile) have no catalog_staff_salesmen doc, so they never
        // show up in the admin panel's Staffs tab. Backfill a self-owned doc
        // (rules allow create when docId == own uid).
        staffData = await _backfillSalesmanDoc(user, userData);
      }
    } on FirebaseException catch (e) {
      if (!_isPermissionDenied(e)) rethrow;
    }

    final name =
        (userData['fullName'] as String?) ??
        (staffData['name'] as String?) ??
        (user.displayName ?? '');
    final region =
        (userData['region'] as String?) ?? (staffData['region'] as String?) ?? '';
    final phone =
        (userData['phone'] as String?) ?? (staffData['phone'] as String?) ?? '';

    return AppUserModel(
      uid: user.uid,
      email: email,
      name: name,
      region: region,
      phone: phone,
    );
  }

  Future<Map<String, dynamic>> _backfillSalesmanDoc(
    User user,
    Map<String, dynamic> userData,
  ) async {
    final email = (user.email ?? '').trim();
    final name =
        ((userData['fullName'] as String?) ?? user.displayName ?? '').trim();
    final now = FieldValue.serverTimestamp();
    final doc = <String, dynamic>{
      'id': user.uid,
      'uid': user.uid,
      'name': name.isEmpty ? email : name,
      'nameLower': (name.isEmpty ? email : name).toLowerCase(),
      'role': 'Salesman',
      'region': (userData['region'] as String?) ?? '',
      'phone': (userData['phone'] as String?) ?? '',
      'email': email,
      'emailLower': email.toLowerCase(),
      'imageUrl': null,
      'dealsClosed': 0,
      'monthlyTargetQar': 0,
      'achievedSalesQar': 0,
      'status': 'active',
      'salesMarketAccess': 'both',
      'createdAt': now,
      'updatedAt': now,
    };
    await _firestore
        .collection(_salesmenCollection)
        .doc(user.uid)
        .set(doc, SetOptions(merge: true));
    return doc;
  }

  Future<_SalesmanDocHit?> _findSalesmanDoc(User user) async {
    final staff = _firestore.collection(_salesmenCollection);
    final byDocId = await staff.doc(user.uid).get();
    if (byDocId.exists) {
      return _SalesmanDocHit(byDocId.reference, byDocId.data() ?? const {});
    }

    final byUid = await staff.where('uid', isEqualTo: user.uid).limit(1).get();
    if (byUid.docs.isNotEmpty) {
      final doc = byUid.docs.first;
      return _SalesmanDocHit(doc.reference, doc.data());
    }

    final email = (user.email ?? '').trim();
    if (email.isNotEmpty) {
      final byEmail = await staff.where('email', isEqualTo: email).limit(1).get();
      if (byEmail.docs.isNotEmpty) {
        final doc = byEmail.docs.first;
        return _SalesmanDocHit(doc.reference, doc.data());
      }
    }

    return null;
  }

  bool _isPermissionDenied(FirebaseException error) {
    return error.code == 'permission-denied' ||
        error.message?.toLowerCase().contains('permission') == true;
  }
}

class _SalesmanDocHit {
  const _SalesmanDocHit(this.ref, this.data);

  final DocumentReference<Map<String, dynamic>> ref;
  final Map<String, dynamic> data;
}
