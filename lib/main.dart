import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/custom_point_model.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

/// Controller tema global sederhana, agar tombol dark mode di layar mana pun
/// (mis. HomeScreen) bisa mengubah tema tanpa state management tambahan.
final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.system);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(CustomPointModelAdapter());

  runApp(const PencariKecamatanApp());
}

class PencariKecamatanApp extends StatelessWidget {
  const PencariKecamatanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Pencari Kecamatan Indonesia',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          home: const SplashScreen(),
        );
      },
    );
  }
}
