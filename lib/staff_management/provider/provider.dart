import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class StaffProvider extends ChangeNotifier {
 StaffProvider (){
  fetchStaff();
 }

  String _username = '';
  String _email = '';
  String _password = '';
  bool _obscurePassword = true;
  bool _submitted = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _staffList = [];

  // Getters
  String get username => _username;
  String get email => _email;
  String get password => _password;
  bool get obscurePassword => _obscurePassword;
  bool get submitted => _submitted;
  List<Map<String, dynamic>> get staffList => _staffList;

  // Setters
  void setUsername(String value) {
    _username = value;
    notifyListeners();
  }

  void setEmail(String value) {
    _email = value;
    notifyListeners();
  }

  void setPassword(String value) {
    _password = value;
    notifyListeners();
  }

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void markSubmitted() {
    _submitted = true;
    notifyListeners();
  }

  bool validateFields() {
    return _username.isNotEmpty &&
        _email.contains('@') &&
        _password.length >= 6;
  }

  Future<void> submitStaff() async {
    if (!validateFields()) {
      throw Exception('Please fill all fields correctly.');
    }

    final bytes = utf8.encode(_password);
    final hashedPassword = sha256.convert(bytes).toString();

    await _firestore.collection('staff').add({
      'username': _username,
      'email': _email,
      'password': hashedPassword,
      'createdAt': FieldValue.serverTimestamp(),
    });

    _username = '';
    _email = '';
    _password = '';
    _submitted = false;
    notifyListeners();

    await fetchStaff(); // Refresh list after adding
  }

  // --------------------------
  // Fetch all staff
  // --------------------------
  Future<void> fetchStaff() async {
    final querySnapshot = await _firestore
        .collection('staff')
        .orderBy('createdAt', descending: true)
        .get();

    _staffList = querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id; // add doc id for delete
      return data;
    }).toList();

    notifyListeners();
  }

  // --------------------------
  // Delete a staff member
  // --------------------------
  Future<void> deleteStaff(String docId) async {
    await _firestore.collection('staff').doc(docId).delete();
    _staffList.removeWhere((staff) => staff['id'] == docId);
    notifyListeners();
  }
}
