import 'package:flutter/material.dart';

import 'package:bumble/core/theme/app_theme.dart';
import 'package:bumble/features/discovery/models/discovery_filter.dart';
import 'package:bumble/features/discovery/services/discovery_service.dart';

class DiscoveryFilterScreen extends StatefulWidget {
  final DiscoveryFilter initial;
  const DiscoveryFilterScreen({super.key, required this.initial});
  @override
  State<DiscoveryFilterScreen> createState() => _DiscoveryFilterScreenState();
}

class _DiscoveryFilterScreenState extends State<DiscoveryFilterScreen> {
  late RangeValues _ages;
  late String _gender;
  late String _lookingFor;
  late bool _verifiedOnly;
  late final TextEditingController _location;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    _location = TextEditingController(text: widget.initial.location);
    _load(widget.initial);
  }

  void _load(DiscoveryFilter value) {
    _ages = RangeValues(value.minAge.toDouble(), value.maxAge.toDouble());
    _gender = value.gender;
    _lookingFor = value.lookingFor;
    _verifiedOnly = value.verifiedOnly;
    _location.text = value.location;
  }

  @override
  void dispose() {
    _location.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await DiscoveryService().saveFilter(
        DiscoveryFilter(
          minAge: _ages.start.round(),
          maxAge: _ages.end.round(),
          gender: _gender,
          lookingFor: _lookingFor,
          location: _location.text,
          verifiedOnly: _verifiedOnly,
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Filter gagal disimpan. Coba lagi.')),
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: kBumbleYellow,
      title: const Text('Filter matching'),
    ),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Temukan yang sesuai denganmu',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text(
          'Preferensi ini berlaku di People dan tersimpan di akunmu.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 28),
        Text(
          'Umur: ${_ages.start.round()}–${_ages.end.round()} tahun',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        RangeSlider(
          values: _ages,
          min: 18,
          max: 100,
          divisions: 82,
          activeColor: Colors.black,
          inactiveColor: kBumbleYellow,
          labels: RangeLabels('${_ages.start.round()}', '${_ages.end.round()}'),
          onChanged: _saving ? null : (value) => setState(() => _ages = value),
        ),
        const SizedBox(height: 16),
        const Text(
          'Tampilkan',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: DiscoveryFilter.genderOptions
              .map(
                (value) => ChoiceChip(
                  label: Text(value),
                  selected: value == _gender,
                  selectedColor: kBumbleYellow,
                  onSelected: _saving
                      ? null
                      : (_) => setState(() => _gender = value),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _location,
          enabled: !_saving,
          maxLength: 100,
          decoration: InputDecoration(
            labelText: 'Kota / lokasi',
            hintText: 'Contoh: Jakarta',
            helperText:
                'Kosongkan untuk semua lokasi. Berdasarkan teks profil.',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Tujuan hubungan',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: DiscoveryFilter.relationshipOptions
              .map(
                (value) => ChoiceChip(
                  label: Text(value),
                  selected: value == _lookingFor,
                  selectedColor: kBumbleYellow,
                  onSelected: _saving
                      ? null
                      : (_) => setState(() => _lookingFor = value),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Hanya profil terverifikasi'),
          value: _verifiedOnly,
          activeTrackColor: kBumbleYellow,
          onChanged: _saving
              ? null
              : (value) => setState(() => _verifiedOnly = value),
        ),
        const SizedBox(height: 24),
        FilledButton(
          style: bumbleButtonStyle(),
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Menyimpan...' : 'Terapkan filter'),
        ),
        TextButton(
          onPressed: _saving
              ? null
              : () => setState(() => _load(const DiscoveryFilter())),
          child: const Text(
            'Reset pilihan',
            style: TextStyle(color: Colors.black),
          ),
        ),
      ],
    ),
  );
}
