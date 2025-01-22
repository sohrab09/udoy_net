import 'package:flutter/material.dart';
import 'package:udoy_net/root_screen/home_page.dart';
import 'package:udoy_net/screens/login_screen.dart';
import 'package:udoy_net/utils/TokenManager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final token = await TokenManager.getToken();

  runApp(MyApp(isLoggedIn: token != null && token.isNotEmpty));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: isLoggedIn ? '/home' : '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}
