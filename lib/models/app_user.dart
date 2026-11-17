// lib/models/app_user.dart

enum UserRole { admin, coach, player }

class AppUser {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? photo;
  final String? teamId;

  ///  معرّف الأكاديمية
  final String academyId;

  ///  اسم الأكاديمية
  final String academyName;

  ///  جديد: رقم التليفون
  final String phone;

  ///  جديد: العنوان
  final String address;

  ///  جديد: الرقم الوظيفي (بيتولّد تلقائي)
  final String jobNumber;

  ///  جديد: تاريخ الانضمام
  final String joinDate;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.photo,
    this.teamId,
    this.academyId = '',
    this.academyName = '',
    this.phone = '',
    this.address = '',
    this.jobNumber = '',
    this.joinDate = '',
  });

  //  helper methods
  bool get isAdmin => role == UserRole.admin;
  bool get isCoach => role == UserRole.coach;
  bool get isPlayer => role == UserRole.player;

  ///  هل المستخدم مرتبط بأكاديمية؟
  bool get hasAcademy => academyId.isNotEmpty;

  ///  هل عنده رقم تليفون؟
  bool get hasPhone => phone.isNotEmpty;

  ///  هل عنده عنوان؟
  bool get hasAddress => address.isNotEmpty;

  //  اسم الدور بالعربي
  String get roleLabel {
    switch (role) {
      case UserRole.admin:
        return 'مدير';
      case UserRole.coach:
        return 'مدرب';
      case UserRole.player:
        return 'لاعب';
    }
  }

  // ============================================================
  // toMap / fromMap
  // ============================================================
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role.name,
        'photo': photo,
        'team_id': teamId,
        'academy_id': academyId,
        'academy_name': academyName,
        'phone': phone,           //  جديد
        'address': address,       //  جديد
        'job_number': jobNumber,  //  جديد
        'join_date': joinDate,    //  جديد
      };

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
        id: map['id'] as String? ?? '',
        name: map['name'] as String? ?? '',
        email: map['email'] as String? ?? '',
        role: UserRole.values.firstWhere(
          (r) => r.name == map['role'],
          orElse: () => UserRole.player,
        ),
        photo: map['photo'] as String?,
        teamId: map['team_id'] as String?,
        academyId: map['academy_id'] as String? ?? '',
        academyName: map['academy_name'] as String? ?? '',
        phone: map['phone'] as String? ?? '',           //  جديد
        address: map['address'] as String? ?? '',       //  جديد
        jobNumber: map['job_number'] as String? ?? '',  //  جديد
        joinDate: map['join_date'] as String? ?? '',    //  جديد
      );

  // ============================================================
  // copyWith
  // ============================================================
  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? photo,
    String? teamId,
    String? academyId,
    String? academyName,
    String? phone,      //  جديد
    String? address,    //  جديد
    String? jobNumber,  //  جديد
    String? joinDate,   //  جديد
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      photo: photo ?? this.photo,
      teamId: teamId ?? this.teamId,
      academyId: academyId ?? this.academyId,
      academyName: academyName ?? this.academyName,
      phone: phone ?? this.phone,           //  جديد
      address: address ?? this.address,     //  جديد
      jobNumber: jobNumber ?? this.jobNumber, //  جديد
      joinDate: joinDate ?? this.joinDate,  //  جديد
    );
  }
}