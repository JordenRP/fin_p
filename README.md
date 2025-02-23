# Finance - Приложение для управления личными финансами

## Описание
Finance - это приложение для управления личными финансами, которое позволяет:
- Отслеживать доходы и расходы
- Категоризировать транзакции
- Устанавливать и контролировать бюджеты
- Просматривать статистику в виде графиков
- Экспортировать данные в CSV формат

## Требования
- Docker и Docker Compose
- Flutter SDK (для разработки)
- Go 1.22 или выше (для разработки)
- PostgreSQL (устанавливается автоматически через Docker)

## Запуск проекта через Docker
1. Запустите приложение с помощью Docker Compose:
```bash
docker compose up --build -d
```

2. Откройте приложение в браузере:
```
http://localhost:3000
```

## Запуск APK на Android
1. Скачайте последнюю версию APK из раздела Releases
2. Перенесите APK файл на ваше Android устройство
3. На устройстве:
   - Откройте файловый менеджер
   - Найдите и нажмите на скачанный APK файл
   - Разрешите установку из неизвестных источников, если потребуется
   - Следуйте инструкциям установщика
4. После установки запустите приложение "Finance"

## Сборка APK из исходного кода
1. Убедитесь, что у вас установлен Flutter SDK:
```bash
flutter doctor
```

2. Перейдите в директорию frontend:
```bash
cd frontend
```

3. Получите зависимости:
```bash
flutter pub get
```

4. Соберите APK:
```bash
flutter build apk --release
```

5. APK файл будет доступен по пути:
```
frontend/build/app/outputs/flutter-apk/app-release.apk
```

### Запуск фронтенда для разработки
```bash
cd frontend
flutter run -d chrome  # для веб-версии
# или
flutter run -d <device-id>  # для мобильных устройств
```

## Дополнительная информация

### Порты по умолчанию
- Frontend: http://localhost:3000
- Backend API: http://localhost:8080
- PostgreSQL: localhost:5432

### Переменные окружения
Все необходимые переменные окружения настроены в `docker-compose.yml`. При локальной разработке вы можете создать файл `.env` на основе `.env.example`.

### База данных
PostgreSQL создается автоматически при первом запуске. Схема базы данных и начальные миграции выполняются автоматически.

## Поддержка
При возникновении проблем создайте Issue в репозитории проекта. 