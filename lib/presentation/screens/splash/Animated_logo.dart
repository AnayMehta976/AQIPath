import 'package:aqi_app/configs/size_config.dart';
import 'package:aqi_app/constants/font_constant.dart';
import 'package:aqi_app/constants/image_constant.dart';
import 'package:flutter/material.dart';

class AnimatedLogoSequence extends StatefulWidget {
  const AnimatedLogoSequence({super.key});

  @override
  State<AnimatedLogoSequence> createState() => _AnimatedLogoSequenceState();
}

class _AnimatedLogoSequenceState extends State<AnimatedLogoSequence>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _scale;
  late Animation<Offset> _slide;

  bool _animationDone = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    _scale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _animationDone = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: SizeConfig.screenHeight * .18),
        AnimatedBuilder(
          animation: _controller,
          builder: (_, __) {
            return Opacity(
              opacity: _opacity.value,
              child: Transform.scale(
                scale: _scale.value,
                child: SlideTransition(
                  position: _slide,
                  child: Image.asset(
                    IMAGECONST.APP_LOGO,
                    width: SizeConfig.defaultSize * 26,
                    height: SizeConfig.defaultSize * 13,
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            );
          },
        ),
        if (_animationDone) ...[
          SizedBox(height: SizeConfig.defaultSize * 5),
          Padding(
            padding: const EdgeInsets.only(right: 40),
            child: Text(
              "WELCOME TO AIR QUILITY INDEX",
              style: FONT_CONST.BOLD_DEFAULT_28.copyWith(
                height: 1.1,
                letterSpacing: 1.2,
              ),
            ),
          ),
          SizedBox(height: SizeConfig.defaultSize * 2),
          Text(
            "Track real-time air quality, get alerts, and stay safe with personalized tips based on your location.",
            style: FONT_CONST.REGULAR_DEFAULT,
          ),
          const Spacer(),
        ],
      ],
    );
  }
}
