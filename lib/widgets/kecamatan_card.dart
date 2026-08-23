import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/kecamatan_model.dart';
import '../theme/app_theme.dart';

class KecamatanCard extends StatelessWidget {
  final KecamatanModel data;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  const KecamatanCard({
    super.key,
    required this.data,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFavorite,
  });

  void _copyData(BuildContext context) {
    Clipboard.setData(ClipboardData(text: data.toClipboardText()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data disalin ke clipboard'), duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (data.isReferensi)
                const Padding(
                  padding: EdgeInsets.only(right: 8, top: 2),
                  child: Icon(Icons.mosque, color: AppColors.gold, size: 20),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.kecamatan,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [data.kabupaten, data.provinsi].where((e) => e != null).join(', '),
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      children: [
                        _chip('${data.lat}, ${data.lng}'),
                        if (data.elevasiM != null) _chip('${data.elevasiM} mdpl'),
                        if (data.zonaWaktu != null) _chip(data.zonaWaktu!),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: Icon(
                      isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: isFavorite ? AppColors.gold : Colors.grey,
                    ),
                    onPressed: onToggleFavorite,
                    tooltip: 'Favorit',
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 20),
                    onPressed: () => _copyData(context),
                    tooltip: 'Salin data',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.emerald.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: const TextStyle(fontSize: 11.5, color: AppColors.emeraldDark)),
    );
  }
}
