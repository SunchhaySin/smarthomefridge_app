import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Insertpanel extends StatefulWidget {
  final VoidCallback onClose;
  final String? loggedInUser;
  final bool isEdit;
  final String? docId;
  final Map<String, dynamic>? existingItem;
  const Insertpanel({
    super.key,
    required this.onClose,
    required this.loggedInUser,
    this.isEdit = false,
    this.docId,
    this.existingItem,
  });

  @override
  State<Insertpanel> createState() => _InsertpanelState();
}

class _InsertpanelState extends State<Insertpanel> {
  final itemNameController = TextEditingController();
  final itemCategoryController = TextEditingController();
  final itemQuantityController = TextEditingController();
  final itemExpirationDateController = TextEditingController();
  final itemPriceController = TextEditingController();

  final Map<String, String> categoryUnits = {
    'Fruit': 'kg',
    'Vegetable': 'kg',
    'Meat': 'kg',
    'Seafood': 'kg',
    'Dairy': 'litre',
    'Beverage': 'litre',
    'Soup': 'bowl',
    'Dessert': 'pcs',
    'Snack': 'pcs',
    'Leftovers': 'pcs',
    'Other': 'pcs',
  };
  String? selectedCategory;
  String quantityUnit = '';

  Future addItem() async {
    if (itemNameController.text.trim().isEmpty ||
        itemCategoryController.text.trim().isEmpty ||
        itemQuantityController.text.trim().isEmpty ||
        itemExpirationDateController.text.trim().isEmpty ||
        itemPriceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter Item Details Above")),
      );
      return;
    }
    try {
      await FirebaseFirestore.instance.collection("StoredItem").add({
        "userUID": widget.loggedInUser, // ← link item to user
        "itemName": itemNameController.text.trim(),
        "itemQuantity": int.tryParse(itemQuantityController.text.trim()) ?? 0,
        "itemCategory": itemCategoryController.text.trim(),
        "itemExpiryDate": itemExpirationDateController.text.trim(),
        "itemPrice": int.tryParse(itemPriceController.text.trim()) ?? 0,
        "itemUnit": quantityUnit,
      });
      // Add notification
      await FirebaseFirestore.instance.collection("Notifications").add({
        "userUID": widget.loggedInUser,
        "type": "add_item",
        "message": "Added ${itemNameController.text.trim()} to your fridge",
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Added ${itemNameController.text.trim()} to fridge!")),
    );
    } on FirebaseException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Failed to add item")),
      );
    }
  }

  Future updateItem() async {
    try {
      await FirebaseFirestore.instance
          .collection("StoredItem")
          .doc(widget.docId)
          .update({
            "itemName": itemNameController.text.trim(),
            "itemQuantity":
                int.tryParse(itemQuantityController.text.trim()) ?? 0,
            "itemCategory": itemCategoryController.text.trim(),
            "itemExpiryDate": itemExpirationDateController.text.trim(),
            "itemPrice": int.tryParse(itemPriceController.text.trim()) ?? 0,
            "itemUnit": quantityUnit,
          });
      // Add notification
      await FirebaseFirestore.instance.collection("Notifications").add({
        "userUID": widget.loggedInUser,
        "type": "edit_item",
        "message": "Updated ${itemNameController.text.trim()} in your fridge",
        "createdAt": FieldValue.serverTimestamp(),
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Item updated successfully!")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to update item")));
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(), // default date shown
      firstDate: DateTime(1900), // earliest selectable
      lastDate: DateTime(2100), // latest selectable
    );

    if (picked != null) {
      setState(() {
        itemExpirationDateController.text =
            "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  @override
  void initState() {
    super.initState();

    if (widget.isEdit && widget.existingItem != null) {
      itemNameController.text = widget.existingItem!["itemName"] ?? "";
      itemCategoryController.text = widget.existingItem!["itemCategory"] ?? "";
      itemQuantityController.text = widget.existingItem!["itemQuantity"]
          .toString();
      itemExpirationDateController.text =
          widget.existingItem!["itemExpiryDate"] ?? "";
      itemPriceController.text = widget.existingItem!["itemPrice"].toString();
      selectedCategory = widget.existingItem!["itemCategory"] ?? "";
      quantityUnit = categoryUnits[selectedCategory] ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            widget.isEdit
                ? "Edit item in fridge"
                : "Insert new Items into Fridge",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo.shade800),
          ),
          SizedBox(height: 15),
          SizedBox(
            height: 40,
            child: TextField(
              controller: itemNameController,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.label_important_outline, size: 20),
                hintText: 'Enter Item Name',
                hintStyle: TextStyle(fontSize: 14),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(height: 5),
          Row(
            children: [
              SizedBox(
                height: 40,
                width: MediaQuery.of(context).size.width * 0.40,
                child: DropdownButtonFormField<String>(
                  value: selectedCategory,
                  isExpanded: true,
                  hint: Center(child: Text('Category', style: TextStyle(fontSize: 14))),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  items: categoryUnits.keys.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Center(child: Text(category, style: TextStyle(fontSize: 14))),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value;
                      itemCategoryController.text = value ?? '';
                      quantityUnit = categoryUnits[value] ?? '';
                    });
                  },
                ),
              ),
              SizedBox(width: 5),
              SizedBox(
                height: 40,
                width: MediaQuery.of(context).size.width * 0.37,
                child: TextField(
                  controller: itemQuantityController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.production_quantity_limits,
                      size: 20,
                    ),
                    hintText: 'Quantity',
                    hintStyle: TextStyle(fontSize: 14),
                    suffixText: quantityUnit, 
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                height: 40,
                width: MediaQuery.of(context).size.width * 0.40,
                child: TextField(
                  controller: itemExpirationDateController,
                  readOnly: true,
                  onTap: () => _selectDate(),
                  decoration: InputDecoration(
                    suffixIcon: Icon(Icons.calendar_today),
                    hintText: 'Expire Date',
                    hintStyle: TextStyle(fontSize: 14),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 5),
              SizedBox(
                height: 40,
                width: MediaQuery.of(context).size.width * 0.37,
                child: TextField(
                  controller: itemPriceController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.currency_bitcoin_outlined),
                    hintText: 'Price',
                    hintStyle: TextStyle(fontSize: 14),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          SizedBox(
            height: 50,
            width: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 100,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (widget.isEdit) {
                        await updateItem();
                      } else {
                        await addItem();
                      }
                      widget.onClose();
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 5,
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      widget.isEdit ? "Edit" : "Add",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: ElevatedButton(
                    onPressed: widget.onClose,
                    style: ElevatedButton.styleFrom(
                      elevation: 5,
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      "Cancel",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
