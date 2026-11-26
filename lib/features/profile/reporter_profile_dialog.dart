import 'package:flutter/material.dart';

import '../../core/storage/app_prefs.dart';
import '../../core/theme/app_theme.dart';
import 'reporter_profile.dart';

/// Menampilkan formulir profil pelapor dan menyimpannya.
///
/// Mengembalikan profil yang disimpan, atau null bila dilewati. Melewati
/// formulir tetap menandai formulir sudah ditampilkan, sehingga tidak muncul
/// lagi otomatis. Profil dapat diubah dari menu Pengaturan.
Future<ReporterProfile?> showReporterProfileDialog(
  BuildContext context, {
  bool firstTime = false,
}) async {
  final ReporterProfile current = await AppPrefs.reporterProfile();
  if (!context.mounted) return null;
  final ReporterProfile? result = await showDialog<ReporterProfile>(
    context: context,
    barrierDismissible: !firstTime,
    builder: (_) => _ReporterProfileDialog(
      initial: firstTime && current.isEmpty
          ? const ReporterProfile(datasetConsent: true)
          : current,
      firstTime: firstTime,
    ),
  );
  if (result != null) {
    await AppPrefs.saveReporterProfile(result);
  } else {
    await AppPrefs.markProfileAsked();
  }
  return result;
}

class _ReporterProfileDialog extends StatefulWidget {
  const _ReporterProfileDialog({required this.initial, required this.firstTime});

  final ReporterProfile initial;
  final bool firstTime;

  @override
  State<_ReporterProfileDialog> createState() => _ReporterProfileDialogState();
}

class _ReporterProfileDialogState extends State<_ReporterProfileDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: widget.initial.name);
  late final TextEditingController _email =
      TextEditingController(text: widget.initial.email);
  late final TextEditingController _phone =
      TextEditingController(text: widget.initial.phone);
  late bool _consent = widget.initial.datasetConsent;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      ReporterProfile(
        name: _name.text,
        email: _email.text,
        phone: _phone.text,
        datasetConsent: _consent,
      ).normalized(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.base100,
      title: Text(widget.firstTime ? 'Kenalan dulu, yuk' : 'Profil pelapor'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nama dan kontak disertakan pada laporan yang Anda kirim, agar '
                'kurator dapat menghubungi Anda bila perlu konfirmasi.',
                style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.mutedGrey),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                maxLength: ReporterProfile.maxNameLength,
                decoration: const InputDecoration(
                  labelText: 'Nama',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                validator: ReporterProfile.validateName,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Email (opsional)',
                  border: OutlineInputBorder(),
                ),
                validator: ReporterProfile.validateEmail,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Nomor telepon / WhatsApp (opsional)',
                  hintText: '08xxxxxxxxxx',
                  border: OutlineInputBorder(),
                ),
                validator: ReporterProfile.validatePhone,
                onFieldSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _consent,
                onChanged: (v) => setState(() => _consent = v),
                title: const Text(
                  'Kirim otomatis foto flora non-endemik',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Foto hasil identifikasi dipakai sebagai dataset untuk melatih '
                  'model. Foto flora tidak dikenali dan temuan endemik selalu '
                  'meminta konfirmasi lebih dulu.',
                  style: TextStyle(fontSize: 12, height: 1.35),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.firstTime ? 'Lewati' : 'Batal'),
        ),
        FilledButton(onPressed: _save, child: const Text('Simpan')),
      ],
    );
  }
}
