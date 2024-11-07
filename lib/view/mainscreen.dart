import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:notificationproject/main.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
Position? _currentPosition;
Timer? _locationTimer;
ValueNotifier<List<Position>> locationUpdate = ValueNotifier<List<Position>>([]);


class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}


class _MainScreenState extends State<MainScreen> {
  List<Map<String, dynamic>> nameColorMap = [
    {
      'name': 'Request Location Permission',
      'color': Colors.blue,
      'pressed': (BuildContext context) => requestLocationPermission(context),
    },
    {
      'name': 'Request Notification Permission',
      'color': Colors.yellow,
      'pressed': (BuildContext context) => requestNotificationPermission(context),
    },
    {
      'name': 'Start Location Update',
      'color': Colors.green,
      'pressed': (BuildContext context) => _showConfirmationDialog(context),
    },
    {
      'name': 'Stop Location Update',
      'color': Colors.red,
      'pressed': (BuildContext context) => _stopLocationUpdates(context),
    },
  ];




  @override
  void initState() {
    super.initState();
    recordsSaved();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;


    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Test App",
          style: TextStyle(
            color: Colors.white, // Set the text color to white
          ),
        ),
        backgroundColor: Colors.black54,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 600) {
            return ValueListenableBuilder<List<Position>>(

                valueListenable: locationUpdate,
                builder: (context, value, child)
                {
                  return SingleChildScrollView(child: Column(
                    children: [
                      // Constrain the height of the ListView.builder
                      Container(
                        color: Colors.black54,
                        height: screenHeight * 0.37, // Set a specific height or use Expanded
                        child: ListView.builder(
                          itemCount: nameColorMap.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: EdgeInsets.all(6.0),
                              child: SizedBox(
                                width: MediaQuery
                                    .of(context)
                                    .size
                                    .width / 2 - 12,
                                height: screenHeight * 0.07,
                                child: ElevatedButton(
                                  onPressed: () {
                                    nameColorMap[index]['pressed'](context);
                                  },
                                  child: Text("${nameColorMap[index]['name']}"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: nameColorMap[index]['color'],
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),


                      // Use the spread operator to add each item from currentPositionLat
                      // Display a loading or error message if the length of `value` is <= 1
                      if (value.length < 1)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            "Fetching location data, please wait...",
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        )
                      else
                        Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Wrap(
                                spacing: 2.0, // Space between items horizontally
                                runSpacing: 5.0, // Space between lines vertically
                                children: [ ...value.asMap().entries.map((entry) =>Container(
                                    width: (MediaQuery.of(context).size.width / 2) - 24,child: Column(
                                  children: [
                                    Text('Record ${entry.key + 1}'),
                                    Text('Lat : ${entry.value.latitude}'),
                                    Text('Long : ${entry.value.longitude}'),
                                    Text('Speed : ${entry.value.speed.toStringAsFixed(2)} m/s'),
                                    SizedBox(height: 20),
                                  ],
                                ))).toList(),

                                ]))
                    ],
                  ));
                });

          } else {
            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 2.0,
                mainAxisSpacing: 3.0,
              ),
              itemCount: nameColorMap.length,
              itemBuilder: (context, index) {
                return Column(children: [Padding(
                  padding: EdgeInsets.all(6.0),
                  child: SizedBox(
                    width: screenWidth * 0.4,
                    height: screenHeight * 0.1,
                    child: ElevatedButton(
                      onPressed: () {
                        nameColorMap[index]['pressed'](context); // Invoke the function with context
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: nameColorMap[index]['color'],
                        foregroundColor: Colors.white,
                      ),
                      child: Text("${nameColorMap[index]['name']}"),
                    ),
                  ),
                )]);
              },
            );
          }
        },
      ),
    );
  }
  static _showConfirmationDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Start Location Update"),
          content: Text("Do you want to start location updates?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("NO"),
            ),
            TextButton(
              onPressed: () async{
                Navigator.of(context).pop();
                await _startLocationUpdates();

              },
              child: Text("YES"),
            ),
          ],
        );
      },
    );
  }


  static requestLocationPermission(BuildContext context) async {
    PermissionStatus status = await Permission.location.request();


    if (status.isGranted) {
      print("Location permission granted.");
    } else if (status.isDenied) {
      print("Location permission denied.");
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }


  static _showNotification(String message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails('your_channel_id', 'your_channel_name',
        importance: Importance.max, priority: Priority.high);
    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      message,
      null,
      platformChannelSpecifics,
    );
  }


  static requestNotificationPermission(BuildContext context) async {
    final status = await Permission.notification.request();


    if (status.isGranted) {
      print("Notification permission granted.");
    } else if (status.isDenied) {
      print("Notification permission denied.");
    } else if (status.isPermanentlyDenied) {
      print("Notification permission permanently denied. Please enable it from settings.");
      openAppSettings();
    }
  }






  static _stopLocationUpdates(BuildContext context) async {
    _locationTimer?.cancel();
    await _showNotification("Location update stopped");
    _currentPosition = null;
  }

  static _startLocationUpdates() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final permissionStatus = await Permission.location.request();
    if (permissionStatus.isGranted) {
      await _showNotification("Location update started");
      print("Location permission granted");

      try {
        // Fetch first location
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        print("First position: ${position.latitude}, ${position.longitude}");

        _currentPosition = position;
        locationUpdate.value.add(position);
        await saveLocationData(locationUpdate.value);

        // Reassign `locationUpdate.value` to new list to notify listeners
        locationUpdate.value = [...locationUpdate.value];

        print('First location fetch completed: ${locationUpdate.value}');

        // Start periodic timer to fetch location every 30 seconds
        _locationTimer = Timer.periodic(Duration(seconds: 30), (_) async {
          try {
            position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
            );
            print("Timer location: ${position.latitude}, ${position.longitude}");

            _currentPosition = position;
            locationUpdate.value.add(position);
            await saveLocationData(locationUpdate.value);

            // Reassign `locationUpdate.value` to new list to notify listeners
            locationUpdate.value = [...locationUpdate.value];

            print('Location update triggered: ${locationUpdate.value}');
          } catch (e) {
            print("Error fetching location in timer: $e");
          }
        });
      } catch (e) {
        print("Error fetching first location: $e");
      }
    } else {
      print("Location permission denied.");
    }
  }

  static saveLocationData(List<Position> positions) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Convert List<Position> to  List<String>
    List<String> positionStrings = positions.map((position) {
      Map<String, dynamic> positionMap = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'speed': position.speed,
      };
      return jsonEncode(positionMap); // Convert map to JSON string
    }).toList();

    // Save List<String> in SharedPreferences
    await prefs.setStringList('locationData', positionStrings);
    print('Location data saved to SharedPreferences');
  }
  Future<List<Position>> loadLocationData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? positionStrings = prefs.getStringList('locationData');

    if (positionStrings != null) {
      // Convert List<String> to List<Position>
      return positionStrings.map((positionString) {
        Map<String, dynamic> positionMap = jsonDecode(positionString);
        return Position(
          latitude: positionMap['latitude'] ?? 0.0, // Default to 0.0 if null
          longitude: positionMap['longitude'] ?? 0.0, // Default to 0.0 if null
          timestamp: DateTime.tryParse(positionMap['timestamp'] ?? '') ?? DateTime.now(), // Default to current time if null
          accuracy: positionMap['accuracy'] ?? 0.0, // Default to 0.0 if null
          altitude: positionMap['altitude'] ?? 0.0, // Default to 0.0 if null
          altitudeAccuracy: positionMap['altitudeAccuracy'] ?? 0.0, // Default to 0.0 if null
          heading: positionMap['heading'] ?? 0.0, // Default to 0.0 if null
          headingAccuracy: positionMap['headingAccuracy'] ?? 0.0, // Default to 0.0 if null
          speed: positionMap['speed'] ?? 0.0, // Default to 0.0 if null
          speedAccuracy: positionMap['speedAccuracy'] ?? 0.0, // Default to 0.0 if null
          floor: positionMap['floor'], // Optional, can be null
          isMocked: positionMap['isMocked'] ?? false,
        );
      }).toList();

    } else {
      return []; // Return an empty list
    }
  }


// is first created
  recordsSaved()async{
    locationUpdate.value= await loadLocationData();
    locationUpdate.value = [...locationUpdate.value];
    return locationUpdate.value;

  }

}
