import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smarthomefridge/builders/ingredientList.dart';
import 'dart:async';

import 'package:smarthomefridge/builders/recipeList.dart';

class Recipepage extends StatefulWidget {
  final String? loggedInUser;
  const Recipepage({super.key, required this.loggedInUser});

  @override
  State<Recipepage> createState() => _RecipepageState();
}

class _RecipepageState extends State<Recipepage> {
  List<Map<String, dynamic>> availableIngredients = [];
  StreamSubscription? _ingredientSub;
  List<Map<String, dynamic>> recipes = [];
  int? expandedRecipeIndex;
  bool isLoadingRecipes = false;
  Set<int> savedRecipeIndices = {}; // Keep Record of Saved Recipes
  bool showSavedRecipes = false;
  Map<int, String> savedRecipeDocIds = {};
  String stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  Future<void> fetchRecipes() async {
    final apiKey = dotenv.env["APIKEY"];
    final ingredientList = availableIngredients
        .map((item) => item["itemName"] as String)
        .join(",");

    // Find recipes by ingredients
    final url = Uri.https("api.spoonacular.com", "/recipes/findByIngredients", {
      "ingredients": ingredientList,
      "apiKey": apiKey,
      "number": "5",
      "ranking": "2",
      "ignorePantry": "true",
    });

    final response = await http.get(url);
    if (response.statusCode != 200) return;

    final data = jsonDecode(response.body) as List;
    if (data.isEmpty) return;

    // Fetch details for all recipes at once
    final ids = data.map((r) => r["id"].toString()).join(",");
    final bulkUrl = Uri.https(
      "api.spoonacular.com",
      "/recipes/informationBulk",
      {"apiKey": apiKey, "ids": ids},
    );

    final bulkRes = await http.get(bulkUrl);
    if (bulkRes.statusCode != 200) return;

    final details = jsonDecode(bulkRes.body) as List;

    final detailed = data.map((recipe) {
      final detail = details.firstWhere(
        (d) => d["id"] == recipe["id"],
        orElse: () => {},
      );
      return {
        "id": recipe["id"],
        "title": recipe["title"],
        "usedCount": recipe["usedIngredientCount"],
        "missedCount": recipe["missedIngredientCount"],
        "readyInMinutes": detail["readyInMinutes"],
        "servings": detail["servings"],
        "instructions": stripHtml(
          detail["instructions"] ?? "No instructions available",
        ),
      };
    }).toList();

    setState(() {
      recipes = detailed;
    });
  }

  Stream<List<Map<String, dynamic>>> getAvailableIngredients() {
    return FirebaseFirestore.instance
        .collection("StoredItem")
        .where("userUID", isEqualTo: widget.loggedInUser)
        .snapshots()
        .map((snapshot) {
          final today = DateTime.now();
          final cleanToday = DateTime(today.year, today.month, today.day);

          return snapshot.docs
              .where((doc) {
                final item = doc.data();
                final expiryString = item["itemExpiryDate"] ?? "";
                if (expiryString.isEmpty) return false;
                final parts = expiryString.split('/');
                final expiryDate = DateTime(
                  int.parse(parts[2]),
                  int.parse(parts[1]),
                  int.parse(parts[0]),
                );
                return expiryDate.difference(cleanToday).inDays >= 0;
              })
              .map((doc) {
                final data = doc.data();
                return {
                  "itemName": data["itemName"] ?? "",
                  "itemQuantity": data["itemQuantity"],
                  "itemUnit": data["itemUnit"] ?? "",
                  "itemCategory": data["itemCategory"] ?? "",
                };
              })
              .toList();
        });
  }

  Future<void> saveRecipe(Map<String, dynamic> recipe, int index) async {
    final docRef = await FirebaseFirestore.instance.collection("Recipes").add({
      "userUID": widget.loggedInUser,
      "title": recipe["title"],
      "readyInMinutes": recipe["readyInMinutes"],
      "servings": recipe["servings"],
      "instructions": recipe["instructions"],
      "usedCount": recipe["usedCount"],
      "missedCount": recipe["missedCount"],
      "savedAt": FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance.collection("Notifications").add({
      "userUID": widget.loggedInUser,
      "type": "save_recipe",
      "message": "Saved a recipe: ${recipe["title"]}",
      "createdAt": FieldValue.serverTimestamp(),
    });
    if (!mounted) return;
    setState(() {
      savedRecipeIndices.add(index);
      savedRecipeDocIds[index] = docRef.id;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Recipe saved!")));
  }

  @override
  void initState() {
    super.initState();
    _ingredientSub = getAvailableIngredients().listen((ingredients) {
      setState(() {
        availableIngredients = ingredients;
      });
    });
  }

  @override
  void dispose() {
    _ingredientSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: double.infinity,
          color: Colors.indigo.shade50,
          child: Column(
            children: [
              SizedBox(height: 60),
              Text(
                "Kitchen Assistant",
                style: TextStyle(
                  color: Colors.indigo.shade800,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              SizedBox(height: 15),
              Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: 410,
                decoration: BoxDecoration(
                  color: Colors.indigo.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 20,
                      ),
                      child: Text(
                        "Available Ingredients",
                        style: TextStyle(
                          color: Colors.indigo.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        Container(
                          height: 90,
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          margin: EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 12,
                          ),
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: availableIngredients
                                .map(
                                  (item) => Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 10,
                                      horizontal: 6,
                                    ),
                                    child: Ingredientlist(
                                      itemName: item["itemName"],
                                      itemQuantity:
                                          (item["itemQuantity"] is int)
                                          ? item["itemQuantity"]
                                          : int.tryParse(
                                                  item["itemQuantity"]
                                                      .toString(),
                                                ) ??
                                                0,
                                      itemCategory: item["itemCategory"],
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade800.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        margin: EdgeInsets.only(right: 12),
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 2,
                        ),
                        child: GestureDetector(
                          child: Text(
                            "Your Recipes",
                            style: TextStyle(color: Colors.indigo.shade100),
                          ),
                          onTap: () {
                            setState(() {
                              showSavedRecipes = true;
                              expandedRecipeIndex = null;
                            });
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Container(
                      height: 210,
                      margin: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: isLoadingRecipes
                          ? Center(child: CircularProgressIndicator())
                          : showSavedRecipes
                          ? StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection("Recipes")
                                  .where(
                                    "userUID",
                                    isEqualTo: widget.loggedInUser,
                                  )
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                                if (!snapshot.hasData ||
                                    snapshot.data!.docs.isEmpty) {
                                  return Center(
                                    child: Text(
                                      "No saved recipes yet",
                                      style: TextStyle(
                                        color: Colors.indigo.shade300,
                                        fontSize: 14,
                                      ),
                                    ),
                                  );
                                }
                                final savedRecipes = snapshot.data!.docs;
                                return ListView.builder(
                                  padding: EdgeInsets.all(8),
                                  itemCount: savedRecipes.length,
                                  itemBuilder: (context, index) {
                                    final doc = savedRecipes[index];
                                    final data =
                                        doc.data() as Map<String, dynamic>;
                                    final recipe = {
                                      "docId": doc.id,
                                      "title": data["title"],
                                      "readyInMinutes": data["readyInMinutes"],
                                      "servings": data["servings"],
                                      "instructions": data["instructions"],
                                      "usedCount": data.containsKey("usedCount")
                                          ? data["usedCount"]
                                          : 0,
                                      "missedCount":
                                          data.containsKey("missedCount")
                                          ? data["missedCount"]
                                          : 0,
                                    };
                                    return RecipeList(
                                      recipe: recipe,
                                      isExpanded: expandedRecipeIndex == index,
                                      isSaved: true,
                                      savedView: true,
                                      onTap: () {
                                        setState(() {
                                          expandedRecipeIndex =
                                              expandedRecipeIndex == index
                                              ? null
                                              : index;
                                        });
                                      },
                                      onSave: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text("Remove Recipe"),
                                            content: Text(
                                              "Are you sure you want to remove this recipe from Saved Recipes?",
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(
                                                  context,
                                                ).pop(false),
                                                child: Text("Cancel"),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.of(
                                                  context,
                                                ).pop(true),
                                                child: Text(
                                                  "Remove",
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirm != true) return;
                                         final recipeName = recipe["title"] ?? "recipe";
                                        await FirebaseFirestore.instance
                                            .collection("Recipes")
                                            .doc(doc.id)
                                            .delete();
                                        await FirebaseFirestore.instance
                                            .collection("Notifications")
                                            .add({
                                              "userUID": widget.loggedInUser,
                                              "type": "remove_recipe",
                                              "message": "Removed ${recipeName} from saved recipe",
                                              "createdAt":
                                                  FieldValue.serverTimestamp(),
                                            });
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text("Recipe removed!"),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                            )
                          : recipes.isEmpty
                          ? Center(
                              child: SizedBox(
                                width: 280,
                                child: Text(
                                  "Press Generate Recipe to get started. Click your recipes to view your saved recipes",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.indigo.shade300,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.all(8),
                              itemCount: recipes.length,
                              itemBuilder: (context, index) {
                                final recipe = recipes[index];
                                return RecipeList(
                                  recipe: recipe,
                                  isExpanded: expandedRecipeIndex == index,
                                  onTap: () {
                                    setState(() {
                                      expandedRecipeIndex =
                                          expandedRecipeIndex == index
                                          ? null
                                          : index;
                                    });
                                  },
                                  onSave: () => saveRecipe(recipe, index),
                                  isSaved: savedRecipeIndices.contains(index),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.indigo.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 20,
                      ),
                      child: Text(
                        "Recipe Manager",
                        style: TextStyle(
                          color: Colors.indigo.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      margin: EdgeInsets.all(8),
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(
                          "This is a smart AI tool to help decide quick recipes with the avaible ingredients in your fridge.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.indigo.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: ElevatedButton(
                        onPressed: () async {
                          setState(() {
                            isLoadingRecipes = true;
                            showSavedRecipes = false;
                            expandedRecipeIndex = null;
                          });
                          await fetchRecipes();
                          setState(() => isLoadingRecipes = false);
                        },
                        style: ElevatedButton.styleFrom(
                          elevation: 10,
                          backgroundColor: Colors.indigo.shade800.withOpacity(
                            0.7,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text(
                          "Generate Recipe ",
                          style: TextStyle(color: Colors.indigo.shade100),
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
    );
  }
}
