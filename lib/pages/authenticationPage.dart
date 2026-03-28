import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthenticationPage extends StatefulWidget {
  const AuthenticationPage({super.key});

  @override
  State<AuthenticationPage> createState() => _AuthenticationPageState();
}

class _AuthenticationPageState extends State<AuthenticationPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailsignupController = TextEditingController();
  final _passwordsignupController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordResetController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _loginMode = true;
  bool _signupMode = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailsignupController.dispose();
    _passwordsignupController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future _handleLogin() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter email and password!")),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Login successful!")));
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'invalid-email') {
        message = "Please enter a valid email.";
      } else {
        message = "Incorrect Email or Password. Please try again.";
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future _handleSignup() async {
    if (_passwordsignupController.text.trim() !=
        _confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Passwords do not match!")));
      return;
    }
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailsignupController.text.trim(),
        password: _passwordsignupController.text.trim(),
      );
      await addUserDetails();
      // await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      setState(() {
        _loginMode = true;
        _signupMode = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Signup successful! Welcome ${ _usernameController.text.trim()} ")),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message;
      if (e.code == 'email-already-in-use') {
        message = "This email is already registered.";
      } else if (e.code == 'weak-password') {
        message = "Password must be at least 6 characters.";
      } else if (e.code == 'invalid-email') {
        message = "Please enter a valid email.";
      } else {
        message = "Signup failed: ${e.message}";
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future addUserDetails() async {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    await FirebaseFirestore.instance.collection("Users").add({
      "Email": _emailsignupController.text.trim(),
      "Password": _passwordsignupController.text.trim(),
      "Username": _usernameController.text.trim(),
      "UID": uid,
    });
  }

  void _resetpassword() {
    String errorMessage = "";
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Reset Your Password"),
              content: Container(
                height: 160,
                width: 300,
                child: Column(
                  children: [
                    Text(
                      "Enter your email address to receive a password reset link.",
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: _passwordResetController,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.email_outlined),
                        hintText: 'Email',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(width: 2),
                        ),
                      ),
                    ),
                    if (errorMessage.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          errorMessage,
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_passwordResetController.text.trim().isEmpty) {
                      setState(
                        () => errorMessage = "Please enter your email address.",
                      );
                    } else {
                      _handlePasswordReset();
                    }
                  },
                  child: Text("Reset Password"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future _handlePasswordReset() async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _passwordResetController.text.trim(),
      );
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Password reset email sent!")));
      _passwordResetController.clear();
    } on FirebaseAuthException {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Email not Registered! Please try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        width: double.infinity,
        child: Padding(
          padding: EdgeInsets.only(top: 60),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: 30, left: 15),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Image(
                            image: AssetImage("assets/refrigerator.png"),
                            width: 30,
                            height: 30,
                          ),
                          SizedBox(width: 10),
                          Text(
                            "Smart Home Fridge",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Get Started Now",
                        style: TextStyle(
                          fontSize: 24,
                          // fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "Create your account or log in to get started with our app!",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: _loginMode
                        ? LinearGradient(
                            colors: [
                              Colors.lightBlue.shade100,
                              Colors.lightBlue.shade200,
                              Colors.lightBlue.shade700,
                            ],
                            begin: AlignmentGeometry.topCenter,
                            end: Alignment.bottomCenter,
                          )
                        : LinearGradient(
                            colors: [
                              Colors.lightGreen.shade100,
                              Colors.lightGreen.shade200,
                              Colors.lightGreen.shade700,
                            ],
                            begin: AlignmentGeometry.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  width: MediaQuery.of(context).size.width * 1,
                  height: MediaQuery.of(context).size.height * 0.55,
                  child: Padding(
                    padding: EdgeInsets.only(top: 30, left: 5),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Container(
                            height: 50,
                            width: MediaQuery.of(context).size.width * 0.9,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.42,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _loginMode = true;
                                        _signupMode = false;
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      elevation: 5,
                                      shadowColor: _loginMode
                                          ? Colors.blue
                                          : Colors.blueGrey,
                                      backgroundColor: _loginMode
                                          ? Colors.black
                                          : Colors.grey.shade300,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        "Log In",
                                        style: TextStyle(
                                          color: _loginMode
                                              ? Colors.lightBlue
                                              : Colors.blueGrey,
                                          fontWeight: FontWeight.bold,
                                          fontSize: _loginMode ? 18 : 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.42,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _signupMode = true;
                                        _loginMode = false;
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      elevation: 5,
                                      shadowColor: _signupMode
                                          ? Colors.green
                                          : Colors.blueGrey,
                                      backgroundColor: _signupMode
                                          ? Colors.black
                                          : Colors.grey.shade300,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        "Sign Up",
                                        style: TextStyle(
                                          color: _signupMode
                                              ? Colors.greenAccent
                                              : Colors.blueGrey,
                                          fontWeight: FontWeight.bold,
                                          fontSize: _signupMode ? 18 : 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: _loginMode ? 60 : 20),
                          Padding(
                            padding: EdgeInsets.only(bottom: 20),
                            child: Icon(
                              Icons.account_circle_sharp,
                              size: 120,
                              color: _loginMode ? Colors.blue : Colors.green,
                            ),
                          ),
                          Text(
                            _loginMode ? 'Login Account' : 'Create Account',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(bottom: 4, top: 30),
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.65,
                              height: 45,
                              child: TextField(
                                controller: _signupMode
                                    ? _emailsignupController
                                    : _emailController,
                                decoration: InputDecoration(
                                  prefixIcon: Icon(
                                    Icons.person_2_outlined,
                                    size: 30,
                                  ),
                                  hintText: 'Email',
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          _signupMode
                              ? Padding(
                                  padding: EdgeInsets.only(bottom: 4, top: 4),
                                  child: SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width *
                                        0.65,
                                    height: 45,
                                    child: TextField(
                                      controller: _usernameController,
                                      decoration: InputDecoration(
                                        prefixIcon: Icon(
                                          Icons.person_2_outlined,
                                          size: 30,
                                        ),
                                        hintText: 'Username',
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : SizedBox.shrink(),
                          Padding(
                            padding: EdgeInsets.only(bottom: 4, top: 4),
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.65,
                              height: 45,
                              child: TextField(
                                controller: _signupMode
                                    ? _passwordsignupController
                                    : _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  prefixIcon: Icon(
                                    Icons.lock_outline_rounded,
                                    size: 25,
                                  ),
                                  hintText: 'Password',
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                          _signupMode
                              ? Padding(
                                  padding: EdgeInsets.only(bottom: 4, top: 4),
                                  child: SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width *
                                        0.65,
                                    height: 45,
                                    child: TextField(
                                      controller: _confirmPasswordController,
                                      obscureText: _obscurePassword,
                                      decoration: InputDecoration(
                                        prefixIcon: Icon(
                                          Icons.lock_outline_rounded,
                                          size: 25,
                                        ),
                                        hintText: 'Confirm  Password',
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscurePassword =
                                                  !_obscurePassword;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : Padding(
                                  padding: EdgeInsets.only(top: 5),
                                  child: GestureDetector(
                                    onTap: () {
                                      _resetpassword();
                                    },
                                    child: Align(
                                      alignment: Alignment(0.48, 0),
                                      child: Text(
                                        "Forgot Password?",
                                        style: TextStyle(color: Colors.black),
                                      ),
                                    ),
                                  ),
                                ),
                          Padding(
                            padding: EdgeInsets.only(top: 20),
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.65,
                              height: 45,
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () {
                                        _loginMode
                                            ? _handleLogin()
                                            : _handleSignup();
                                      },
                                style: ElevatedButton.styleFrom(
                                  elevation: 5,
                                  backgroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: _isLoading
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                _loginMode
                                                    ? Colors.blue.shade400
                                                    : Colors.green.shade400,
                                              ),
                                        ),
                                      )
                                    : Text(
                                        _loginMode ? 'Login' : 'Sign Up',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: _loginMode
                                              ? Colors.blue.shade400
                                              : Colors.green.shade400,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
