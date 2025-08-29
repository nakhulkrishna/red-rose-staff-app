import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WhatsAppNumberProvider extends ChangeNotifier {
  String _number = "";
  String _countryCode = "+91";

  String get number => _number;
  String get countryCode => _countryCode;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> loadNumber() async {
    final prefs = await SharedPreferences.getInstance();
    _number = prefs.getString('whatsapp_number') ?? "";
    _countryCode = prefs.getString('whatsapp_country_code') ?? "+91";
    notifyListeners();
  }

  Future<void> saveNumber(String number, {String? code}) async {
    _countryCode = code ?? _countryCode;
    String formattedNumber = number.startsWith('+') ? number : "$_countryCode$number";
    _number = formattedNumber;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('whatsapp_number', _number);
    await prefs.setString('whatsapp_country_code', _countryCode);

    try {
      await _firestore.collection('order_whatsapp').doc('main_number').set({
        'number': _number,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error saving number to Firestore: $e");
    }

    notifyListeners();
  }

  bool validateNumber(String number) {
    final regExp = RegExp(r'^\+?\d{6,15}$');
    return regExp.hasMatch(number);
  }
}
