import 'package:flutter/material.dart';
import 'package:house_of_sheelaa/theme/brand_theme.dart';

/// Badge to visually differentiate appointment-based services from digital/instant services
/// Shows duration for appointments, "Instant Delivery" for digital services
class ServiceTypeBadge extends StatelessWidget {
  final bool hasAppointment;
  final int? durationMinutes;

  const ServiceTypeBadge({
    super.key,
    required this.hasAppointment,
    this.durationMinutes,
  });

  @override
  Widget build(BuildContext context) {
    if (hasAppointment) {
      return _buildAppointmentBadge();
    } else {
      // Don't show any badge for non-appointment services
      return const SizedBox.shrink();
    }
  }

  /// Badge for appointment-based services (shows duration and calendar icon)
  Widget _buildAppointmentBadge() {
    final durationText = _formatDuration();
        
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            BrandColors.cardinalPink.withOpacity(0.15),
            BrandColors.ecstasy.withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: BrandColors.cardinalPink.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_month_rounded,
            size: 14,
            color: BrandColors.cardinalPink,
          ),
          const SizedBox(width: 6),
          Text(
            durationText,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: BrandColors.cardinalPink,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  /// Badge for digital/instant services (shows bolt icon and "Instant Delivery")
  Widget _buildDigitalBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            BrandColors.ecstasy.withOpacity(0.15),
            BrandColors.persianRed.withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: BrandColors.ecstasy.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bolt_rounded,
            size: 14,
            color: BrandColors.ecstasy,
          ),
          const SizedBox(width: 6),
          const Text(
            'Instant Delivery',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: BrandColors.ecstasy,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  /// Format duration in user-friendly way
  String _formatDuration() {
    if (durationMinutes == null) return 'Book appointment';
    
    if (durationMinutes! >= 60) {
      final hours = durationMinutes! ~/ 60;
      final minutes = durationMinutes! % 60;
      if (minutes == 0) {
        return '$hours ${hours == 1 ? "hour" : "hrs"} session';
      }
      return '$hours hr $minutes min session';
    }
    return '$durationMinutes min session';
  }
}
