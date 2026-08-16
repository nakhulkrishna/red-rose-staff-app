import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
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
    final cleanedName = name.trim();
    final cleanedEmail = email.trim();
    final now = FieldValue.serverTimestamp();

    // Self-registration contract enforced by firestore.rules on catalog_users:
    // own uid as doc id, role Staff/Salesman, approvalStatus 'pending',
    // isActive false. An admin approves the account from the admin panel.
    await _firestore.collection(_usersCollection).doc(user.uid).set({
      'uid': user.uid,
      'fullName': cleanedName,
      'email': cleanedEmail,
      'phone': phone,
      'region': region,
      'role': 'Salesman',
      'requestedRole': 'Salesman',
      'approvalStatus': 'pending',
      'isActive': false,
      'permissions': <String, dynamic>{},
      'createdAt': now,
      'updatedAt': now,
    });

    // Also create a self-owned salesman profile (allowed by rules for
    // docId == own uid) so the admin panel's Staffs tab lists the new
    // salesman immediately. It starts inactive; the admin's activate toggle
    // also approves the linked catalog_users account by email.
    await _firestore.collection(_salesmenCollection).doc(user.uid).set({
      'id': user.uid,
      'uid': user.uid,
      'name': cleanedName,
      'nameLower': cleanedName.toLowerCase(),
      'role': 'Salesman',
      'region': region,
      'phone': phone,
      'email': cleanedEmail,
      'emailLower': cleanedEmail.toLowerCase(),
      'imageUrl': null,
      'dealsClosed': 0,
      'monthlyTargetQar': 0,
      'achievedSalesQar': 0,
      'status': 'inactive',
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
    await _enforceBanPolicy(user);

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
      staffData = staffDoc?.data ?? const <String, dynamic>{};
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

    // Approval state lives on catalog_users (managed by the admin panel).
    // Missing fields are treated as approved/active so pre-existing salesmen
    // without a catalog_users doc keep working, matching the rules' leniency.
    final statusSource = userData.isNotEmpty ? userData : staffData;

    return AppUserModel(
      uid: user.uid,
      email: email,
      name: name,
      region: region,
      phone: phone,
      approvalStatus: _readApprovalStatus(statusSource),
      isActive: _readIsActive(statusSource),
    );
  }

  String _readApprovalStatus(Map<String, dynamic> data) {
    final raw = data['approvalStatus'];
    if (raw is String && raw.trim().isNotEmpty) return raw.trim();
    return 'approved';
  }

  bool _readIsActive(Map<String, dynamic> data) {
    final raw = data['isActive'];
    if (raw is bool) return raw;
    if (raw is String) return raw.toLowerCase() != 'false';
    return true;
  }

  Future<void> _enforceBanPolicy(User user) async {
    _SalesmanDocHit? staffDoc;
    try {
      staffDoc = await _findSalesmanDoc(user);
    } on FirebaseException catch (e) {
      if (_isPermissionDenied(e)) return;
      rethrow;
    }
    if (staffDoc == null) {
      return;
    }

    final data = staffDoc.data;
    final accountStatus = ((data['accountStatus'] as String?) ?? 'active')
        .trim()
        .toLowerCase();
    if (accountStatus != 'banned') {
      return;
    }

    final rawBanUntil = data['banUntil'];
    final banUntil = rawBanUntil is Timestamp ? rawBanUntil.toDate() : null;
    final now = DateTime.now();

    if (banUntil != null && !banUntil.isAfter(now)) {
      try {
        await _clearExpiredBan(staffDoc.ref);
      } on FirebaseException catch (e) {
        if (!_isPermissionDenied(e)) rethrow;
      }
      return;
    }

    await _auth.signOut();

    final message = banUntil == null
        ? 'Temporarily banned.'
        : 'Temporarily banned until ${DateFormat('dd MMM yyyy, hh:mm a').format(banUntil.toLocal())}.';
    throw FirebaseAuthException(code: 'user-banned', message: message);
  }

  Future<void> _clearExpiredBan(DocumentReference<Map<String, dynamic>> ref) {
    return ref.set({
      'accountStatus': 'active',
      'banUntil': FieldValue.delete(),
      'banReason': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
