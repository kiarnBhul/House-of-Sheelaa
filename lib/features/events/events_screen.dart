import 'package:flutter/material.dart';
import 'package:house_of_sheelaa/theme/brand_theme.dart';

class EventsScreen extends StatelessWidget {
  static const String route = '/events';
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    // Sample events data - can be replaced with actual data
    final List<Map<String, dynamic>> events = [
      {
        "title": "9-9-9 Portal Activation Ceremony",
        "subtitle": "Release Past Karma • Manifest Abundance",
        "date": "9 Sept 2025",
        "time": "7:00 PM - 9:00 PM",
        "location": "Online & In-Person",
        "description": "Join us for a powerful ceremony to activate the 9-9-9 portal energy. Release past karma and manifest abundance in your life.",
        "image": "https://images.unsplash.com/photo-1505455184862-5548843f2951?w=1200&q=80&auto=format&fit=crop",
      },
      {
        "title": "Full Moon Group Healing",
        "subtitle": "Emotional Release • Chakra Alignment",
        "date": "14 Oct 2025",
        "time": "6:30 PM - 8:30 PM",
        "location": "Online",
        "description": "Experience deep emotional release and chakra alignment during this powerful full moon healing session.",
        "image": "https://images.unsplash.com/photo-1533038590840-1cde6e668a91?w=1200&q=80",
      },
      {
        "title": "Free Aura Cleansing Week",
        "subtitle": "Clear Negative Energy • Personal Guidance",
        "date": "1-7 Nov 2025",
        "time": "All Day",
        "location": "Multiple Locations",
        "description": "A week-long event offering free aura cleansing sessions and personal spiritual guidance.",
        "image": "https://images.unsplash.com/photo-1576092768241-dec231879fc3?w=1200&q=80",
      },
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                BrandColors.alabaster.withValues(alpha: 0.25),
                BrandColors.alabaster.withValues(alpha: 0.15),
              ],
            ),
            border: Border.all(
              color: BrandColors.alabaster.withValues(alpha: 0.4),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.of(context).pop(),
              child: Icon(
                Icons.arrow_back_rounded,
                color: BrandColors.alabaster,
              ),
            ),
          ),
        ),
        title: Text(
          'Upcoming Events',
          style: tt.headlineSmall?.copyWith(
            color: BrandColors.alabaster,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              BrandColors.jacaranda,
              BrandColors.cardinalPink,
              BrandColors.persianRed,
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      BrandColors.alabaster.withValues(alpha: 0.15),
                      BrandColors.alabaster.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: BrandColors.alabaster.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: BrandColors.codGrey.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              BrandColors.ecstasy.withValues(alpha: 0.3),
                              BrandColors.persianRed.withValues(alpha: 0.3),
                            ],
                          ),
                        ),
                        child: Image.network(
                          event['image'] as String,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.event_rounded,
                            size: 60,
                            color: BrandColors.alabaster,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event['title'] as String,
                              style: tt.headlineSmall?.copyWith(
                                color: BrandColors.alabaster,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              event['subtitle'] as String,
                              style: tt.titleMedium?.copyWith(
                                color: BrandColors.ecstasy,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 18,
                                  color: BrandColors.alabaster.withValues(alpha: 0.8),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  event['date'] as String,
                                  style: tt.bodyMedium?.copyWith(
                                    color: BrandColors.alabaster.withValues(alpha: 0.9),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 18,
                                  color: BrandColors.alabaster.withValues(alpha: 0.8),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  event['time'] as String,
                                  style: tt.bodyMedium?.copyWith(
                                    color: BrandColors.alabaster.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  size: 18,
                                  color: BrandColors.alabaster.withValues(alpha: 0.8),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  event['location'] as String,
                                  style: tt.bodyMedium?.copyWith(
                                    color: BrandColors.alabaster.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              event['description'] as String,
                              style: tt.bodyLarge?.copyWith(
                                color: BrandColors.alabaster.withValues(alpha: 0.9),
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [BrandColors.ecstasy, BrandColors.persianRed],
                                ),
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: BrandColors.ecstasy.withValues(alpha: 0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  // Handle event registration
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Registration for ${event['title']} coming soon!'),
                                      backgroundColor: BrandColors.ecstasy,
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: BrandColors.alabaster,
                                  minimumSize: const Size.fromHeight(48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                ),
                                child: const Text(
                                  'Register Now',
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}


