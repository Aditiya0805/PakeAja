import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pakeaja/core/constants/app_constants.dart';
import 'package:pakeaja/core/providers/service_providers.dart';
import 'package:pakeaja/core/theme/app_theme.dart';
import 'package:pakeaja/core/widgets/cloth_image_view.dart';
import 'package:pakeaja/core/widgets/custom_button.dart';
import 'package:pakeaja/core/widgets/state_widgets.dart';
import 'package:pakeaja/data/models/cloth_model.dart';
import 'package:pakeaja/features/auth/providers/auth_provider.dart' show authStateProvider;
import 'package:pakeaja/features/wardrobe/providers/wardrobe_provider.dart';

class EditClothScreen extends ConsumerStatefulWidget {
  final String clothId;

  const EditClothScreen({super.key, required this.clothId});

  @override
  ConsumerState<EditClothScreen> createState() => _EditClothScreenState();
}

class _EditClothScreenState extends ConsumerState<EditClothScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  ClothCategory _category = ClothCategory.top;
  String _color = 'black';
  ClothStyle _style = ClothStyle.casual;
  ClothWeather _weather = ClothWeather.cool;

  String? _newBase64Image;
  ClothModel? _cloth;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCloth();
  }

  Future<void> _loadCloth() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final cloth = await ref
        .read(clothRepositoryProvider)
        .watchCloth(user.uid, widget.clothId)
        .first;

    if (cloth != null && mounted) {
      setState(() {
        _cloth = cloth;
        _nameController.text = cloth.name;
        _category = cloth.category;
        _color = cloth.color;
        _style = cloth.styles.isNotEmpty ? cloth.styles.first : ClothStyle.casual;
        _weather = cloth.weather;
        _loading = false;
      });
    } else if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickNewImage(bool fromCamera) async {
    final imageService = ref.read(imageServiceProvider);
    final result = fromCamera
        ? await imageService.pickFromCamera()
        : await imageService.pickFromGallery();

    if (result.bytes != null || result.image != null) {
      final base64String = await imageService.compressAndConvertToBase64(
        image: result.image,
        bytes: result.bytes,
      );
      if (mounted && base64String.isNotEmpty) {
        setState(() {
          _newBase64Image = base64String;
        });
      }
    } else if (result.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error!),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Ambil dari Kamera'),
              onTap: () {
                context.pop();
                _pickNewImage(true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                context.pop();
                _pickNewImage(false);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final data = <String, dynamic>{
      'name': _nameController.text.trim(),
      'category': _category.value,
      'color': _color,
      'styles': [_style.value],
      'weather': _weather.value,
    };

    if (_newBase64Image != null) {
      data['imageUrl'] = _newBase64Image;
    }

    final success = await ref.read(updateClothProvider.notifier).updateCloth(
          uid: user.uid,
          clothId: widget.clothId,
          data: data,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pakaian berhasil diperbarui.'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      context.pop();
    } else if (mounted) {
      final err = ref.read(updateClothProvider).error?.toString() ??
          'Gagal memperbarui pakaian.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan: $err'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _confirmDelete() {
    if (_cloth == null) return;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Pakaian'),
        content: Text('Yakin hapus "${_cloth!.name}"? Tindakan tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final user = ref.read(authStateProvider).value;
              if (user == null) return;

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text('Menghapus "${_cloth!.name}"...'),
                      ],
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }

              final success = await ref
                  .read(deleteClothProvider.notifier)
                  .deleteCloth(
                    uid: user.uid,
                    clothId: _cloth!.id,
                    imageUrl: _cloth!.imageUrl,
                  );

              if (!mounted) return;
              ScaffoldMessenger.of(context).hideCurrentSnackBar();

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pakaian berhasil dihapus.'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
                // Pop back to wardrobe
                context.pop();
              } else {
                final err = ref.read(deleteClothProvider).error?.toString() ??
                    'Gagal menghapus pakaian.';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal menghapus: $err'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: LoadingWidget());
    }

    if (_cloth == null) {
      return const Scaffold(
        body: ErrorWidgetPage(message: 'Pakaian tidak ditemukan.'),
      );
    }

    final updateState = ref.watch(updateClothProvider);
    final currentImage = _newBase64Image ?? _cloth!.imageUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Pakaian'),
        actions: [
          IconButton(
            onPressed: _confirmDelete,
            icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
            tooltip: 'Hapus Pakaian',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Preview foto
                Stack(
                  children: [
                    ClothImageView(
                      imageUrl: currentImage,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: FilledButton.tonalIcon(
                        onPressed: _showImagePickerOptions,
                        icon: const Icon(Icons.camera_alt, size: 16),
                        label: const Text('Ganti Foto', style: TextStyle(fontSize: 12)),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          backgroundColor: Colors.black.withOpacity(0.6),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

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
                        onSelected: (_) => setState(() => _color = entry.key),
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
                const SizedBox(height: 24),

                CustomButton(
                  text: 'Simpan Perubahan',
                  onPressed: updateState.isLoading ? null : _save,
                  isLoading: updateState.isLoading,
                  icon: Icons.check,
                ),
                const SizedBox(height: 12),

                CustomButton(
                  text: 'Hapus Pakaian',
                  onPressed: _confirmDelete,
                  variant: ButtonVariant.danger,
                  icon: Icons.delete_outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
