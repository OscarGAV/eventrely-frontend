import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/utils/notification_utils.dart';
import 'features/events/presentation/bloc/event_bloc.dart';
import 'features/events/presentation/pages/home_page.dart';
import 'core/utils/injection_container.dart' as di;
import 'core/config/themes/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configurar la barra de estado para modo oscuro
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.backgroundColor,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  // Bloquear orientación a vertical (opcional)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
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
        
        // Aplicar tema oscuro
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        
        // Configuración de idioma
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('es', 'PE'), // Español (Perú)
        ],
        locale: const Locale('es', 'PE'),
        
        home: const HomePage(),
      ),
    );
  }
}