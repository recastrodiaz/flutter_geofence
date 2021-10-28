import 'dart:math';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_geofence/geofence.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      new FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    initPlatformState();

// initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
    var initializationSettingsAndroid =
        new AndroidInitializationSettings('app_icon');
    var initializationSettingsIOS =
        IOSInitializationSettings(onDidReceiveLocalNotification: null);
    var initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: null);
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
    Geofence.initialize();
    Geofence.startListening(GeolocationEvent.entry, (entry) {
      scheduleNotification("Entry of a georegion", "Welcome to: ${entry.id}");
    });

    Geofence.startListening(GeolocationEvent.exit, (entry) {
      scheduleNotification("Exit of a georegion", "Byebye to: ${entry.id}");
    });

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: ListView(
          children: <Widget>[
            Text('Running on: $_platformVersion\n'),
            RaisedButton(
              child: Text("Add region"),
              onPressed: () {
                Geolocation location = Geolocation(
                    latitude: 53.337752,
                    longitude: -6.258879,
                    radius: 50.0,
                    id: "Dublin1 - Park");
                Geofence.addGeolocation(location, GeolocationEvent.entry)
                    .then((onValue) {
                  print("great success");
                  scheduleNotification(
                      "Georegion added", "Your geofence has been added!");
                }).catchError((onError) {
                  print("great failure");
                });
              },
            ),
            RaisedButton(
              child: Text("Add neighbour region"),
              onPressed: () {
                Geolocation location = Geolocation(
                    latitude: 53.3402202,
                    longitude: -6.2720896,
                    radius: 50.0,
                    id: "Dublin2 - Cathedral");
                Geofence.addGeolocation(location, GeolocationEvent.entry)
                    .then((onValue) {
                  print("great success");
                  scheduleNotification(
                      "Georegion added", "Your geofence has been added!");
                }).catchError((onError) {
                  print("great failure");
                });
              },
            ),
            RaisedButton(
              child: Text("Remove regions"),
              onPressed: () {
                Geofence.removeAllGeolocations();
              },
            ),
            RaisedButton(
              child: Text("Request Permissions"),
              onPressed: () {
                Geofence.requestPermissions();
              },
            ),
            RaisedButton(
              child: Text("Request Notifications Permissions"),
              onPressed: () {
                flutterLocalNotificationsPlugin
                    .resolvePlatformSpecificImplementation<
                        IOSFlutterLocalNotificationsPlugin>()
                    ?.requestPermissions(
                      alert: true,
                      badge: true,
                      sound: true,
                    );
              },
            ),
            RaisedButton(
              child: Text("Trigger Notification"),
              onPressed: () {
                scheduleNotification(
                    "This is a test notifications", "Test body");
              },
            ),
            RaisedButton(
                child: Text("get user location"),
                onPressed: () {
                  Geofence.getCurrentLocation().then((coordinate) {
                    print(
                        "great got latitude: ${coordinate?.latitude} and longitude: ${coordinate?.longitude}");
                  });
                }),
            RaisedButton(
                child: Text("Listen to background updates"),
                onPressed: () {
                  Geofence.startListeningForLocationChanges();
                  Geofence.backgroundLocationUpdated.stream.listen((event) {
                    scheduleNotification("You moved significantly",
                        "a significant location change just happened.");
                  });
                }),
            RaisedButton(
                child: Text("Stop listening to background updates"),
                onPressed: () {
                  Geofence.stopListeningForLocationChanges();
                }),
          ],
        ),
      ),
    );
  }

  void scheduleNotification(String title, String subtitle) {
    print("scheduling one with $title and $subtitle");
    var rng = new Random();
    Future.delayed(Duration(seconds: 1)).then((result) async {
      var androidPlatformChannelSpecifics = AndroidNotificationDetails(
          'your channel id', 'your channel name',
          channelDescription: 'your channel description',
          importance: Importance.high,
          priority: Priority.high,
          ticker: 'ticker');
      var iOSPlatformChannelSpecifics = IOSNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      var platformChannelSpecifics = NotificationDetails(
          android: androidPlatformChannelSpecifics,
          iOS: iOSPlatformChannelSpecifics);
      await flutterLocalNotificationsPlugin.show(
        rng.nextInt(100000),
        title,
        subtitle,
        platformChannelSpecifics,
        payload: 'item x',
      );
    });
  }
}
