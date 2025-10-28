# Financer Actions

Automated GitHub Actions for Financer project tasks.

## 📋 Table of Contents

- [Sanity Daily Backup](#sanity-daily-backup)
- [Setup](#setup)
- [Usage](#usage)
- [Data Recovery](#data-recovery)
- [Adding New Markets](#adding-new-markets)
- [Security](#security)

---

## 🔄 Sanity Daily Backup

Automated daily backup of Sanity CMS to AWS S3 for multiple markets.

### What Gets Exported:

- ✅ **All documents** (content, structure, metadata)
- ✅ **Asset references** (links to images and files)
- ✅ **Lightweight archive** in `.tar.gz` format with timestamp
- ℹ️ **Note:** Actual image files are NOT included (see `BACKUP_WITH_ASSETS.md` to re-enable)

### Schedule:

- Automatically runs **daily at 3:00 AM UTC**
- Can be triggered manually via GitHub Actions UI

### Features:

- **Parallel processing** - up to 5 markets simultaneously
- **Fail-safe** - one market failure won't stop others
- **Organized storage** - separate S3 folders per market
- **No dependencies** - pure Node.js HTTP API calls
- **Fast backups** - documents only (~2 minutes per market)
- **Small archives** - typically < 10 MB per market

---

## ⚙️ Setup

### 1. Create Required GitHub Secrets

Navigate to **Settings → Secrets and variables → Actions** and add:

#### Sanity Configuration:
- `SANITY_MARKETS` - JSON array with all markets (see format below)

#### AWS S3 Configuration:
- `S3_BUCKET` - S3 bucket name for backups
- `AWS_ACCESS_KEY_ID` - AWS Access Key ID
- `AWS_SECRET_ACCESS_KEY` - AWS Secret Access Key
- `AWS_REGION` - AWS region (e.g., `eu-central-1`)

### 2. Markets Configuration Format (`SANITY_MARKETS`)

Create a JSON array with all markets. Each market should contain:
- `market` - market name (used in filename and S3 folder)
- `id` - Sanity Project ID
- `key` - Sanity API Token with read permissions

**Example** (use `markets-config.example.json` as template):

```json
[
  { "market": "Spain", "id": "abc123", "key": "sk..." },
  { "market": "Brazil", "id": "def456", "key": "sk..." },
  { "market": "Mexico", "id": "ghi789", "key": "sk..." }
]
```

> ⚠️ **Important:** JSON must be minified (single line) when adding to GitHub Secret.
> 
> **Easy way** - use the helper script:
> ```bash
> ./minify-config.sh markets-config.example.json
> ```
> 
> Or minify manually using Python:
> ```bash
> python3 -c "import json; print(json.dumps(json.load(open('markets-config.example.json')), separators=(',', ':')))"
> ```

### 3. Create S3 Bucket

```bash
aws s3 mb s3://your-backup-bucket-name
```

### 4. Configure IAM Policy for S3

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

## 🚀 Usage

### Automatic Execution

The action runs automatically every day at 3:00 AM UTC and creates backups for **all markets in parallel**.

### Manual Execution

1. Go to **Actions** tab in GitHub
2. Select **Sanity Daily Backup**
3. Click **Run workflow**

### Parallel Processing

- Processes **up to 5 markets simultaneously**
- If one market fails, others continue
- Each market has its own job in Actions UI for easy monitoring

### S3 File Structure

```
s3://your-bucket/backups/
├── spain/
│   ├── sanity-backup-spain-2025-10-28_03-00-00.tar.gz
│   └── sanity-backup-spain-2025-10-29_03-00-00.tar.gz
├── brazil/
│   ├── sanity-backup-brazil-2025-10-28_03-00-00.tar.gz
│   └── sanity-backup-brazil-2025-10-29_03-00-00.tar.gz
├── mexico/
│   └── sanity-backup-mexico-2025-10-28_03-00-00.tar.gz
└── ...
```

---

## 🔙 Data Recovery

### 1. Download Backup from S3

```bash
aws s3 cp s3://your-bucket/backups/spain/sanity-backup-spain-2025-10-28_03-00-00.tar.gz .
```

### 2. Extract Archive

```bash
tar -xzf sanity-backup-spain-2025-10-28_03-00-00.tar.gz
```

### 3. Restore Data to Sanity

#### Import Documents:
```bash
sanity dataset import data.ndjson production --replace
```

> **⚠️ Warning:** The `--replace` flag will delete all existing data in the dataset. To add data instead, use without the flag.

#### About Assets (Images):
- Asset references are preserved in documents
- Original images remain on Sanity CDN and will continue to work
- No need to restore assets separately unless CDN images were deleted
- If needed, see `BACKUP_WITH_ASSETS.md` for full asset backup/restore

---

## 🆕 Adding New Markets

### Simple Process:

1. **Get current config** from GitHub Secret `SANITY_MARKETS`
2. **Add new market** to the JSON array:
```json
{ "market": "New Market", "id": "project_id", "key": "sk..." }
```
3. **Minify JSON** using the helper script:
```bash
./minify-config.sh config.json
```
Or manually with Python:
```bash
python3 -c "import json; print(json.dumps(json.load(open('config.json')), separators=(',', ':')))"
```
4. **Update GitHub Secret** `SANITY_MARKETS` with the new value
5. Done! The new market will be included in the next backup run

### Using Local File (Optional)

1. Copy `markets-config.example.json` → `markets-config.json`
2. Fill with real data
3. Minify and copy to clipboard:
```bash
./minify-config.sh markets-config.json
```

The script automatically detects your OS and copies to clipboard!

> 💡 **Tip:** `markets-config.json` is in `.gitignore` to prevent accidental secret leaks

---

## 📝 Backup Structure

Each backup contains:

```
sanity-backup-market-2025-10-28T13-21-07.tar.gz
└── data.ndjson              # All documents in NDJSON format (with asset references)
```

**Note:** Images are not included in backups. Asset references (URLs) are preserved in documents.
- Images remain accessible on Sanity CDN
- See `BACKUP_WITH_ASSETS.md` for full backup option (significantly slower)

---

## 🔒 Security

- ✅ **All tokens in GitHub Secrets** - no hardcoded credentials
- ✅ **Isolated tokens** - each market has its own Sanity token
- ✅ **Minimal permissions** - read-only tokens
- ✅ **Leak protection** - `markets-config.json` in `.gitignore`
- ✅ **Fail-safe mode** - one market failure doesn't break entire backup
- 🔐 Use AWS IAM roles with minimal required permissions
- 🔐 Enable S3 bucket encryption (encryption at rest)
- 🔐 Regularly rotate access tokens
- 🔐 Use S3 bucket policies to restrict access

---

## 📚 Additional Resources

- [Sanity Export API](https://www.sanity.io/docs/export)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AWS S3 Documentation](https://docs.aws.amazon.com/s3/)

---

## 📄 License

MIT
