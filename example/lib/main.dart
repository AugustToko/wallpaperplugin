import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:wallpaperplugin/wallpaperplugin.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _wallpaperStatus = "Initial";

  String _wallpaperImageUrl = "https://images.pexels.com/photos/2170473/pexels-photo-2170473.jpeg?auto=compress&cs=tinysrgb&dpr=2&h=650&w=940";

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String wallpaperStatus = "Unexpected Result";
    if(_checkAndGetPermission()!=null) {
      String _localFile = await _downloadFileUsingDio(
          _wallpaperImageUrl,
          "test_wallpaper");
      // Platform messages may fail, so we use a try/catch PlatformException.
      try {
        Wallpaperplugin.setWallpaperWithCrop(localFile: _localFile);
        wallpaperStatus = "new Wallpaper set";
      } on PlatformException {
        print("Platform exception");
        wallpaperStatus = "Platform Error Occured";
      }
    }
    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
    setState(() {
      _wallpaperStatus = wallpaperStatus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Wallpaper Plugin example app'),
        ),
        body: Center(
          child: Text('Wallpaper Status: $_wallpaperStatus\n'),
        ),
      ),
    );
  }
///This code helps in downloading a jpeg to local folder
  Future<String> _downloadFileUsingDio(String url, String _photoId) async {
    Dio dio = Dio();
    String dir = await _localPath;
    var localFile = '$dir/$_photoId.jpeg';
    File file = new File(localFile);
    if (!file.existsSync()) {
      try {
        await dio.download(url, localFile, onReceiveProgress: (received, total) {
          if (total != -1) {
            print("Photo downloading : " +
                (received / total * 100).toStringAsFixed(0) +
                "%");
          }
        });
        return localFile;
      } on PlatformException catch (error) {
        print(error);
      }
    }
    return localFile;
  }
  ///returns the local path + /wallpapers, this is where the image file is downloaded.
  Future<String> get _localPath async {
    Directory appDocDirectory = await getExternalStorageDirectory();
    Directory directory =
    await new Directory(appDocDirectory.path + '/wallpapers')
        .create(recursive: true);
    // The created directory is returned as a Future.
    return directory.path;
  }


  /// This method checks for permission and if not given will request the user for the same.
  /// It will return true if permission is given, or else will return null
  static _checkAndGetPermission() async{
    PermissionStatus permission =
    await PermissionHandler().checkPermissionStatus(PermissionGroup.storage);
    if (permission != PermissionStatus.granted) {
      Map<PermissionGroup, PermissionStatus> permissions =
      await PermissionHandler().requestPermissions([PermissionGroup.storage]);
      if(permissions[PermissionGroup.storage] != PermissionStatus.granted){
        return null;
      }
    }
    return true;
  }
}
