import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({Key? key}) : super(key: key);

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late Future<ListResult> futureFiles;
  Map<int, double> downloadProgress = {};

  @override
  void initState() {
    super.initState();
    futureFiles = FirebaseStorage.instance.ref('/Registrar files').listAll();
  }

  @override
  Widget build(BuildContext context) {
    Permission.storage.request();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Information'),
      ),
      body: buildFileList(futureFiles),
    );
  }

  FutureBuilder<ListResult> buildFileList(Future<ListResult> futureFiles) {
    return FutureBuilder<ListResult>(
        future: futureFiles,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final files = snapshot.data!.items;

            return ListView.builder(
                scrollDirection: Axis.vertical,
                shrinkWrap: true,
                itemCount: files.length,
                itemBuilder: (context, index) {
                  //get specific file
                  final file = files[index];

                  double? progress = downloadProgress[index];

                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Card(
                      child: Column(
                        children: [
                          ListTile(
                            title: Text(file.name),
                            subtitle: progress != null
                                ? LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: Colors.black,
                                  )
                                : null,
                            trailing: IconButton(
                              onPressed: () => downloadFile(index, file),
                              icon: const Icon(Icons.download),
                            ),
                          ),
                          FutureBuilder<FullMetadata>(
                            future: file.getMetadata(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return Text(
                                    snapshot.data!.timeCreated.toString());
                              } else {
                                return Text('');
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                });
          } else if (snapshot.hasError) {
            return const Center(child: Text("An Error has occurred"));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        });
  }

  downloadFile(int index, Reference file) async {
    final url = await file.getDownloadURL();
    final path = '/storage/emulated/0/Download/${file.name}';
    await Dio().download(url, path, onReceiveProgress: (received, total) {
      double progress = received / total;
      setState(() {
        downloadProgress[index] = progress;
      });
    });

    if (url.contains('.mp4')) {
      await GallerySaver.saveVideo(path, toDcim: true);
    } else if (url.contains('.jpg')) {
      await GallerySaver.saveImage(path, toDcim: true);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Downloaded ${file.name}')),
    );
  }
}
