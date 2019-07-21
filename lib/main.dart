import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:launcher_assist/launcher_assist.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var installedApps;
  var wallpaper;
  bool accessStorage;

  @override
  initState() {
    accessStorage = false;
    super.initState();
    // Get all apps
    LauncherAssist.getAllApps().then((var apps) {
      setState(() {
        installedApps = apps;
      });
    });
    handleStoragePermissions().then((permissionGranted) {
      if (permissionGranted) {
        LauncherAssist.getWallpaper().then((imageData) {
          setState(() {
            wallpaper = imageData;
            accessStorage = !accessStorage;
          });
        });
      } else {
        print("inside of the else part ");
      }
    });
  }

  Future<bool> handleStoragePermissions() async {
    PermissionStatus storagePermissionStatus = await _getPermissionStatus();

    if (storagePermissionStatus == PermissionStatus.granted) {
      //which means that we have been given the permission to access device storage,
      return true;
    } else {
      _handleInvalidPermissions(storagePermissionStatus);
      return false;
    }
  }

  Future<PermissionStatus> _getPermissionStatus() async {
    print("inside get permission status");
    PermissionStatus permission = await PermissionHandler()
        .checkPermissionStatus(PermissionGroup.storage);
    if (permission != PermissionStatus.granted &&
        permission != PermissionStatus.disabled) {
      Map<PermissionGroup, PermissionStatus> permissionStatus =
          await PermissionHandler()
              .requestPermissions([PermissionGroup.storage]);
      return permissionStatus[PermissionGroup.storage] ??
          PermissionStatus.unknown;
    } else {
      print("already granted");
      return permission;
    }
  }

  void _handleInvalidPermissions(
    PermissionStatus storagePermissionStatus,
  ) {
    if (storagePermissionStatus == PermissionStatus.denied) {
      throw new PlatformException(
          code: "PERMISSION_DENIED",
          message: "Access to location data denied",
          details: null);
    } else if (storagePermissionStatus == PermissionStatus.disabled) {
      throw new PlatformException(
          code: "PERMISSION_DISABLED",
          message: "Location data is not available on device",
          details: null);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get wallpaper as binary data
    if (accessStorage) {
      setState(() {});
      print("set state called");
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.grey),
      home: Scaffold(
        body: WillPopScope(
          onWillPop: () => Future(() => false),
          child: Stack(
            children: <Widget>[
              WallpaperContainer(wallpaper: wallpaper),
              installedApps != null
                  ? ForegroundWidget(installedApps: installedApps)
                  : Container(),
              accessStorage
                  ? Container()
                  : Positioned(
                      top: 0,
                      left: 20,
                      child: SafeArea(
                        child: Tooltip(
                          message: "Click this to allow storage permission",
                          child: GestureDetector(
                            onTap: () {
                              handleStoragePermissions()
                                  .then((permissionGranted) {
                                if (permissionGranted) {
                                  LauncherAssist.getWallpaper()
                                      .then((imageData) {
                                    setState(() {
                                      wallpaper = imageData;
                                      accessStorage = !accessStorage;
                                    });
                                  });
                                } else {
                                }
                              });
                              setState(() {});
                            },
                            child: Icon(
                              Icons.storage,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class ForegroundWidget extends StatefulWidget {
  const ForegroundWidget({
    Key key,
    @required this.installedApps,
  }) : super(key: key);

  final installedApps;

  @override
  _ForegroundWidgetState createState() => _ForegroundWidgetState();
}

class _ForegroundWidgetState extends State<ForegroundWidget>
    with SingleTickerProviderStateMixin {
  AnimationController opacityController;
  Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    opacityController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
    );
    _opacity = Tween(begin: 0.0, end: 1.0).animate(opacityController);
  }

  @override
  Widget build(BuildContext context) {
    opacityController.forward();
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        padding: EdgeInsets.fromLTRB(30, 50, 30, 0),
        child: gridViewContainer(widget.installedApps),
      ),
    );
  }

  gridViewContainer(installedApps) {
    return GridView.count(
      crossAxisCount: 4,
      mainAxisSpacing: 40,
      physics: BouncingScrollPhysics(),
      children: List.generate(
        installedApps != null ? installedApps.length : 0,
        (index) {
          return GestureDetector(
            child: Container(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  iconContainer(index),
                  SizedBox(height: 10),
                  Text(
                    installedApps[index]["label"],
                    style: TextStyle(
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            onTap: () =>
                LauncherAssist.launchApp(installedApps[index]["package"]),
          );
        },
      ),
    );
  }


  iconContainer(index) {
    try {
      return Image.memory(
        widget.installedApps[index]["icon"] != null
            ? widget.installedApps[index]["icon"]
            : Uint8List(0),
        height: 50,
        width: 50,
      );
    } catch (e) {
      return Container();
    }
  }
}

class WallpaperContainer extends StatelessWidget {
  const WallpaperContainer({
    Key key,
    @required this.wallpaper,
  }) : super(key: key);

  final wallpaper;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: Image.memory(
        wallpaper != null ? wallpaper : Uint8List(0),
        fit: BoxFit.cover,
      ),
    );
  }
}
