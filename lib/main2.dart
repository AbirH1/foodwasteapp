import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

final initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

final initializationSettingsIOS = IOSInitializationSettings(
  requestAlertPermission: false,
  requestBadgePermission: false,
  requestSoundPermission: false,
  onDidReceiveLocalNotification:
      (int id, String? title, String? body, String? payload) async {},
);

IOSInitializationSettings(
    {required bool requestAlertPermission,
    required bool requestBadgePermission,
    required bool requestSoundPermission,
    required Future<Null> Function(
            int id, String? title, String? body, String? payload)
        onDidReceiveLocalNotification}) {}

final initializationSettings = InitializationSettings(
  android: initializationSettingsAndroid,
  iOS: initializationSettingsIOS,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  await Firebase.initializeApp();
  runApp(
    ChangeNotifierProvider(
      create: (context) => FoodItemProvider(),
      child: MyApp(),
    ),
  );
}

Future<void> scheduleNotification(
    FoodItem item, Duration preExpiryPeriod) async {
  if (item.expiryDate != null) {
    var scheduledNotificationDateTime =
        item.expiryDate!.subtract(preExpiryPeriod);

    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'your channel id', 'your channel name',
        importance: Importance.max, priority: Priority.high, showWhen: false);

    var iOSPlatformChannelSpecifics = IOSNotificationDetails();

    var platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.zonedSchedule(
        item.hashCode,
        'Expiry Reminder',
        '${item.name} is expiring soon!',
        tz.TZDateTime.from(scheduledNotificationDateTime, tz.local),
        platformChannelSpecifics,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime);
  }
}

IOSNotificationDetails() {}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Waste App',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.lightBlue[800],
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      routes: {
        '/': (context) => HomePage(),
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
      },
      initialRoute: '/',
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white60,
        shadowColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
        ),
        title: Text('Food Waste App'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddFoodItemScreen()),
                );
              },
              child: Text('Add Food Item'),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                // Scan expiry date
                DateTime? expiryDate = await scanExpiryDate();
                print('Scanned expiry date: $expiryDate');
              },
              child: Text('Scan Expiry Date'),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                // Scan barcode
                String barcode = await scanBarcode();
                print('Scanned barcode: $barcode');
              },
              child: Text('Scan Barcode'),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LocalFoodBanksPage()),
                );
              },
              child: Text('Local Food Banks'),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => InformativeTipsPage()),
                );
              },
              child: Text('Informative Tips'),
            ),
          ],
        ),
      ),
    );
  }
}

class AddFoodItemScreen extends StatefulWidget {
  @override
  _AddFoodItemScreenState createState() => _AddFoodItemScreenState();
}

class _AddFoodItemScreenState extends State<AddFoodItemScreen> {
  String? selectedCategory;
  String name = '';
  double quantity = 0.0;
  DateTime? expiryDate;
  DateTime? scannedDate;

  final List<String> categories = ['Fruit', 'Vegetable', 'Dairy', 'Meat'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Food Item'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedCategory,
              onChanged: (value) {
                setState(() {
                  selectedCategory = value;
                });
              },
              items: categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              decoration: InputDecoration(
                labelText: 'Category',
              ),
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Name'),
              onChanged: (value) {
                setState(() {
                  name = value;
                });
              },
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Quantity'),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  quantity = double.tryParse(value) ?? 0.0;
                });
              },
            ),
            ElevatedButton(
              onPressed: () async {
                // Scan expiry date
                DateTime? date = await scanExpiryDate();
                setState(() {
                  expiryDate = date;
                });
              },
              child: Text('Scan Expiry Date'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Add food item
                FoodItem foodItem = FoodItem(
                  category: selectedCategory!,
                  name: name,
                  quantity: quantity,
                  expiryDate: expiryDate,
                );

                await Provider.of<FoodItemProvider>(context, listen: false)
                    .addFoodItem(foodItem);
                Navigator.pop(context);
              },
              child: Text('Add Food Item'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<String> scanBarcode() async {
  try {
    var result = await BarcodeScanner.scan();
    return result.rawContent ?? 'Scan failed';
  } on PlatformException catch (e) {
    if (e.code == BarcodeScanner.cameraAccessDenied) {
      return 'The user did not grant the camera permission!';
    } else {
      return 'Unknown error: $e';
    }
  } on FormatException {
    return 'null (User returned using the "back"-button before scanning anything. Result)';
  } catch (e) {
    return 'Unknown error: $e';
  }
}

Future<DateTime?> scanExpiryDate() async {
  // Dummy implementation, replace with actual barcode date extraction logic
  return DateTime.now().add(Duration(days: 7));
}

class LocalFoodBanksPage extends StatefulWidget {
  @override
  _LocalFoodBanksPageState createState() => _LocalFoodBanksPageState();
}

class _LocalFoodBanksPageState extends State<LocalFoodBanksPage> {
  List<Map<String, dynamic>> foodBanks = [];

  @override
  void initState() {
    super.initState();
    fetchFoodBanks();
  }

  Future<void> fetchFoodBanks() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    // Use your actual API key for Google Maps Geocoding API
    final apiKey =
        "https://maps.googleapis.com/maps/api/js?key=YOUR_API_KEY&callback=initMap";
    final url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${position.latitude},${position.longitude}&radius=5000&type=food_bank&key=$apiKey';

    var http;
    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    setState(() {
      foodBanks = (data['results'] as List)
          .map((result) => {
                'name': result['name'],
                'address': result['vicinity'],
              })
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Local Food Banks'),
      ),
      body: ListView.builder(
        itemCount: foodBanks.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(foodBanks[index]['name']),
            subtitle: Text(foodBanks[index]['address']),
          );
        },
      ),
    );
  }
}

class InformativeTipsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Informative Tips'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Tip 1: Store food properly to extend its shelf life.'),
            Text('Tip 2: Plan your meals to avoid buying excess food.'),
            Text('Tip 3: Donate unused food to local food banks.'),
          ],
        ),
      ),
    );
  }
}

class FoodItem {
  final String category;
  final String name;
  final double quantity;
  final DateTime? expiryDate;

  FoodItem({
    required this.category,
    required this.name,
    required this.quantity,
    this.expiryDate,
  });
}

class FoodItemProvider extends ChangeNotifier {
  final List<FoodItem> _foodItems = [];

  List<FoodItem> get foodItems => _foodItems;

  Future<void> addFoodItem(FoodItem foodItem) async {
    _foodItems.add(foodItem);
    notifyListeners();
    if (foodItem.expiryDate != null) {
      await scheduleNotification(foodItem, Duration(days: 1));
    }
    FirebaseFirestore.instance.collection('foodItems').add({
      'category': foodItem.category,
      'name': foodItem.name,
      'quantity': foodItem.quantity,
      'expiryDate': foodItem.expiryDate?.millisecondsSinceEpoch,
    });
  }
}
