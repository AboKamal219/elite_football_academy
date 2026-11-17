// lib/services/auth_service.dart

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../models/app_user.dart';
import 'coach_service.dart';
import 'player_service.dart';
import 'team_service.dart';
import 'training_service.dart';
import 'match_service.dart';
import 'notification_service.dart';
import 'tournament_service.dart';
import 'report_service.dart';
import 'attendance_service.dart';
import 'supabase_service.dart';

// ============================================================
// ENUMS (unchanged — the UI switches over them)
// ============================================================
enum SignupResult {
  success,
  emailAlreadyExists,
  invalidAcademyCode,
  academyNameTaken,
  emailVerificationRequired, // Confirm-email is ON: a 6-digit code was e-mailed
  unknownError,
}

enum ChangePasswordResult {
  success,
  wrongOldPassword,
  mockAccount,
  notLoggedIn,
  error,
}

enum LoginIssue { none, emailNotConfirmed }

class _AuthNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

class AuthService {
  static AppUser? _currentUser;
  /// why the last login() returned null (lets the screen route to the verify page)
  static LoginIssue lastLoginIssue = LoginIssue.none;
  static AppUser? get currentUser => _currentUser;

  static final _AuthNotifier notifier = _AuthNotifier();
  static Listenable get listenable => notifier;

  static void init() {
    SupabaseService.setAcademyIdResolver(() => _currentUser?.academyId ?? '');
  }

  static UserRole _roleFrom(dynamic v) {
    if (v is UserRole) return v;
    if (v is String) {
      return UserRole.values
          .firstWhere((r) => r.name == v, orElse: () => UserRole.player);
    }
    return UserRole.player;
  }

  static AppUser _userFromMap(Map<String, dynamic> data) => AppUser(
        id: data['id'] as String? ?? '',
        name: data['name'] as String? ?? '',
        email: data['email'] as String? ?? '',
        role: _roleFrom(data['role']),
        teamId: data['team_id'] as String?,
        academyId: data['academy_id'] as String? ?? '',
        academyName: data['academy_name'] as String? ?? '',
        phone: data['phone'] as String? ?? '',
        address: data['address'] as String? ?? '',
        jobNumber: data['job_number'] as String? ?? '',
        joinDate: data['join_date'] as String? ?? '',
        photo: data['photo'] as String?,
      );

  static Future<void> _safeSignOut() async {
    try {
      await SupabaseService.client.auth.signOut();
    } catch (_) {}
  }

  // ============================================================
  // LOGIN
  // ============================================================
  static Future<AppUser?> login(String email, String password) async {
    final key = email.trim().toLowerCase();
    lastLoginIssue = LoginIssue.none;
    if (!SupabaseService.isInitialized) return null;

    try {
      final response = await SupabaseService.client.auth
          .signInWithPassword(email: key, password: password);
      final uid = response.user?.id;
      if (uid == null) return null;

      var user = await _fetchUserFromSupabase(uid);
      if (user == null) {
        // Verified account whose profile was never created (signup interrupted
        // before e-mail verification finished): build it from the signup metadata.
        final done = await _completeProfile();
        user = done.user;
      }
      if (user == null) {
        await _safeSignOut();
        return null;
      }
      _currentUser = user;
      await _saveUserLocally(user);
      notifier.notify();
      return user;
    } on sb.AuthException catch (e) {
      if (e.code == 'email_not_confirmed' ||
          e.message.toLowerCase().contains('email not confirmed')) {
        lastLoginIssue = LoginIssue.emailNotConfirmed;
      }
      if (kDebugMode) debugPrint('Login Error: $e');
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('Login Error: $e');
      return null;
    }
  }

  static Future<AppUser?> _fetchUserFromSupabase(String userId) async {
    try {
      final data = await SupabaseService.client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (data == null) return null;

      var academyName = data['academy_name'] as String? ?? '';
      final academyId = data['academy_id'] as String? ?? '';
      if (academyId.isNotEmpty) {
        try {
          final academy = await SupabaseService.client
              .from('academies')
              .select('name')
              .eq('id', academyId)
              .maybeSingle();
          academyName = academy?['name'] as String? ?? academyName;
        } catch (_) {}
      }
      return _userFromMap({...data, 'academy_name': academyName});
    } catch (e) {
      if (kDebugMode) debugPrint('Fetch User Error: $e');
      return null;
    }
  }

  /// Re-reads the profile from the server (team_id changes when an admin
  /// assigns a coach/player to a team). Safe to call any time.
  static Future<AppUser?> refreshCurrentUser() async {
    final uid = SupabaseService.authUser?.id;
    if (uid == null) return _currentUser;
    final fresh = await _fetchUserFromSupabase(uid);
    if (fresh != null) {
      _currentUser = fresh;
      await _saveUserLocally(fresh);
      notifier.notify();
    }
    return _currentUser;
  }

  // ============================================================
  // SIGNUP — the SERVER decides role + academy (RPC), never the client
  // ============================================================
  static Future<({AppUser? user, SignupResult result})> signup({
    required String name,
    required String email,
    required String password,
    String academyCode = '',
    String newAcademyName = '',
    String phone = '',
    String address = '',
  }) async {
    final key = email.trim().toLowerCase();

    if (!SupabaseService.isInitialized ||
        (newAcademyName.trim().isEmpty && academyCode.trim().isEmpty)) {
      return (user: null, result: SignupResult.unknownError);
    }

    try {
      final client = SupabaseService.client;

      // 1) validate BEFORE creating the auth user (no orphan accounts)
      if (newAcademyName.trim().isNotEmpty) {
        final free = await client
            .rpc('academy_name_available', params: {'p_name': newAcademyName.trim()});
        if (free != true) {
          return (user: null, result: SignupResult.academyNameTaken);
        }
      } else {
        final kind = await client
            .rpc('check_signup_code', params: {'p_code': academyCode.trim()});
        if (kind == null) {
          return (user: null, result: SignupResult.invalidAcademyCode);
        }
      }

      // 2) auth user. The signup intent travels in the user metadata so the
      //    server can finish the profile (complete_signup) after the user
      //    verifies the e-mail — the ROLE is never sent: the code decides it.
      final sb.AuthResponse r;
      try {
        r = await client.auth.signUp(
          email: key,
          password: password,
          data: {
            'name': name.trim(),
            'phone': phone,
            'address': address,
            if (newAcademyName.trim().isNotEmpty)
              'new_academy_name': newAcademyName.trim()
            else
              'academy_code': academyCode.trim(),
          },
        );
      } on sb.AuthException catch (e) {
        final m = e.message.toLowerCase();
        if (m.contains('already registered') || m.contains('already exists')) {
          return (user: null, result: SignupResult.emailAlreadyExists);
        }
        if (kDebugMode) debugPrint('signUp error: $e');
        return (user: null, result: SignupResult.unknownError);
      }

      // "Confirm email" ON + address already registered: Supabase hides it by
      // returning a user with NO identities.
      if (r.user != null && (r.user!.identities?.isEmpty ?? false)) {
        return (user: null, result: SignupResult.emailAlreadyExists);
      }

      // "Confirm email" ON: no session until the user types the e-mailed code.
      if (r.session == null) {
        return (user: null, result: SignupResult.emailVerificationRequired);
      }

      // "Confirm email" OFF (development): finish immediately.
      final done = await _completeProfile();
      if (done.user == null) {
        final code = done.error;
        if (code == 'academy_name_taken') {
          return (user: null, result: SignupResult.academyNameTaken);
        }
        if (code == 'invalid_academy_code') {
          return (user: null, result: SignupResult.invalidAcademyCode);
        }
        if (code == 'profile_exists') {
          return (user: null, result: SignupResult.emailAlreadyExists);
        }
        return (user: null, result: SignupResult.unknownError);
      }
      return (user: done.user, result: SignupResult.success);
    } catch (e) {
      if (kDebugMode) debugPrint('General Signup Error: $e');
      return (user: null, result: SignupResult.unknownError);
    }
  }

  // ============================================================
  // Finishes the profile on the server (RPC complete_signup) for the
  // CURRENT session, then loads it. Returns an error key on failure.
  // ============================================================
  static Future<({AppUser? user, String? error})> _completeProfile() async {
    final client = SupabaseService.client;
    final authUser = client.auth.currentUser;
    if (authUser == null) return (user: null, error: 'not_authenticated');
    try {
      await client.rpc('complete_signup');
      final user = await _fetchUserFromSupabase(authUser.id);
      if (user == null) return (user: null, error: 'error');
      _currentUser = user;
      await _saveUserLocally(user);
      notifier.notify();
      return (user: user, error: null);
    } on sb.PostgrestException catch (e) {
      final m = e.message;
      String key = 'error';
      for (final k in const [
        'academy_name_taken',
        'invalid_academy_code',
        'profile_exists',
        'missing_signup_data',
      ]) {
        if (m.contains(k)) key = k;
      }
      if (kDebugMode) debugPrint('complete_signup: $e');
      await _safeSignOut();
      return (user: null, error: key);
    } catch (e) {
      if (kDebugMode) debugPrint('complete_signup: $e');
      return (user: null, error: 'error');
    }
  }

  // ============================================================
  // E-MAIL VERIFICATION (6-digit code from the inbox)
  // ============================================================
  static Future<({AppUser? user, String? error})> verifySignupCode(
      String email, String code) async {
    if (!SupabaseService.isInitialized) return (user: null, error: 'error');
    try {
      final r = await SupabaseService.client.auth.verifyOTP(
        type: sb.OtpType.signup,
        email: email.trim().toLowerCase(),
        token: code.trim(),
      );
      if (r.session == null &&
          SupabaseService.client.auth.currentSession == null) {
        return (user: null, error: 'invalid_code');
      }
      return await _completeProfile();
    } on sb.AuthException catch (e) {
      if (kDebugMode) debugPrint('verifySignupCode: $e');
      return (user: null, error: 'invalid_code');
    } catch (e) {
      if (kDebugMode) debugPrint('verifySignupCode: $e');
      return (user: null, error: 'error');
    }
  }

  static Future<bool> resendSignupCode(String email) async {
    if (!SupabaseService.isInitialized) return false;
    try {
      await SupabaseService.client.auth
          .resend(type: sb.OtpType.signup, email: email.trim().toLowerCase());
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('resendSignupCode: $e');
      return false;
    }
  }

  static Future<String?> getAcademyCode() async {
    final codes = await SupabaseService.getAcademyCodes();
    final c = codes?['admin'];
    return (c == null || c.isEmpty) ? null : c;
  }

  // ============================================================
  // PROFILE UPDATE — returns false if the server did not save it
  // (it used to return true even when the update failed)
  // ============================================================
  /// Why the last updateUser() returned false (shown to the user to diagnose).
  static String? lastUpdateError;

  static Future<bool> updateUser(AppUser updatedUser) async {
    lastUpdateError = null;
    if (!SupabaseService.isInitialized || !SupabaseService.isLoggedIn) {
      lastUpdateError = 'not_logged_in';
      return false;
    }
    try {
      // only the fields a user may edit; role/academy/team are server-owned
      final res = await SupabaseService.client
          .from('users')
          .update({
            'name': updatedUser.name,
            'phone': updatedUser.phone,
            'address': updatedUser.address,
            'photo': updatedUser.photo,
          })
          .eq('id', updatedUser.id)
          .select('id');
      if (res.isEmpty) {
        lastUpdateError =
            'no_row_updated (id=${updatedUser.id}, auth=${SupabaseService.authUser?.id})';
        return false;
      }

      // keep server-owned fields from the cached user
      final merged = (_currentUser ?? updatedUser).copyWith(
        name: updatedUser.name,
        phone: updatedUser.phone,
        address: updatedUser.address,
        photo: updatedUser.photo,
      );
      _currentUser = merged;
      await _saveUserLocally(merged);
      notifier.notify();
      return true;
    } catch (e) {
      lastUpdateError = e.toString();
      if (kDebugMode) debugPrint('updateUser: $e');
      return false;
    }
  }

  static Future<ChangePasswordResult> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final user = _currentUser;
    if (user == null) return ChangePasswordResult.notLoggedIn;
    if (!SupabaseService.isInitialized) return ChangePasswordResult.error;

    try {
      if (SupabaseService.authUser == null) {
        return ChangePasswordResult.notLoggedIn;
      }
      try {
        await SupabaseService.client.auth
            .signInWithPassword(email: user.email, password: oldPassword);
      } on sb.AuthException {
        return ChangePasswordResult.wrongOldPassword;
      }
      await SupabaseService.client.auth
          .updateUser(sb.UserAttributes(password: newPassword));
      return ChangePasswordResult.success;
    } catch (_) {
      return ChangePasswordResult.error;
    }
  }

  // ============================================================
  // FORGOT PASSWORD — really sends the reset e-mail now
  // (the screen used to fake it with Future.delayed)
  // ============================================================
  static Future<bool> sendPasswordReset(String email) async {
    if (!SupabaseService.isInitialized) return false;
    try {
      await SupabaseService.client.auth
          .resetPasswordForEmail(email.trim().toLowerCase());
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('sendPasswordReset: $e');
      return false;
    }
  }

  // ============================================================
  // RESET PASSWORD WITH THE CODE FROM THE E-MAIL
  //   returns null on success, else: invalid_code | same_password |
  //   weak_password | error
  // ============================================================
  static Future<String?> resetPasswordWithCode({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    if (!SupabaseService.isInitialized) return 'error';
    final client = SupabaseService.client;
    try {
      final r = await client.auth.verifyOTP(
        type: sb.OtpType.recovery,
        email: email.trim().toLowerCase(),
        token: code.trim(),
      );
      if (r.session == null && client.auth.currentSession == null) {
        return 'invalid_code';
      }
      try {
        await client.auth.updateUser(sb.UserAttributes(password: newPassword));
      } on sb.AuthException catch (e) {
        await _safeSignOut();
        if (e.code == 'same_password') return 'same_password';
        if (e.code == 'weak_password') return 'weak_password';
        return 'error';
      }
      await _safeSignOut(); // the user logs in again with the new password
      return null;
    } on sb.AuthException catch (e) {
      if (kDebugMode) debugPrint('resetPasswordWithCode: $e');
      return 'invalid_code';
    } catch (e) {
      if (kDebugMode) debugPrint('resetPasswordWithCode: $e');
      return 'error';
    }
  }

  // ============================================================
  // DELETE ACCOUNT (RPC) — backend ready for a button/flow
  // ============================================================
  /// null = deleted. Otherwise: not_authenticated | last_admin_has_members | error
  static Future<String?> deleteAccount() async {
    if (!SupabaseService.isInitialized || !SupabaseService.isLoggedIn) {
      return 'not_authenticated';
    }
    try {
      await SupabaseService.client.rpc('delete_my_account');
      await logout();
      return null;
    } on sb.PostgrestException catch (e) {
      if (e.message.contains('last_admin_has_members')) {
        return 'last_admin_has_members';
      }
      if (kDebugMode) debugPrint('deleteAccount: $e');
      return 'error';
    } catch (e) {
      if (kDebugMode) debugPrint('deleteAccount: $e');
      return 'error';
    }
  }

  // ============================================================
  // LOCAL SESSION
  // ============================================================
  static Future<void> _saveUserLocally(AppUser user) async {
    SupabaseService.setAcademyId(user.academyId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);
    await prefs.setString('user_id', user.id);
    await prefs.setString('user_name', user.name);
    await prefs.setString('user_email', user.email);
    await prefs.setString('user_role', user.role.name);
    await prefs.setString('user_academy_id', user.academyId);
    await prefs.setString('user_academy_name', user.academyName);
    await prefs.setString('user_phone', user.phone);
    await prefs.setString('user_address', user.address);
    await prefs.setString('user_job_number', user.jobNumber);
    await prefs.setString('user_join_date', user.joinDate);
    if (user.photo != null) {
      await prefs.setString('user_photo', user.photo!);
    } else {
      await prefs.remove('user_photo');
    }
    // team can become empty (coach unassigned) -> must clear the old value
    if (user.teamId != null && user.teamId!.isNotEmpty) {
      await prefs.setString('user_team_id', user.teamId!);
    } else {
      await prefs.remove('user_team_id');
    }
  }

  static Future<AppUser?> loadUserFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!(prefs.getBool('is_logged_in') ?? false)) return null;

      final id = prefs.getString('user_id');
      final name = prefs.getString('user_name');
      final email = prefs.getString('user_email');
      final roleName = prefs.getString('user_role');
      if (id == null || name == null || email == null || roleName == null) {
        return null;
      }

      // The stored copy must belong to the live session (if there is one).
      final live = SupabaseService.authUser;
      if (live != null && live.id != id) return null;

      // Refresh from the server so team_id / role / name are current.
      if (live != null) {
        final fresh = await _fetchUserFromSupabase(live.id)
            .timeout(const Duration(seconds: 6), onTimeout: () => null);
        if (fresh != null) {
          _currentUser = fresh;
          await _saveUserLocally(fresh);
          return fresh;
        }
      }

      final user = AppUser(
        id: id,
        name: name,
        email: email,
        role: _roleFrom(roleName),
        teamId: prefs.getString('user_team_id'),
        academyId: prefs.getString('user_academy_id') ?? '',
        academyName: prefs.getString('user_academy_name') ?? '',
        phone: prefs.getString('user_phone') ?? '',
        address: prefs.getString('user_address') ?? '',
        jobNumber: prefs.getString('user_job_number') ?? '',
        joinDate: prefs.getString('user_join_date') ?? '',
        photo: prefs.getString('user_photo'),
      );
      _currentUser = user;
      SupabaseService.setAcademyId(user.academyId);
      return user;
    } catch (e) {
      return null;
    }
  }

  static Future<void> logout() async {
    if (SupabaseService.isInitialized) await _safeSignOut();
    SupabaseService.clearAcademyId();

    final prefs = await SharedPreferences.getInstance();
    for (final k in const [
      'is_logged_in', 'user_id', 'user_name', 'user_email', 'user_role',
      'user_team_id', 'user_academy_id', 'user_academy_name', 'user_phone',
      'user_address', 'user_job_number', 'user_join_date', 'user_photo',
    ]) {
      await prefs.remove(k);
    }

    // local caches only — nothing is deleted on the server
    await Future.wait([
      PlayerService.clearAll(),
      TeamService.clearAll(),
      CoachService.clearAll(),
      TrainingService.clearAll(),
      MatchService.clearAll(),
      NotificationService.clearAll(),
      TournamentService.clearAll(),
      ReportService.clearAll(),
      AttendanceService.clearLocal(),
    ]);

    _currentUser = null;
    notifier.notify();
  }
}