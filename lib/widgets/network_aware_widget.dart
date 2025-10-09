import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // MODIFICATION: Import Cupertino widgets
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:provider/provider.dart';
import '../services/connectivity_service.dart';

// --- FINAL MODIFICATION: Import the new navigation service ---
import '../services/navigation_service.dart';

class NetworkAwareWidget extends StatefulWidget {
  final Widget child;

  const NetworkAwareWidget({
    super.key,
    required this.child,
  });

  @override
  State<NetworkAwareWidget> createState() => _NetworkAwareWidgetState();
}

class _NetworkAwareWidgetState extends State<NetworkAwareWidget> {
  bool _isDialogShowing = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  static const String _logName = 'NetworkAwareWidget';

  @override
  void reassemble() {
    super.reassemble();
    log('Hot Reload detected. Resetting _isDialogShowing state to false.', name: _logName);
    _isDialogShowing = false;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeConnectivityListener();
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      log('Navigator context is not available, skipping UI update.', name: _logName);
      return;
    }

    final bool hasInternet = results.any(
      (result) =>
          result != ConnectivityResult.none &&
          result != ConnectivityResult.bluetooth,
    );
    log('Handling connectivity change. HasInternet: $hasInternet. Current _isDialogShowing: $_isDialogShowing', name: _logName);

    if (!hasInternet && !_isDialogShowing) {
      log('Condition met: No internet and no dialog showing. Showing dialog.', name: _logName);
      setState(() {
        _isDialogShowing = true;
      });

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          // --- MODIFICATION: Use CupertinoAlertDialog for an iOS-style dialog ---
          return CupertinoAlertDialog(
            title: const Text('無網路連線'),
            content: const Text('請檢查您的網路連線並重試。'),
            actions: <Widget>[
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('確定'),
                onPressed: () {
                  Navigator.of(dialogContext, rootNavigator: true).pop();
                },
              ),
            ],
          );
        },
      ).then((_) {
        log('Dialog has been dismissed.', name: _logName);
        if (mounted) {
          setState(() {
            _isDialogShowing = false;
          });
        }
      });
    } else if (hasInternet && _isDialogShowing) {
      log('Condition met: Internet is back and dialog is showing. Popping dialog.', name: _logName);
      Navigator.of(context, rootNavigator: true).pop();
    } else {
      log('Condition not met for UI change. Doing nothing.', name: _logName);
    }
  }

  Future<void> _initializeConnectivityListener() async {
    if (!mounted) return;
    final connectivityService = Provider.of<ConnectivityService>(context, listen: false);

    try {
      final initialResults = await connectivityService.checkConnectivity();
      log('Initial connectivity check results: $initialResults', name: _logName);
      _handleConnectivityChange(initialResults);
    } catch (e) {
      log('Error during initial connectivity check: $e', name: _logName);
      _handleConnectivityChange([ConnectivityResult.none]);
    }

    _connectivitySubscription =
        connectivityService.connectivityStream.listen((List<ConnectivityResult> results) {
      log('Listener received connectivity results from stream: $results', name: _logName);
      _handleConnectivityChange(results);
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
