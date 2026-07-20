import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:knoq_app/app.dart';
import 'package:knoq_app/core/constants/env_config.dart';
import 'package:knoq_app/services/crash_reporting_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  EnvConfig.currentEnvironment = Environment.prod;

  // Firebase
  await Firebase.initializeApp();

  // Crashlytics — disable in debug but enable in prod
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
  CrashReportingService().initialize();

  // Hive local storage
  await Hive.initFlutter();
  await Hive.openBox('app_settings');
  await Hive.openBox('active_session');
  await Hive.openBox('pending_sync');
  await Hive.openBox('sessions_cache');

  runApp(const ProviderScope(child: KnoQApp()));
}
