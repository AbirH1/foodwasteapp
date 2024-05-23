import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'firebase_options.dart'; // Import the generated file

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  const firebaseConfig = FirebaseOptions(
    apiKey: "AIzaSyCXA0owapVZHufG_i4xWjY70aPK1dvFsTY",
    authDomain: "food-wasteapp.firebaseapp.com",
    projectId: "food-wasteapp",
    storageBucket: "food-wasteapp.appspot.com",
    messagingSenderId: "640878287658",
    appId: "1:640878287658:web:772f3f0addb268d6aa1c53",
  );

  await Firebase.initializeApp(options: firebaseConfig);

  // Initialize timezone data for local notifications
  tz.initializeTimeZones();

  // Initialize local notifications
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final initializationSettingsAndroid = AndroidInitializationSettings(
      '@mipmap/ic_launcher'); // Set your android icon here
  final initializationSettingsIOS = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
    onDidReceiveLocalNotification:
        (int id, String? title, String? body, String? payload) async {
      // Handle the received notification
    },
  );
  final initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(
    ChangeNotifierProvider(
      create: (context) => FoodItemProvider(),
      child: MyApp(),
    ),
  );
}

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
                DateTime? expiryDate = await scanExpiryDate();
                print('Scanned expiry date: $expiryDate');
              },
              child: Text('Scan Expiry Date'),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
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
                DateTime? date = await scanExpiryDate();
                setState(() {
                  expiryDate = date;
                });
              },
              child: Text('Scan Expiry Date'),
            ),
            ElevatedButton(
              onPressed: () async {
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
    return result.rawContent;
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

class LocalFoodBanksPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Local Food Banks'),
      ),
      body: Center(
        child: Column(
          children: [
            // Add your child widgets here
          ],
        ),
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
            Text(
              'Reduce Food Waste',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              '1. Plan your meals ahead of time.\n'
              '2. Store food correctly.\n'
              '3. Understand expiration dates.\n'
              '4. Use leftovers creatively.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Back'),
            ),
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

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'name': name,
      'quantity': quantity,
      'expiryDate': expiryDate?.millisecondsSinceEpoch,
    };
  }

  static FoodItem fromMap(Map<String, dynamic> map) {
    return FoodItem(
      category: map['category'],
      name: map['name'],
      quantity: map['quantity'],
      expiryDate: map['expiryDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['expiryDate'])
          : null,
    );
  }
}

class FoodItemProvider with ChangeNotifier {
  final CollectionReference collection =
      FirebaseFirestore.instance.collection('food_items');

  Future<void> addFoodItem(FoodItem item) {
    return collection.add(item.toMap());
  }

  Stream<List<FoodItem>> getFoodItems() {
    return collection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return FoodItem.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _login() async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      Navigator.pushReplacementNamed(context, '/');
    } catch (e) {
      print(e);
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              child: Text('Login'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/register');
              },
              child: Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _register() async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      Navigator.pushReplacementNamed(context, '/');
    } catch (e) {
      print(e);
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _register,
              child: Text('Register'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
