import 'dart:convert';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smarthomefridge/builders/insertPanel.dart';
import 'package:smarthomefridge/builders/itemList.dart';
import 'package:smarthomefridge/pages/notificationPage.dart';
import 'package:smarthomefridge/pages/profilePage.dart';
import 'package:smarthomefridge/pages/recipePage.dart';
import 'package:smarthomefridge/pages/spendingPage.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage>
    with SingleTickerProviderStateMixin {
  final loggedInUser = FirebaseAuth.instance.currentUser;
  // String? username;
  bool showInsertPanel = false;
  int _selectedIndex = 0;
  double dragStartX = 0;
  Map<String, dynamic>? selectedItem;
  String? selectedDocId;
  final ValueNotifier<Map<String, int>> fridgeStats = ValueNotifier({
    'total': 0,
    'expiringSoon': 0,
    'expired': 0,
  });

  late final List<Widget> _pages = [
    Center(child: Text("Home Page")),
    Recipepage(loggedInUser: loggedInUser?.uid),
    Spendingpage(loggedInUser: loggedInUser?.uid),
    Profilepage(loggedInUser: loggedInUser?.uid),
  ];
  DateTime currentDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    setState(() {
      currentDay = DateTime.now();
    });
  }


  void signOut() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Log Out"),
          content: Text("Are you sure you want to log out?"),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancel", style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () {
                FirebaseAuth.instance.signOut();
                Navigator.of(context).pop();
              },
              child: Text("Sign Out", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>?> fetchFoodData(String foodName) async {
    final apiKey = dotenv.env["APIKEY"];

    // search for the ingredient
    final searchUrl = Uri.https(
      "api.spoonacular.com",
      "/food/ingredients/search",
      {"query": foodName, "apiKey": apiKey, "number": "1"},
    );

    final searchResponse = await http.get(searchUrl);

    if (searchResponse.statusCode == 200) {
      final searchData = jsonDecode(searchResponse.body);

      if (searchData["results"] != null && searchData["results"].isNotEmpty) {
        final ingredientId = searchData["results"][0]["id"];
        final ingredientName = searchData["results"][0]["name"];

        // fetch nutrition details for that ingredient
        final detailUrl = Uri.https(
          "api.spoonacular.com",
          "/food/ingredients/$ingredientId/information",
          {
            "apiKey": apiKey,
            "amount": "100", // per 100g
            "unit": "grams",
          },
        );

        final detailResponse = await http.get(detailUrl);

        if (detailResponse.statusCode == 200) {
          final detail = jsonDecode(detailResponse.body);
          final nutrients = detail["nutrition"]["nutrients"] as List;

          final foodData = [
            "Calories",
            "Protein",
            "Carbohydrates",
            "Fat",
            "Sugar",
            "Sodium",
            "Fiber",
            "Cholesterol",
          ];

          final filteredNutrients = nutrients
              .where((n) => foodData.contains(n["name"]))
              .map(
                (n) => {
                  "name": n["name"],
                  "amount": n["amount"],
                  "unit": n["unit"],
                },
              )
              .toList();

          return {"name": ingredientName, "nutrients": filteredNutrients};
        }
      }
    }

    return null;
  }

  void showFoodDialog(BuildContext context, Map<String, dynamic> product) {
    final name = product["name"] ?? "Unknown";
    final nutrients = product["nutrients"] as List;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Nutrition per 100g",
                style: TextStyle(color: Colors.indigo.shade800, fontSize: 14),
              ),
              SizedBox(height: 8),
              ...nutrients.map(
                (n) => Padding(
                  padding: EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        n["name"],
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        "${n["amount"]} ${n["unit"]}",
                        style: TextStyle(color: Colors.indigo.shade800),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: _selectedIndex == 0
          ? AppBar(
              title: Text(
                "Fridge Inventory",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Colors.indigo.shade600,
                ),
              ),
              backgroundColor: Colors.white,
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.notifications_rounded,
                    size: 30,
                    color: Colors.indigo.shade600,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            Notificationpage(loggedInUser: loggedInUser?.uid),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.logout_rounded,
                    size: 30,
                    color: Colors.indigo.shade600,
                  ),
                  onPressed: () {
                    signOut();
                  },
                ),
              ],
            )
          : null,
      body: _selectedIndex == 0
          ? SingleChildScrollView(
              child: Container(
                color: Colors.indigo.shade50,
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: EdgeInsets.only(top: 10, bottom: 5, right: 25),
                        child: Text(
                          "${currentDay.day}/${currentDay.month}/${currentDay.year}",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.indigo.shade600,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width * 0.9,
                          height: showInsertPanel ? 350 : 500,
                          alignment: Alignment.topCenter,
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade100,
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 15),
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection("StoredItem")
                                .where("userUID", isEqualTo: loggedInUser?.uid)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (snapshot.hasError) {
                                return Center(
                                  child: Text("Error loading items"),
                                );
                              }
                              if (!snapshot.hasData ||
                                  snapshot.data!.docs.isEmpty) {
                                return Center(
                                  child: Text("No items in fridge"),
                                );
                              }
                              final items = snapshot.data!.docs;
                              int totalItems = items.length;
                              int expiredItems = 0;
                              int expiringSoonItems = 0;

                              DateTime today = DateTime.now();
                              DateTime cleanToday = DateTime(
                                today.year,
                                today.month,
                                today.day,
                              );

                              for (var doc in items) {
                                final item = doc.data() as Map<String, dynamic>;
                                final expiryString =
                                    item["itemExpiryDate"] ?? "";
                                if (expiryString.isEmpty) continue;

                                final parts = expiryString.split('/');
                                DateTime expiryDate = DateTime(
                                  int.parse(parts[2]),
                                  int.parse(parts[1]),
                                  int.parse(parts[0]),
                                );

                                int daysLeft = expiryDate
                                    .difference(cleanToday)
                                    .inDays;
                                if (daysLeft < 0) {
                                  expiredItems++;
                                } else if (daysLeft <= 3) {
                                  expiringSoonItems++;
                                }
                              }
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                fridgeStats.value = {
                                  'total': totalItems,
                                  'expiringSoon': expiringSoonItems,
                                  'expired': expiredItems,
                                };
                              });
                              return Column(
                                children: [
                                  Expanded(
                                    child: ListView.builder(
                                      padding: EdgeInsets.zero,
                                      shrinkWrap: true,
                                      itemCount: items.length,
                                      itemBuilder: (context, index) {
                                        final item =
                                            items[index].data()
                                                as Map<String, dynamic>;
                                        return Center(
                                          child: Dismissible(
                                            key: Key(items[index].id),
                                            direction:
                                                DismissDirection.horizontal,
                                            background: Container(
                                              alignment: Alignment.centerLeft,
                                              padding: EdgeInsets.only(
                                                left: 20,
                                              ),
                                              color: Colors.green,
                                              child: Icon(
                                                Icons.edit,
                                                color: Colors.white,
                                              ),
                                            ),
                                            secondaryBackground: Container(
                                              alignment: Alignment.centerRight,
                                              padding: EdgeInsets.only(
                                                right: 20,
                                              ),
                                              color: Colors.red,
                                              child: Icon(
                                                Icons.delete,
                                                color: Colors.white,
                                              ),
                                            ),
                                            confirmDismiss: (direction) async {
                                              if (direction ==
                                                  DismissDirection.startToEnd) {
                                                // Swipe right → edit
                                                setState(() {
                                                  showInsertPanel = true;
                                                  selectedItem = item;
                                                  selectedDocId =
                                                      items[index].id;
                                                });
                                              } else if (direction ==
                                                  DismissDirection.endToStart) {
                                                // Swipe left → delete
                                                bool?
                                                confirmDelete = await showDialog(
                                                  context: context,
                                                  builder: (context) {
                                                    return AlertDialog(
                                                      title: Text(
                                                        "Delete Item",
                                                      ),
                                                      content: Text(
                                                        "Are you sure you want to delete '${item["itemName"]}'?",
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.of(
                                                                context,
                                                              ).pop(false),
                                                          child: Text("Cancel"),
                                                        ),
                                                        ElevatedButton(
                                                          style:
                                                              ElevatedButton.styleFrom(
                                                                backgroundColor:
                                                                    Colors.red,
                                                              ),
                                                          onPressed: () =>
                                                              Navigator.of(
                                                                context,
                                                              ).pop(true),
                                                          child: Text(
                                                            "Delete",
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                                if (confirmDelete == true) {
                                                  final itemName =
                                                      item["itemName"] ??
                                                      "item";
                                                  // Deletes Item
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection("StoredItem")
                                                      .doc(items[index].id)
                                                      .delete();
                                                  // Created Notification
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection(
                                                        "Notifications",
                                                      )
                                                      .add({
                                                        "userUID":
                                                            loggedInUser?.uid,
                                                        "type": "delete_item",
                                                        "message":
                                                            "Deleted $itemName from fridge",
                                                        "createdAt":
                                                            FieldValue.serverTimestamp(),
                                                      });
                                                }
                                                return false;
                                              }
                                              return false;
                                            },
                                            child: GestureDetector(
                                              child: ItemList(
                                                itemName:
                                                    item["itemName"] ?? "",
                                                itemQuantity:
                                                    int.tryParse(
                                                      item["itemQuantity"]
                                                          .toString(),
                                                    ) ??
                                                    0,

                                                itemCategory:
                                                    item["itemCategory"] ?? "",
                                                itemUnit:
                                                    item["itemUnit"] ?? "",
                                                itemExpiryDate:
                                                    item["itemExpiryDate"] ??
                                                    "",
                                                itemPrice:
                                                    int.tryParse(
                                                      item["itemPrice"]
                                                          .toString(),
                                                    ) ??
                                                    0,
                                              ),
                                              onTap: () async {
                                                showDialog(
                                                  context: context,
                                                  barrierDismissible: false,
                                                  builder: (_) => Center(
                                                    child:
                                                        CircularProgressIndicator(),
                                                  ),
                                                );

                                                final foodData =
                                                    await fetchFoodData(
                                                      item["itemName"] ?? "",
                                                    );

                                                Navigator.of(
                                                  context,
                                                ).pop(); 

                                                if (!mounted) return;

                                                if (foodData != null) {
                                                  showFoodDialog(
                                                    context,
                                                    foodData,
                                                  );
                                                } else {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        "No data found for ${item["itemName"]}",
                                                      ),
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 15, bottom: 15),
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.9,
                            height: showInsertPanel ? 260 : 60,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.indigo.shade100,
                              borderRadius: BorderRadius.all(
                                Radius.circular(10),
                              ),
                            ),
                            child: showInsertPanel
                                ? Container(
                                    width:
                                        MediaQuery.of(context).size.width *
                                        0.85,
                                    child: Insertpanel(
                                      onClose: () => setState(
                                        () => showInsertPanel = false,
                                      ),
                                      loggedInUser: loggedInUser?.uid,
                                      isEdit: selectedItem != null,
                                      docId: selectedDocId,
                                      existingItem: selectedItem,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        icon: Icon(Icons.add_box_sharp),
                                        iconSize: 20,
                                        color: Colors.indigo.shade800,
                                        onPressed: () {
                                          setState(() {
                                            showInsertPanel = true;
                                            selectedItem =
                                                null; // <--- reset for add mode
                                            selectedDocId =
                                                null; // <--- reset for add mode
                                          });
                                        },
                                      ),
                                      Text(
                                        "Click to open data entry form",
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.indigo.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        Container(
                          width: MediaQuery.of(context).size.width * 0.9,
                          height: 180,
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade100,
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          child: ValueListenableBuilder<Map<String, int>>(
                            valueListenable: fridgeStats,
                            builder: (context, stats, _) {
                              return Column(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(
                                      top: 15,
                                      bottom: 15,
                                    ),
                                    child: Text(
                                      "Fridge Health",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.indigo.shade800,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 2,
                                      horizontal: 20,
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.indigo.shade50,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Total Items",
                                            style: TextStyle(
                                              color: Colors.green.shade800,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            "${stats['total']}",
                                            style: TextStyle(
                                              color: Colors.indigo.shade800,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 2,
                                      horizontal: 20,
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.indigo.shade50,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Expiring Soon",
                                            style: TextStyle(
                                              color: Colors.orange.shade800,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            "${stats['expiringSoon']}",
                                            style: TextStyle(
                                              color: Colors.indigo.shade800,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 2,
                                      horizontal: 20,
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.indigo.shade50,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Expired",
                                            style: TextStyle(
                                              color: Colors.red.shade800,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            "${stats['expired']}",
                                            style: TextStyle(
                                              color: Colors.indigo.shade800,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          : _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Container(
              decoration: BoxDecoration(
                color: Colors.indigo.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.all(4),
              child: Icon(Icons.home, color: Colors.indigo.shade800),
            ),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Container(
              decoration: BoxDecoration(
                color: Colors.indigo.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.all(4),
              child: Icon(Icons.food_bank, color: Colors.indigo.shade800),
            ),
            label: "Recipe",
          ),
          BottomNavigationBarItem(
            icon: Container(
              decoration: BoxDecoration(
                color: Colors.indigo.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.all(4),
              child: Icon(Icons.bar_chart, color: Colors.indigo.shade800),
            ),
            label: "Spendings",
          ),
          BottomNavigationBarItem(
            icon: Container(
              decoration: BoxDecoration(
                color: Colors.indigo.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.all(4),
              child: Icon(Icons.person, color: Colors.indigo.shade800),
            ),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}
