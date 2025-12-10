import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review_model.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get reviews for a specific service
  Stream<List<ReviewModel>> getReviews(String serviceName) {
    // Sanitize service name to be document ID friendly if needed, 
    // strictly speaking user said "document id is services name".
    // We will use the service name directly as the collection ID 
    // or as a document ID in a 'services' collection with a 'reviews' subcollection.
    // The user requirement: "create the new collection in firestroe called review colleciton with the doucment id is services name."
    // Interpretation: Collection 'reviews' -> Document {ServiceName} -> Subcollection 'items' (or array, but subcollection is better).
    
    return _firestore
        .collection('reviews')
        .doc(serviceName)
        .collection('items')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ReviewModel.fromJson({...doc.data(), 'id': doc.id});
      }).toList();
    });
  }

  // Add a new review
  Future<void> addReview(String serviceName, ReviewModel review) async {
    final docRef = _firestore
        .collection('reviews')
        .doc(serviceName)
        .collection('items')
        .doc(); // Auto-generate ID

    final reviewWithId = ReviewModel(
      id: docRef.id,
      userName: review.userName,
      rating: review.rating,
      comment: review.comment,
      createdAt: DateTime.now(),
      isVerified: review.isVerified,
      userId: review.userId,
    );

    await docRef.set(reviewWithId.toJson());
    
    // Update aggregate stats on the main document if needed
    // For now just ensuring the parent document exists
    await _firestore.collection('reviews').doc(serviceName).set({
      'lastUpdated': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  // Delete a review (Admin function)
  Future<void> deleteReview(String serviceName, String reviewId) async {
    await _firestore
        .collection('reviews')
        .doc(serviceName)
        .collection('items')
        .doc(reviewId)
        .delete();
  }
  
  // Get all reviews for Admin (This might be expensive if not careful, 
  // but for now we iterate collections or structure differently. 
  // Given Firestore limitations, listing all subcollections requires a collection group query).
  // We'll use collection group query 'items' if we want ALL reviews across ALL services,
  // but we need to know which service they belong to.
  // Alternatively, we fetch the list of services from 'reviews' collection first.
  
  Stream<List<String>> getReviewedServices() {
     return _firestore.collection('reviews').snapshots().map((snapshot) {
       return snapshot.docs.map((doc) => doc.id).toList();
     });
  }
}
