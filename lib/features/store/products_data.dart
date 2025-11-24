import 'models/product_model.dart';

class ProductsData {
  static List<Product> getAllProducts() {
    return [
      // Salt
      Product(
        id: 'bmr_salt_lavender',
        name: 'BMR Salt - Lavender',
        subtitle: 'Relaxing lavender scent',
        description: 'Premium BMR (Body Mind Rejuvenation) salt infused with calming lavender essence. Perfect for spiritual baths and cleansing rituals. Helps release negative energy and promotes deep relaxation.',
        price: '₹899',
        priceValue: 899,
        image: 'assets/images/bmr_salt.jpg',
        category: 'Salt',
        rating: 4.8,
        reviewCount: 156,
        benefits: [
          'Purifies aura and removes negative energy',
          'Promotes deep relaxation and stress relief',
          'Enhances meditation and spiritual practices',
          'Natural lavender aromatherapy benefits',
          'Suitable for ritual baths and foot soaks',
        ],
        reviews: [
          Review(
            userName: 'Priya Sharma',
            rating: 5.0,
            comment: 'Absolutely amazing! The lavender scent is so calming. I use it every night before meditation.',
            date: DateTime(2024, 11, 15),
          ),
          Review(
            userName: 'Rahul Mehta',
            rating: 4.5,
            comment: 'Great quality salt. Really helps in energy cleansing.',
            date: DateTime(2024, 11, 10),
          ),
          Review(
            userName: 'Anjali Patel',
            rating: 5.0,
            comment: 'Best BMR salt I\'ve used! Highly recommend for spiritual baths.',
            date: DateTime(2024, 11, 5),
          ),
        ],
      ),
      Product(
        id: 'bmr_salt_rose',
        name: 'BMR Salt - Rose',
        subtitle: 'Soothing rose fragrance',
        description: 'Luxurious BMR salt with natural rose essence. Ideal for energy cleansing and attracting positive vibrations. Enhances self-love and emotional healing.',
        price: '₹899',
        priceValue: 899,
        image: 'assets/images/bmr_salt.jpg',
        category: 'Salt',
        rating: 4.7,
        reviewCount: 142,
        benefits: [
          'Opens heart chakra and promotes self-love',
          'Attracts positive energy and good fortune',
          'Soothes emotional wounds and trauma',
          'Natural rose aromatherapy',
          'Ideal for love and relationship rituals',
        ],
        reviews: [
          Review(
            userName: 'Meera Singh',
            rating: 5.0,
            comment: 'Rose scent is divine! Perfect for self-love rituals.',
            date: DateTime(2024, 11, 12),
          ),
        ],
      ),

      // Bracelets
      Product(
        id: 'bracelet_amethyst',
        name: 'Amethyst Bracelet',
        subtitle: 'Promotes calmness',
        description: 'Authentic amethyst crystal bracelet handcrafted for spiritual protection and inner peace. Known as the "stone of spirituality," amethyst enhances intuition and connects you to higher consciousness.',
        price: '₹2,499',
        priceValue: 2499,
        image: 'assets/images/bracelet.jpg',
        category: 'Bracelets',
        rating: 4.9,
        reviewCount: 203,
        benefits: [
          'Enhances spiritual awareness and intuition',
          'Provides protection from negative energies',
          'Promotes emotional stability and inner peace',
          'Aids in meditation and spiritual growth',
          'Helps overcome addictions and bad habits',
          'Improves sleep quality and reduces nightmares',
        ],
        reviews: [
          Review(
            userName: 'Kavita Reddy',
            rating: 5.0,
            comment: 'Beautiful bracelet! I feel so much calmer since wearing it.',
            date: DateTime(2024, 11, 18),
          ),
          Review(
            userName: 'Amit Kumar',
            rating: 5.0,
            comment: 'Excellent quality amethyst. Really helps with meditation.',
            date: DateTime(2024, 11, 14),
          ),
        ],
      ),
      Product(
        id: 'bracelet_rose_quartz',
        name: 'Rose Quartz Bracelet',
        subtitle: 'Enhances love',
        description: 'Beautiful rose quartz crystal bracelet that radiates unconditional love and compassion. Perfect for opening the heart chakra and attracting loving relationships.',
        price: '₹2,499',
        priceValue: 2499,
        image: 'assets/images/bracelet.jpg',
        category: 'Bracelets',
        rating: 4.8,
        reviewCount: 187,
        benefits: [
          'Opens and heals the heart chakra',
          'Attracts love and strengthens relationships',
          'Promotes self-love and confidence',
          'Releases emotional wounds and trauma',
          'Brings peace and calmness to emotions',
          'Enhances compassion and forgiveness',
        ],
        reviews: [
          Review(
            userName: 'Neha Gupta',
            rating: 5.0,
            comment: 'Love this bracelet! It\'s beautiful and I feel more positive energy.',
            date: DateTime(2024, 11, 16),
          ),
        ],
      ),

      // Soaps
      Product(
        id: 'soap_lavender',
        name: 'Lavender Soap',
        subtitle: 'Gentle cleansing',
        description: 'Handmade spiritual soap infused with lavender essential oil and natural herbs. Cleanses both body and aura, removing negative attachments and promoting spiritual clarity.',
        price: '₹899',
        priceValue: 899,
        image: 'assets/images/bmr_shop.jpg',
        category: 'Soaps',
        rating: 4.6,
        reviewCount: 128,
        benefits: [
          'Cleanses physical and energetic body',
          'Removes negative energy attachments',
          'Promotes restful sleep and relaxation',
          'Natural and gentle on all skin types',
          'Enhances spiritual protection',
        ],
        reviews: [
          Review(
            userName: 'Simran Kaur',
            rating: 5.0,
            comment: 'Best soap ever! Smells amazing and feels great on skin.',
            date: DateTime(2024, 11, 13),
          ),
        ],
      ),
      Product(
        id: 'soap_rose',
        name: 'BMR Soap',
        subtitle: 'Moisturizing and fragrant',
        description: 'Luxurious handmade soap with rose petals and essential oils. Nourishes skin while attracting love, beauty, and positive energy into your life.',
        price: '₹500',
        priceValue: 500,
        image: 'assets/images/bmr_shop.jpg',
        category: 'Soaps',
        rating: 5.0,
        reviewCount: 3,
        benefits: [
          'Moisturizes and softens skin naturally',
          'Attracts love and positive relationships',
          'Enhances beauty and self-confidence',
          'Opens heart chakra during bathing rituals',
          'Removes emotional blockages',
        ],
        reviews: [
          Review(
            userName: 'Ritu Malhotra',
            rating: 5.0,
            comment: 'Love the rose fragrance! Very moisturizing.',
            date: DateTime(2024, 11, 11),
          ),
          Review(
            userName: 'Pooja Shah',
            rating: 5.0,
            comment: 'Amazing quality! My skin feels so soft.',
            date: DateTime(2024, 11, 8),
          ),
          Review(
            userName: 'Deepak Joshi',
            rating: 5.0,
            comment: 'Excellent soap for daily spiritual cleansing.',
            date: DateTime(2024, 11, 3),
          ),
        ],
      ),

      // Sprays
      Product(
        id: 'spray_aura',
        name: 'Aura Spray',
        subtitle: 'Cleanses aura',
        description: 'Powerful aura cleansing spray made with sacred herbs and essential oils. Instantly removes negative energy from your personal space and aura field. Perfect for daily spiritual hygiene.',
        price: '₹799',
        priceValue: 799,
        image: 'assets/images/aura_spray.jpg',
        category: 'Sprays',
        rating: 4.7,
        reviewCount: 164,
        benefits: [
          'Instantly cleanses and purifies aura',
          'Removes negative energy from spaces',
          'Protects against psychic attacks',
          'Enhances meditation and prayer',
          'Creates sacred and peaceful atmosphere',
          'Portable and easy to use anywhere',
        ],
        reviews: [
          Review(
            userName: 'Sanjay Desai',
            rating: 5.0,
            comment: 'Use it daily! Really clears the energy in my home.',
            date: DateTime(2024, 11, 17),
          ),
          Review(
            userName: 'Vidya Iyer',
            rating: 4.5,
            comment: 'Very effective for cleansing spaces.',
            date: DateTime(2024, 11, 9),
          ),
        ],
      ),

      // Rituals
      Product(
        id: 'ritual_incense',
        name: 'Incense Sticks',
        subtitle: 'Purifies space',
        description: 'Premium spiritual incense sticks made from natural herbs and resins. Used for centuries in spiritual practices to purify spaces, invite divine energy, and enhance meditation.',
        price: '₹299',
        priceValue: 299,
        image: 'assets/images/spiritual_products.jpg',
        category: 'Rituals',
        rating: 4.8,
        reviewCount: 245,
        benefits: [
          'Purifies and sanctifies living spaces',
          'Removes negative and stagnant energy',
          'Enhances focus during meditation',
          'Invites divine blessings and protection',
          'Natural aromatherapy benefits',
          'Long-lasting and slow-burning',
        ],
        reviews: [
          Review(
            userName: 'Manish Rao',
            rating: 5.0,
            comment: 'Best incense sticks! Burns slowly and smells divine.',
            date: DateTime(2024, 11, 19),
          ),
        ],
      ),
    ];
  }

  static List<String> getCategories() {
    return [
      'Soaps',
      'Oils',
      'FengShui',
      'Rituals',
      'Herbs',
      'Bracelets',
      'Amulets',
      'Crystal Pendants',
      'Salt',
      'Sprays',
    ];
  }

  static List<Product> getProductsByCategory(String category) {
    return getAllProducts().where((p) => p.category == category).toList();
  }
}

