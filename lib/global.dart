import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage(
  aOptions: AndroidOptions(sharedPreferencesName: "settings", resetOnError: true),
  iOptions: IOSOptions(accountName: "settings"),
);
