import 'package:flutter/material.dart';

class GeneralWeatherCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const GeneralWeatherCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.blue.shade700, // Header background color
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header for location
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Text(
                '${data['location']}明天天氣預報',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Weather details
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _getWeatherIcon(data['condition_icon']),
                  const SizedBox(height: 10),
                  Text(
                    data['date'],
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    data['condition_description'],
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text('高溫', style: TextStyle(color: Colors.grey[600])),
                          Text(
                            '${data['high_temperature']}°C',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text('低溫', style: TextStyle(color: Colors.grey[600])),
                          Text(
                            '${data['low_temperature']}°C',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  _buildDetailRow('天氣狀況', data['temperature_change_advice']),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildDetailColumn('降雨機率', data['precipitation_chance']),
                      _buildDetailColumn('風向/風速', data['wind_direction_speed']),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    '天氣資料來源: ${data['data_source']}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  Text(
                    '資料時間: ${data['data_update_time']}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[700]),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildDetailColumn(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[700]),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _getWeatherIcon(String iconName) {
    IconData iconData;
    Color iconColor = Colors.orange; // Default color for sunny
    switch (iconName.toLowerCase()) {
      case 'sunny':
        iconData = Icons.wb_sunny;
        break;
      case 'cloudy':
        iconData = Icons.cloud;
        iconColor = Colors.blueGrey;
        break;
      case 'partly_cloudy':
        iconData = Icons.cloud; // Or a more specific partly cloudy icon if available
        iconColor = Colors.blueGrey.shade300;
        break;
      case 'rainy':
        iconData = Icons.umbrella;
        iconColor = Colors.blue;
        break;
      case 'stormy':
        iconData = Icons.flash_on;
        iconColor = Colors.deepPurple;
        break;
      case 'snowy':
        iconData = Icons.ac_unit;
        iconColor = Colors.lightBlue;
        break;
      default:
        iconData = Icons.wb_sunny; // Default to sunny if unknown
        break;
    }
    return Icon(iconData, size: 60, color: iconColor);
  }
}
