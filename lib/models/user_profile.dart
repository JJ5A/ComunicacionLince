import 'package:collection/collection.dart';

enum UserRole { student, professor }

extension UserRoleLabel on UserRole {
  String get label => this == UserRole.professor ? 'Profesor' : 'Alumno';
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.displayName,
    required this.phoneNumber,
    required this.email,
    required this.role,
    this.avatarPath,
    this.bio,
    this.specialty,
    this.contactIds = const <String>[],
  });

  final String id;
  final String displayName;
  final String phoneNumber;
  final String email;
  final UserRole role;
  final String? avatarPath;
  final String? bio;
  final String? specialty;
  final List<String> contactIds;

  bool get isProfessor => role == UserRole.professor;

  String initials() {
    final pieces = displayName.split(' ');
    return pieces.take(2).map((p) => p.isEmpty ? '' : p[0].toUpperCase()).join();
  }

  String maskedPhone({bool showFull = false}) {
    if (showFull) return phoneNumber;
    if (phoneNumber.length < 4) return '••••';
    final tail = phoneNumber.substring(phoneNumber.length - 4);
    return '••••$tail';
  }

  UserProfile copyWith({
    String? displayName,
    String? phoneNumber,
    String? email,
    UserRole? role,
    String? avatarPath,
    String? bio,
    String? specialty,
    List<String>? contactIds,
  }) {
    return UserProfile(
      id: id,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      role: role ?? this.role,
      avatarPath: avatarPath ?? this.avatarPath,
      bio: bio ?? this.bio,
      specialty: specialty ?? this.specialty,
      contactIds: contactIds ?? this.contactIds,
    );
  }

  static UserProfile? findByPhone(String phone, List<UserProfile> pool) {
    return pool.firstWhereOrNull((user) => user.phoneNumber == phone);
  }

  static UserProfile? findByEmail(String email, List<UserProfile> pool) {
    return pool.firstWhereOrNull((user) => user.email == email);
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'display_name': displayName,
      'phone_number': phoneNumber,
      'email': email,
      'role': role.name,
      'avatar_path': avatarPath,
      'bio': bio,
      'specialty': specialty,
      'contact_ids': contactIds,
    }..removeWhere((_, value) => value == null);
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    final contactList = (map['contact_ids'] as List?)?.whereType<String>().toList() ?? const <String>[];
    return UserProfile(
      id: map['id'] as String,
      displayName: map['display_name'] as String? ?? map['displayName'] as String? ?? 'Usuario',
      phoneNumber: map['phone_number'] as String? ?? map['phoneNumber'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: UserRole.values.firstWhere(
        (role) => role.name == (map['role'] as String? ?? '').toLowerCase(),
        orElse: () => UserRole.student,
      ),
      avatarPath: map['avatar_path'] as String?,
      bio: map['bio'] as String?,
      specialty: map['specialty'] as String?,
      contactIds: contactList,
    );
  }
}
