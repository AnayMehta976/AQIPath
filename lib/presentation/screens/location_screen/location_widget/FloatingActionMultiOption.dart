import 'package:aqi_app/constants/color_constant.dart';
import 'package:aqi_app/constants/font_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

class TravelModeFAB extends StatefulWidget {
  final showingfrombtmbar;
  const TravelModeFAB({super.key, required this.showingfrombtmbar});

  @override
  State<TravelModeFAB> createState() => _TravelModeFABState();
}

class _TravelModeFABState extends State<TravelModeFAB> {
  String? selectedMode = 'driving';

  IconData get mainFABIcon {
    switch (selectedMode) {
      case 'driving':
        return (Icons.directions_car);
      case 'walking':
        return Icons.directions_walk;
      case 'cycling':
        return Icons.directions_bike;
      default:
        return Icons.directions_car; // default icon when no mode is selected
    }
  }

  Color get mainFABColor {
    return selectedMode == null ? Colors.green : COLOR_CONST.backgroundColor;
  }

  @override
  Widget build(BuildContext context) {
    return SpeedDial(
      // icon: mainFABIcon,
      backgroundColor: mainFABColor,
      overlayColor: Colors.white,
      overlayOpacity: 0.3,
      buttonSize: widget.showingfrombtmbar ? Size(50, 50) : Size(55, 55),
      shape:
          widget.showingfrombtmbar
              ? ContinuousRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              )
              : CircleBorder(),
      children: [
        SpeedDialChild(
          backgroundColor:
              selectedMode == 'cycling'
                  ? Colors.deepPurple
                  : COLOR_CONST.discountColor,
          child: Icon(Icons.directions_bike, color: Colors.white),
          label: 'Cycling',
          labelStyle: FONT_CONST.MEDIUM_DEFAULT_16.copyWith(
            color: Colors.black,
          ),
          onTap: () {
            setState(() {
              selectedMode = 'cycling';
            });
            showWalkCycleDialog(context, 'cycle');
          },
        ),
        SpeedDialChild(
          backgroundColor:
              selectedMode == 'driving'
                  ? Colors.deepPurple
                  : COLOR_CONST.discountColor,
          child: Icon(Icons.directions_car, color: Colors.white),
          label: 'Driving',
          labelStyle: FONT_CONST.MEDIUM_DEFAULT_16.copyWith(
            color: Colors.black,
          ),
          onTap: () {
            setState(() {
              selectedMode = 'driving';
            });
          },
        ),
        SpeedDialChild(
          backgroundColor:
              selectedMode == 'walking'
                  ? Colors.deepPurple
                  : COLOR_CONST.discountColor,
          child: Icon(Icons.directions_walk, color: Colors.white),
          label: 'Walking',
          labelStyle: FONT_CONST.MEDIUM_DEFAULT_16.copyWith(
            color: Colors.black,
          ),
          onTap: () {
            setState(() {
              selectedMode = 'walking';
            });
            showWalkCycleDialog(context, 'walk');
          },
        ),
      ],
      // icon: mainFABIcon,
      child: Icon(mainFABIcon, color: Colors.white),
    );
  }

  Future<void> showWalkCycleDialog(BuildContext context, String mode) async {
    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  mode == 'walk'
                      ? Icons.directions_walk
                      : Icons.directions_bike,
                  size: 48,
                  color: Colors.green,
                ),
                const SizedBox(height: 12),
                Text(
                  'How do you want to ${mode == 'walk' ? 'walk' : 'cycle'}?',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                OptionCard(
                  icon: Icons.auto_awesome,
                  title: 'Find the best place using AI',
                  description:
                      'Analyze routes in a 5 km radius based on AQI, traffic & weather.',
                  onTap: () {

                    Navigator.pop(context);

                    debugPrint('🔍 AI smart route selected for $mode');
                    
                    // TODO: Call your AI route finder logic
                  },
                ),
                const SizedBox(height: 16),
                OptionCard(
                  icon: Icons.edit_location_alt,
                  title: 'I know the place',
                  description:
                      'Write your destination manually. We\'ll analyze AQI, traffic & weather for your route.',
                  onTap: () {
                    Navigator.pop(context);
                    debugPrint('✏️ Manual destination selected for $mode');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const OptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 36, color: Colors.blueAccent),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
