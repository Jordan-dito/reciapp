import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/app_config.dart';
import '../models/user_model.dart';

class AuthLocalDataSource {
  AuthLocalDataSource();

  Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = json.encode(user.toJson());
    await prefs.setString('user', userJson);
    await prefs.setBool(AppConfig.isLoggedInKey, true);
    if (user.token != null) {
      await prefs.setString(AppConfig.authTokenKey, user.token!);
    }
  }

  Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson != null) {
      final userMap = json.decode(userJson) as Map<String, dynamic>;
      return UserModel.fromJson(userMap);
    }
    return null;
  }

  Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    await prefs.remove(AppConfig.authTokenKey);
    await prefs.setBool(AppConfig.isLoggedInKey, false);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedInFlag = prefs.getBool(AppConfig.isLoggedInKey) ?? false;

    // Verificar que también exista un usuario guardado
    if (isLoggedInFlag) {
      final user = await getUser();
      return user != null;
    }

    return false;
  }
}
