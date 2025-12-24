import 'package:flutter/material.dart';
import 'package:flutter_contacts/contact.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_ui/common/widgets/error.dart';
import 'package:whatsapp_ui/common/widgets/loader.dart';
import 'package:whatsapp_ui/features/select_contacts/controller/select_contact_controller.dart';

// --------------------------
// Notifier to manage selected group contacts
class SelectedGroupContacts extends Notifier<List<Contact>> {
  @override
  List<Contact> build() => [];

  void addContact(Contact contact) {
    state = [...state, contact];
  }

  void removeContact(Contact contact) {
    state = state.where((c) => c != contact).toList();
  }

  void clear() {
    state = [];
  }
}

// Register the NotifierProvider
final selectedGroupContactsProvider =
    NotifierProvider<SelectedGroupContacts, List<Contact>>(
  SelectedGroupContacts.new,
);

// --------------------------

class SelectContactsGroup extends ConsumerStatefulWidget {
  const SelectContactsGroup({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _SelectContactsGroupState();
}

class _SelectContactsGroupState extends ConsumerState<SelectContactsGroup> {
  List<int> selectedContactsIndex = [];

  void selectContact(int index, Contact contact) {
    if (selectedContactsIndex.contains(index)) {
      selectedContactsIndex.remove(index);
      ref.read(selectedGroupContactsProvider.notifier).removeContact(contact);
    } else {
      selectedContactsIndex.add(index);
      ref.read(selectedGroupContactsProvider.notifier).addContact(contact);
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Watch the FutureProvider that gives registered contacts
    final contactsAsync = ref.watch(getRegisteredContactsProvider);

    return contactsAsync.when(
      data: (contactList) {
        if (contactList.isEmpty) {
          return const Center(
            child: Text('No registered contacts found'),
          );
        }

        return Expanded(
          child: ListView.builder(
            itemCount: contactList.length,
            itemBuilder: (context, index) {
              final contact = contactList[index];
              final isSelected = selectedContactsIndex.contains(index);

              return InkWell(
                onTap: () => selectContact(index, contact),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(
                      contact.displayName,
                      style: const TextStyle(fontSize: 18),
                    ),
                    leading: isSelected
                        ? const Icon(
                            Icons.done,
                            color: Colors.green,
                          )
                        : null,
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Loader(),
      error: (err, trace) => ErrorScreen(error: err.toString()),
    );
  }
}
