import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String? phone;
  final String? pincode;
  final String? city;
  final String? state;
  final String? language;
  final String? languageCode;
  final DateTime createdAt;
  final DateTime? lastSignIn;

  const UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.phone,
    this.pincode,
    this.city,
    this.state,
    this.language,
    this.languageCode,
    required this.createdAt,
    this.lastSignIn,
  });

  // Create from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Handle null timestamps safely
    DateTime createdAt;
    try {
      final createdAtTimestamp = data['createdAt'] as Timestamp?;
      createdAt = createdAtTimestamp?.toDate() ?? DateTime.now();
    } catch (e) {
      // Error parsing createdAt timestamp
      createdAt = DateTime.now();
    }
    
    DateTime? lastSignIn;
    try {
      final lastSignInTimestamp = data['lastSignIn'] as Timestamp?;
      lastSignIn = lastSignInTimestamp?.toDate();
    } catch (e) {
      // Error parsing lastSignIn timestamp
      lastSignIn = null;
    }
    
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'],
      pincode: data['pincode'],
      city: data['city'],
      state: data['state'],
      language: data['language'],
      languageCode: data['languageCode'],
      createdAt: createdAt,
      lastSignIn: lastSignIn,
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'phone': phone,
      'pincode': pincode,
      'city': city,
      'state': state,
      'language': language,
      'languageCode': languageCode,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastSignIn': lastSignIn != null ? Timestamp.fromDate(lastSignIn!) : null,
    };
  }

  // Create a copy with updated fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? phone,
    String? pincode,
    String? city,
    String? state,
    String? language,
    String? languageCode,
    DateTime? createdAt,
    DateTime? lastSignIn,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      pincode: pincode ?? this.pincode,
      city: city ?? this.city,
      state: state ?? this.state,
      language: language ?? this.language,
      languageCode: languageCode ?? this.languageCode,
      createdAt: createdAt ?? this.createdAt,
      lastSignIn: lastSignIn ?? this.lastSignIn,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.uid == uid &&
        other.email == email &&
        other.name == name &&
        other.phone == phone &&
        other.pincode == pincode &&
        other.city == city &&
        other.state == state &&
        other.language == language &&
        other.languageCode == languageCode;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
        email.hashCode ^
        name.hashCode ^
        phone.hashCode ^
        pincode.hashCode ^
        city.hashCode ^
        state.hashCode ^
        language.hashCode ^
        languageCode.hashCode;
  }
} 