import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pakeaja/core/constants/app_constants.dart';
import 'package:pakeaja/core/providers/service_providers.dart';
import 'package:pakeaja/core/theme/app_theme.dart';
import 'package:pakeaja/core/widgets/custom_button.dart';
import 'package:pakeaja/data/models/cloth_model.dart';
import 'package:pakeaja/features/auth/providers/auth_provider.dart' show authStateProvider;
import 'package:pakeaja/features/wardrobe/providers/wardrobe_provider.dart';

class AddClothScreen extends ConsumerStatefulWidget {
  const AddClothScreen({super.key});

  @override
  ConsumerState<AddClothScreen> createState() => _AddClothScreenState();
}

class _AddClothScreenState extends ConsumerState<AddClothScreen> {
  File? _image;
  Uint8List? _imageBytes;
  String? _error;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();

  ClothCategory _category = ClothCategory.top;
  String _color = 'black';
  ClothStyle _style = ClothStyle.casual;
  ClothWeather _weather = ClothWeather.cool;

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool fromCamera) async {
    final imageService = ref.read(imageServiceProvider);
    final result = fromCamera
        ? await imageService.pickFromCamera()
        : await imageService.pickFromGallery();

    if (result.bytes != null) {
      setState(() {
        _image = result.image;
        _imageBytes = result.bytes;
        _error = null;
      });
      // Auto-focus ke nama
      FocusScope.of(context).nextFocus();
    } else if (result.error != null) {
      setState(() => _error = result.error);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageBytes == null) {
      setState(() => _error = 'Tambahkan foto pakaian terlebih dahulu.');
      return;
    }

    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final cloth = ClothModel(
      id: '', // akan digenerate di repository
      name: _nameController.text.trim(),
      category: _category,
      color: _color,
      styles: [_style],
      weather: _weather,
      imageUrl: '',
      createdAt: DateTime.now(),
    );

    final success = await ref.read(addClothProvider.notifier).addCloth(
          uid: user.uid,
          cloth: cloth,
          image: _image,
          imageBytes: _imageBytes,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pakaian berhasil ditambahkan.'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      context.pop();
    } else {
      final state = ref.read(addClothProvider);
      setState(() => _error = state.error ?? 'Gagal menyimpan pakaian.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final addState = ref.watch(addClothProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Pakaian')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image preview / picker
                _buildImagePicker(),
                const SizedBox(height: 16),

                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_error!,
                        style: const TextStyle(color: AppTheme.errorColor)),
                  ),
                  const SizedBox(height: 16),
                ],

                // Nama
                TextFormField(
                  controller: _nameController,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Nama pakaian wajib diisi';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Nama Pakaian',
                    hintText: 'Contoh: Kemeja Putih',
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                ),
                const SizedBox(height: 16),

                // Kategori
                const Text('Kategori',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ClothCategory.values.map((cat) {
                    return ChoiceChip(
                      label: Text(cat.label),
                      selected: _category == cat,
                      onSelected: (_) => setState(() => _category = cat),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Warna
                const Text('Warna',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final entry in AppConstants.clothColors.entries)
                      ChoiceChip(
                        label: Text(entry.value),
                        selected: _color == entry.key,
                        onSelected: (_) =>
                            setState(() => _color = entry.key),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Gaya
                const Text('Gaya',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ClothStyle.values.map((s) {
                    return ChoiceChip(
                      label: Text(s.label),
                      selected: _style == s,
                      onSelected: (_) => setState(() => _style = s),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Cuaca
                const Text('Cuaca',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ClothWeather.values.map((w) {
                    return ChoiceChip(
                      label: Text(w.label),
                      selected: _weather == w,
                      onSelected: (_) => setState(() => _weather = w),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Catatan opsional
                TextField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Catatan (opsional)',
                    hintText: 'Contoh: Cocok untuk acara resmi',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 24),

                // Save button
                CustomButton(
                  text: 'Simpan Pakaian',
                  onPressed: addState.isLoading ? null : _save,
                  isLoading: addState.isLoading,
                  icon: Icons.check,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    if (_imageBytes != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.memory(
              _imageBytes!,
              height: 240,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              children: [
                IconButton.filledTonal(
                  onPressed: _showImageSourceDialog,
                  icon: const Icon(Icons.edit, size: 20),
                  tooltip: 'Ganti Foto',
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: () => setState(() {
                    _image = null;
                    _imageBytes = null;
                  }),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.errorColor,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.delete_outline, size: 20),
                  tooltip: 'Hapus Foto',
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          const Icon(Icons.add_a_photo_outlined,
              size: 44, color: AppTheme.primaryColor),
          const SizedBox(height: 8),
          const Text(
            'Tambahkan Foto Pakaian',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ambil langsung dengan kamera atau pilih dari galeri',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(true),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Kamera'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _pickImage(false),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Galeri'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Tambah Pakaian',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt,
                      color: AppTheme.primaryColor),
                ),
                title: const Text('Kamera'),
                subtitle: const Text('Ambil foto langsung'),
                onTap: () {
                  context.pop();
                  _pickImage(true);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library,
                      color: AppTheme.primaryColor),
                ),
                title: const Text('Galeri'),
                subtitle: const Text('Pilih dari galeri'),
                onTap: () {
                  context.pop();
                  _pickImage(false);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
