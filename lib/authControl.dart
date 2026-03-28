import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smarthomefridge/pages/authenticationPage.dart';
import 'package:smarthomefridge/pages/homePage.dart';

class Authcontrol extends StatelessWidget {
  const Authcontrol({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Homepage();
          } else {
            return AuthenticationPage();
          }
        },
      ),
    );
  }
}