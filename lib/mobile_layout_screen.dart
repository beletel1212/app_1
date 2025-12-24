import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_ui/common/utils/colors.dart';
import 'package:whatsapp_ui/common/utils/utils.dart';
import 'package:whatsapp_ui/features/auth/controller/auth_controller.dart';
import 'package:whatsapp_ui/features/group/screens/create_group_screen.dart';
import 'package:whatsapp_ui/features/select_contacts/screens/select_contacts_screen.dart';
import 'package:whatsapp_ui/features/chat/widgets/contacts_list.dart';
import 'package:whatsapp_ui/features/status/screens/confirm_status_screen.dart';
import 'package:whatsapp_ui/features/status/screens/status_contacts_screen.dart';
import 'package:whatsapp_ui/features/profile/screens/profile_screen.dart';
import 'package:whatsapp_ui/features/landing/screens/landing_screen.dart';
import 'package:whatsapp_ui/features/settings/screens/settings_screen.dart';

import 'package:whatsapp_ui/features/select_contacts/controller/select_contact_controller.dart';

class MobileLayoutScreen extends ConsumerStatefulWidget {
  const MobileLayoutScreen({super.key});

  @override
  ConsumerState<MobileLayoutScreen> createState() => _MobileLayoutScreenState();
}

class _MobileLayoutScreenState extends ConsumerState<MobileLayoutScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {

  late TabController tabBarController;

  @override
  void initState() {
    super.initState();
    tabBarController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    tabBarController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 🟩 Update user online/offline state
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        ref.read(authControllerProvider).setUserState(true);
        ref.read(selectContactControllerProvider)
            .initializeRegisteredContactsOnAppStart();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        ref.read(authControllerProvider).setUserState(false);
        break;
    }
  }

  /// 🟩 Build drawer with profile and logout options
  Widget _buildDrawer(BuildContext context) {
    final userAsync = ref.watch(userDataAuthProvider);

    return Drawer(
      backgroundColor: backgroundColor,
      child: userAsync.when(
        data: (user) {
          final displayName = user?.name ?? 'Guest User';
          final displayPhone = user?.phoneNumber ?? 'No phone linked';
          final displayImage = user?.profilePic ??
              'https://png.pngitem.com/pimgs/s/649-6490124_katie-notopoulos-katienotopoulos-i-write-about-tech-round.png';

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(color: appBarColor),
                accountName: Text(
                  displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                accountEmail: Text(
                  displayPhone,
                  style: const TextStyle(color: Colors.grey),
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundImage: NetworkImage(displayImage),
                  radius: 40,
                ),
              ),
              // 🟦 Profile tile
              ListTile(
                leading: const Icon(Icons.person, color: Colors.white),
                title: const Text('Profile', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context); // Close drawer
                  Navigator.pushNamed(context, ProfileScreen.routeName);
                },
              ),

              // 🟦 Settings tile
              ListTile(
                leading: const Icon(Icons.settings, color: Colors.white),
                title: const Text('Settings', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context); // Close drawer
                  Navigator.pushNamed(context, SettingsScreen.routeName);
                },
              ),

              // 🟦 Logout tile
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
                onTap: () => _confirmLogout(context),
              ),
             

                          ],
          );
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: tabColor)),
        error: (err, _) => Center(
            child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent))),
      ),
    );
  }

  /// 🟩 Logout confirmation dialog
  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // close dialog
               ref.read(authControllerProvider).signOut(context);
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                    context, LandingScreen.routeName, (route) => false);
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        drawer: _buildDrawer(context), // Attach the drawer here
        appBar: AppBar(
          
          elevation: 0,
          backgroundColor: appBarColor,
          centerTitle: false,
          title: const Text(
            'WhatsApp',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search, color: Colors.grey),
              onPressed: () {},
            ),
            PopupMenuButton(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: const Text('Create Group'),
                  onTap: () => Future(
                    () => {
                      if (context.mounted)
                        Navigator.pushNamed(
                          context,
                          CreateGroupScreen.routeName,
                        )
                    },
                  ),
                )
              ],
            ),
          ],
          bottom: TabBar(
            controller: tabBarController,
            indicatorColor: tabColor,
            indicatorWeight: 4,
            labelColor: tabColor,
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'CHATS'),
              Tab(text: 'STATUS'),
              Tab(text: 'CALLS'),
            ],
          ),
        ),
        body: TabBarView(
          controller: tabBarController,
          children: const [
            ContactsList(),
            StatusContactsScreen(),
            Center(child: Text('Calls')),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            if (tabBarController.index == 0) {
              Navigator.pushNamed(context, SelectContactsScreen.routeName);
            } else {
              File? pickedImage = await pickImageFromGallery(context);
              if (context.mounted) {
                Navigator.pushNamed(
                  context,
                  ConfirmStatusScreen.routeName,
                  arguments: pickedImage,
                );
              }
            }
          },
          backgroundColor: tabColor,
          child: const Icon(Icons.comment, color: Colors.white),
        ),
      ),
    );
  }
}
