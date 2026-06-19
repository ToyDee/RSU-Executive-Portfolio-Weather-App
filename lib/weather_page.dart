import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'app_security.dart'; // for AppConfig.openWeatherApiKey

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> with TickerProviderStateMixin {
  late TabController _tabController;
  String _unit = 'metric';
  String _unitLabel = '°C';

  Map<String, dynamic>? weatherData;
  Map<String, dynamic>? airData;
  String? weatherError;
  String? airError;
  bool _weatherLoading = true;
  bool _airLoading = true;

  // IMPROVEMENT: API key from --dart-define, never hardcoded
  final String _apiKey = AppConfig.openWeatherApiKey;
  final double _lat = 13.736717;
  final double _lon = 100.523186;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchWeather();
    _fetchAir();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchWeather() async {
    setState(() { _weatherLoading = true; weatherError = null; });
    // IMPROVEMENT: friendly error if no API key provided
    if (_apiKey.isEmpty) {
      setState(() { weatherError = 'No API key configured.\nRun with --dart-define=OWM_API_KEY=your_key'; _weatherLoading = false; });
      return;
    }
    try {
      final url = 'https://api.openweathermap.org/data/2.5/weather?lat=$_lat&lon=$_lon&units=$_unit&appid=$_apiKey';
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (!mounted) return;
      if (res.statusCode == 200) {
        setState(() { weatherData = json.decode(res.body); _weatherLoading = false; });
      } else {
        setState(() { weatherError = 'Server error ${res.statusCode}. Try again.'; _weatherLoading = false; });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { weatherError = 'No connection. Check your network.'; _weatherLoading = false; });
    }
  }

  Future<void> _fetchAir() async {
    setState(() { _airLoading = true; airError = null; });
    if (_apiKey.isEmpty) {
      setState(() { airError = 'No API key configured.'; _airLoading = false; });
      return;
    }
    try {
      final url = 'https://api.openweathermap.org/data/2.5/air_pollution?lat=$_lat&lon=$_lon&appid=$_apiKey';
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (!mounted) return;
      if (res.statusCode == 200) {
        setState(() { airData = json.decode(res.body); _airLoading = false; });
      } else {
        setState(() { airError = 'Server error ${res.statusCode}.'; _airLoading = false; });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { airError = 'No connection. Check your network.'; _airLoading = false; });
    }
  }

  void _toggleUnit() {
    setState(() {
      _unit = _unit == 'metric' ? 'imperial' : 'metric';
      _unitLabel = _unit == 'metric' ? '°C' : '°F';
    });
    _fetchWeather();
  }

  String _aqiLabel(int aqi) {
    switch (aqi) {
      case 1: return 'Good'; case 2: return 'Fair'; case 3: return 'Moderate';
      case 4: return 'Poor'; case 5: return 'Very Poor'; default: return 'Unknown';
    }
  }

  Color _aqiColor(int aqi) {
    switch (aqi) {
      case 1: return const Color(0xFF2E7D32); case 2: return const Color(0xFFF9A825);
      case 3: return const Color(0xFFE65100); case 4: return const Color(0xFFC62828);
      case 5: return const Color(0xFF6A1B9A); default: return Colors.grey;
    }
  }

  // FIX #5: now accepts isNight so a clear sky at night shows the moon icon
  // instead of the sun icon. Other conditions (clouds/rain/mist) keep one
  // icon regardless of time of day, since there isn't a night variant for them.
  String _weatherIcon(String condition, {bool isNight = false}) {
    final cond = condition.toLowerCase();
    if (cond == 'clear' && isNight) return 'Assets/Icons/night.png';
    switch (cond) {
      case 'clear': return 'Assets/Icons/sun.png';
      case 'clouds': return 'Assets/Icons/cloud.png';
      case 'rain': case 'drizzle': case 'thunderstorm': return 'Assets/Icons/raining.png';
      case 'mist': case 'fog': case 'haze': return 'Assets/Icons/mist.png';
      default: return 'Assets/Icons/cloud.png';
    }
  }

  // FIX #5: determines day/night using the API's own sunrise/sunset
  // timestamps (in the 'sys' object) compared against the data timestamp 'dt'.
  // Falls back to false (treat as day) if any field is missing.
  bool _isNightTime(Map<String, dynamic> weather) {
    final sys = weather['sys'] as Map<String, dynamic>?;
    final currentDt = weather['dt'] as int?;
    final sunrise = sys?['sunrise'] as int?;
    final sunset = sys?['sunset'] as int?;
    if (currentDt == null || sunrise == null || sunset == null) return false;
    return currentDt < sunrise || currentDt > sunset;
  }

  String _formatTimestamp(int unixSeconds) {
    final dt = DateTime.fromMillisecondsSinceEpoch(unixSeconds * 1000).toLocal();
    return '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year}  ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather & Air Quality'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.wb_sunny_outlined), text: 'Weather'),
            Tab(icon: Icon(Icons.air), text: 'Air Quality'),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: _toggleUnit,
            icon: const Icon(Icons.swap_horiz, color: Colors.white, size: 18),
            label: Text(_unitLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildWeatherTab(), _buildAirTab()],
      ),
    );
  }

  Widget _buildWeatherTab() {
    if (_weatherLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)));
    if (weatherError != null) return _ErrorView(message: weatherError!, onRetry: _fetchWeather);
    final main    = weatherData!['main'];
    final weather = weatherData!['weather'][0];
    final wind    = weatherData!['wind'];
    final isNight = _isNightTime(weatherData!); // FIX #5

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: const Color(0xFF1B5E20).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: Column(
              children: [
                Image.asset(_weatherIcon(weather['main'], isNight: isNight), width: 90, height: 90), // FIX #5
                const SizedBox(height: 12),
                Text('${main['temp'].round()}$_unitLabel',
                    style: const TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.w300, height: 1)),
                const SizedBox(height: 6),
                Text(weather['description'].toString().toUpperCase(),
                    style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13, letterSpacing: 1.5)),
                const SizedBox(height: 4),
                Text(weatherData!['name'] ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatCard(icon: 'Assets/Icons/high_temperature.png', label: 'High', value: '${main['temp_max'].round()}$_unitLabel'),
              const SizedBox(width: 10),
              _StatCard(icon: 'Assets/Icons/low_temperature.png',  label: 'Low',  value: '${main['temp_min'].round()}$_unitLabel'),
              const SizedBox(width: 10),
              _StatCard(icon: 'Assets/Icons/humidity.png',         label: 'Humidity', value: '${main['humidity']}%'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _InfoTile(icon: Icons.thermostat_outlined, label: 'Feels like', value: '${main['feels_like'].round()}$_unitLabel'),
              const SizedBox(width: 10),
              _InfoTile(icon: Icons.air, label: 'Wind', value: '${wind['speed']} ${_unit == 'metric' ? 'm/s' : 'mph'}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAirTab() {
    if (_airLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)));
    if (airError != null) return _ErrorView(message: airError!, onRetry: _fetchAir);
    final list   = airData!['list'][0];
    final aqi    = list['main']['aqi'] as int;
    final comp   = list['components'];
    final timeStr = _formatTimestamp(list['dt'] as int);
    final aqiColor = _aqiColor(aqi);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity, padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: aqiColor, borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: aqiColor.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))]),
            child: Column(
              children: [
                Text('$aqi', style: const TextStyle(color: Colors.white, fontSize: 64, fontWeight: FontWeight.w800, height: 1)),
                const SizedBox(height: 6),
                Text('AQI · ${_aqiLabel(aqi)}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text('Updated: $timeStr', style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('POLLUTANT BREAKDOWN',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 1.2)),
                const SizedBox(height: 14),
                _PollutantRow(label: 'PM2.5', value: comp['pm2_5'], unit: 'μg/m³'),
                _PollutantRow(label: 'PM10',  value: comp['pm10'],  unit: 'μg/m³'),
                _PollutantRow(label: 'CO',    value: comp['co'],    unit: 'μg/m³'),
                _PollutantRow(label: 'NO₂',   value: comp['no2'],   unit: 'μg/m³'),
                _PollutantRow(label: 'O₃',    value: comp['o3'],    unit: 'μg/m³', isLast: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String icon, label, value;
  const _StatCard({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Column(children: [
          Image.asset(icon, width: 28, height: 28),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
        ]),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoTile({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Row(children: [
          Icon(icon, color: const Color(0xFF388E3C), size: 22),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          ]),
        ]),
      ),
    );
  }
}

class _PollutantRow extends StatelessWidget {
  final String label, unit;
  final dynamic value;
  final bool isLast;
  const _PollutantRow({required this.label, required this.value, required this.unit, this.isLast = false});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        Text('$value $unit', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
      ]),
      if (!isLast) ...[const SizedBox(height: 10), Divider(height: 1, color: Colors.grey.shade100), const SizedBox(height: 10)],
    ]);
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15)),
          const SizedBox(height: 20),
          ElevatedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry')),
        ]),
      ),
    );
  }
}