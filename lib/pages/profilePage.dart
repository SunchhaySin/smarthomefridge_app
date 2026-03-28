import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smarthomefridge/pages/authenticationPage.dart';


class Profilepage extends StatefulWidget {
  final String? loggedInUser;
  const Profilepage({super.key, required this.loggedInUser});

  @override
  State<Profilepage> createState() => _ProfilepageState();
}

class _ProfilepageState extends State<Profilepage> {
  late TextEditingController usernameController;
  late TextEditingController emailController;

  bool isLoading = true;
  bool isSaving = false;
  bool isEditing = false;
  String? docId;

  @override
  void initState() {
    super.initState();
    usernameController = TextEditingController();
    emailController = TextEditingController();
    fetchUserInfo();
  }

  Future<void> fetchUserInfo() async {
    setState(() => isLoading = true);

    final query = await FirebaseFirestore.instance
        .collection("Users")
        .where("UID", isEqualTo: widget.loggedInUser)
        .limit(1)
        .get();

    if (!mounted) return;

    if (query.docs.isNotEmpty) {
      final data = query.docs.first.data();
      setState(() {
        docId = query.docs.first.id;
        usernameController.text = data['Username'] ?? '';
        emailController.text = data['Email'] ?? '';
        isLoading = false;
      });
    }
  }

  Future updateProfile() async {
    try {
      await FirebaseFirestore.instance.collection("Users").doc(docId).update({
        "Email": emailController.text.trim(),
        "Username": usernameController.text.trim(),
      });
      await FirebaseFirestore.instance.collection("Notifications").add({
        "userUID": widget.loggedInUser,
        "type": "update_username",
        "message": "You have updated your username to ${usernameController.text}",
        "createdAt": FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Profile updated successfully!")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to update Profile")));
    }
  }


    
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text(
                "User Profile",
                style: TextStyle(
                  color: Colors.indigo.shade800,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              SizedBox(height:30),
              Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: 450,
                decoration: BoxDecoration(
                  color: Colors.indigo.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                child: Column(
                  children: [
                    Icon(
                      Icons.account_circle_sharp,
                      size: 100,
                      color: Colors.indigo.shade600,
                    ),
                    SizedBox(height: 20),
                    isLoading
                        ? CircularProgressIndicator()
                        : Column(
                            children: [
                              Column(
                                children: [
                                  Align(
                                    alignment: AlignmentDirectional(-0.95, -1.0),
                                    child: Text(
                                      "Username",
                                      style: TextStyle(
                                        color: Colors.indigo.shade800,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  TextField(
                                    readOnly: !isEditing,
                                    controller: usernameController,
                                    contextMenuBuilder: isEditing
                                        ? null
                                        : (context, editableTextState) =>
                                              const SizedBox.shrink(),
                                    decoration: InputDecoration(
                                      filled: true,
                                      isDense: true,
                                      fillColor: isEditing
                                          ? Colors.indigo.shade200
                                          : Colors.indigo.shade50,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.indigo.shade800,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10),
                              Column(
                                children: [
                                  Align(
                                    alignment: AlignmentDirectional(-0.95, -1.0),
                                    child: Text(
                                      "Email",
                                      style: TextStyle(
                                        color: Colors.indigo.shade800,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  TextField(
                                    readOnly: true,
                                    controller: emailController,
                                    contextMenuBuilder: isEditing
                                        ? null
                                        : (context, editableTextState) =>
                                              const SizedBox.shrink(),
                                    decoration: InputDecoration(
                                      filled: true,
                                      isDense: true,
                                      fillColor: Colors.indigo.shade50,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.indigo.shade800,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 30),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        isEditing = true;
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      elevation: 10,
                                      backgroundColor: Colors.green.shade800
                                          .withOpacity(0.7),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                    child: Text(
                                      "Edit Profile",
                                      style: TextStyle(
                                        color: Colors.green.shade100,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  ElevatedButton(
                                    onPressed: () async {
                                      await updateProfile();
                                      setState(() {
                                        isEditing = false;
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      elevation: 10,
                                      backgroundColor: Colors.indigo.shade800
                                          .withOpacity(0.7),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                    child: Text(
                                      "Confirm Edit",
                                      style: TextStyle(
                                        color: Colors.indigo.shade100,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ],
                ),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                 Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AuthenticationPage()));
                },
                style: ElevatedButton.styleFrom(
                  elevation: 10,
                  backgroundColor: Colors.red.shade800.withOpacity(0.7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Sign out", style: TextStyle(color: Colors.red.shade50)),
                    SizedBox(width: 8),
                    Icon(Icons.logout, color: Colors.red.shade50),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
