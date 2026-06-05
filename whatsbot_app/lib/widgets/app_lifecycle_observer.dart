import 'package:flutter/widgets.dart';

import '../services/message_alerts_service.dart';

/// Propaga primer plano / segundo plano al servicio de alertas.
class AppLifecycleObserver extends StatefulWidget {
  const AppLifecycleObserver({super.key, required this.child});

  final Widget child;

  @override
  State<AppLifecycleObserver> createState() => _AppLifecycleObserverState();
}

class _AppLifecycleObserverState extends State<AppLifecycleObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    messageAlerts.setAppInForeground(true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    messageAlerts.setAppInForeground(
      state == AppLifecycleState.resumed,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
