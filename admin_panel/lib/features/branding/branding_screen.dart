import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/clients_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/admin_scaffold.dart';

class BrandingScreen extends ConsumerStatefulWidget {
  const BrandingScreen({super.key});

  @override
  ConsumerState<BrandingScreen> createState() => _BrandingScreenState();
}

class _BrandingScreenState extends ConsumerState<BrandingScreen> {
  String? _selectedClientId;
  final _companyCtrl = TextEditingController();
  Color _primaryColor = const Color(0xFF3B82F6);
  String _logoUrl = '';
  Uint8List? _pendingLogo;
  String _pendingLogoExt = 'png';
  bool _saving = false;

  @override
  void dispose() {
    _companyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsProvider);

    return AdminScaffold(
      title: 'Branding',
      child: clientsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Erro: $e'),
        data: (clients) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Config panel
            Expanded(
              flex: 3,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedClientId,
                        decoration: const InputDecoration(labelText: 'Cliente'),
                        items: clients
                            .map((c) => DropdownMenuItem(
                                value: c.id, child: Text(c.name)))
                            .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          final c = clients.firstWhere((c) => c.id == v);
                          setState(() {
                            _selectedClientId = v;
                            _companyCtrl.text = c.companyName;
                            _logoUrl = c.logoUrl;
                            _pendingLogo = null;
                            try {
                              _primaryColor = Color(int.parse(
                                  c.primaryColor.replaceFirst('#', '0xFF')));
                            } catch (_) {}
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _companyCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Nome da empresa'),
                      ),
                      const SizedBox(height: 20),
                      Text('Cor primária',
                          style: Theme.of(context).textTheme.labelMedium),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _pickColor(context),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _primaryColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outline),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '#${_primaryColor.value.toRadixString(16).substring(2).toUpperCase()}',
                              style: const TextStyle(fontFamily: 'monospace'),
                            ),
                            const SizedBox(width: 8),
                            const Text('(toque para alterar)',
                                style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text('Logo',
                          style: Theme.of(context).textTheme.labelMedium),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _pickLogo,
                        icon: const Icon(Icons.upload_file, size: 18),
                        label: const Text('Seleccionar ficheiro'),
                      ),
                      if (_pendingLogo != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(_pendingLogo!,
                                height: 60, fit: BoxFit.contain),
                          ),
                        ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed:
                            (_selectedClientId != null && !_saving) ? _save : null,
                        child: _saving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Guardar'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),
            // Live preview
            Expanded(
              flex: 2,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Preview',
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 16),
                      _BrandingPreview(
                        companyName: _companyCtrl.text,
                        primaryColor: _primaryColor,
                        logoBytes: _pendingLogo,
                        logoUrl: _logoUrl,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _pickColor(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Escolher cor'),
        content: ColorPicker(
          pickerColor: _primaryColor,
          onColorChanged: (c) => setState(() => _primaryColor = c),
        ),
        actions: [
          FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _pickLogo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    final ext = (file.extension ?? 'png').toLowerCase();
    setState(() {
      _pendingLogo = file.bytes!;
      _pendingLogoExt = ext;
    });
  }

  Future<void> _save() async {
    if (_selectedClientId == null) return;
    setState(() => _saving = true);
    try {
      String? uploadedUrl;
      if (_pendingLogo != null) {
        uploadedUrl = await StorageService()
            .uploadLogo(_selectedClientId!, _pendingLogo!, _pendingLogoExt);
        setState(() {
          _logoUrl = uploadedUrl!;
          _pendingLogo = null;
        });
      }
      final hex =
          '#${_primaryColor.value.toRadixString(16).substring(2).toUpperCase()}';
      await FirestoreService().updateBranding(
        _selectedClientId!,
        logoUrl: uploadedUrl,
        primaryColor: hex,
        companyName: _companyCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Guardado')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _BrandingPreview extends StatelessWidget {
  final String companyName;
  final Color primaryColor;
  final Uint8List? logoBytes;
  final String logoUrl;

  const _BrandingPreview({
    required this.companyName,
    required this.primaryColor,
    required this.logoBytes,
    required this.logoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      overflow: Overflow.clip,
      child: Column(
        children: [
          // Mock header
          Container(
            color: primaryColor,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                if (logoBytes != null)
                  Image.memory(logoBytes!, height: 28, fit: BoxFit.contain)
                else if (logoUrl.isNotEmpty)
                  Image.network(logoUrl, height: 28, fit: BoxFit.contain)
                else
                  Container(
                    height: 28,
                    width: 28,
                    color: Colors.white24,
                    child: const Icon(Icons.image, color: Colors.white54, size: 18),
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    companyName.isEmpty ? 'Empresa' : companyName,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Mock content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  height: 12,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 160,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: primaryColor),
                  onPressed: null,
                  child: const Text('Enviar mensagem'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
