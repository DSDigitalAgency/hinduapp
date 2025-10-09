import 'dart:convert';
import 'package:flutter/services.dart';

class PincodeService {
  static Map<String, dynamic>? _pincodeData;
  
  // Load pincode data from JSON asset
  static Future<void> loadPincodeData() async {
    if (_pincodeData != null) return; // Already loaded
    
    try {
      final String jsonString = await rootBundle.loadString('assets/data/pincodes.json');
      _pincodeData = json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      _pincodeData = {};
    }
  }
  
  // Get city and state for a given pincode
  static Future<PincodeInfo?> getPincodeInfo(String pincode) async {
    await loadPincodeData();
    
    if (_pincodeData == null || !_pincodeData!.containsKey(pincode)) {
      return null;
    }
    
    final data = _pincodeData![pincode] as Map<String, dynamic>;
    return PincodeInfo(
      pincode: data['pincode'] as String,
      city: data['city'] as String,
      state: data['state'] as String,
    );
  }
  
  // Check if pincode exists in our database
  static Future<bool> isValidPincode(String pincode) async {
    await loadPincodeData();
    return _pincodeData?.containsKey(pincode) ?? false;
  }
  
  // Get all available pincodes (for debugging/admin purposes)
  static Future<List<String>> getAllPincodes() async {
    await loadPincodeData();
    return _pincodeData?.keys.toList() ?? [];
  }
}

class PincodeInfo {
  final String pincode;
  final String city;
  final String state;
  
  PincodeInfo({
    required this.pincode,
    required this.city,
    required this.state,
  });
  
  @override
  String toString() {
    return '$city, $state - $pincode';
  }
  
  Map<String, dynamic> toJson() {
    return {
      'pincode': pincode,
      'city': city,
      'state': state,
    };
  }
} 