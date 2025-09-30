import 'package:flutter/material.dart';

class ShoppingListScreen extends StatelessWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping List'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.sync),
              label: const Text('Generate from Current Week\'s Plan'),
              onPressed: () {
                // TODO: Connect to Cubit to generate list
              },
            ),
          ),
          const Expanded(
            child: Center(
              child: Text('Generate a list to see your items.'),
            ),
          ),
        ],
      ),
    );
  }
}