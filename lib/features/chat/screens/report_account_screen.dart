import 'package:flutter/material.dart';

import 'package:bumble/core/services/safety_service.dart';
import 'package:bumble/core/theme/app_theme.dart';

class ReportAccountScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String? matchId;
  final String? messageId;
  const ReportAccountScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    this.matchId,
    this.messageId,
  });
  @override
  State<ReportAccountScreen> createState() => _ReportAccountScreenState();
}

class _ReportAccountScreenState extends State<ReportAccountScreen> {
  final _details = TextEditingController();
  String _reason = SafetyService.reportReasons.first;
  bool _alsoBlock = false;
  bool _sending = false;
  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_reason == 'Lainnya' && _details.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jelaskan alasan laporanmu.')),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      await SafetyService().reportUser(
        otherUid: widget.otherUserId,
        reason: _reason,
        details: _details.text,
        matchId: widget.matchId,
        messageId: widget.messageId,
        alsoBlock: _alsoBlock,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Laporan tersimpan. Terima kasih.')),
        );
        Navigator.pop(context, _alsoBlock);
      }
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Laporan gagal dikirim. Coba lagi.')),
        );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: kBumbleYellow,
      title: const Text('Report akun'),
    ),
    backgroundColor: Colors.white,
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Laporkan ${widget.otherUserName}',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        const Text(
          'Pilih alasan yang paling sesuai. Identitas pelapor tidak ditampilkan kepada akun tersebut.',
          style: TextStyle(color: Colors.black54),
        ),
        if (widget.messageId != null)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'Laporan ini menyertakan referensi pesan yang kamu pilih.',
            ),
          ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: SafetyService.reportReasons
              .map(
                (reason) => ChoiceChip(
                  label: Text(reason),
                  selected: _reason == reason,
                  selectedColor: kBumbleYellow,
                  onSelected: _sending
                      ? null
                      : (_) => setState(() => _reason = reason),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _details,
          enabled: !_sending,
          maxLines: 4,
          maxLength: 1000,
          decoration: InputDecoration(
            labelText: 'Ceritakan apa yang terjadi',
            hintText: 'Tambahkan detail (opsional, wajib untuk Lainnya)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Block akun ini juga'),
          subtitle: const Text(
            'Profil dan chat disembunyikan untuk kedua akun.',
          ),
          value: _alsoBlock,
          activeTrackColor: kBumbleYellow,
          onChanged: _sending
              ? null
              : (value) => setState(() => _alsoBlock = value),
        ),
        const SizedBox(height: 24),
        FilledButton(
          style: bumbleButtonStyle(),
          onPressed: _sending ? null : _submit,
          child: Text(_sending ? 'Mengirim...' : 'Kirim laporan'),
        ),
      ],
    ),
  );
}
