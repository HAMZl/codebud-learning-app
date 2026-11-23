import 'package:flutter/material.dart';

import 'routes.dart';
import 'services/app_scope.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(await AppScope.production(child: const CodeBudApp()));
}

class CodeBudApp extends StatelessWidget {
  const CodeBudApp({super.key, this.initialRoute = Routes.launch});

  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CodeBud',
      theme: AppTheme.light(),
      initialRoute: initialRoute,
      onGenerateRoute: Routes.onGenerateRoute,
    );
  }
}
