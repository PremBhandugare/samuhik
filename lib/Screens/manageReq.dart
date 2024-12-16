import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:samuhik/Screens/dondetScr.dart';

class ManageDon extends StatefulWidget {
  const ManageDon({Key? key, required this.CurrUserID}) : super(key: key);
  final String CurrUserID;

  @override
  State<ManageDon> createState() => _ManageDonState();
}

class _ManageDonState extends State<ManageDon> {
  Future<void> _deleteRequest(String documentId, BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('donationRequests')
          .doc(documentId)
          .delete();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Request deleted successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting request: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmation(String documentId, BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Delete Request',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Are you sure you want to delete this donation request? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteRequest(documentId, context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('donationRequests')
            .where('userId', isEqualTo: widget.CurrUserID)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
              return _buildDonationCard(data, document.id, context);
            }).toList(),
          );
        },
      ),
    );
  }

 Widget _buildDonationCard(Map<String, dynamic> data, String documentId, BuildContext context) {
  double initialAmount = (data['initial'] ?? 0).toDouble();
  double totalAmount = (data['amount'] ?? 0).toDouble();
  double progress = totalAmount > 0 ? (initialAmount / totalAmount) : 0.0;

  return Card(
    elevation: 4,
    color: Colors.black,  // Set card background color to black
    margin: const EdgeInsets.only(bottom: 20),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (data['imageUrl'] != null)
          _buildImageSection(data['imageUrl']),
        
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(data, progress),
              const SizedBox(height: 16),
              _buildDescriptionSection(data),
              const SizedBox(height: 20),
              _buildProgressSection(initialAmount, totalAmount, progress),
              const SizedBox(height: 20),
              _buildActionButtons(documentId, context),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildHeaderSection(Map<String, dynamic> data, double progress) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rs.${NumberFormat('#,##,###').format(data['amount'])}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,  // Set text color to white
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatDate(data['date']),
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),  // Set secondary text color to lighter white
              fontSize: 14,
            ),
          ),
        ],
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _getProgressColor(progress).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '${(progress * 100).toInt()}% Funded',
          style: TextStyle(
            color: _getProgressColor(progress),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    ],
  );
}

Widget _buildDescriptionSection(Map<String, dynamic> data) {
  return Text(
    data['description'] ?? 'No description',
    style: TextStyle(
      fontSize: 16,
      color: Colors.white.withOpacity(0.7),  // Set text color to lighter white
      height: 1.5,
    ),
    maxLines: 3,
    overflow: TextOverflow.ellipsis,
  );
}

Widget _buildProgressSection(double initialAmount, double totalAmount, double progress) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation(_getProgressColor(progress)),
          minHeight: 8,
        ),
      ),
      const SizedBox(height: 10),
      Text(
        'Rs.${NumberFormat('#,##,###').format(initialAmount)} raised of Rs.${NumberFormat('#,##,###').format(totalAmount)}',
        style: TextStyle(
          color: Colors.white.withOpacity(0.7),  // Set text color to lighter white
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}

  Widget _buildImageSection(String imageUrl) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Image.network(
        imageUrl,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 200,
          color: Colors.grey[200],
          child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey[400]),
        ),
      ),
    );
  }



 
  Widget _buildActionButtons(String documentId, BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DonorDetailsPage(requestId: documentId),
              ),
            ),
            icon: const Icon(Icons.people_outline, size: 20),
            label: const Text('View Donors'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: () => _showDeleteConfirmation(documentId, context),
          icon: const Icon(Icons.delete_outline),
          color: Colors.red[400],
          tooltip: 'Delete Request',
          iconSize: 28,
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.volunteer_activism,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 20),
          Text(
            'No donation requests yet',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Your donation requests will appear here',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red[300],
            ),
            const SizedBox(height: 20),
            Text(
              'Error loading requests',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey[800],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              error,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress < 0.3) return Colors.red;
    if (progress < 0.7) return Colors.orange;
    return Colors.green;
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    if (date is Timestamp) {
      return DateFormat('MMM d, yyyy').format(date.toDate());
    }
    return date.toString();
  }
}