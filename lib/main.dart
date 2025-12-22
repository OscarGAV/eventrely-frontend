import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/utils/notification_utils.dart';
import 'features/events/presentation/bloc/event_bloc.dart';
import 'features/events/presentation/pages/home_page.dart';
import 'core/utils/injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar timezone
  tz.initializeTimeZones();
  
  // Inicializar notificaciones
  await NotificationUtils.initialize();
  
  // Inicializar dependency injection
  await di.init();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<EventBloc>(),
      child: MaterialApp(
        title: 'EventRELY',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: Colors.blue[700],
          ),
        ),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('es', 'PE'), // Español (Perú)
        ],
        home: const HomePage(),
      ),
    );
  }
}