import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:house_of_sheelaa/theme/brand_theme.dart';
import 'numerology_service_form_screen.dart';
import 'service_detail_page_new.dart';
import 'package:house_of_sheelaa/core/odoo/odoo_state.dart';
import 'package:house_of_sheelaa/core/models/odoo_models.dart';

class ServiceDetailScreen extends StatelessWidget {
  const ServiceDetailScreen({super.key});

  static const String route = '/service_detail';

  @override
  Widget build(BuildContext context) {
    bool isValidImageUrl(String? u) {
      if (u == null || u.isEmpty) return false;
      final low = u.toLowerCase();
      if (!(low.startsWith('http') || low.startsWith('data:'))) return false;
      // Some external placeholder hosts (eg. Unsplash demo URLs) can 404 in development;
      // treat known-problem hosts as invalid so we don't trigger noisy network requests.
      if (low.contains('unsplash.com')) return false;
      return true;
    }

    final tt = Theme.of(context).textTheme;
    final args =
        (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?) ??
        {};
    final name = (args['name'] as String?) ?? 'Service';
    final subtitle = (args['subtitle'] as String?) ?? '';
    final image = (args['image'] as String?) ?? '';
    // Subs passed from caller (may be empty when navigating from category card)
    List<Map<String, dynamic>> subs = (args['subs'] as List?)?.cast<Map<String, dynamic>>() ?? <Map<String, dynamic>>[];

    // If no subs were provided, try to build them from OdooState using category id or name
    final odooState = Provider.of<OdooState>(context);
    if (subs.isEmpty && odooState.isAuthenticated && odooState.categories.isNotEmpty) {
      int? categoryId;
      if (args.containsKey('id')) {
        final rawId = args['id'];
        if (rawId is int) {
          categoryId = rawId;
        } else if (rawId is String) categoryId = int.tryParse(rawId);
      }

      // try to find category by id or by name
      OdooCategory? cat;
      if (categoryId != null) {
        try {
          cat = odooState.categories.firstWhere((c) => c.id == categoryId);
        } catch (e) {
          cat = null;
        }
      }
      if (cat == null) {
        final nameMatch = (args['name'] as String?) ?? '';
        try {
          cat = odooState.categories.firstWhere((c) => c.name == nameMatch);
        } catch (e) {
          cat = null;
        }
      }

      if (cat != null) {
        final cid = cat.id;
        // Use services collection (OdooService) — these are fetched with type='service'
        final services = odooState.services.where((s) {
          final byPublic = s.publicCategoryIds != null && s.publicCategoryIds!.contains(cid);
          final byInternal = s.categoryId != null && s.categoryId == cid;
          return byPublic || byInternal;
        }).toList();

        // Ensure appointment types are loaded once so we can map services to appointments
        if (odooState.appointmentTypes.isEmpty && odooState.isAuthenticated) {
          Future.microtask(() async {
            try {
              await odooState.loadAppointmentTypes();
            } catch (_) {}
          });
        }

        // Build a map of service IDs to appointment types for quick lookup
        final appointmentMap = <int, OdooAppointmentType>{};
        for (var apt in odooState.appointmentTypes) {
          if (apt.productId != null) {
            appointmentMap[apt.productId!] = apt;
          }
        }

        final built = <Map<String, dynamic>>[];

        if (services.isNotEmpty) {
          for (var s in services) {
            // Check if this service has an appointment type linked
            final hasAppt = appointmentMap.containsKey(s.id);
            final apptType = appointmentMap[s.id];

            // Healing category override: force appointment flow even if metadata is missing
            final bool forceHealingAppointment = (cat.name.toLowerCase() == 'healing');

            if (s.subServices != null && s.subServices!.isNotEmpty) {
              // Only use subServices if they exist - don't duplicate the parent
              for (var ss in s.subServices!) {
                final resolvedAppointmentId = ss.appointmentId ?? apptType?.id ?? s.appointmentTypeId;
                built.add({
                  'type': 'service',
                  'id': ss.id,
                  'name': ss.name,
                  'image': ss.imageUrl ?? s.imageUrl ?? 'assets/images/background.jpg',
                  'price': ss.price ?? s.price,
                  'durationMin': ss.durationMinutes ??
                      (apptType?.duration != null ? (apptType!.duration! * 60).round() : null),
                  'hasAppointment': forceHealingAppointment || ss.hasAppointment || hasAppt,
                    'appointmentId': forceHealingAppointment
                      ? (resolvedAppointmentId ?? (appointmentMap.values.isNotEmpty ? appointmentMap.values.first.id : null))
                      : resolvedAppointmentId,
                  'appointmentLink': ss.appointmentLink ?? apptType?.websiteUrl ?? s.appointmentLink,
                });
              }
            } else {
              // Only add parent if no subServices exist
              final resolvedAppointmentId = apptType?.id ?? s.appointmentTypeId;
              built.add({
                'type': 'service',
                'id': s.id,
                'name': s.name,
                'image': s.imageUrl ?? 'assets/images/background.jpg',
                'price': s.price,
                'durationMin': apptType?.duration != null ? (apptType!.duration! * 60).round() : null,
                'hasAppointment': forceHealingAppointment || s.hasAppointment || hasAppt,
                'appointmentId': forceHealingAppointment
                  ? (resolvedAppointmentId ?? (appointmentMap.values.isNotEmpty ? appointmentMap.values.first.id : null))
                  : resolvedAppointmentId,
                'appointmentLink': apptType?.websiteUrl ?? s.appointmentLink,
              });
            }
          }
        } else {
          // Fallback: some Odoo setups return services as product templates/products with type='service'.
          // Use products list filtered by type == 'service' if services list is empty.
          final fallback = odooState.products.where((p) {
            final byPublic = p.publicCategoryIds != null && p.publicCategoryIds!.contains(cid);
            final byInternal = p.categoryId != null && p.categoryId == cid;
            final isService = (p.type ?? '') == 'service';
            return (byPublic || byInternal) && isService;
          }).toList();
          for (var p in fallback) {
            built.add({
              'type': 'service',
              'id': p.id,
              'name': p.name,
              'image': p.imageUrl ?? 'assets/images/background.jpg',
              'price': p.price,
              'durationMin': null,
            });
          }
                debugPrint('[ServiceDetail] services empty — used products fallback count=${fallback.length}');
          // If both services and product fallback are empty, trigger a background refresh
          if (built.isEmpty) {
            debugPrint('[ServiceDetail] no matches for category id=$cid, requesting refresh…');
            // kick off background loads without blocking UI
            Future.microtask(() async {
              try {
                await odooState.loadServices();
                await odooState.loadProducts(inStock: false);
              } catch (_) {}
            });
          }
        }

        subs = built;
                // Only show explicitly assigned services/products. Do not use name-match heuristics.
                debugPrint('[ServiceDetail] category=${cat.name} id=$cid services=${services.length} subs=${subs.length} products=${odooState.products.length}');
      }
    }
    // Do not show global/all-services fallback here — keep category pages strict.

    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
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
                        (isValidImageUrl(image))
                          ? Image.network(
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
                            )
                          : Container(
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
            if (kDebugMode)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        'DEBUG: Raw Odoo data (first 30)',
                        style: tt.titleSmall?.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Builder(builder: (ctx) {
                        final services = odooState.services;
                        final products = odooState.products;
                        final sb = StringBuffer();
                        sb.writeln('services (${services.length}):');
                        for (var s in services.take(30)) {
                          sb.writeln('id=${s.id} name="${s.name}" categ=${s.categoryId} public=${s.publicCategoryIds}');
                        }
                        sb.writeln('\nproducts (${products.length}):');
                        for (var p in products.take(30)) {
                          sb.writeln('id=${p.id} name="${p.name}" type=${p.type} categ=${p.categoryId} public=${p.publicCategoryIds}');
                        }
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Text(
                              sb.toString(),
                              style: tt.bodySmall?.copyWith(color: Colors.white70, fontFamily: 'monospace'),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            if (subs.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 8),
                      Text(
                        'No services found in this category.',
                        style: tt.bodyLarge?.copyWith(
                          color: BrandColors.alabaster.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              try {
                                await odooState.refreshAll();
                                debugPrint('[ServiceDetail] manual refresh complete');
                              } catch (e) {
                                debugPrint('[ServiceDetail] refresh error: $e');
                              }
                            },
                            child: const Text('Refresh'),
                          ),
                          const SizedBox(width: 12),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('Back'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            else
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
                        final serviceId = (m['id'] as int?);
                        final img = (m['image'] as String?) ?? '';
                        final price = (m['price'] as num?);
                        final pmin = (m['priceMin'] as num?);
                        final pmax = (m['priceMax'] as num?);
                        final mins = (m['durationMin'] as int?);
                        final hasAppointment = m['hasAppointment'] as bool? ?? false;
                        final appointmentId = m['appointmentId'] as int?;
                        final appointmentLink = m['appointmentLink'] as String?;

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

                        void handleTap() {
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
                            return;
                          }

                          // For healing services, trigger appointment booking
                          if (serviceId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Service not configured correctly'),
                                backgroundColor: BrandColors.persianRed,
                              ),
                            );
                            return;
                          }

                          _startBookingFlow(
                            context,
                            title: title,
                            serviceId: serviceId,
                            price: price?.toDouble(),
                            durationMinutes: mins,
                            image: img,
                            categoryName: name,
                            appointmentId: appointmentId,
                            appointmentLink: appointmentLink,
                            hasAppointmentFlag: hasAppointment,
                          );
                        }

                        return GestureDetector(
                          onTap: handleTap,
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
                                    child: (isValidImageUrl(img))
                                      ? Image.network(
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
                                        )
                                      : Container(
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
            // Extra bottom spacing to avoid RenderFlex overflow on small viewports
            SliverToBoxAdapter(
              child: SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 64),
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

  Future<void> _startBookingFlow(
    BuildContext context, {
    required String title,
    required int serviceId,
    double? price,
    int? durationMinutes,
    String? image,
    String? categoryName,
    int? appointmentId,
    String? appointmentLink,
    bool hasAppointmentFlag = false,
  }) async {
    try {
      int? resolvedAppointmentId = appointmentId;

      // Use already-loaded appointment types (faster, no extra network)
      final odooState = Provider.of<OdooState>(context, listen: false);
      if (resolvedAppointmentId == null && odooState.appointmentTypes.isNotEmpty) {
        OdooAppointmentType? matchedType;
        for (var type in odooState.appointmentTypes) {
          if (type.productId == serviceId) {
            matchedType = type;
            break;
          }
        }
        // Fallback: match by name
        matchedType ??= odooState.appointmentTypes.firstWhere(
          (t) => t.name.toLowerCase() == title.toLowerCase(),
          orElse: () => odooState.appointmentTypes.first,
        );
        resolvedAppointmentId = matchedType.id;
      }

      // Navigate to service detail page (handles both appointment and product flows)
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceDetailPageNew(
              serviceName: title,
              serviceId: serviceId,
              serviceImage: image,
              price: price,
              durationMinutes: durationMinutes,
              categoryName: categoryName,
              appointmentId: resolvedAppointmentId,
              appointmentLink: appointmentLink,
              hasAppointment: resolvedAppointmentId != null,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error in _startBookingFlow: $e');
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: BrandColors.persianRed,
          ),
        );
      }
    }
  }
}