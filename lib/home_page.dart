import 'package:flutter/material.dart';

class home_page extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Food Waste App'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                // Navigate to Add Food Item screen
                Navigator.pushNamed(context, '/add_food_item');
              },
              child: Text('Add Food Item'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to Scan Expiry Date screen
                Navigator.pushNamed(context, '/scan_expiry_date');
              },
              child: Text('Scan Expiry Date'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to Scan Barcode screen
                Navigator.pushNamed(context, '/scan_barcode');
              },
              child: Text('Scan Barcode'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to Local Food Banks screen
                Navigator.pushNamed(context, '/local_food_banks');
              },
              child: Text('Local Food Banks'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to Informative Tips screen
                Navigator.pushNamed(context, '/informative_tips');
              },
              child: Text('Informative Tips'),
            ),
          ],
        ),
      ),
    );
  }
}
