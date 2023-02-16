import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  bool visible = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              height: 40,
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
              onTap: () {
                setState(() {
                  visible = false;
                });
              },
            ),
            const SizedBox(
              height: 4,
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
              onTap: () {
                setState(() {
                  visible = false;
                });
              },
            ),
            const SizedBox(
              height: 20,
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  //check if the given user is an admin by its role
                  String? email = emailController.text.split("@")[0];
                  final ref = FirebaseDatabase.instance.ref();
                  final snapshot = await ref.child('users/$email').get();
                  if (snapshot.exists) {
                    //sign in
                    await FirebaseAuth.instance.signInWithEmailAndPassword(
                        email: emailController.text.trim(),
                        password: passwordController.text.trim());

                    //change it to map
                    Map roleValue =
                        Map<String, dynamic>.from(snapshot.value as Map);
                  } else {
                    throw FirebaseAuthException(
                        message: 'No data available.', code: '00');
                  }

                  //
                } on FirebaseAuthException catch (e) {
                  setState(() {
                    visible = true;
                  });
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.lock_open),
                  Text("Sign In"),
                ],
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Visibility(
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              visible: visible,
              child: const Text(
                "Incorrect email or password!",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            SizedBox(
              height: 10,
              child: Divider(
                thickness: 1,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("No Account?"),
                TextButton(
                    onPressed: () {
                      // Navigator.of(context)
                      //     .pushReplacementNamed("/signupscreen");
                      Navigator.of(context).pushNamed("/signupscreen");
                    },
                    child: Text("Sign up")),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
