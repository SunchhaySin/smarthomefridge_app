import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Notificationpage extends StatefulWidget {
  final String? loggedInUser;
  const Notificationpage({super.key, required this.loggedInUser});

  @override
  State<Notificationpage> createState() => _NotificationpageState();
}

class _NotificationpageState extends State<Notificationpage> {
  Stream<List<Map<String, dynamic>>> getNotifications() {
    return FirebaseFirestore.instance
        .collection("Notifications")
        .where("userUID", isEqualTo: widget.loggedInUser)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                "docId": doc.id,
                "type": data["type"] ?? "",
                "message": data["message"] ?? "",
                "createdAt": data["createdAt"],
              };
            }).toList());
  }

  Future<void> clearAllNotifications() async {
    final snapshot = await FirebaseFirestore.instance
        .collection("Notifications")
        .where("userUID", isEqualTo: widget.loggedInUser)
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  IconData getNotificationIcon(String type) {
    switch (type) {
      case "add_item":
        return Icons.add_circle_outline;
      case "edit_item":
        return Icons.edit_outlined;
      case "delete_item":
        return Icons.delete_outline;
      case "save_recipe":
        return Icons.bookmark_outline;
      case "update_username":
        return Icons.person_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color getNotificationColor(String type) {
    switch (type) {
      case "add_item":
        return Colors.green.shade800;
      case "edit_item":
        return Colors.orange.shade800;
      case "delete_item":
        return Colors.red.shade800;
      case "save_recipe":
        return Colors.indigo.shade800;
      case "update_username":
        return Colors.blue.shade800;
      default:
        return Colors.grey.shade800;
    }
  }

  String formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return "";
    final dt = (timestamp as Timestamp).toDate();
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      body: Padding(
        padding: EdgeInsets.only(top: 60),
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Notifications",
                    style: TextStyle(
                      color: Colors.indigo.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.close,
                      color: Colors.indigo.shade800,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 15),

            // Notifications List
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: getNotifications(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_off_outlined,
                            size: 48,
                            color: Colors.indigo.shade200,
                          ),
                          SizedBox(height: 12),
                          Text(
                            "No notifications yet",
                            style: TextStyle(
                              color: Colors.indigo.shade300,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final notifications = snapshot.data!;
                  return ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notif = notifications[index];
                      final type = notif["type"] as String;
                      return Container(
                        margin: EdgeInsets.only(bottom: 10),
                        padding: EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: getNotificationColor(type)
                                    .withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                getNotificationIcon(type),
                                size: 18,
                                color: getNotificationColor(type),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    notif["message"],
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.indigo.shade800,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    formatTimestamp(notif["createdAt"]),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.indigo.shade400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Clear All Button
            Padding(
              padding: EdgeInsets.all(20),
              child: SizedBox(
                width: MediaQuery.sizeOf(context).width * 0.7,
                child: ElevatedButton(
                  onPressed: () async {
                    await clearAllNotifications();
                    if (!mounted) return;
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 10,
                    backgroundColor: Colors.indigo.shade800.withOpacity(0.7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(
                    "Clear all Notifications",
                    style: TextStyle(color: Colors.indigo.shade100),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}