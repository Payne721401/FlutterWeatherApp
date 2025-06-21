import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/weather_data.dart';
import '../utils/weather_utils.dart';
import 'weather_card.dart';

class WeeklyForecastCard extends StatelessWidget {
  final List<DailyForecast> dailyForecasts;

  const WeeklyForecastCard({super.key, required this.dailyForecasts});

  @override
  Widget build(BuildContext context) {
    return WeatherCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("一週預報", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: dailyForecasts.length, // Iterate through each day
            itemBuilder: (context, index) {
              final forecast = dailyForecasts[index];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date/Day Name Header
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      '${DateFormat('M/d').format(forecast.date)} ${forecast.dayName}', // e.g., '4/28 星期三'
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  // Day Forecast Row
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0), // Indent slightly
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Row(
                            children: [
                              Chip(
                                label: Text('白天', style: TextStyle(fontSize: 10, color: Colors.black87)),
                                backgroundColor: Colors.grey[200],
                                padding: EdgeInsets.symmetric(horizontal: 5, vertical: 0),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              const SizedBox(width: 10),
                               Icon(
                                getWeatherIcon(forecast.dayIconCode),
                                size: 22,
                                color: getWeatherIconColor(forecast.dayIconCode)), // Use colored icon
                               const SizedBox(width: 8),
                               Text(
                                '${forecast.dayPrecipitationChance}%',
                                style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '高: ${forecast.dayTempHigh.round()}° 低: ${forecast.dayTempLow.round()}°', // Day High/Low
                            textAlign: TextAlign.right,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Night Forecast Row
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0), // Indent slightly
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         Expanded(
                          flex: 3,
                          child: Row(
                            children: [
                              Chip(
                                label: Text('夜間', style: TextStyle(fontSize: 10, color: Colors.white)),
                                backgroundColor: Colors.blueGrey[600],
                                padding: EdgeInsets.symmetric(horizontal: 5, vertical: 0),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              const SizedBox(width: 10),
                              Icon(
                                getWeatherIcon(forecast.nightIconCode),
                                size: 22,
                                color: getWeatherIconColor(forecast.nightIconCode)), // Use colored icon
                              const SizedBox(width: 8),
                              Text(
                                '${forecast.nightPrecipitationChance}%',
                                style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                           flex: 2,
                           child: Text(
                              '高: ${forecast.nightTempHigh.round()}° 低: ${forecast.nightTempLow.round()}°', // Night High/Low
                              textAlign: TextAlign.right,
                              style: Theme.of(context).textTheme.bodyMedium,
                           ),
                        ),
                      ],
                    ),
                  ),
                  // Add a Divider between days, except for the last day
                  if (index < dailyForecasts.length - 1) const Divider(height: 20, thickness: 1),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
