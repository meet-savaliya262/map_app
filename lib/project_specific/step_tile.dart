import 'package:flutter/material.dart';

class StepTileWidget extends StatelessWidget {
  final String instruction;
  final String distance;
  final String maneuver;

  const StepTileWidget({
    super.key,
    required this.instruction,
    required this.distance,
    required this.maneuver,
  });

  IconData getTurnIcon() {
    switch (maneuver) {
      case "turn-right": return Icons.turn_right;
      case "turn-left": return Icons.turn_left;
      case "turn-slight-right": return Icons.turn_slight_right;
      case "turn-slight-left": return Icons.turn_slight_left;
      case "roundabout-right": return Icons.roundabout_right;
      case "roundabout-left": return Icons.roundabout_left;
      case "uturn-right": return Icons.u_turn_right;
      case "uturn-left": return Icons.u_turn_left;
      default: return Icons.navigation_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(getTurnIcon(), size: 28),
      title: Text(instruction),
      subtitle: Text(distance),
    );
  }
}