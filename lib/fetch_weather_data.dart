import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:rive_weather_app/weather_data.dart';
import 'package:rive_weather_app/weather_result.dart';

Future<WeatherResult> fetchWeatherData(String? city) async {
  try {
    String apiKey = dotenv.env['WEATHER_API_KEY'] ?? '';

    final response = await http.get(
      Uri.parse(
        'https://api.weatherapi.com/v1/forecast.json?key=$apiKey&q=$city&days=1',
      ),
    );
    final responseJson = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return WeatherResult(weatherData: WeatherData.fromJson(responseJson));
    } else {
      return WeatherResult(errorMessage: responseJson['error']['message']);
    }
  } catch (e) {
    return WeatherResult(errorMessage: 'Failed to fetch weather data: $e');
  }
}
