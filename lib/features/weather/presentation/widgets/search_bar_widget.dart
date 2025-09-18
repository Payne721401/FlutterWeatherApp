import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../state/weather_data_state.dart';
import '../../data/models/weather_alert.dart';
import '../../../location/presentation/screens/add_location_screen.dart';

Map<String, dynamic> _getAlertStyle(String title) {
  int priority;
  Color color;

  switch (title) {
    case '火山':
      priority = 0;
      color = Colors.red[900]!;
      break;
    case '海嘯':
      priority = 1;
      color = Colors.red[700]!;
      break;
    case '地震':
      priority = 2;
      color = Colors.brown[600]!;
      break;
    case '颱風':
      priority = 3;
      color = Colors.purple[700]!;
      break;
    case '降雨':
      priority = 4;
      color = Colors.blue[700]!;
      break;
    case '強風':
      priority = 5;
      color = Colors.teal[600]!;
      break;
    case '高溫':
      priority = 6;
      color = Colors.orange[800]!;
      break;
    case '低溫':
      priority = 7;
      color = Colors.lightBlue[400]!;
      break;
    case '濃霧':
      priority = 8;
      color = Colors.grey[600]!;
      break;
    case '淹水':
      priority = 9;
      color = Colors.blueGrey[700]!;
      break;
    default:
      priority = 99;
      color = Colors.grey[400]!;
  }
  return {'priority': priority, 'color': color};
}

class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final weatherDataState = context.watch<WeatherDataState>();
    final alerts = weatherDataState.alerts;

    // Use selectedLocationName for display, fallback to a prompt
    final locationNameToDisplay = weatherDataState.selectedLocationName ?? '查詢地點...';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: SizedBox(
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: Icon(Icons.search, size: 28.0, color: Colors.black87),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddLocationScreen()),
                  );
                },
              ),
            ),
            Center(
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddLocationScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(8.0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                  child: Text(
                    locationNameToDisplay,
                    style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            if (!kIsWeb)
              Align(
                alignment: Alignment.centerRight,
                child: Builder(
                  builder: (context) {
                    final bool isLoading = weatherDataState.isLoading;
                    final bool hasAlerts = alerts.isNotEmpty;

                    if (isLoading) {
                      // 狀態一：載入中
                      return const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.0), // 調整邊距以對齊
                        child: Icon(Icons.warning_amber_rounded, size: 28, color: Colors.grey),
                      );
                    } else if (hasAlerts) {
                      // 狀態三：有警報
                      return Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          IconButton(
                            icon: Icon(Icons.warning_amber_rounded, size: 28, color: Theme.of(context).colorScheme.error),
                            tooltip: '警特報',
                            onPressed: () => _showWeatherAlerts(context, alerts),
                          ),
                          Positioned(
                            right: 4,
                            top: 4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                alerts.length.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        ],
                      );
                    } else {
                      // 狀態二：無警報
                      return IconButton(
                        icon: Icon(Icons.warning_amber_rounded, size: 28, color: Colors.grey[400]),
                        tooltip: '目前無警特報',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('目前無警特報'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      );
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showWeatherAlerts(BuildContext context, List<WeatherAlert> alerts) {
    // 排序
    alerts.sort((a, b) {
      final aPriority = _getAlertStyle(a.title)['priority'] as int;
      final bPriority = _getAlertStyle(b.title)['priority'] as int;
      return aPriority.compareTo(bPriority);
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(12.0, 16.0, 12.0, 0),
        contentPadding: const EdgeInsets.fromLTRB(12.0, 16.0, 12.0, 12.0),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        title: Row(
          children: [
            const SizedBox(width: 10),
            Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 10),
            const Text('警特報'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final alert = alerts[index];
              final formattedTime = DateFormat('M/dd HH:mm').format(alert.issuedTime.toLocal());
              final alertStyle = _getAlertStyle(alert.title);
              final alertColor = alertStyle['color'] as Color;

              return Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 2.0),
                  decoration: BoxDecoration(
                    color: Colors.white, // 使用白色背景
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border(
                      left: BorderSide(
                        color: alertColor.withOpacity(0.7), // 加入透明度
                        width: 5,
                      ),
                    ),
                  ),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formattedTime,
                          style: TextStyle(fontSize: 12.0, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                        child: Text(
                          alert.description,
                          textAlign: TextAlign.justify,
                          style: const TextStyle(height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('關閉'),
          ),
        ],
      ),
    );
  }
}
