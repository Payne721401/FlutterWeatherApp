import 'package:flutter/material.dart';

class WeatherCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const WeatherCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      margin: EdgeInsets.zero, // Let the parent ListView handle spacing
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      color: Colors.white,
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
