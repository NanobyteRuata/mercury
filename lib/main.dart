import 'package:flutter/material.dart';
// import 'package:mercury/models/contact.dart';
import 'package:mercury/screens/message_list_screen.dart';
// import 'package:sqflite/sqflite.dart';
// import 'package:path/path.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Database db;
  // Future<Database> database;
  // bool isLoading = true;
  // bool found = false;

  // Future<List<Contact>> contacts() async {
  //   // Get a reference to the database.
  //   db = await database;

  //   // Query the table for all The Contacts.
  //   final List<Map<String, dynamic>> maps = await db.query('contacts');

  //   // Convert the List<Map<String, dynamic> into a List<Contacts>.
  //   return List.generate(maps.length, (i) {
  //     return Contact(
  //         name: maps[i]['name'],
  //         address: maps[i]['address'],
  //         key: maps[i]['key']);
  //   });
  // }

  // void initialize() async {
  //   database = openDatabase(
  //     join(await getDatabasesPath(), 'mercury.db'),
  //     onCreate: (db, version) {
  //       return db.execute(
  //           "CREATE TABLE contacts(id TEXT, name Text, address Text, key Text)");
  //     },
  //     version: 1,
  //   );
  //   contacts().then((value) {
  //     setState(() {
  //       isLoading = false;
  //       if (value.length == 0) {
  //         found = false;
  //       } else {
  //         found = true;
  //         print(value);
  //       }
  //     });
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mercury',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MessageListScreen(),
    );
  }
}
