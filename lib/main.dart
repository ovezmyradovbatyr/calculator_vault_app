// keytool -genkey -v -keystore C:\Users\Admin\Calculator\android\app\upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'features/calculator/data/repositories/calculator_repository_impl.dart';
import 'features/calculator/domain/usecases/calculator_usecases.dart';
import 'features/calculator/presentation/bloc/calculator_bloc.dart';
import 'features/calculator/presentation/pages/calculator_page.dart';
import 'features/calculator/presentation/pages/splash_screen.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLocalizations.instance.init();
  runApp(const CalculatorApp());
}

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = CalculatorRepositoryImpl();

    return ListenableBuilder(
      listenable: AppLocalizations.instance,
      builder: (context, _) => MaterialApp(
        title: 'Calculator',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(brightness: Brightness.dark, fontFamily: 'Gilroy'),
        home: BlocProvider(
          create: (_) => CalculatorBloc(
            inputDigit: InputDigit(repository),
            inputDecimal: InputDecimal(repository),
            inputOperator: InputOperator(repository),
            calculate: Calculate(repository),
            clear: Clear(repository),
            toggleSign: ToggleSign(repository),
            percentage: Percentage(repository),
          ),
          child: SplashScreen(child: const CalculatorPage()),
        ),
      ),
    );
  }
}
