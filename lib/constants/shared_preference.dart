import 'package:shared_preferences/shared_preferences.dart';

class SharePrefrenceAPI {
  static Future getKey() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('APIKEY') ?? '';
  }

  static Future setKey(String text) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString('APIKEY', text);
  }

  static Future getSpeak() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('speak') ?? true;
  }

  static Future setSpeak(bool bo) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool('speak', bo);
  }
}
