# receyta

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

galeria de componentes (fora do app):
flutter run -t lib/gallery_app.dart

benchmark de scroll do TilePattern (A4 — 60 cards a 60fps):
flutter run --profile -t lib/gallery_app.dart
# abrir "TilePattern — benchmark", rolar, conferir o overlay de performance
# ou o gráfico de frames no DevTools (nenhum frame acima de 16ms)

gerar splash-screen: 
flutter pub run flutter_native_splash:create

gerar app icon (iOS, Android legado + adaptativo, web):
dart run flutter_launcher_icons
# requer assets/brand/AppiconForeground.png — 1024x1024, fundo transparente,
# a bandeja coral inteira dentro do círculo central de ~620px (safe zone do
# ícone adaptativo Android). O fundo `paper` (#F5F2EA) é cor sólida na config.

