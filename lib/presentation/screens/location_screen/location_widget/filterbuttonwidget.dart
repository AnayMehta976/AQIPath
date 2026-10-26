import 'package:aqi_app/constants/color_constant.dart';
import 'package:aqi_app/utils/utils.dart';
import 'package:flutter/material.dart';
import '../location_bloc/location_event.dart';

class FilterRowWidget extends StatefulWidget {
  final int initialfilter;
  final Function(RouteFilterType?) onFilterSelected;

  const FilterRowWidget({
    Key? key,
    required this.onFilterSelected,
    required this.initialfilter,
  }) : super(key: key);

  @override
  State<FilterRowWidget> createState() => _FilterRowWidgetState();
}

class _FilterRowWidgetState extends State<FilterRowWidget> {
  RouteFilterType? selectedFilter;

  void _handleTap(RouteFilterType type) {
    setState(() {
      // Toggle filter if same tapped again
      selectedFilter = selectedFilter == type ? null : type;
    });

    widget.onFilterSelected(selectedFilter);
  }

  @override
  void initState() {
    if (widget.initialfilter != -1) {
      if (widget.initialfilter == 2) {
        _handleTap(RouteFilterType.fastest);
      } else if (widget.initialfilter == 0) {
        _handleTap(RouteFilterType.lowAqi);
      }
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _filterButton("LOW AQI", Colors.green, RouteFilterType.lowAqi),
        _filterButton("Average AQI", Colors.amber, RouteFilterType.averageAqi),
        _filterButton("Fast route", Colors.redAccent, RouteFilterType.fastest),
      ],
    );
  }

  Widget _filterButton(String label, Color color, RouteFilterType type) {
    final isSelected = selectedFilter == type;

    return GestureDetector(
      onTap: () => _handleTap(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          // ignore: deprecated_member_use
          color: isSelected ? color : color.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            if (isSelected)
              Icon(Icons.check, color: COLOR_CONST.cardShadowColor),
            if (isSelected) 2.toSpace,
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
