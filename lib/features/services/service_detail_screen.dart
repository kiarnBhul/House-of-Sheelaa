import 'package:flutter/material.dart';
import 'package:house_of_sheelaa/theme/brand_theme.dart';
import 'numerology_service_form_screen.dart';

class ServiceDetailScreen extends StatelessWidget {
  const ServiceDetailScreen({super.key});

  static const String route = '/service_detail';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final args =
        (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?) ??
        {};
    final name = (args['name'] as String?) ?? 'Service';
    final subtitle = (args['subtitle'] as String?) ?? '';
    final image = (args['image'] as String?) ?? '';
    final subs = (args['subs'] as List?)?.cast<Map>() ?? const <Map>[];

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    BrandColors.jacaranda,
                    BrandColors.cardinalPink,
                  ],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                height: 240,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFFD85E),
                    width: 1.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        image,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.low,
                        loadingBuilder: (ctx, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0x4030012F),
                                  Color(0x407E0562),
                                  Color(0x20F9751E),
                                ],
                              ),
                            ),
                          );
                        },
                        errorBuilder: (ctx, error, stack) {
                          return Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0x8030012F),
                                  Color(0x807E0562),
                                  Color(0x40F9751E),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0x9930012F)],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: tt.headlineSmall?.copyWith(
                                color: BrandColors.alabaster,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (subtitle.isNotEmpty)
                              Text(
                                subtitle,
                                style: tt.bodySmall?.copyWith(
                                  color: BrandColors.alabaster.withValues(
                                    alpha: 0.9,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sub Services',
                      style: tt.titleLarge?.copyWith(
                        color: BrandColors.alabaster,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 3,
                      width: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD85E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverLayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.crossAxisExtent;
                final cross = w >= 900 ? 4 : (w >= 600 ? 3 : 2);
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cross,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.78,
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final m = subs[index].cast<String, dynamic>();
                      final title = (m['name'] as String?) ?? '';
                      final img = (m['image'] as String?) ?? '';
                      final price = (m['price'] as num?);
                      final pmin = (m['priceMin'] as num?);
                      final pmax = (m['priceMax'] as num?);
                      final mins = (m['durationMin'] as int?);

                      String priceText = '';
                      if (pmin != null && pmax != null) {
                        priceText =
                            '₹${pmin.toStringAsFixed(0)} – ₹${pmax.toStringAsFixed(0)}';
                      } else if (price != null && mins != null) {
                        priceText =
                            '₹${price.toStringAsFixed(0)} — $mins minutes';
                      } else if (price != null) {
                        priceText = '₹${price.toStringAsFixed(0)}';
                      } else if (mins != null) {
                        priceText = 'Price varies — $mins minutes';
                      }

                      return GestureDetector(
                        onTap: () {
                          // Navigate to numerology form if it's a numerology service
                          if (name == 'Numerology') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NumerologyServiceFormScreen(
                                  serviceName: title,
                                  serviceImage: img,
                                ),
                              ),
                            );
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                BrandColors.alabaster.withValues(alpha: 0.15),
                                BrandColors.alabaster.withValues(alpha: 0.08),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: BrandColors.alabaster.withValues(alpha: 0.25),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: BrandColors.codGrey.withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFFFD85E),
                                  width: 2,
                                ),
                              ),
                              child: ClipOval(
                                child: Image.network(
                                  img,
                                  fit: BoxFit.cover,
                                  filterQuality: FilterQuality.low,
                                  gaplessPlayback: true,
                                  frameBuilder:
                                      (ctx, child, frame, syncLoaded) =>
                                          AnimatedOpacity(
                                            opacity:
                                                (syncLoaded || frame != null)
                                                ? 1
                                                : 0,
                                            duration: const Duration(
                                              milliseconds: 280,
                                            ),
                                            curve: Curves.easeOut,
                                            child: child,
                                          ),
                                  loadingBuilder: (ctx, child, prog) {
                                    if (prog == null) return child;
                                    return Container(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color(0x4030012F),
                                            Color(0x407E0562),
                                            Color(0x20F9751E),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (ctx, err, st) {
                                    return Container(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color(0x8030012F),
                                            Color(0x807E0562),
                                            Color(0x40F9751E),
                                          ],
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.healing,
                                        color: Colors.white70,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: tt.titleSmall?.copyWith(
                                color: BrandColors.alabaster,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            priceText.isEmpty
                                ? const SizedBox.shrink()
                                : Text(
                                    priceText,
                                    textAlign: TextAlign.center,
                                    style: tt.bodySmall?.copyWith(
                                      color: BrandColors.ecstasy,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ],
                        ),
                        ),
                      );
                    }, childCount: subs.length),
                  ),
                );
              },
            ),
          ],
            ),
          ),
        ],
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: BrandColors.alabaster),
      ),
    );
  }
}