import 'package:flutter/material.dart';

class ItemList extends StatefulWidget {
  final String itemName;
  final int itemQuantity;
  final String itemCategory;
  final String itemExpiryDate;
  final int itemPrice;
  final String itemUnit;

  const ItemList({
    super.key,
    required this.itemName,
    required this.itemQuantity,
    required this.itemCategory,
    required this.itemExpiryDate,
    required this.itemPrice,
    required this.itemUnit,
  });

  @override
  State<ItemList> createState() => _ItemListState();
}

class _ItemListState extends State<ItemList> {
  @override
  Widget build(BuildContext context) {
    final Map<String, Color> categoryColors = {
      'Fruit': Colors.orange.shade100,
      'Vegetable': Colors.green.shade100,
      'Meat': Colors.red.shade100,
      'Seafood': Colors.blue.shade100,
      'Dairy': Colors.amber.shade100,
      'Beverage': Colors.cyan.shade100,
      'Soup': Colors.deepPurple.shade100,
      'Dessert': Colors.pink.shade100,
      'Snack': Colors.deepOrange.shade100,
      'Leftovers': Colors.teal.shade100,
      'Other': Colors.blueGrey.shade100,
    };

    final color = categoryColors[widget.itemCategory] ?? Colors.blueGrey;

    final Map<String, IconData> categoryIcons = {
      'Fruit': Icons.apple,
      'Vegetable': Icons.eco,
      'Meat': Icons.set_meal,
      'Seafood': Icons.set_meal,
      'Dairy': Icons.water_drop,
      'Beverage': Icons.local_drink,
      'Soup': Icons.soup_kitchen,
      'Dessert': Icons.cake,
      'Snack': Icons.cookie,
      'Leftovers': Icons.lunch_dining,
      'Other': Icons.kitchen,
    };

    final icon = categoryIcons[widget.itemCategory] ?? Icons.kitchen;

    DateTime parseDate(String date) {
      final parts = date.split('/');

      int day = int.parse(parts[0]);
      int month = int.parse(parts[1]);
      int year = int.parse(parts[2]);

      return DateTime(year, month, day);
    }

    DateTime expiryDate = parseDate(widget.itemExpiryDate);

    DateTime today = DateTime.now();
    DateTime cleanToday = DateTime(today.year, today.month, today.day);

    int daysLeft = expiryDate.difference(cleanToday).inDays;

    String expiryText;

    if (daysLeft < 0) {
      expiryText = "Expired";
    } else if (daysLeft == 0) {
      expiryText = "Today";
    } else if (daysLeft == 1) {
      expiryText = "1 day";
    } else {
      expiryText = "$daysLeft days";
    }

    return Container(
      width: MediaQuery.of(context).size.width * 0.84,
      height: 60,
      margin: EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: Row(
        children: [
          SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.indigoAccent.shade100)
            ),
            padding: EdgeInsets.all(8),
            child: Icon(icon, size: 30, color: Colors.indigo.shade500)),
          SizedBox(width: 20),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.itemName,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                    child: Text(
                      "${widget.itemCategory}",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.indigo.shade800,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Row(
                    children: [
                      Text(
                        "${widget.itemQuantity}",
                        style: TextStyle(fontSize: 12),
                      ),
                      SizedBox(width:2),
                      Text("${widget.itemUnit}", style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  SizedBox(width: 10),
                  Text(
                    "${widget.itemPrice} ฿",
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          Spacer(),
          Padding(
            padding: EdgeInsets.only(right: 15),
            child: Text(
              expiryText,
              style: TextStyle(
                fontSize: 12,
                color: daysLeft < 0
                    ? Colors.red
                    : (daysLeft <= 3 ? Colors.orange : Colors.green),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
