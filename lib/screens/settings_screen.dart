import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _dateModeEnabled = true;
  bool _incognitoModeEnabled = false;
  bool _autoSpotlightEnabled = false;

  Future<void> _logOut() async {
    await AuthService().logout();
  }

  void _showUnavailable(String title) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$title belum tersedia.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(28, 16, 28, 34),
        children: [
          _SettingsTile(
            title: 'Type of connection',
            trailing: 'BFF',
            onTap: () => _showUnavailable('Type of connection'),
          ),
          const SizedBox(height: 14),
          _SettingsToggleTile(
            title: 'Date mode',
            value: _dateModeEnabled,
            onChanged: (value) => setState(() => _dateModeEnabled = value),
          ),
          const _Description(
            'Hide your profile in Date and just use BFF. If you do this, you\'ll lose your connections and chats in Date.',
          ),
          const SizedBox(height: 14),
          _SettingsTile(
            title: 'Snooze mode',
            onTap: () => _showUnavailable('Snooze mode'),
          ),
          const _Description(
            'Hide your profile temporarily, in all modes. You won\'t lose any connections or chats.',
          ),
          const SizedBox(height: 14),
          _SettingsToggleTile(
            title: 'Incognito Mode for Date',
            value: _incognitoModeEnabled,
            onChanged: (value) => setState(() => _incognitoModeEnabled = value),
          ),
          const _Description(
            'Only people you\'ve liked already, or like later, will see your profile. If you turn on Incognito Mode for Date, this won\'t apply across Bizz or BFF.',
          ),
          const SizedBox(height: 14),
          _SettingsToggleTile(
            title: 'Auto-Spotlight',
            value: _autoSpotlightEnabled,
            onChanged: (value) => setState(() => _autoSpotlightEnabled = value),
          ),
          const _Description(
            'We\'ll use Spotlight automatically to boost your profile when most people will see it',
          ),
          const SizedBox(height: 26),
          const _SectionTitle('Location'),
          const SizedBox(height: 14),
          _SettingsTile(
            title: 'Current location',
            trailing: 'Jakarta, ID',
            onTap: () => _showUnavailable('Current location'),
          ),
          const SizedBox(height: 14),
          _SettingsTile(
            title: 'Travel',
            leading: const _TravelIcon(),
            onTap: () => _showUnavailable('Travel'),
          ),
          const _Description(
            'Change your location to connect with people in other locations.',
          ),
          const SizedBox(height: 26),
          _SettingsTile(
            title: 'Video autoplay settings',
            onTap: () => _showUnavailable('Video autoplay settings'),
          ),
          const SizedBox(height: 14),
          _SettingsTile(
            title: 'Notification settings',
            onTap: () => _showUnavailable('Notification settings'),
          ),
          const SizedBox(height: 14),
          _SettingsTile(
            title: 'Legal information',
            onTap: () => _showUnavailable('Legal information'),
          ),
          const SizedBox(height: 14),
          _SettingsTile(
            title: 'Get help',
            onTap: () => _showUnavailable('Get help'),
          ),
          const SizedBox(height: 14),
          _SettingsTile(
            title: 'Security and Privacy',
            onTap: () => _showUnavailable('Security and Privacy'),
          ),
          const SizedBox(height: 34),
          OutlinedButton(
            onPressed: _logOut,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              side: const BorderSide(color: Colors.black, width: 1.2),
              foregroundColor: Colors.black,
            ),
            child: const Text(
              'Log out',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
          ),
          TextButton(
            onPressed: () => _showUnavailable('Delete account'),
            child: const Text(
              'Delete account',
              style: TextStyle(color: Colors.black, fontSize: 18),
            ),
          ),
          const SizedBox(height: 44),
          const Icon(Icons.hexagon_outlined, size: 32, color: Colors.black54),
          const SizedBox(height: 4),
          const Text(
            'Bumble',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black54,
              fontSize: 25,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Version 1.0.0\nCreated with love.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontSize: 16, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.title,
    required this.onTap,
    this.trailing,
    this.leading,
  });

  final String title;
  final String? trailing;
  final Widget? leading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        constraints: const BoxConstraints(minHeight: 74),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xffdddddd), width: 1.6),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 18)],
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: const TextStyle(fontSize: 17, color: Colors.black54),
              ),
            const SizedBox(width: 18),
            const Icon(Icons.arrow_forward_ios, size: 25),
          ],
        ),
      ),
    );
  }
}

class _SettingsToggleTile extends StatelessWidget {
  const _SettingsToggleTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 74),
      padding: const EdgeInsets.only(left: 32, right: 24),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xffdddddd), width: 1.6),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: Colors.black,
            activeThumbColor: Colors.white,
          ),
        ],
      ),
    );
  }
}

class _Description extends StatelessWidget {
  const _Description(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 10, 24, 0),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black54,
          fontSize: 16,
          height: 1.5,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.black54,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TravelIcon extends StatelessWidget {
  const _TravelIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: Colors.black,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.luggage, color: Colors.white, size: 21),
    );
  }
}
