import 'package:flutter/material.dart';

class Ingredientlist extends StatefulWidget {
  final String itemName;
  final int itemQuantity;
  final String itemCategory;

  const Ingredientlist({
    super.key,
    required this.itemName,
    required this.itemQuantity,
    required this.itemCategory,
  });

  @override
  State<Ingredientlist> createState() => _IngredientListState();
}

class _IngredientListState extends State<Ingredientlist> {
  final Map<String, Color> categoryColors = {
    'Fruit': Colors.orange,
    'Vegetable': Colors.green,
    'Meat': Colors.red,
    'Seafood': Colors.blue,
    'Dairy': Colors.amber.shade800,
    'Beverage': Colors.cyan,
    'Soup': Colors.deepPurple,
    'Dessert': Colors.pink,
    'Snack': Colors.deepOrange,
    'Leftovers': Colors.teal,
    'Other': Colors.blueGrey,
  };

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

  @override
  Widget build(BuildContext context) {
    final color = categoryColors[widget.itemCategory] ?? Colors.blueGrey;
    final icon = categoryIcons[widget.itemCategory] ?? Icons.kitchen;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 25, color: color),
              SizedBox(height: 4),
              Text(
                widget.itemName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Text(
              "x${widget.itemQuantity}",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
