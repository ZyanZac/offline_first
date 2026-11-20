import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'bootstrap.dart';
import 'services/background.dart';
import 'ui/home_page.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initFirebase();
  await Workmanager().initialize(callbackDispatcher);
  runApp(const MaterialApp(home: HomePage()));
}