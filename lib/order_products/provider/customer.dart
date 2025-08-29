import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class Costomer extends ChangeNotifier {
  Costomer() {
    fetchStaff();
  }

  String _username = '';
  String _phoneNumber = '';
  String searchQuery = "";
  bool _submitted = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _staffList = [];

  // Getters
  String get username => _username;
  String get email => _phoneNumber;

  bool get submitted => _submitted;
  List<Map<String, dynamic>> get staffList => _staffList;

  // Setters
  void setUsername(String value) {
    _username = value;
    notifyListeners();
  }

  void setEmail(String value) {
    _phoneNumber = value;
    notifyListeners();
  }

  void markSubmitted() {
    _submitted = true;
    notifyListeners();
  }
  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }
  bool validateFields() {
    // Qatar numbers must be 8 digits starting with 3,5,6,7
    final qatarPattern = RegExp(r'^[3567][0-9]{7}$');

    return _username.isNotEmpty && qatarPattern.hasMatch(_phoneNumber);
  }

  Future<void> submitStaff() async {
    if (!validateFields()) {
      throw Exception('Please fill all fields correctly.');
    }

    await _firestore.collection('customers').add({
      'username': _username,
      'phoneNumber': _phoneNumber,

      'createdAt': FieldValue.serverTimestamp(),
    });

    _username = '';
    _phoneNumber = '';

    _submitted = false;
    notifyListeners();

    await fetchStaff(); // Refresh list after adding
  }
  List<Map<String, dynamic>> get filteredStaff {
    if (searchQuery.isEmpty) return _staffList;

    final query = searchQuery.toLowerCase().trim();

    return _staffList.where((customer) {
      final name = (customer['username'] ?? '').toLowerCase();
      final phone = (customer['phoneNumber'] ?? '').toLowerCase();
      return name.contains(query) || phone.contains(query);
    }).toList();
  }

  // --------------------------
  // Fetch all staff
  // --------------------------
  Future<void> fetchStaff() async {
    final querySnapshot = await _firestore
        .collection('customers')
        .orderBy('createdAt', descending: true)
        .get();

    _staffList = querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id; // add doc id for delete
      return data;
    }).toList();

    notifyListeners();
  }

  Future<void> deleteStaff(String docId) async {
    await _firestore.collection('staff').doc(docId).delete();
    _staffList.removeWhere((staff) => staff['id'] == docId);
    notifyListeners();
  }
}
