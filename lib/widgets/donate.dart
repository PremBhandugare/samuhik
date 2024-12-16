 import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

void showDonationDialog(BuildContext context, Map<String, dynamic> data) {
    final _formKey = GlobalKey<FormState>();
    String _name = '';
    int _amount = 0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Make a Donation'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: InputDecoration(labelText: 'Your Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _name = value!;
                  },
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Amount'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _amount = int.parse(value!);
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Donate'),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  processDonation(context, data, _name, _amount);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void processDonation(BuildContext context, Map<String, dynamic> data, String name, int amount) async {
    try {
      await FirebaseFirestore.instance.collection('donationRequests').doc(data['id']).update({
        'initial': FieldValue.increment(amount),
        'donors': FieldValue.arrayUnion([
          {
            'name': name,
            'money': amount,
          }
        ]),
      });

      Navigator.of(context).pop(); // Close the dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Thank you for your donation!')),
      );
    } catch (e) {
      print('Error processing donation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing donation. Please try again.')),
      );
    }
  }