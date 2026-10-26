import 'package:flutter/material.dart';

class ExpandableText extends StatefulWidget {
  const ExpandableText({
    super.key,
    required this.text,
    this.maxLines = 3,
    this.style,
  });

  final String text;
  final int maxLines;
  final TextStyle? style;

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _isExpanded =
      false; // This state is not directly used for expansion, but for future potential.
  bool _isClamped =
      false; // Indicates if the text is currently clamped (overflowing its maxLines)

  @override
  void initState() {
    super.initState();
    // Schedule a post-frame callback to check if text is clamped
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTextClamping();
    });
  }

  // This method checks if the text exceeds the given maxLines
  void _checkTextClamping() {
    final textPainter = TextPainter(
      text: TextSpan(
        text: widget.text,
        style: widget.style ?? Theme.of(context).textTheme.bodyMedium,
      ),
      maxLines: widget.maxLines,
      textDirection: TextDirection.ltr, // Or based on locale
    );

    textPainter.layout(
      maxWidth: MediaQuery.of(context).size.width * 0.8,
    ); // Adjust multiplier as needed or use LayoutBuilder

    // If the text has exceeded the maxLines, then it is clamped.
    if (textPainter.didExceedMaxLines) {
      setState(() {
        _isClamped = true;
      });
    }
  }

  // Shows the full text in a dialog
  void _showFullTextDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'Full Text',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
          ),
          content: SingleChildScrollView(
            child: Text(
              widget.text,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text(
                'Close',
                style: TextStyle(
                  color: Colors.indigo,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textStyle =
        widget.style ??
        Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.black);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        LayoutBuilder(
          builder: (context, constraints) {
            final textPainter = TextPainter(
              text: TextSpan(text: widget.text, style: textStyle),
              maxLines: widget.maxLines,
              textDirection: TextDirection.ltr, // Or determine dynamically
            );

            // Perform layout to get metrics
            textPainter.layout(maxWidth: constraints.maxWidth);

            // Update _isClamped state based on current layout
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _isClamped != textPainter.didExceedMaxLines) {
                setState(() {
                  _isClamped = textPainter.didExceedMaxLines;
                });
              }
            });

            return Text(
              widget.text,
              maxLines: widget.maxLines,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
            );
          },
        ),
        if (_isClamped)
          GestureDetector(
            onTap: _showFullTextDialog,
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Show More',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
