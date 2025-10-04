// lib/hourly_forecast.dart

import 'package:intl/intl.dart';

class HourlyForecast {
  final bool isCloudy;
  final bool isRainy;
  final String formattedTime; // e.g., "09:00 AM"
  final int hour; // e.g., 9
  final String tempC;
  final String tempF;

  HourlyForecast({
    required this.isCloudy,
    required this.isRainy,
    required this.formattedTime,
    required this.hour,
    required this.tempC,
    required this.tempF,
  });

  /// A helper function to parse date strings from the API.
  static String _formatApiTime(String dateTimeStr) {
    final dt = DateTime.parse(dateTimeStr);
    return DateFormat('hh:mm a').format(dt); // e.g., "09:00 AM"
  }

  /// Creates an HourlyForecast instance from a JSON map.
  factory HourlyForecast.fromJson(Map<String, dynamic> json) {
    // Define weather condition thresholds as constants for clarity.
    const cloudinessThreshold = 20;
    const rainThreshold = 1; // in mm

    return HourlyForecast(
      isCloudy: (json['cloud'] as int) >= cloudinessThreshold,
      isRainy: (json['precip_mm'] as num) >= rainThreshold,
      formattedTime: _formatApiTime(json['time'] as String),
      hour: DateTime.parse(json['time'] as String).hour,
      tempC: (json['temp_c'] as num).round().toString(),
      tempF: (json['temp_f'] as num).round().toString(),
    );
  }
}
