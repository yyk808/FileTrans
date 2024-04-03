import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class SavedFiles {
  static late final Database savedFiles;
  static bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    savedFiles = await openDatabase(
      join(await getDatabasesPath(), 'saved_files.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE saved_files(id INTEGER PRIMARY KEY, name TEXT, path TEXT)',
        );
      },
      version: 1,
    );
    _initialized = true;
  }

  Future<void> insertFile(String name, String path) async {
    await savedFiles.insert(
      'saved_files',
      {
        'name': name,
        'path': path,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<FileMeta>> getFiles() async {
    final files = await savedFiles.query('saved_files');
    return List.generate(files.length, (i) {
      return FileMeta(
        id: files[i]['id'] as int,
        name: files[i]['name'] as String,
        path: files[i]['path'] as String,
      );
    });
  }

  Future<void> deleteFile(int id) async {
    await savedFiles.delete(
      'saved_files',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateFile(int id, String name, String path) async {
    await savedFiles.update(
      'saved_files',
      {
        'name': name,
        'path': path,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    await savedFiles.close();
    _initialized = false;
  }
}

class FileMeta {
  final int id;
  final String path;
  final String name;

  FileMeta({required this.id, required this.path, required this.name});
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'path': path,
      'name': name,
    };
  }
  @override
  String toString() {
    return "FileTile{id: $id, path: $path, name: $name}";
  }
}