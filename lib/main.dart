import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:whatsapp_ui/common/utils/colors.dart';
import 'package:whatsapp_ui/common/widgets/loader.dart';
import 'package:whatsapp_ui/common/widgets/error.dart';
import 'package:whatsapp_ui/features/auth/controller/auth_controller.dart';
import 'package:whatsapp_ui/features/landing/screens/landing_screen.dart';
import 'package:whatsapp_ui/features/select_contacts/initializer/contacts_lifecycle_listener.dart';
import 'package:whatsapp_ui/features/select_contacts/initializer/initialize_contacts_provider.dart';
import 'package:whatsapp_ui/models/user_model.dart';
import 'package:whatsapp_ui/firebase_options.dart';
import 'package:whatsapp_ui/router.dart';
import 'package:whatsapp_ui/mobile_layout_screen.dart';

/// 🟢 Entry point of the app
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🟩 Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 🟩 Initialize Hive (local database)
  await Hive.initFlutter();

  // 🟩 Register Hive adapter for UserModel
  Hive.registerAdapter(UserModelAdapter());

  // 🟩 Open Hive box for storing registered contacts
  await Hive.openBox<UserModel>('registeredContactsBox');

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

/// 🟢 Root widget of the app
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🟩 Trigger initialization of registered contacts on app startup
    ref.watch(initializeContactsProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WhatsApp UI',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: backgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: appBarColor,
        ),
      ),
      onGenerateRoute: (settings) => generateRoute(settings),

      /// 🟩 Determine home screen based on user authentication state
      home: ref.watch(userDataAuthProvider).when(
            data: (user) {
              if (user == null) {
                // 🚪 User not logged in → Landing screen
                return const LandingScreen();
              }

              // ✅ User is logged in → wrap main layout with lifecycle listener
              return const ContactsLifecycleListener(
                child: MobileLayoutScreen(),
              );
            },
            error: (err, trace) {
              // ❌ Show error screen if user auth fetch fails
              return ErrorScreen(error: err.toString());
            },
            loading: () => const Loader(), // ⏳ Show loader while fetching auth
          ),
    );
  }
}
