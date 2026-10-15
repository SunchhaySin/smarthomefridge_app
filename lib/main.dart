import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:smarthomefridge/pages/loadingPage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform,);
  await dotenv.load(fileName: "env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      builder: (context, child) {

        // Constrain the width and height of the app when opened on bigger screens (web)
        if(kIsWeb) {
          return MobileFrameWrapper(child: child ?? const SizedBox());
        }
        return child ?? const SizedBox();
      },
      home: LoadingPage()
    );
  }
}

class MobileFrameWrapper extends StatelessWidget {
  final Widget child;
  const MobileFrameWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E), 
      body: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isSmallScreen = constraints.maxWidth < 400;

            if (isSmallScreen) {
              return child;
            }

            return Container(
              constraints: const BoxConstraints(
                maxWidth: 400, 
                maxHeight: 850, 
              ),
              decoration: BoxDecoration(
                color: Colors.black,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade800, width: 4),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: child, 
              ),
            );
          },
        ),
      ),
    );
  }
}