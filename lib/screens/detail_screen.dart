import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/kecamatan_model.dart';
import '../services/app_data_service.dart';
import '../services/qibla_service.dart';
import '../theme/app_theme.dart';
import '../widgets/watermark_footer.dart';
import '../widgets/qibla_compass.dart';
import 'add_point_screen.dart';

class DetailScreen extends StatelessWidget {
  final KecamatanModel data;
  const DetailScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final kabah = AppDataService.instance.kabah;
    final lirboyo = AppDataService.instance.lirboyo;

    final bearingKiblat = QiblaService.bearingDerajat(
      lat1: data.lat, lng1: data.lng, lat2: kabah.lat, lng2: kabah.lng,
    );
    final jarakKabah = QiblaService.jarakKm(
      lat1: data.lat, lng1: data.lng, lat2: kabah.lat, lng2: kabah.lng,
    );
    final jarakLirboyo = QiblaService.jarakKm(
      lat1: data.lat, lng1: data.lng, lat2: lirboyo.lat, lng2: lirboyo.lng,
    );

    return Scaffold(
      appBar: AppBar(title: Text(data.kecamatan)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _sectionCard(
                    title: 'Lokasi Administratif',
                    icon: Icons.location_city_rounded,
                    children: [
                      _row('Kecamatan', data.kecamatan),
                      if (data.kabupaten != null) _row('Kabupaten/Kota', data.kabupaten!),
                      _row('Provinsi', data.provinsi),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _sectionCard(
                    title: 'Koordinat',
                    icon: Icons.explore_rounded,
                    children: [
                      _row('Latitude (Desimal)', '${data.lat}'),
                      _row('Longitude (Desimal)', '${data.lng}'),
                      if (data.latDms != null) _row('Lintang (DMS)', data.latDms!),
                      if (data.lngDms != null) _row('Bujur (DMS)', data.lngDms!),
                      if (data.elevasiM != null) _row('Elevasi', '${data.elevasiM} mdpl'),
                      if (data.zonaWaktu != null)
                        _row('Zona Waktu', '${data.zonaWaktu} (UTC+${data.utcOffset})'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _sectionCard(
                    title: 'Arah Kiblat & Jarak',
                    icon: Icons.mosque_rounded,
                    children: [
                      _row('Arah Kiblat', '${bearingKiblat.toStringAsFixed(2)}° (${QiblaService.arahMataAngin(bearingKiblat)})'),
                      _row('Jarak ke Ka\'bah', '${jarakKabah.toStringAsFixed(1)} km'),
                      _row('Jarak ke Lirboyo', '${jarakLirboyo.toStringAsFixed(1)} km'),
                      const SizedBox(height: 12),
                      Center(child: QiblaCompass(bearingDerajat: bearingKiblat)),
                      const SizedBox(height: 4),
                      Center(
                        child: Text(
                          'Kompas 100% offline (tanpa peta tile) — jarum emas menunjuk Ka\'bah.\nBerputar otomatis jika perangkat mendukung sensor kompas.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (!data.isReferensi)
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => AddPointScreen(induk: data)),
                        );
                      },
                      icon: const Icon(Icons.add_location_alt_rounded),
                      label: const Text('Tambah Titik di Kecamatan Ini'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.emerald,
                        side: const BorderSide(color: AppColors.emerald),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: data.toClipboardText()));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Data disalin ke clipboard')),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Salin Semua Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emerald,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
            const WatermarkFooter(),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppColors.emerald),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            const Divider(height: 18),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13.5)),
          ),
        ],
      ),
    );
  }
}
