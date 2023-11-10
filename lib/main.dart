import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intinow/authentication/user_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _initialization,
        builder: (context, snapshot)
        {
          if(snapshot.connectionState == ConnectionState.waiting)
          {
            return const MaterialApp(
              home: Scaffold(
                body: Center(
                ),
              ),
            );
          }
          else if(snapshot.hasError)
          {
            return const MaterialApp(
              home: Scaffold(
                body: Center(
                  child: Text('An error has been occurred!',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'IntiNow',
            theme: ThemeData(
              primarySwatch: Colors.red,
            ),
            home: SplashScreen(),
          );
        }
    );
  }
}



class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 1), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => UserState()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset('assets/images/logo.png', width: 220, height: 140,),
      ),
    );
  }
}
