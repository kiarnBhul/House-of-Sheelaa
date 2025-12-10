import 'package:flutter/material.dart';
import 'package:house_of_sheelaa/core/models/review_model.dart';
import 'package:house_of_sheelaa/core/services/review_service.dart';

class ReviewsPage extends StatefulWidget {
  const ReviewsPage({super.key});

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  final ReviewService _reviewService = ReviewService();
  String? _expandedService;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Manage Reviews'),
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<String>>(
        stream: _reviewService.getReviewedServices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
          }

          final services = snapshot.data ?? [];

          if (services.isEmpty) {
            return const Center(child: Text('No reviews found.', style: TextStyle(color: Colors.white70)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final serviceName = services[index];
              return Card(
                color: const Color(0xFF1E1E1E),
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  title: Text(
                    serviceName,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  iconColor: Colors.white70,
                  collapsedIconColor: Colors.white54,
                  onExpansionChanged: (expanded) {
                    setState(() {
                      _expandedService = expanded ? serviceName : null;
                    });
                  },
                  children: [
                    if (_expandedService == serviceName)
                      _buildReviewsList(serviceName),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildReviewsList(String serviceName) {
    return StreamBuilder<List<ReviewModel>>(
      stream: _reviewService.getReviews(serviceName),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          );
        }

        final reviews = snapshot.data!;
        
        if (reviews.isEmpty) {
           return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No reviews.', style: TextStyle(color: Colors.white54)),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reviews.length,
          separatorBuilder: (context, index) => const Divider(color: Colors.white10),
          itemBuilder: (context, index) {
            final review = reviews[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.white10,
                child: Text(
                  review.rating.toStringAsFixed(1),
                  style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(
                review.userName,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (review.comment.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        review.comment,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  Text(
                    review.createdAt.toLocal().toString().split('.')[0],
                    style: const TextStyle(color: Colors.white30, fontSize: 12),
                  ),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () => _confirmDelete(serviceName, review.id),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(String serviceName, String reviewId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text('Delete Review?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteReview(serviceName, reviewId);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteReview(String serviceName, String reviewId) async {
    try {
      await _reviewService.deleteReview(serviceName, reviewId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
