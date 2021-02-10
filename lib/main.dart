import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'main.config.dart';
import 'app.dart';

final getIt = GetIt.instance;

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  configureDependencyInjection();

  runApp(App());
}

@injectableInit
void configureDependencyInjection() => $initGetIt(getIt);
