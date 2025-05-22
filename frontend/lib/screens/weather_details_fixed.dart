import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/weather_service.dart';
import 'package:intl/intl.dart';

class WeatherDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> currentWeather;
  final Map<String, dynamic>? weatherForecast;
  final Map<String, dynamic>? sprayRecommendations;
  final String weatherUnits;
  final Function refreshCallback;

  const WeatherDetailsScreen({
    Key? key,
    required this.currentWeather,
    this.weatherForecast,
    this.sprayRecommendations,
    required this.weatherUnits,
    required this.refreshCallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Extract weather data
    final temp = currentWeather['temperature'];
    final feelsLike = currentWeather['feels_like'];
    final condition = currentWeather['weather_condition'] ?? 'unknown';
    final description = currentWeather['weather_description'] ?? 'Unknown';
    final iconCode = currentWeather['weather_icon'] ?? '01d';
    final humidity = currentWeather['humidity'];
    final pressure = currentWeather['pressure'];
    final windSpeed = currentWeather['wind_speed'];
    final windDirection = currentWeather['wind_direction'];
    final locationName = currentWeather['location_name'] ?? 'Unknown';
    final country = currentWeather['country'] ?? '';
    final sunrise = currentWeather['sunrise'];
    final sunset = currentWeather['sunset'];
    final visibility = currentWeather['visibility'];
    final cloudiness = currentWeather['cloudiness'];

    // Format data
    final formattedTemp = WeatherService.formatTemperature(temp, weatherUnits);
    final formattedFeelsLike =
        WeatherService.formatTemperature(feelsLike, weatherUnits);
    final windDirectionText =
        WeatherService.getWindDirection(windDirection) ?? 'N/A';
    final iconUrl = WeatherService.getWeatherIconUrl(iconCode);

    // Format sunrise/sunset times
    final sunriseTime = sunrise != null
        ? DateTime.fromMillisecondsSinceEpoch(sunrise * 1000)
        : null;
    final sunsetTime = sunset != null
        ? DateTime.fromMillisecondsSinceEpoch(sunset * 1000)
        : null;
    final timeFormat = DateFormat('HH:mm');

    // Get forecast data
    final hasForecast = weatherForecast != null &&
        weatherForecast!.containsKey('list') &&
        (weatherForecast!['list'] as List)
            .isNotEmpty; // Get spray recommendations
    final hasOptimalTimes = sprayRecommendations != null &&
        sprayRecommendations!.containsKey('optimal_times') &&
        sprayRecommendations!['optimal_times'] != null &&
        (sprayRecommendations!['optimal_times'] is List) &&
        (sprayRecommendations!['optimal_times'] as List).isNotEmpty;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // App Bar with weather header
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            stretch: true,
            backgroundColor: _getWeatherColor(condition),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: _getWeatherGradient(condition),
                  ),
                  image: DecorationImage(
                    image: AssetImage(_getWeatherBackgroundImage(condition)),
                    fit: BoxFit.cover,
                    opacity: 0.2,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Location with icon
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on,
                              color: Colors.white.withOpacity(0.9),
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$locationName, $country',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Weather icon in glowing container - now using custom icon
                      _buildCustomWeatherIcon(iconCode),
                      const SizedBox(height: 16),

                      // Temperature with description badge
                      Text(
                        formattedTemp,
                        style: const TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1,
                          shadows: [
                            Shadow(
                              blurRadius: 10.0,
                              color: Colors.black26,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Text(
                          description.toString().toUpperCase(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Feels like $formattedFeelsLike',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              collapseMode: CollapseMode.pin,
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: () => refreshCallback(),
                tooltip: 'Refresh weather data',
              ),
            ],
          ),

          // Weather details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current conditions card
                  Card(
                    elevation: 8,
                    shadowColor: Colors.black26,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white,
                            Colors.blue.shade50,
                          ],
                          stops: const [0.6, 1.0],
                        ),
                      ),
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  Icons.thermostat_rounded,
                                  color: Colors.blue.shade700,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Current Conditions',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Redesigned grid layout with better visual appeal
                          GridView.count(
                            crossAxisCount: 3,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            childAspectRatio:
                                5.0, // Significantly increased to prevent overflow completely
                            crossAxisSpacing: 4, // Further reduced spacing
                            mainAxisSpacing: 6, // Further reduced spacing
                            children: [
                              _buildDetailItem(Icons.water_drop_outlined,
                                  '${humidity ?? 0}%', 'Humidity', Colors.blue),
                              _buildDetailItem(
                                  Icons.compress,
                                  '${pressure ?? 0} hPa',
                                  'Pressure',
                                  Colors.purple),
                              _buildDetailItem(
                                  Icons.visibility,
                                  visibility != null
                                      ? '${(visibility / 1000).toStringAsFixed(1)} km'
                                      : 'N/A',
                                  'Visibility',
                                  Colors.teal),
                              _buildDetailItem(
                                  Icons.air,
                                  '${windSpeed ?? 0} ${weatherUnits == 'imperial' ? 'mph' : 'm/s'}',
                                  'Wind',
                                  Colors.blue.shade700),
                              _buildDetailItem(
                                  Icons.explore_outlined,
                                  windDirectionText,
                                  'Direction',
                                  Colors.orange),
                              _buildDetailItem(
                                  Icons.cloud,
                                  '${cloudiness ?? 0}%',
                                  'Cloudiness',
                                  Colors.blueGrey),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Sun times card
                  Card(
                    elevation: 8,
                    shadowColor: Colors.black26,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white,
                            Colors.orange.shade50,
                          ],
                          stops: const [0.6, 1.0],
                        ),
                      ),
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  Icons.wb_twilight_rounded,
                                  color: Colors.orange.shade700,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Sun Times',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildSunTimeItem(
                                Icons.wb_sunny_rounded,
                                sunriseTime != null
                                    ? timeFormat.format(sunriseTime)
                                    : '--:--',
                                'Sunrise',
                                Colors.amber,
                              ),
                              Container(
                                height: 80,
                                width: 1,
                                color: Colors.grey.shade300,
                              ),
                              _buildSunTimeItem(
                                Icons.nightlight_round,
                                sunsetTime != null
                                    ? timeFormat.format(sunsetTime)
                                    : '--:--',
                                'Sunset',
                                Colors.indigo,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Spray recommendations with detailed information
                  if (hasOptimalTimes) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Optimal Spray Times',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSprayRecommendationsSection()
                  ],

                  // Forecast section (kept simple for now)
                  if (hasForecast) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Forecast',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // You can enhance this section in a future update
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  } // Enhanced detail item with improved visual design

  Widget _buildDetailItem(
      IconData icon, String value, String label, Color iconColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4), // Minimal padding
            margin: const EdgeInsets.only(left: 4, right: 4),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 14, // Smallest icon size that's still visible
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 11, // Very small font size
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9, // Very small font size
                    color: Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Sun time item with custom styling
  Widget _buildSunTimeItem(
      IconData icon, String time, String label, Color iconColor) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 28,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          time,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // Build the spray recommendations section
  Widget _buildSprayRecommendationsSection() {
    if (sprayRecommendations == null ||
        !sprayRecommendations!.containsKey('optimal_times') ||
        (sprayRecommendations!['optimal_times'] as List).isEmpty) {
      return const Center(
        child: Text(
          'No spray recommendations available',
          style: TextStyle(
            fontSize: 16,
            fontStyle: FontStyle.italic,
            color: Colors.grey,
          ),
        ),
      );
    }

    final optimalTimes = sprayRecommendations!['optimal_times'] as List;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.schedule_rounded,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Best Times to Spray',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          // Recommendations list
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: optimalTimes.length,
            itemBuilder: (context, index) {
              final optimalTime = optimalTimes[index];
              final date = optimalTime['date'] ?? 'Unknown date';
              final timeWindows = optimalTime['time_windows'] as List? ?? [];
              final weatherConditions = optimalTime['weather_conditions'] ?? {};

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: index < optimalTimes.length - 1
                      ? Border(bottom: BorderSide(color: Colors.grey.shade200))
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: Colors.green.shade800,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          date,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Optimal Time Windows:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (var window in timeWindows)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.green.shade300),
                            ),
                            child: Text(
                              window.toString(),
                              style: TextStyle(
                                color: Colors.green.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (weatherConditions.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Weather Conditions:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildWeatherConditionItem(
                            Icons.thermostat,
                            '${weatherConditions['temperature'] ?? "N/A"}',
                            'Temperature',
                          ),
                          _buildWeatherConditionItem(
                            Icons.air,
                            '${weatherConditions['wind_speed'] ?? "N/A"} ${weatherUnits == 'imperial' ? 'mph' : 'm/s'}',
                            'Wind',
                          ),
                          _buildWeatherConditionItem(
                            Icons.water_drop,
                            '${weatherConditions['humidity'] ?? "N/A"}%',
                            'Humidity',
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Helper method for weather condition items
  Widget _buildWeatherConditionItem(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Keep column size minimal
          children: [
            Icon(icon, size: 16, color: Colors.blue.shade700), // Smaller icon
            const SizedBox(height: 2), // Less spacing
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 11, // Smaller text
              ),
              overflow: TextOverflow.ellipsis, // Handle overflow
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 9, // Even smaller text
                color: Colors.grey.shade600,
              ),
              overflow: TextOverflow.ellipsis, // Handle overflow
            ),
          ],
        ),
      ),
    );
  }

  // Custom widget for weather icon similar to home screen
  Widget _buildCustomWeatherIcon(String iconCode) {
    // Custom weather icon based on the code
    IconData iconData;
    Color iconColor = Colors.white;
    Color backgroundColor = Colors.white.withOpacity(0.2);
    double size = 60.0;

    if (iconCode.contains('01')) {
      // Clear sky
      iconData = iconCode.contains('d')
          ? Icons.wb_sunny_rounded
          : Icons.nightlight_round;
      iconColor = iconCode.contains('d') ? Colors.amber : Colors.white;
      backgroundColor = iconCode.contains('d')
          ? Colors.orange.withOpacity(0.2)
          : Colors.indigo.withOpacity(0.3);
    } else if (iconCode.contains('02')) {
      // Few clouds
      iconData = iconCode.contains('d')
          ? Icons.wb_cloudy_rounded
          : Icons.nights_stay_rounded;
      backgroundColor = iconCode.contains('d')
          ? Colors.lightBlue.withOpacity(0.2)
          : Colors.indigo.withOpacity(0.3);
    } else if (iconCode.contains('03') || iconCode.contains('04')) {
      // Scattered or broken clouds
      iconData = Icons.cloud_rounded;
      backgroundColor = Colors.blueGrey.withOpacity(0.3);
    } else if (iconCode.contains('09')) {
      // Shower rain
      iconData = Icons.grain_rounded;
      iconColor = Colors.lightBlue.shade100;
      backgroundColor = Colors.indigo.withOpacity(0.3);
    } else if (iconCode.contains('10')) {
      // Rain
      iconData = Icons.water_drop_rounded;
      iconColor = Colors.lightBlue.shade100;
      backgroundColor = Colors.indigo.withOpacity(0.3);
    } else if (iconCode.contains('11')) {
      // Thunderstorm
      iconData = Icons.flash_on_rounded;
      iconColor = Colors.amber;
      backgroundColor = Colors.deepPurple.withOpacity(0.3);
    } else if (iconCode.contains('13')) {
      // Snow
      iconData = Icons.ac_unit_rounded;
      backgroundColor = Colors.lightBlue.withOpacity(0.2);
    } else if (iconCode.contains('50')) {
      // Mist/fog
      iconData = Icons.waves_rounded;
      backgroundColor = Colors.grey.withOpacity(0.3);
    } else {
      // Default
      iconData = Icons.cloud_rounded;
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // Decorative background circles
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: backgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.15),
            border:
                Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
          ),
          child: Icon(
            iconData,
            color: iconColor,
            size: size,
          ),
        ),
      ],
    );
  }

  // Helper method for weather icon data
  IconData _getWeatherIconData(String iconCode) {
    // OpenWeatherMap icon codes reference:
    // 01: clear sky
    // 02: few clouds
    // 03: scattered clouds
    // 04: broken clouds
    // 09: shower rain
    // 10: rain
    // 11: thunderstorm
    // 13: snow
    // 50: mist/fog
    // 'd' suffix means day, 'n' suffix means night

    if (iconCode.contains('01')) {
      // Clear sky
      return iconCode.contains('d')
          ? Icons.wb_sunny_rounded // Day - sun
          : Icons.nightlight_round; // Night - moon
    } else if (iconCode.contains('02')) {
      // Few clouds
      return iconCode.contains('d')
          ? Icons.wb_cloudy // Day - sun with cloud
          : Icons.nights_stay; // Night - moon with cloud
    } else if (iconCode.contains('03')) {
      // Scattered clouds
      return Icons.cloud_outlined;
    } else if (iconCode.contains('04')) {
      // Broken clouds (overcast)
      return Icons.cloud;
    } else if (iconCode.contains('09')) {
      // Shower rain
      return Icons.grain;
    } else if (iconCode.contains('10')) {
      // Rain
      return iconCode.contains('d')
          ? Icons.wb_cloudy // Rainy day
          : Icons.nights_stay; // Rainy night
    } else if (iconCode.contains('11')) {
      // Thunderstorm
      return Icons.flash_on;
    } else if (iconCode.contains('13')) {
      // Snow
      return Icons.ac_unit;
    } else if (iconCode.contains('50')) {
      // Mist/fog
      return Icons.blur_on;
    } else {
      // Default
      return Icons.cloud_rounded;
    }
  }

  // Weather background image paths
  String _getWeatherBackgroundImage(String condition) {
    condition = condition.toLowerCase();

    if (condition.contains('clear') || condition.contains('sun')) {
      return 'assets/images/weather/clear_sky.jpg';
    } else if (condition.contains('cloud')) {
      return 'assets/images/weather/cloudy.jpg';
    } else if (condition.contains('rain') || condition.contains('drizzle')) {
      return 'assets/images/weather/rain.jpg';
    } else if (condition.contains('thunder')) {
      return 'assets/images/weather/thunderstorm.jpg';
    } else if (condition.contains('snow')) {
      return 'assets/images/weather/snow.jpg';
    } else if (condition.contains('mist') || condition.contains('fog')) {
      return 'assets/images/weather/fog.jpg';
    } else {
      return 'assets/images/weather/default_weather.jpg';
    }
  }

  // Weather color based on condition
  Color _getWeatherColor(String condition) {
    condition = condition.toLowerCase();

    if (condition.contains('clear') || condition.contains('sun')) {
      return const Color(0xFF1E88E5);
    } else if (condition.contains('cloud')) {
      return const Color(0xFF546E7A);
    } else if (condition.contains('rain') || condition.contains('drizzle')) {
      return const Color(0xFF1A237E);
    } else if (condition.contains('thunder')) {
      return const Color(0xFF1A237E);
    } else if (condition.contains('snow')) {
      return const Color(0xFF546E7A);
    } else if (condition.contains('mist') || condition.contains('fog')) {
      return const Color(0xFF616161);
    } else {
      return const Color(0xFF43A047);
    }
  }

  // Weather gradient colors based on condition
  List<Color> _getWeatherGradient(String condition) {
    condition = condition.toLowerCase();

    if (condition.contains('clear') || condition.contains('sun')) {
      return [
        const Color(0xFF2196F3),
        const Color(0xFF1976D2),
      ];
    } else if (condition.contains('cloud')) {
      return [
        const Color(0xFF546E7A),
        const Color(0xFF455A64),
      ];
    } else if (condition.contains('rain') || condition.contains('drizzle')) {
      return [
        const Color(0xFF3949AB),
        const Color(0xFF1A237E),
      ];
    } else if (condition.contains('thunder')) {
      return [
        const Color(0xFF303F9F),
        const Color(0xFF1A237E),
      ];
    } else if (condition.contains('snow')) {
      return [
        const Color(0xFF78909C),
        const Color(0xFF546E7A),
      ];
    } else if (condition.contains('mist') || condition.contains('fog')) {
      return [
        const Color(0xFF78909C),
        const Color(0xFF546E7A),
      ];
    } else {
      return [
        const Color(0xFF43A047),
        const Color(0xFF2E7D32),
      ];
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
