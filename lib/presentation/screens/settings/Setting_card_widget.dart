import 'package:flutter/material.dart';

class SettingsCard extends StatelessWidget {
  final VoidCallback onPrivacyPolicy;
  final VoidCallback onAbout;
  final VoidCallback onRemoveAccount;

  const SettingsCard({
    Key? key,
    required this.onPrivacyPolicy,
    required this.onAbout,
    required this.onRemoveAccount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),

      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildButton(
              context,
              title: "Privacy Policy",
              icon: Icons.privacy_tip_outlined,
              onTap: onPrivacyPolicy,
            ),
            // const Divider(),
            // _buildButton(
            //   context,
            //   title: "About",
            //   icon: Icons.info_outline,
            //   onTap: onAbout,
            // ),
            const Divider(),
            _buildButton(
              context,
              title: "Forget & Remove Account",
              icon: Icons.delete_forever_outlined,
              onTap: onRemoveAccount,
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Theme.of(context).primaryColor),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: color ?? Colors.black,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
