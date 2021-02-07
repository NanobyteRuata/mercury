import 'package:flutter/material.dart';
import 'package:mercury/screens/home_screen.dart';
import 'package:mercury/services/base_db_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isLoading = true;

  @override
  void initState() {
    _init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mercury',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: isLoading
          ? Scaffold(
              body: Container(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            )
          : HomeScreen(),
    );
  }

  _init() async {
    await BaseDbService.initDB();
    setState(() => isLoading = false);
  }

  @override
  void dispose() {
    BaseDbService.closeDB();
    super.dispose();
  }
}
