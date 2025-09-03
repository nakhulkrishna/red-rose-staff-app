import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserModel {
  final String id;
  final String name;
  final String email;

  UserModel({required this.id, required this.name, required this.email});

  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    return UserModel(
      id: id,
      name: data['username'] ?? '',
      email: data['email'] ?? '',
    );
  }
}

class UserProvider extends ChangeNotifier {
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Check if user is already logged in
  Future<bool> checkLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString('user_id');
    if (id != null) {
      // fetch user data from Firestore
      final doc = await _firestore.collection('staff').doc(id).get();
      if (doc.exists) {
        _currentUser = UserModel.fromMap(doc.data()!, doc.id);
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  // Inside UserProvider
  Future<bool> login(String email, String password) async {
    try {
      // Hash the entered password
      final bytes = utf8.encode(password);
      final hashedPassword = sha256.convert(bytes).toString();

      // Query Firestore with email & hashed password
      QuerySnapshot snapshot = await _firestore
          .collection('staff')
          .where('email', isEqualTo: email)
          .where('password', isEqualTo: hashedPassword)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        _currentUser = UserModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );

        // Save user id and name in shared preferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', _currentUser!.id);
        await prefs.setString(
          'username',
          _currentUser!.name,
        ); // <--- save name

        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      print("Login Error: $e");
      return false;
    }
  }

  Future<String?> getUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  // Logout
  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    _currentUser = null;
    notifyListeners();
  }
}
