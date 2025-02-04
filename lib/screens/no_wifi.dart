import 'package:flutter/material.dart';
import 'package:udoy_net/root_screen/home_page.dart';

class NoWiFiPage extends StatelessWidget {
  const NoWiFiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("No WiFi Connection"),
        centerTitle: true,
        automaticallyImplyLeading:
            false, // Add this line to remove the back button
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off,
              size: 100,
              color: Colors.redAccent,
            ),
            SizedBox(height: 20),
            Text(
              "No WiFi Connection",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "Please connect to a WiFi network.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => HomePage()),
                );
              },
              child: Text("Retry"),
            )
          ],
        ),
      ),
    );
  }
}
