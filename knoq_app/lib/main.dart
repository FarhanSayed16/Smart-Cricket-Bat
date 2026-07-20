import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:knoq_app/app.dart';
import 'package:knoq_app/core/constants/env_config.dart';
import 'package:knoq_app/services/crash_reporting_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set environment to DEV by default for local testing
  EnvConfig.currentEnvironment = Environment.dev;

  // Firebase
  await Firebase.initializeApp();

  // Crashlytics
  CrashReportingService().initialize();

  // Hive local storage
  await Hive.initFlutter();
  await Hive.openBox('app_settings');
  await Hive.openBox('active_session');
  await Hive.openBox('pending_sync');
  await Hive.openBox('sessions_cache');

  runApp(const ProviderScope(child: KnoQApp()));
}
