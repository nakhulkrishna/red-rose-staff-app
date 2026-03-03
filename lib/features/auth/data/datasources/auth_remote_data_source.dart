import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
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
    final now = FieldValue.serverTimestamp();
    final staffPayload = <String, dynamic>{
      'id': staffCode,
      'uid': user.uid,
      'name': cleanedName,
      'nameLower': cleanedName.toLowerCase(),
      'region': region,
      'phone': phone,
      'email': cleanedEmail,
      'role': 'Salesman',
      'status': 'active',
      'isActive': true,
      'approvalStatus': 'approved',
      'accountStatus': 'active',
      'banUntil': null,
      'banReason': null,
      'imageUrl': null,
      'achievedSalesQar': 0,
      'monthlyTargetQar': 0,
      'dealsClosed': 0,
      'createdAt': now,
      'updatedAt': now,
    };

    await _firestore
        .collection(_salesmenCollection)
        .doc(staffCode)
        .set(staffPayload, SetOptions(merge: true));
    await _firestore
        .collection(_salesmenCollection)
        .doc(user.uid)
        .set(staffPayload, SetOptions(merge: true));

    return _buildUser(user);
  }

  Future<void> signOut() {
    return _auth.signOut();
  }

  Future<AppUserModel> _buildUser(User user) async {
    await _enforceBanPolicy(user);

    final email = user.email ?? '';
    Map<String, dynamic> data = const <String, dynamic>{};
    try {
      final staffDoc = await _findSalesmanDoc(user);
      data = staffDoc?.data ?? const <String, dynamic>{};
    } on FirebaseException catch (e) {
      if (!_isPermissionDenied(e)) rethrow;
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

class _SalesmanDocHit {
  const _SalesmanDocHit(this.ref, this.data);

  final DocumentReference<Map<String, dynamic>> ref;
  final Map<String, dynamic> data;
}
