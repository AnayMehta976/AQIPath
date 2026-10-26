import 'package:flutter/material.dart';
import 'package:gauge_indicator/gauge_indicator.dart';

class RadialGaugeVIEW extends StatelessWidget {
  final double maxvalue;
  final double cvalue;
  RadialGaugeVIEW({Key? key, required this.maxvalue, required this.cvalue})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      height: 100,
      child: AnimatedRadialGauge(
        radius: 70,
        builder:
            (context, _, value) => RadialGaugeLabel(
              style: TextStyle(
                color: const Color(0xFF002E5F),

                fontWeight: FontWeight.bold,
              ),
              value: cvalue,
            ),
        duration: const Duration(milliseconds: 2000),
        curve: Curves.elasticOut,
        value: cvalue,
        axis: GaugeAxis(
          min: 0,
          max: maxvalue,
          degrees: 20,
          pointer: GaugePointer.needle(
            width: 16,
            height: 100,
            borderRadius: 16,
            color: Color(0xFF193663),
          ),

          progressBar: const GaugeProgressBar.rounded(color: Color(0xFFB4C2F8)),
          transformer: const GaugeAxisTransformer.colorFadeIn(
            interval: Interval(0.0, 0.3),
            background: Color(0xFFD9DEEB),
          ),
          style: GaugeAxisStyle(
            // thickness: _controller.thickness,
            // background: _controller.backgroundColor,
            // segmentSpacing: _controller.spacing,
            blendColors: false,
          ),

          /// Define axis segments (optional).
          segments: [
            GaugeSegment(
              from: 0,
              to: maxvalue / 3,
              color: Color(0xFFD9DEEB),
              cornerRadius: Radius.zero,
            ),
            GaugeSegment(
              from: maxvalue / 3,
              to: maxvalue / 2,
              color: Color(0xFFD9DEEB),
              cornerRadius: Radius.zero,
            ),
            GaugeSegment(
              from: maxvalue / 2,
              to: maxvalue / 2,
              color: Color(0xFFD9DEEB),
              cornerRadius: Radius.zero,
            ),
          ],
        ),
      ),
    );
  }
}
