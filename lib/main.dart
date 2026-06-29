import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/network/local_database.dart';
import 'core/network/supabase_service.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'features/cart/presentation/bloc/cart_bloc.dart';
import 'features/checkout/presentation/bloc/checkout_bloc.dart';
import 'features/checkout/presentation/widgets/pos_dashboard.dart';
import 'features/menu/data/datasources/local_menu_datasource.dart';
import 'features/menu/data/repositories/menu_repository_impl.dart';
import 'features/menu/presentation/bloc/menu_bloc.dart';
import 'features/menu/presentation/bloc/menu_event.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Local Hive Databases
  await LocalDatabase.init();

  // Initialize Supabase Cloud Sync
  await SupabaseService.init();
  SupabaseService.syncOfflineSales(); // Run offline sync in background

  runApp(const CoffeePOSApp());
}

class CoffeePOSApp extends StatefulWidget {
  const CoffeePOSApp({super.key});

  @override
  State<CoffeePOSApp> createState() => _CoffeePOSAppState();
}

class _CoffeePOSAppState extends State<CoffeePOSApp> {
  // Theme state
  bool _isDarkMode = false;
  // Locale state
  Locale _activeLocale = const Locale('en');

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  void _toggleLocale() {
    setState(() {
      _activeLocale = _activeLocale.languageCode == 'en' 
          ? const Locale('km') 
          : const Locale('en');
    });
  }

  @override
  Widget build(BuildContext context) {
    // Initialise repository & datasources
    final menuDatasource = LocalMenuDatasource();
    final menuRepository = MenuRepositoryImpl(menuDatasource);

    return MultiBlocProvider(
      providers: [
        BlocProvider<MenuBloc>(
          create: (context) => MenuBloc(menuRepository: menuRepository)..add(LoadMenu()),
        ),
        BlocProvider<CartBloc>(
          create: (context) => CartBloc(),
        ),
        BlocProvider<CheckoutBloc>(
          create: (context) => CheckoutBloc(),
        ),
      ],
      child: MaterialApp(
        title: 'Raksa Coffee POS',
        debugShowCheckedModeBanner: false,
        themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        locale: _activeLocale,
        supportedLocales: const [
          Locale('en'),
          Locale('km'),
        ],
        localizationsDelegates: const [
          AppLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: PosDashboard(
          onThemeToggled: _toggleTheme,
          isDarkMode: _isDarkMode,
          onLocaleToggled: _toggleLocale,
          activeLocale: _activeLocale,
        ),
      ),
    );
  }
}
