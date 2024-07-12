import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'hr_dashboard_page.dart';
import 'services/auth_service.dart';
import 'services/dark_mode.dart';
import 'signup_page.dart';
import 'admin_dashboard_page.dart';
import 'services/company_name_service.dart';
import 'services/logo_service.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const OoribaApp());
}

class OoribaApp extends StatelessWidget {
  const OoribaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DarkModeService()),
        ChangeNotifierProvider(create: (_) => CompanyNameService()),
        ChangeNotifierProvider(create: (_) => LogoService()),
      ],
      child: Consumer3<DarkModeService, CompanyNameService, LogoService>(
        builder: (context, darkModeService, companyNameService, logoService, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: companyNameService.companyName,
            theme: ThemeData(
              primarySwatch: Colors.blue,
              brightness: Brightness.light,
            ),
            darkTheme: ThemeData(
              primarySwatch: Colors.blue,
              brightness: Brightness.dark,
            ),
            themeMode:
                darkModeService.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: LoginPage(),
          );
        },
      ),
    );
  }
}

class LoginPage extends StatelessWidget {
  LoginPage({Key? key}) : super(key: key);

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  @override
  Widget build(BuildContext context) {
    final darkModeService = Provider.of<DarkModeService>(context, listen: false);
    final companyNameService = Provider.of<CompanyNameService>(context);
    final logoService = Provider.of<LogoService>(context);

    // Requesting permissions for handling notifications
    _firebaseMessaging.requestPermission();

    return Scaffold(
      appBar: AppBar(
        title: Text(companyNameService.companyName),
        actions: [
          IconButton(
            icon: Icon(darkModeService.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              darkModeService.toggleDarkMode();
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 400, // Limit the width for larger screens
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          'Welcome To ${companyNameService.companyName}',
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            logoService.logo != null
                                ? Image.file(
                                    logoService.logo!,
                                    width: 200,
                                    height: 190,
                                  )
                                : Image.asset(
                                    'assets/images/companyLogo.png',
                                    width: 200,
                                    height: 190,
                                  ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            filled: true,
                            labelText: 'Email ID',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => HRDashboardPage()),
                              );
                            },
                            child: const Text('Forgot Password'),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () async {
                            await AuthService().signin(
                              email: _emailController.text,
                              password: _passwordController.text,
                              context: context,
                            );
                          },
                          child: const Text('Sign In'),
                        ),
                        const SizedBox(height: 20),
                        RichText(
                          text: TextSpan(
                            text: "Don't have an account? ",
                            style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge!
                                    .color),
                            children: [
                              TextSpan(
                                text: 'Sign Up here',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const SignUpPage()),
                                    );
                                  },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => AdminDashboardPage()),
                            );
                          },
                          child: const Text('Admin'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
