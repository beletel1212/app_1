import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_ui/features/select_contacts/repository/select_contact_repository.dart';

/// 🟩 Listens for app lifecycle changes (pause/resume)
/// and refreshes registered contacts when the app returns to foreground.
class ContactsLifecycleListener extends StatefulWidget {
  final Widget child;
  const ContactsLifecycleListener({super.key, required this.child});

  @override
  State<ContactsLifecycleListener> createState() => _ContactsLifecycleListenerState();
}

class _ContactsLifecycleListenerState extends State<ContactsLifecycleListener>
    with WidgetsBindingObserver {
  late WidgetRef _ref;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      // 🟩 When user returns to app, re-fetch registered contacts from Firestore
      _ref.read(selectContactsRepositoryProvider).initializeRegisteredContactsOnAppStart();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🟩 Wrap child in Consumer to access Riverpod ref
    return Consumer(
      builder: (context, ref, _) {
        _ref = ref;
        return widget.child;
      },
    );
  }
}
