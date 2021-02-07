import 'dart:async';

import 'package:sqflite/sqflite.dart';

class BaseDbService {
  static Database database;

  static Future<bool> initDB() async {
    try {
      // open the database
      database = await openDatabase('mercury.db', version: 1,
          onCreate: (Database db, int version) async {
        // When creating the db, create the table
        await db.execute(
            'CREATE TABLE Contacts (id INTEGER PRIMARY KEY, name TEXT, address TEXT, key TEXT, isGroup INTEGER)');
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  static void closeDB() {
    database.close();
  }
}
