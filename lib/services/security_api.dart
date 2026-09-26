import 'package:cloud_functions/cloud_functions.dart';

/// All balance/reward mutations go through Firebase Cloud Functions.
/// Firestore rules intentionally deny direct client writes to the economy fields.
class SecurityApi {
  SecurityApi._();
  static final SecurityApi instance = SecurityApi._();

  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'asia-south1');

  Future<Map<String, dynamic>> _call(
    String name, [
    Map<String, dynamic>? data,
  ]) async {
    final result = await _functions.httpsCallable(name).call(data ?? {});
    final raw = result.data;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return <String, dynamic>{};
  }

  Future<Map<String, dynamic>> initializeUser({
    required String username,
    required String email,
    String? referralCode,
  }) {
    return _call('initializeUser', {
      'username': username,
      'email': email,
      'referralCode': referralCode?.trim().toUpperCase(),
    });
  }

  Future<String> resolveUsername(String username) async {
    final result = await _call('resolveUsername', {
      'username': username.trim().toLowerCase(),
    });
    return (result['email'] ?? '').toString();
  }

  Future<Map<String, dynamic>> startSocialTask(String taskId) {
    return _call('startSocialTask', {'taskId': taskId});
  }

  Future<Map<String, dynamic>> completeSocialTask(String taskId) {
    return _call('completeSocialTask', {'taskId': taskId});
  }

  Future<Map<String, dynamic>> claimSpin() {
    return _call('claimSpin');
  }

  Future<Map<String, dynamic>> claimScratch() {
    return _call('claimScratch');
  }

  Future<Map<String, dynamic>> convertCoins(int coins) {
    return _call('convertCoins', {'coins': coins});
  }

  Future<Map<String, dynamic>> requestWithdrawal({
    required bool isCash,
    required double amount,
    required String upi,
  }) {
    return _call('requestWithdrawal', {
      'isCash': isCash,
      'amount': amount,
      'upi': upi.trim(),
    });
  }
}
