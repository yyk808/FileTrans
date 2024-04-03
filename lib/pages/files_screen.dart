import 'package:file_trans_rework/common/saved_files.dart';
import 'package:flutter/material.dart';

class FileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final files = SavedFiles();
    files.initialize();

    return Scaffold(
      appBar: AppBar(
        title: const Text("History Files"),
      ),
      body: Padding(
        padding: const EdgeInsets.only(right: 10, left: 10),
        child: FutureBuilder(
          future: files.getFiles(),
          builder:
              (BuildContext context, AsyncSnapshot<List<FileMeta>> snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return ListView(
                  children: snapshot.data!.reversed.map((e) => FileTile(f: e)).toList());
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }
}

class FileTile extends StatelessWidget {
  const FileTile({super.key, required this.f});

  final FileMeta f;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(f.name),
      subtitle: Text(f.path),
      leading: const Icon(Icons.file_copy_rounded),
    );
  }
}
