import 'package:rive/rive.dart';
import 'package:device_preview/device_preview.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:flutter/material.dart';

import 'package:rive_weather_app/fetch_weather_data.dart';
import 'package:rive_weather_app/hourly_forecast.dart';

import 'package:rive_weather_app/weather_result.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Call init before using Rive.
  await RiveNative.init();
  await dotenv.load(fileName: ".env");
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DevicePreview(
        enabled: true,
        builder: (context) => const MainApp(), // Wrap your app
      ),
    ),
  );
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final TextEditingController _citySearchController = TextEditingController();
  WeatherResult? _weatherResult;
  String? _selectedTempC;
  String? _selectedTempF;
  int? _selectedHour;
  bool _isLoading = true;
  final String defaultCity = 'california';

  //rive
  late File file;
  late RiveWidgetController controller;
  NumberInput? _timeInput;
  BooleanInput? _cloudyInput;
  BooleanInput? _isRainingInput;
  BooleanInput? _isOpenInput;
  final String stateMachineName = 'State Machine 1';
  final String artboardName = 'proto1';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _initRive();
    await _fetchAndApplyWeather(defaultCity);
  }

  Future<void> _initRive() async {
    file = (await File.asset(
      'assets/weather_app_demo.riv',
      riveFactory: Factory.rive,
    ))!;

    controller = RiveWidgetController(
      file,
      artboardSelector: ArtboardSelector.byName(artboardName),
      stateMachineSelector: StateMachineSelector.byName(stateMachineName),
    );

    _timeInput = controller.stateMachine.number('time');
    _isRainingInput = controller.stateMachine.boolean('rainy');
    _cloudyInput = controller.stateMachine.boolean('cloudy');
    _isOpenInput = controller.stateMachine.boolean('isOpen');
  }

  Future<void> _fetchAndApplyWeather(String city) async {
    setState(() {
      _isLoading = true;
    });

    final result = await fetchWeatherData(city);
    if (!mounted) return;

    setState(() {
      _weatherResult = result;
      if (!_weatherResult!.hasError) {
        final weatherData = _weatherResult!.weatherData!;
        //set the initial selected values to the current weather
        _selectedTempC = weatherData.currentTempC;
        _selectedTempF = weatherData.currentTempF;
        _selectedHour = weatherData.localHour;
        _applyWeatherToRive(
          isCloudy: weatherData.isCloudy,
          isRainy: weatherData.isRainy,
          currentHour: weatherData.localHour,
        );
      }
      _isLoading = false;
    });
  }

  // Updates the rive animation based on weather conditions
  void _applyWeatherToRive({
    required bool isCloudy,
    required bool isRainy,
    required int currentHour,
  }) {
    _cloudyInput?.value = isCloudy;
    _timeInput?.value = currentHour.toDouble();
    _isRainingInput?.value = isRainy;
    _isOpenInput?.value = true;
  }

  // Handles tap events on the hourly forecast list

  void _onHourSelected(HourlyForecast hourData) {
    setState(() {
      _selectedTempC = hourData.tempC;
      _selectedTempF = hourData.tempF;
      _selectedHour = hourData.hour;
    });

    _applyWeatherToRive(
      isCloudy: hourData.isCloudy,
      isRainy: hourData.isRainy,
      currentHour: hourData.hour,
    );
  }

  @override
  void dispose() {
    _citySearchController.dispose();
    controller.dispose();
    file.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: TextField(
          controller: _citySearchController,
          decoration: InputDecoration(
            hintText: 'Search for a city',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white),
            icon: Icon(Icons.search, color: Colors.white),
          ),
          style: TextStyle(color: Colors.white, fontSize: 18),
          onSubmitted: _fetchAndApplyWeather,
        ),
      ),
      backgroundColor: Colors.transparent,
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          if (!_isLoading)
            RiveWidget(
              controller: controller,
              fit: Fit.cover,
              key: ValueKey(controller),
            ),
          //conditionally build the UI content based on the state
          _buildContent(),
        ],
      ),
    );
  }

  //builds the main content base on the current state (loading, error, or data)

  Widget _buildContent() {
    if (_isLoading) {
      return const CircularProgressIndicator();
    }
    if (_weatherResult?.hasError == true) {
      return Text(
        'Error: ${_weatherResult?.errorMessage ?? "An unknown error occurred."}',
        style: const TextStyle(color: Colors.red, fontSize: 18),
      );
    }
    return Column(
      children: [
        const SizedBox(height: 50),
        _buildCurrentWeatherInfo(),
        const Spacer(),
        Text(
          'Hourly Forecast',
          style: TextStyle(
            fontSize: 30,
            color: Colors.blueAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 40),
        _buildHourlyForecastList(),
        const SizedBox(height: 50),
      ],
    );
  }

  //build the widget displaying the city name and current selected temperature
  Widget _buildCurrentWeatherInfo() {
    final weatherData = _weatherResult!.weatherData!;
    return Column(
      children: [
        Text(
          weatherData.cityName,
          style: TextStyle(
            fontSize: 28,
            color: artboardName == 'proto1' ? Colors.white : Colors.blueAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '${_selectedTempC}°C / ${_selectedTempF}°F',
          style: TextStyle(
            fontSize: 22,
            color: artboardName == 'proto1' ? Colors.white : Colors.blueAccent,
          ),
        ),
      ],
    );
  }

  /// Builds the horizontal list of hourly forecast items.
  Widget _buildHourlyForecastList() {
    final forecast = _weatherResult!.weatherData!.hourlyForecast;
    return SizedBox(
      height: 300,
      width: 300, // Give the list a fixed height
      child: ListView.builder(
        itemCount: forecast.length,
        itemBuilder: (context, index) {
          final hourData = forecast[index];
          final isSelected = _selectedHour == hourData.hour;

          return GestureDetector(
            onTap: () => _onHourSelected(hourData),
            child: Container(
              padding: const EdgeInsets.all(12),

              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.3)
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    hourData.formattedTime,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${hourData.tempC}°C/${hourData.tempF}°F',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
