import 'package:flutter/material.dart';

class RecipeList extends StatelessWidget {
  final Map<String, dynamic> recipe;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback onSave;
  final bool isSaved; 
  final bool savedView;  

  const RecipeList({
    super.key,
    required this.recipe,
    required this.isExpanded,
    required this.onTap,
    required this.onSave,
    required this.isSaved,
    this.savedView = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 6),
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: savedView ? Colors.green.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: savedView ? Colors.green.shade200 : Colors.indigo.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    recipe["title"],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.indigo.shade800,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onSave,
                  child: Icon(
                    isSaved ? Icons.bookmark_added : Icons.bookmark_border,
                    size: 18,
                    color: Colors.indigo.shade800,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              "Uses ${recipe["usedCount"]} ingredients · Missing ${recipe["missedCount"]}",
              style: TextStyle(fontSize: 11, color: Colors.indigo.shade600),
            ),
            if (isExpanded) ...[
              SizedBox(height: 8),
              Divider(color: Colors.indigo.shade100),
              Row(
                children: [
                  Icon(Icons.timer, size: 14, color: Colors.indigo.shade800),
                  SizedBox(width: 4),
                  Text(
                    "${recipe["readyInMinutes"]} mins",
                    style: TextStyle(fontSize: 11, color: Colors.indigo.shade600),
                  ),
                  SizedBox(width: 12),
                  Icon(Icons.people, size: 14, color: Colors.indigo.shade800),
                  SizedBox(width: 4),
                  Text(
                    "${recipe["servings"]} servings",
                    style: TextStyle(fontSize: 11, color: Colors.indigo.shade600),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                "Instructions",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.indigo.shade800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                recipe["instructions"],
                style: TextStyle(fontSize: 11, color: Colors.indigo.shade300),
              ),
            ],
          ],
        ),
      ),
    );
  }
}