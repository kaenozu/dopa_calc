import 'package:flutter/material.dart';

import 'calculator_page.dart';

class DopaCalculatorApp extends StatelessWidget {
  const DopaCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ドパ電卓',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF090A0F),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFD400),
          brightness: Brightness.dark,
        ),
        // Bundle NotoSansJP-VF ensures Japanese renders on Web CanvasKit/SkWasm without tofu
        fontFamily: 'Noto Sans JP',
        textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Noto Sans JP'),
      ),
      home: const CalculatorPage(),
    );
  }
}
