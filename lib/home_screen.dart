import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';

import 'constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<ListResult> futureFiles;
  Map<int, double> downloadProgress = {};
  PlatformFile? pickedFile;
  UploadTask? uploadTask;

  Future selectFile() async {
    final result = await FilePicker.platform.pickFiles();

    setState(() {
      pickedFile = result?.files.first;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Selected: ${pickedFile!.name}')),
    );
  }

  Future uploadFile(String filename) async {
    final path = '/Registrar files/$filename';
    final file = File(pickedFile!.path!);

    final ref = FirebaseStorage.instance.ref().child(path);

    setState(() {
      uploadTask = ref.putFile(file);
    });

    final snapshot = await uploadTask!
        .whenComplete(() => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('${pickedFile!.name} uploaded successfully')),
            ));
  }

  @override
  void initState() {
    super.initState();
    futureFiles = FirebaseStorage.instance.ref('/Registrar files').listAll();
  }

//loading mechemer
  //
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    Permission.storage.request();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.logout),
              TextButton(
                onPressed: () => FirebaseAuth.instance.signOut(),
                child: const Text(
                  "Sign Out",
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              )
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Signed in as:    ${user.email!}"),
              const SizedBox(
                height: 4,
              ),
            ],
          ),
          Expanded(
              child: Column(
            children: [
              Card(
                child: ListTile(
                  leading: Text(Departments[0]),
                  onTap: () => Navigator.pushNamed(context, '/detailscreen'),
                ),
              ),
              if (pickedFile != null)
                ElevatedButton(
                  onPressed: () => uploadFile(pickedFile!.name),
                  child: const Text('Upload File'),
                ),
              buildProgress(),
            ],
          ))
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: selectFile,
        child: const Icon(Icons.add),
      ),
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

                  return ListTile(
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

  Widget buildProgress() => StreamBuilder<TaskSnapshot>(
        stream: uploadTask?.snapshotEvents,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final data = snapshot.data!;
            double progress = data.bytesTransferred / data.totalBytes;
            print('ss');
            return SizedBox(
              height: 50,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey,
                    color: Colors.green,
                  ), // LinearProgress Indicator
                  Center(
                    child: Text(
                      '${(100 * progress).roundToDouble()}%',
                      style: const TextStyle(color: Colors.white),
                    ), // Text
                  ), // Center
                ],
              ),
            );
          } else {
            print('xx');
            return const SizedBox(height: 50);
          }
        },
      ); // StreamBuilder
}
