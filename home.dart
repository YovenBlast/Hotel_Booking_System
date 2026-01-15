import 'package:auth_firebase/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ProductPage(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: TextTheme(
          headline1: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue),
          bodyText1: TextStyle(fontSize: 18, color: Colors.black),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.blue),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.blue),
          ),
          labelStyle: TextStyle(fontSize: 22, color: Colors.blue),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white, backgroundColor: Colors.blue,
            textStyle: TextStyle(fontSize: 20),
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }
}

class ProductPage extends StatefulWidget {
  @override
  _ProductPageState createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _priceController = TextEditingController();
  TextEditingController _roomNumberController = TextEditingController();
  String? _selectedProductId;

  String? _selectedRoomCategory;

  final List<String> _roomCategories = [
    'Classic Room',
    'Family Room',
    'Family Suite',
    'VIP Suite',
  ];

  @override
  void initState() {
    super.initState();
  }

  Future<void> _addProduct() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final roomNumber = _roomNumberController.text;

        final snapshot = await FirebaseFirestore.instance
            .collection('products')
            .where('room_number', isEqualTo: roomNumber)
            .get();

        if (snapshot.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Product with this room number already exists!')),
          );
          return;
        }

        try {
          await FirebaseFirestore.instance.collection('products').add({
            'room_category': _selectedRoomCategory,
            'description': _descriptionController.text,
            'price': double.parse(_priceController.text),
            'room_number': _roomNumberController.text,
            'user_id': user.uid,
          });
          _clearForm();
        } catch (e) {
          print('Error inserting product: $e');
        }
      }
    }
  }

  Future<void> _updateProduct(String id) async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        await FirebaseFirestore.instance.collection('products').doc(id).update({
          'room_category': _selectedRoomCategory,
          'description': _descriptionController.text,
          'price': double.parse(_priceController.text),
          'room_number': _roomNumberController.text,
        });
        _clearForm();
      } catch (e) {
        print('Error updating product: $e');
      }
    }
  }

  Future<void> _deleteProduct(String id) async {
    try {
      await FirebaseFirestore.instance.collection('products').doc(id).delete();
      _clearForm();
    } catch (e) {
      print('Error deleting product: $e');
    }
  }

  void _showDeleteConfirmationDialog(String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this room?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Yes'),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteProduct(id);
              },
            ),
          ],
        );
      },
    );
  }

  void _clearForm() {
    setState(() {
      _formKey.currentState!.reset();
      _selectedRoomCategory = null;
      _descriptionController.clear();
      _priceController.clear();
      _roomNumberController.clear();
      _selectedProductId = null;
    });
  }

  Widget _logout(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xff0D6EFD),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        minimumSize: const Size(double.infinity, 60),
        elevation: 0,
      ),
      onPressed: () async {
        await AuthService().signout(context: context);
      },
      child: const Text("Sign Out"),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hotel Rooms CRUD', style: Theme.of(context).textTheme.headline1!),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedRoomCategory,
                    hint: Text('Select Room Category'),
                    onChanged: (value) {
                      setState(() {
                        _selectedRoomCategory = value;
                      });
                    },
                    items: _roomCategories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a room category';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _roomNumberController,
                    decoration: InputDecoration(
                      labelText: 'Room Number',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please enter a room number';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                    ),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _priceController,
                    decoration: InputDecoration(
                      labelText: 'Price',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please enter a price';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: _addProduct,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: Text('Add'),
                      ),
                      ElevatedButton(
                        onPressed: _selectedProductId != null ? () => _updateProduct(_selectedProductId!) : null,
                        child: Text('Update'),
                      ),
                      ElevatedButton(
                        onPressed: _selectedProductId != null ? () => _showDeleteConfirmationDialog(_selectedProductId!) : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedProductId != null ? Colors.red : Colors.grey,
                        ),
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('products').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final products = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 4,
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text(
                            product['room_category'] ?? 'No Category',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${product['description']} - Room Number: ${product['room_number']}',
                            style: TextStyle(fontSize: 16),
                          ),
                          trailing: Text(
                            '\$${product['price']}',
                            style: TextStyle(fontSize: 16, color: Colors.green),
                          ),
                          onTap: () {
                            setState(() {
                              _selectedProductId = product.id;
                              _selectedRoomCategory = product['room_category'];
                              _descriptionController.text = product['description'];
                              _priceController.text = product['price'].toString();
                              _roomNumberController.text = product['room_number'];
                            });
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            SizedBox(height: 16), // Add some spacing before the sign-out button
            _logout(context), // Add the sign-out button here
          ],
        ),
      ),
    );
  }
}
