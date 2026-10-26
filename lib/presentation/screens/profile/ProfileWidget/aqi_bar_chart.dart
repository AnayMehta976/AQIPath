import 'package:aqi_app/configs/size_config.dart';
import 'package:flutter/material.dart';

// 1. Data Model
class BarData {
  final String label;
  final int value;

  BarData(this.label, this.value);
}

class CustomBarChart extends StatelessWidget {
  final List data;
  final double maxYValue; // The maximum value on the Y-axis

  CustomBarChart({required this.data, required this.maxYValue});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.contain, // Adjust as per your layout needs
      child: SizedBox(
        width:
            SizeConfig.screenWidth * .97, // You might want to make this dynamic
        height:
            SizeConfig.screenHeight *
            0.23, // You might want to make this dynamic
        child: CustomPaint(painter: _BarChartPainter(data, maxYValue)),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List data;
  final double maxYValue;

  _BarChartPainter(this.data, this.maxYValue);
  Color getColorForAqi(int aqi) {
    if (aqi <= 50)
      return Colors.green;
    else if (aqi <= 100)
      return Colors.lightGreen;
    else if (aqi <= 200)
      return Colors.orange;
    else if (aqi <= 300)
      return Colors.red;
    else if (aqi <= 400)
      return Colors.purple;
    else
      return Colors.brown;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double chartWidth = size.width;
    final double chartHeight = size.height;

    // Define some padding/margins
    final double yAxisLabelWidth = 40.0; // Space for Y-axis labels
    final double xAxisLabelHeight = 30.0; // Space for X-axis labels
    final double barSpacing = 15.0; // Space between bars

    final double drawableWidth = chartWidth - yAxisLabelWidth;
    final double drawableHeight = chartHeight - xAxisLabelHeight;

    // Paint objects
    final Paint barPaint;

    final Paint axisPaint =
        Paint()
          ..color = Colors.grey[700]!
          ..strokeWidth = 1.0;

    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Draw Y-axis
    canvas.drawLine(
      Offset(yAxisLabelWidth, 0),
      Offset(yAxisLabelWidth, drawableHeight),
      axisPaint,
    );

    // Draw X-axis
    canvas.drawLine(
      Offset(yAxisLabelWidth, drawableHeight),
      Offset(chartWidth, drawableHeight),
      axisPaint,
    );

    // Calculate bar width
    final double totalBarWidth = drawableWidth - (data.length - 1) * barSpacing;
    final double barWidth = totalBarWidth / data.length;

    // Draw bars and X-axis labels
    for (int i = 0; i < data.length; i++) {
      final BarData bar = data[i];

      // Calculate bar height relative to drawableHeight
      final double barHeight = (bar.value / maxYValue) * drawableHeight;

      // Bar position
      final double x = yAxisLabelWidth + i * (barWidth + barSpacing);
      final double y = drawableHeight - barHeight;

      // Draw the bar
      canvas.drawRect(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        Paint()
          ..color = getColorForAqi(
            data[i].value.round(),
          ) // Adjust color as needed
          ..style = PaintingStyle.fill,
      );

      // Draw X-axis label
      textPainter.text = TextSpan(
        text: bar.label,
        style: TextStyle(color: Colors.black, fontSize: 12),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          x + (barWidth / 2) - (textPainter.width / 2),
          drawableHeight + 5,
        ),
      );
    }

    // Draw Y-axis labels (example for 0, 50, 100)
    List<double> yAxisValues = [
      0,
      50,
      100,
      200,
      300,
      500,
    ]; // Customize these based on your maxYValue
    for (double value in yAxisValues) {
      final double y = drawableHeight - (value / maxYValue) * drawableHeight;
      textPainter.text = TextSpan(
        text: value.toInt().toString(),
        style: TextStyle(color: Colors.black, fontSize: 12),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          yAxisLabelWidth - textPainter.width - 5,
          y - textPainter.height / 2,
        ),
      );
      canvas.drawLine(
        Offset(yAxisLabelWidth, y),
        Offset(yAxisLabelWidth + 5, y),
        axisPaint,
      ); // Tick mark
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    // Only repaint if the data or maxYValue changes
    return oldDelegate.data != data || oldDelegate.maxYValue != maxYValue;
  }
}
