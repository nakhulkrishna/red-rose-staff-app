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

  Future<bool> isRegistrationEnabled() async {
    try {
      final doc = await _firestore.collection('AppConfig').doc('registration').get();
      if (doc.exists) {
        return doc.data()?['status'] == 'ON';
      }
      return false; // default to false if not set
    } catch (e) {
      print("Error fetching registration toggle: $e");
      return false;
    }
  }

  Future<bool> checkLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString('user_id');
    if (id != null) {
      final doc = await _firestore.collection('staff').doc(id).get();
      if (doc.exists) {
        _currentUser = UserModel.fromMap(doc.data()!, doc.id);
        notifyListeners();
        return true;
      }
    }
    return false;
  }


  // Login function
Future<bool> login(String email, String password) async {
  if (!isValidEmail(email)) {
    print("Invalid email format");
    return false;
  }

  try {
    final bytes = utf8.encode(password);
    final hashedPassword = sha256.convert(bytes).toString();

    QuerySnapshot snapshot = await _firestore
        .collection('staff')
        .where('email', isEqualTo: email)
        .where('password', isEqualTo: hashedPassword)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      _currentUser = UserModel.fromMap(
          doc.data() as Map<String, dynamic>, doc.id);

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', _currentUser!.id);
      await prefs.setString('username', _currentUser!.name);

      notifyListeners();
      return true;
    }

    return false;
  } catch (e) {
    print("Login Error: $e");
    return false;
  }
}

  // Registration function
Future<bool> register(String name, String email, String password) async {
  if (!isValidEmail(email)) {
    print("Invalid email format");
    return false;
  }

  try {
    final bytes = utf8.encode(password);
    final hashedPassword = sha256.convert(bytes).toString();

    QuerySnapshot existing = await _firestore
        .collection('staff')
        .where('email', isEqualTo: email)
        .get();

    if (existing.docs.isNotEmpty) {
      print("Email already exists");
      return false;
    }

    DocumentReference doc = await _firestore.collection('staff').add({
      'username': name,
      'email': email,
      'password': hashedPassword,
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', doc.id);
    await prefs.setString('username', name);

    _currentUser = UserModel(id: doc.id, name: name, email: email);
    notifyListeners();

    return true;
  } catch (e) {
    print("Registration Error: $e");
    return false;
  }
}

  // Logout
  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    _currentUser = null;
    notifyListeners();
  }
  bool isValidEmail(String email) {
  final emailRegex = RegExp(
    r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
  );
  return emailRegex.hasMatch(email);
}

}

// class UserProvider extends ChangeNotifier {
//   UserModel? _currentUser;

//   UserModel? get currentUser => _currentUser;

//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   // Check if user is already logged in
//   Future<bool> checkLogin() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String? id = prefs.getString('user_id');
//     if (id != null) {
//       // fetch user data from Firestore
//       final doc = await _firestore.collection('Admin').doc(id).get();
//       if (doc.exists) {
//         _currentUser = UserModel.fromMap(doc.data()!, doc.id);
//         notifyListeners();
//         return true;
//       }
//     }
//     return false;
//   }

//   // Inside UserProvider
//   Future<bool> login(String email, String password) async {
//     try {
//       // Hash the entered password
//       final bytes = utf8.encode(password);
//       final hashedPassword = sha256.convert(bytes).toString();

//       // Query Firestore with email & hashed password
//       QuerySnapshot snapshot = await _firestore
//           .collection('Admin')
//           .where('email', isEqualTo: email)
//           .where('password', isEqualTo: hashedPassword)
//           .get();

//       if (snapshot.docs.isNotEmpty) {
//         final doc = snapshot.docs.first;
//         _currentUser = UserModel.fromMap(
//           doc.data() as Map<String, dynamic>,
//           doc.id,
//         );

//         // Save user id and name in shared preferences
//         SharedPreferences prefs = await SharedPreferences.getInstance();
//         await prefs.setString('user_id', _currentUser!.id);
//         await prefs.setString(
//           'username',
//           _currentUser!.name,
//         ); // <--- save name

//         notifyListeners();
//         return true;
//       }

//       return false;
//     } catch (e) {
//       print("Login Error: $e");
//       return false;
//     }
//   }

//   Future<String?> getUserName() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     return prefs.getString('user_name');
//   }

//   // Logout
//   Future<void> logout() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     await prefs.remove('user_id');
//     _currentUser = null;
//     notifyListeners();
//   }
// }
