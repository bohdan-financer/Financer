# Financer Actions

Репозиторий с GitHub Actions для автоматизации задач проекта Financer.

## 📋 Содержание

- [Sanity Daily Backup](#sanity-daily-backup)
- [Настройка](#настройка)
- [Использование](#использование)
- [Восстановление данных](#восстановление-данных)

---

## 🔄 Sanity Daily Backup

GitHub Action для автоматического ежедневного бэкапа Sanity CMS в AWS S3.

### Что экспортируется:

- ✅ **Все документы** (тексты, структура, метаданные)
- ✅ **Изображения и файлы** (оригиналы всех assets)
- ✅ **Полный архив** в формате `.tar.gz` с меткой даты

### Расписание:

- Автоматически каждый день в **3:00 UTC**
- Можно запустить вручную через GitHub Actions UI

---

## ⚙️ Настройка

### 1. Создайте необходимые Secrets в GitHub:

Перейдите в **Settings → Secrets and variables → Actions** и добавьте:

#### Sanity Secrets:
- `SANITY_PROJECT_ID` - ID вашего Sanity проекта
- `SANITY_TOKEN` - Токен с правами на чтение (создать в [sanity.io/manage](https://sanity.io/manage))

#### AWS S3 Secrets:
- `S3_BUCKET` - Название S3 bucket для бэкапов
- `AWS_ACCESS_KEY_ID` - AWS Access Key ID
- `AWS_SECRET_ACCESS_KEY` - AWS Secret Access Key
- `AWS_REGION` - Регион AWS (например, `eu-central-1`)

### 2. Создайте S3 Bucket:

```bash
aws s3 mb s3://your-backup-bucket-name
```

### 3. Настройте IAM политику для S3:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:PutObjectAcl"
      ],
      "Resource": "arn:aws:s3:::your-backup-bucket-name/*"
    }
  ]
}
```

---

## 🚀 Использование

### Автоматический запуск:
Action запускается автоматически каждый день в 3:00 UTC.

### Ручной запуск:
1. Перейдите на вкладку **Actions** в GitHub
2. Выберите **Sanity Daily Backup**
3. Нажмите **Run workflow**

### Структура файлов в S3:

```
s3://your-bucket/backups/
├── sanity-backup-2025-10-28_03-00-00.tar.gz
├── sanity-backup-2025-10-29_03-00-00.tar.gz
└── sanity-backup-2025-10-30_03-00-00.tar.gz
```

---

## 🔙 Восстановление данных

### 1. Скачайте бэкап из S3:

```bash
aws s3 cp s3://your-bucket/backups/sanity-backup-2025-10-28_03-00-00.tar.gz .
```

### 2. Распакуйте архив:

```bash
tar -xzf sanity-backup-2025-10-28_03-00-00.tar.gz
cd backup
```

### 3. Восстановите данные в Sanity:

#### Импорт документов:
```bash
sanity dataset import sanity-backup.ndjson production --replace
```

#### Импорт assets (изображения):
```bash
tar -xzf sanity-assets.tar.gz
# Assets автоматически восстановятся при импорте документов
```

> **⚠️ Внимание:** Флаг `--replace` удалит все существующие данные в датасете. Для добавления данных используйте без флага.

---

## 📝 Структура бэкапа

Каждый бэкап содержит:

```
sanity-backup-full.tar.gz
└── backup/
    ├── sanity-backup.ndjson      # Все документы в NDJSON формате
    └── sanity-assets.tar.gz      # Все файлы и изображения
```

---

## 🔒 Безопасность

- Все чувствительные данные хранятся в GitHub Secrets
- Используйте AWS IAM роли с минимальными правами
- Рекомендуется включить шифрование S3 bucket
- Регулярно ротируйте токены доступа

---

## 📚 Дополнительные ресурсы

- [Sanity Export API](https://www.sanity.io/docs/export)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AWS S3 Documentation](https://docs.aws.amazon.com/s3/)

---

## 📄 Лицензия

MIT
