import 'package:flutter/material.dart';

class HealthRecommendationsDialog extends StatelessWidget {
  final Map recommendations;

  const HealthRecommendationsDialog({Key? key, required this.recommendations})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final categories = {
      'children': 'Children',
      'elderly': 'Elderly',
      'pregnantWomen': 'Pregnant Women',
      'asthmatic': 'Asthmatic Individuals',
      'generalPublic': 'General Public',
    };

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 12,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
          maxWidth: 400,
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Health Recommendations',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...categories.entries.map((entry) {
                      final key = entry.key;
                      final title = entry.value;

                      if (recommendations[key] == null)
                        return const SizedBox.shrink();

                      final List recs =
                          recommendations[key] is List
                              ? recommendations[key]
                              : [recommendations[key].toString()];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                                color: Colors.blueGrey[800],
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...recs.map(
                              (rec) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(top: 6),
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: Colors.blueAccent,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        rec.toString(),
                                        style: TextStyle(
                                          fontSize: 15,
                                          height: 1.4,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),

            // Close button top right
            Positioned(
              right: 0,
              top: 0,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.grey[600]),
                splashRadius: 20,
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
