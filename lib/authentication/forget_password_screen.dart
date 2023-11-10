// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intinow/authentication/login_screen.dart';

class ForgetPassword extends StatefulWidget {
  @override
  State<ForgetPassword> createState() => _ForgetPasswordState();
}

class _ForgetPasswordState extends State<ForgetPassword>
    with TickerProviderStateMixin {

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _forgetPassTextController =
      TextEditingController(text: '');

  void _forgetPassSubmitForm() async {
    try {
      await _auth.sendPasswordResetEmail(
        email: _forgetPassTextController.text,
      );
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => LoginScreen()));
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              children: [
                SizedBox(
                  height: size.height * 0.1,
                ),
                const Text(
                  'Forget Password',
                  style: TextStyle(
                    color: Colors.blueGrey,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins-Medium',
                    fontSize: 55,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                const Text(
                  'Enter your email address',
                  style: TextStyle(
                    color: Colors.blueGrey,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                TextField(
                  controller: _forgetPassTextController,
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Color(0xe4f1f1f1),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                  onPressed: () {
                    _forgetPassSubmitForm();
                  },
                  style: ElevatedButton.styleFrom(
                    fixedSize: const Size(365, 50),
                    textStyle: const TextStyle(
                      fontSize: 18,
                    ),
                  ),
                  child: const Text('Reset Now'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
