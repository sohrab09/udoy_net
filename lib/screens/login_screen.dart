import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:udoy_net/screens/error_screen.dart';
import 'package:udoy_net/utils/TokenManager.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userIdController = TextEditingController(text: '09610389428');
  final _passwordController = TextEditingController(text: '88');
  bool _obscurePassword = true;
  bool isLoading = false; // Track loading state
  String ipAddress = '';
  Timer? _timer;

  String date = '';
  String time = '';
  // String authToken = '';

  @override
  void initState() {
    super.initState();
    getIPAddress();
    getDatTime();

    _timer = Timer.periodic(Duration(hours: 1), (timer) {
      getDatTime();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> getIPAddress() async {
    final url = Uri.parse('https://api.ipify.org');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = response.body.trim();
        await verifyIPAddress(data);
        setState(() {
          ipAddress = data;
        });
      } else {
        print('Request failed with status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> verifyIPAddress(String ipAddress) async {
    final url = Uri.parse(
        'https://api.udoyadn.com/api/Auth/GetUdoyNetworkStatus?ip=$ipAddress');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data == false) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ErrorScreen()),
          );
        }
      } else {
        print('Request failed with status verify: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in IP verification: $e');
    }
  }

  Future<void> getDatTime() async {
    final url = Uri.parse('https://api.udoyadn.com/api/Auth/GetDateTime');
    try {
      final response = await http.post(url);
      if (response.statusCode == 200) {
        final data = response.body.trim();
        final dateParts = data.split(' ')[0].split('/');
        final timeParts = data.split(' ')[1].split(':');
        final period = data.split(' ')[2];

        final date = dateParts[0];
        int hour = int.parse(timeParts[0]);
        if (period == 'PM' && hour != 12) {
          hour += 12;
        } else if (period == 'AM' && hour == 12) {
          hour = 0;
        }

        final formattedHour = hour.toString().padLeft(2, '0');

        setState(() {
          this.date = date;
          time = formattedHour;
        });
      } else {
        print('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> sendRequest(String userId, String password) async {
    String userIp = '';
    String latitude = '';
    String longitude = '';
    String userPlatform = '';
    String userBrowser = '';
    bool captchaValue = true;

    Map<String, dynamic> requestBody = {
      'userID': 'CUS$userId',
      'password': '$date$time',
      'userIp': userIp,
      'userLocation': {
        'latitude': latitude,
        'longitude': longitude,
      },
      'userPlatform': userPlatform,
      'userBrowser': userBrowser,
      'captchaValue': captchaValue,
    };

    String jsonBody = json.encode(requestBody);
    final url = Uri.parse('https://api.udoyadn.com/api/Auth/GetAuthToken');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonBody,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        String authToken = data['token'];
        String customerID = userId;

        await TokenManager.setToken(authToken);
        await TokenManager.setCustomerID(customerID);

        await handleLogin(userId, password, authToken);
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login Failed')),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred')),
      );
    }
  }

  Future<void> handleLogin(
      String userId, String password, String authToken) async {
    Map<String, dynamic> requestBody = {
      'data': {
        'userName': userId,
        'password': password,
      }
    };

    String jsonBody = json.encode(requestBody);
    final url =
        Uri.parse('https://api.udoyadn.com/api/SelfcareApps/GetUdoyAppsLogin');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken'
        },
        body: jsonBody,
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() {
          isLoading = false; // Show the button again if login fails
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login Failed')),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false; // Show the button again if error occurs
      });
      print('Error: $e');
    }
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true; // Show the spinner when login is clicked
      });
      await sendRequest(_userIdController.text, _passwordController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Color(0xFF65AA4B),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 100),
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.wifi,
                      size: 50,
                      color: Color(0xFF65AA4B),
                    ),
                  ),
                  Text(
                    "UDOY",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Manage your network and Wi-Fi easily",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  SizedBox(height: 40),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _userIdController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            hintText: "UserID",
                            prefixIcon: Icon(Icons.person, color: Colors.green),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'UserID is required';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            hintText: "Password",
                            prefixIcon: Icon(Icons.lock, color: Colors.green),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Password is required';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : _login, // Disable while loading
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            padding: EdgeInsets.symmetric(
                              horizontal: 100,
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: isLoading
                              ? CircularProgressIndicator(
                                  color: Colors.white,
                                ) // Show loading spinner on button
                              : Text(
                                  'LOGIN',
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.white),
                                ),
                        ),
                        SizedBox(height: 20),
                        TextButton(
                          onPressed: () {
                            // Add forgot password functionality
                          },
                          child: Text(
                            "Forgot Password?",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
