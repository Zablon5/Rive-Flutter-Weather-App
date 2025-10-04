import 'package:rive_weather_app/weather_data.dart';

class WeatherResult {
  final WeatherData? weatherData;
  final String? errorMessage;

  WeatherResult({this.weatherData, this.errorMessage});

  bool get hasError => errorMessage != null;
}
