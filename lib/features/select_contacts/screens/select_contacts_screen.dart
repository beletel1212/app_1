import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_ui/common/widgets/error.dart';
import 'package:whatsapp_ui/common/widgets/loader.dart';
import 'package:whatsapp_ui/features/select_contacts/controller/select_contact_controller.dart';

/// 🟩 Displays a list of *registered* contacts (users who are on the app)
/// and lets the user select one to start chatting.
class SelectContactsScreen extends ConsumerWidget {
  static const String routeName = '/select-contact';

  const SelectContactsScreen({super.key});

  // ---------------------------------------------------------------------------
  /// 🟩 Handles contact tap
  ///
  /// When a contact is tapped, this calls the controller which checks if
  /// the selected contact is a registered app user and navigates to chat.
  void _selectContact(
    WidgetRef ref,
    Contact selectedContact,
    BuildContext context,
  ) {
    ref
        .read(selectContactControllerProvider)
        .selectContact(selectedContact, context);
  }

  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🟩 Watch for registered contacts (Hive or Firestore)
    final contactsAsync = ref.watch(getRegisteredContactsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select contact'),
        actions: [
          IconButton(
            onPressed: () {
              // 🔍 Optional: You can later add a search feature here.
            },
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),

      // -----------------------------------------------------------------------
      /// 🟩 Body: uses Riverpod's `AsyncValue.when()` to handle states
      body: contactsAsync.when(
        // 🟢 When data is successfully loaded
        data: (contactList) {
          if (contactList.isEmpty) {
            return const Center(
              child: Text(
                'No registered contacts found',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            itemCount: contactList.length,
            itemBuilder: (context, index) {
              final contact = contactList[index];
              return InkWell(
                onTap: () => _selectContact(ref, contact, context),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: ListTile(
                    title: Text(
                      contact.displayName,
                      style: const TextStyle(fontSize: 18),
                    ),
                    leading: contact.photo == null
                        ? const CircleAvatar(
                            radius: 30,
                            backgroundImage: AssetImage(
                              'assets/default_avatar.png', // 🖼️ optional fallback image
                            ),
                          )
                        : CircleAvatar(
                            backgroundImage: MemoryImage(contact.photo!),
                            radius: 30,
                          ),
                  ),
                ),
              );
            },
          );
        },

        // 🟡 When still loading
        loading: () => const Loader(),

        // 🔴 When there’s an error
        error: (err, trace) => ErrorScreen(error: err.toString()),
      ),
    );
  }
}
