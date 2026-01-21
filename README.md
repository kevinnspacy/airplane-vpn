# Airplane VPN 🛫

Современное VPN-приложение для Android с поддержкой VLESS + Reality протокола.

## 📋 Требования

- macOS (для разработки под iOS в будущем)
- Flutter SDK 3.0+
- Android Studio
- Android устройство или эмулятор (API 24+)

## 🚀 Быстрый старт

### 1. Установка инструментов

```bash
# Установите Homebrew (если ещё нет)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Установите Flutter
brew install --cask flutter

# Установите Android Studio
brew install --cask android-studio

# Проверьте установку
flutter doctor
```

### 2. Настройка Android Studio

1. Откройте Android Studio
2. Пройдите начальную настройку
3. Установите плагин Flutter: `Settings → Plugins → Flutter → Install`
4. Настройте Android SDK: `Settings → Languages & Frameworks → Android SDK`
   - Установите Android SDK 34
   - Установите Android SDK Build-Tools 34
   - Установите Android SDK Command-line Tools

### 3. Клонирование и запуск

```bash
# Перейдите в папку проекта
cd airplane_vpn

# Получите зависимости
flutter pub get

# Запустите на устройстве/эмуляторе
flutter run
```

## 📁 Структура проекта

```
airplane_vpn/
├── lib/
│   ├── main.dart                 # Точка входа
│   ├── theme/
│   │   └── app_theme.dart        # Тема приложения
│   ├── models/
│   │   ├── vless_config.dart     # Модель VLESS конфигурации
│   │   └── connection_state.dart # Состояние подключения
│   ├── providers/
│   │   ├── vpn_provider.dart     # Управление VPN
│   │   ├── servers_provider.dart # Управление серверами
│   │   └── settings_provider.dart# Настройки
│   ├── screens/
│   │   ├── home_screen.dart      # Главный экран
│   │   ├── servers_screen.dart   # Список серверов
│   │   ├── add_server_screen.dart# Добавление сервера
│   │   └── settings_screen.dart  # Настройки
│   └── widgets/
│       ├── connection_button.dart # Кнопка подключения
│       ├── connection_stats_card.dart # Статистика
│       └── server_selector.dart   # Выбор сервера
├── android/
│   └── app/src/main/
│       ├── kotlin/com/airplane/vpn/
│       │   ├── MainActivity.kt    # Flutter-Android мост
│       │   ├── AirplaneVpnService.kt # VPN сервис
│       │   └── VpnServiceManager.kt  # Менеджер состояния
│       ├── AndroidManifest.xml    # Манифест с разрешениями
│       └── res/                   # Ресурсы Android
└── pubspec.yaml                   # Зависимости Flutter
```

## 🔧 Интеграция sing-box

Для работы VPN необходимо добавить sing-box как нативную библиотеку.

### Вариант 1: Скачать готовые библиотеки

1. Скачайте sing-box для Android с [GitHub Releases](https://github.com/SagerNet/sing-box/releases)
2. Создайте папку `android/app/src/main/jniLibs/`
3. Поместите библиотеки по архитектурам:
   ```
   jniLibs/
   ├── arm64-v8a/
   │   └── libsingbox.so
   ├── armeabi-v7a/
   │   └── libsingbox.so
   └── x86_64/
       └── libsingbox.so
   ```

### Вариант 2: Использовать sing-box Android library

Добавьте в `android/app/build.gradle`:

```gradle
dependencies {
    implementation 'io.nekohasekai:sing-box:1.8.0'
}
```

## 📱 Сборка релиза

### Android APK

```bash
# Сборка APK
flutter build apk --release

# APK будет в: build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle (для Google Play)

```bash
# Сборка AAB
flutter build appbundle --release

# AAB будет в: build/app/outputs/bundle/release/app-release.aab
```

## ⚙️ Настройка подписи для релиза

1. Создайте keystore:
```bash
keytool -genkey -v -keystore ~/airplane-vpn.jks -keyalg RSA -keysize 2048 -validity 10000 -alias airplane
```

2. Создайте файл `android/key.properties`:
```properties
storePassword=<ваш пароль>
keyPassword=<ваш пароль>
keyAlias=airplane
storeFile=/Users/<username>/airplane-vpn.jks
```

3. Обновите `android/app/build.gradle` для использования подписи.

## 🎨 Кастомизация

### Изменение цветов

Отредактируйте `lib/theme/app_theme.dart`:

```dart
static const Color primaryColor = Color(0xFF6C5CE7);  // Основной цвет
static const Color accentColor = Color(0xFF00D9FF);   // Акцентный цвет
static const Color successColor = Color(0xFF00E676);  // Цвет успеха
```

### Изменение иконки приложения

1. Подготовьте иконку 1024x1024 PNG
2. Используйте [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons)

## 🐛 Отладка

```bash
# Логи Flutter
flutter logs

# Логи Android (в Android Studio)
# Фильтр: tag:SingBox OR tag:VPN
```

## 📚 Полезные ссылки

- [Flutter Documentation](https://docs.flutter.dev/)
- [sing-box Documentation](https://sing-box.sagernet.org/)
- [VLESS Protocol](https://xtls.github.io/en/config/outbounds/vless.html)
- [Reality Protocol](https://github.com/XTLS/REALITY)

## 📝 TODO

- [ ] Добавить интеграцию sing-box библиотеки
- [ ] Реализовать сканирование QR-кода
- [ ] Добавить split tunneling (выбор приложений)
- [ ] Добавить виджет для быстрого подключения
- [ ] Добавить поддержку iOS
- [ ] Добавить тесты

## 📄 Лицензия

MIT License
