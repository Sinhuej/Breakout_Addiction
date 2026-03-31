import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/support_contact.dart';

class SupportContactRepository {
  static const String _storageKey = 'trusted_support_contact';

  Future<SupportContact?> getContact() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final contact = SupportContact.fromMap(decoded);
    return contact.isValid ? contact : null;
  }

  Future<void> saveContact(SupportContact contact) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(contact.toMap()));
  }

  Future<void> clearContact() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
