import 'package:flutter/material.dart';
import 'package:udoy_net/screens/login_screen.dart';
import 'package:udoy_net/screens/profile_screen.dart';
import 'package:udoy_net/utils/TokenManager.dart';
import 'package:udoy_net/utils/version_manager.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({super.key});

  @override
  CustomDrawerState createState() => CustomDrawerState();
}

class CustomDrawerState extends State<CustomDrawer> {
  String? customerCode = '';
  String? customerName = '';

  @override
  void initState() {
    super.initState();
    fetchCustomerInfo();
  }

  Future<void> fetchCustomerInfo() async {
    customerCode = await TokenManager.getCustomerCode();
    customerName = await TokenManager.getCustomerName();
    setState(() {});
  }

  // define a route for each item in the drawer
  Future<void> _navigateToScreen(String routeName) async {
    Navigator.pop(context);

    if (routeName == '/profile') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ProfileScreen()),
      );
    }
  }

  void _logout() async {
    await TokenManager.logout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: Color(0xFF65AA4B),
            ),
            accountName: Text(
              (customerName ?? 'Unknown').toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            accountEmail: Text(
              "Customer Code: ${customerCode ?? 'N/A'}",
              style: TextStyle(fontSize: 16),
            ),
          ),
          ListTile(
            leading: Icon(Icons.account_circle, color: Color(0xFF65AA4B)),
            title: Text('Profile'),
            onTap: () {
              _navigateToScreen('/profile');
            },
          ),
          Spacer(),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text('Logout'),
            onTap: _logout,
          ),
          Divider(
            color: Colors.grey,
            thickness: 0.1,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Version: ${VersionManager.getAppVersion()}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
