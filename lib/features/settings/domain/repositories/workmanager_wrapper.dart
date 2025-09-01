import 'package:workmanager/workmanager.dart';

class WorkmanagerWrapper {
  Future<void> registerPeriodicTask(
    String uniqueName,
    String taskName, {
    Duration? frequency,
    // --- START OF MODIFICATION ---
    // Added the 'constraints' parameter to match the real Workmanager method.
    // This allows our repository to pass the constraints through the wrapper.
    Constraints? constraints,
    // --- END OF MODIFICATION ---
  }) {
    return Workmanager().registerPeriodicTask(
      uniqueName,
      taskName,
      frequency: frequency,
      // Pass the received constraints to the real method.
      constraints: constraints,
    );
  }

  Future<void> registerOneOffTask(String uniqueName, String taskName) {
    return Workmanager().registerOneOffTask(uniqueName, taskName);
  }

  Future<void> cancelByUniqueName(String uniqueName) {
    return Workmanager().cancelByUniqueName(uniqueName);
  }
}
