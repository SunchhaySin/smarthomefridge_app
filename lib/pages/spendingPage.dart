import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Spendingpage extends StatefulWidget {
  final String? loggedInUser;
  const Spendingpage({super.key, required this.loggedInUser});

  @override
  State<Spendingpage> createState() => _SpendingPageState();
}

class _SpendingPageState extends State<Spendingpage> {
  Stream<List<Map<String, dynamic>>> getItems() {
    return FirebaseFirestore.instance
        .collection("StoredItem")
        .where("userUID", isEqualTo: widget.loggedInUser)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              "itemName": data["itemName"] ?? "",
              "itemCategory": data["itemCategory"] ?? "Other",
              "itemPrice": (data["itemPrice"] ?? 0).toDouble(),
              "itemExpiryDate": data["itemExpiryDate"] ?? "",
            };
          }).toList(),
        );
  }

  bool isExpired(String expiryString) {
    if (expiryString.isEmpty) return false;
    try {
      final parts = expiryString.split('/');
      final expiryDate = DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
      final today = DateTime.now();
      final cleanToday = DateTime(today.year, today.month, today.day);
      return expiryDate.isBefore(cleanToday);
    } catch (_) {
      return false;
    }
  }

  Map<String, double> getCategoryTotals(List<Map<String, dynamic>> items) {
    final Map<String, double> totals = {};
    for (final item in items) {
      final category = item["itemCategory"] as String;
      final price = item["itemPrice"] as double;
      totals[category] = (totals[category] ?? 0) + price;
    }
    return totals;
  }

  double getTotalSpent(List<Map<String, dynamic>> items) {
    return items.fold(0.0, (sum, item) => sum + (item["itemPrice"] as double));
  }

  double getWastedCost(List<Map<String, dynamic>> items) {
    return items
        .where((item) => isExpired(item["itemExpiryDate"]))
        .fold(0.0, (sum, item) => sum + (item["itemPrice"] as double));
  }

  Color getCategoryColor(String category) {
    final colors = {
      "Meat": Colors.red.shade400,
      "Vegetable": Colors.green.shade400,
      "Fruit": Colors.orange.shade400,
      "Dairy": Colors.blue.shade300,
      "Beverage": Colors.purple.shade300,
      "Snack": Colors.yellow.shade700,
      "Frozen": Colors.cyan.shade400,
      "Other": Colors.grey.shade400,
    };
    return colors[category] ?? Colors.indigo.shade300;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: getItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data ?? [];
          final totalSpent = getTotalSpent(items);
          final wastedCost = getWastedCost(items);
          final categoryTotals = getCategoryTotals(items);
          final expiredItems = items
              .where((i) => isExpired(i["itemExpiryDate"]))
              .toList();

          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              child: Container(
                width: double.infinity,
                color: Colors.indigo.shade50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 60),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        "Spending Overview",
                        style: TextStyle(
                          color: Colors.indigo.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    SizedBox(height: 15),

                    // Summary Cards
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: _summaryCard(
                              label: "Total Spent",
                              value: "฿${totalSpent.toStringAsFixed(2)}",
                              icon: Icons.account_balance_wallet,
                              color: Colors.indigo.shade700,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _summaryCard(
                              label: "Wasted",
                              value: "฿${wastedCost.toStringAsFixed(2)}",
                              icon: Icons.delete_outline,
                              color: Colors.red.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20),

                    // Spending by Category
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        "Spending by Category",
                        style: TextStyle(
                          color: Colors.indigo.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 20),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: categoryTotals.isEmpty
                          ? Center(
                              child: Text(
                                "No items yet",
                                style: TextStyle(color: Colors.indigo.shade300),
                              ),
                            )
                          : Column(
                              children: categoryTotals.entries.map((entry) {
                                final percentage = totalSpent > 0
                                    ? entry.value / totalSpent
                                    : 0.0;
                                return Padding(
                                  padding: EdgeInsets.only(bottom: 12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                width: 10,
                                                height: 10,
                                                decoration: BoxDecoration(
                                                  color: getCategoryColor(
                                                    entry.key,
                                                  ),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                entry.key,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.indigo.shade800,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            "฿${entry.value.toStringAsFixed(2)}",
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.indigo.shade700,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 6),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: LinearProgressIndicator(
                                          value: percentage,
                                          minHeight: 8,
                                          backgroundColor:
                                              Colors.indigo.shade50,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                getCategoryColor(entry.key),
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                    ),

                    SizedBox(height: 20),

                    // Expired / Wasted Items
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        "Expired Items",
                        style: TextStyle(
                          color: Colors.indigo.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: expiredItems.isEmpty
                          ? Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(
                                child: Text(
                                  "No expired items ",
                                  style: TextStyle(
                                    color: Colors.indigo.shade300,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.all(12),
                              itemCount: expiredItems.length,
                              itemBuilder: (context, index) {
                                final item = expiredItems[index];
                                return Container(
                                  margin: EdgeInsets.only(bottom: 8),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.red.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.warning_amber_rounded,
                                            size: 16,
                                            color: Colors.red.shade400,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            item["itemName"],
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.red.shade700,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        "฿${(item["itemPrice"] as double).toStringAsFixed(2)}",
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.red.shade700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _summaryCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 22),
          SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}
