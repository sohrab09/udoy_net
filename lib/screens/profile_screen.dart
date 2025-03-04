import 'package:flutter/material.dart';
import 'package:udoy_net/utils/TokenManager.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? customerName = '';
  String? customerCode = '';
  String? pppoeUserid = '';

  @override
  void initState() {
    super.initState();
    fetchCustomerInfo();
  }

  Future<void> fetchCustomerInfo() async {
    customerName = await TokenManager.getCustomerName();
    customerCode = await TokenManager.getCustomerCode();
    pppoeUserid = await TokenManager.getPppoeUserid();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF65AA4B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // User Details Section
            _buildProfileText(
                customerName?.toUpperCase() ?? 'Unknown', 24, FontWeight.bold),
            const SizedBox(height: 10),
            _buildProfileText(
                "Customer Code: ${customerCode ?? 'N/A'}", 16, FontWeight.w400),
            const SizedBox(height: 16),

            // PPPoE Details
            _buildProfileText(
                'PPPoE User ID: ${pppoeUserid ?? 'N/A'}', 16, FontWeight.w400),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Helper method to build the profile text widget
  Widget _buildProfileText(
      String text, double fontSize, FontWeight fontWeight) {
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: Colors.black87,
      ),
    );
  }
}
