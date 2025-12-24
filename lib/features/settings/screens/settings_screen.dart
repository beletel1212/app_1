import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_ui/features/auth/controller/auth_controller.dart';
import 'package:whatsapp_ui/common/utils/colors.dart';

class SettingsScreen extends ConsumerWidget {
  static const routeName = '/settings-screen';

  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsyncValue = ref.watch(userDataAuthProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: appBarColor,
      ),
      body: userAsyncValue.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text("No user data found"),
            );
          }

          return ListView(
            children: [
              SwitchListTile(
                title: const Text("Show my online state"),
                value: user.showOnlineStatus,
                onChanged: (value) {
                  ref
                      .read(authControllerProvider)
                      .updateShowOnlineStatus(value);
                },
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text("Error: $e")),
      ),
    );
  }
}
