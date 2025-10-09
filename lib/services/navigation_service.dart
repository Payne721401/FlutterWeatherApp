import 'package:flutter/widgets.dart';

// This GlobalKey is used to access the Navigator from outside the widget tree,
// for example, from the NetworkAwareWidget.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
