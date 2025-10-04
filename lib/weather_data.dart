// lib/weather_data.dart

import 'package:rive_weather_app/hourly_forecast.dart';

class WeatherData {
  final String cityName;
  final List<HourlyForecast> hourlyForecast;
  final String currentTempC;
  final String currentTempF;
  final bool isCloudy;
  final bool isRainy;
  final int localHour;

  WeatherData({
    required this.cityName,
    required this.hourlyForecast,
    required this.currentTempC,
    required this.currentTempF,
    required this.isCloudy,
    required this.isRainy,
    required this.localHour,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    const cloudinessThreshold = 20;
    const rainThreshold = 1; // in mm

    final location = json['location'] as Map<String, dynamic>;
    final current = json['current'] as Map<String, dynamic>;
    final forecastHours =
        json['forecast']['forecastday'][0]['hour'] as List<dynamic>;

    // Use the new HourlyForecast.fromJson factory
    final hourlyData = forecastHours
        .map(
          (hourJson) =>
              HourlyForecast.fromJson(hourJson as Map<String, dynamic>),
        )
        .toList();

    return WeatherData(
      cityName: '${location['name']}, ${location['country']}',
      currentTempC: (current['temp_c'] as num).round().toString(),
      currentTempF: (current['temp_f'] as num).round().toString(),
      isCloudy: (current['cloud'] as int) >= cloudinessThreshold,
      isRainy: (current['precip_mm'] as num) >= rainThreshold,
      localHour: DateTime.parse(location['localtime'] as String).hour,
      hourlyForecast: hourlyData,
    );
  }
}
