# 🚀 Quick Setup Guide

## Step 1: Prepare Markets Configuration

You need a JSON array in this format:

```json
[
  { "market": "Spain", "id": "abc123", "key": "sk..." },
  { "market": "Brazil", "id": "def456", "key": "sk..." }
]
```

Use `markets-config.example.json` as a template.

## Step 2: Minify JSON

### Option A: Using the Helper Script (Easiest)

```bash
./minify-config.sh markets-config.example.json
```

The script will minify the JSON and copy it to your clipboard automatically!

### Option B: Using Python Directly

```bash
# Minify and display
python3 -c "import json; print(json.dumps(json.load(open('markets-config.example.json')), separators=(',', ':')))"

# Minify and copy to clipboard (macOS)
python3 -c "import json; print(json.dumps(json.load(open('markets-config.example.json')), separators=(',', ':')))" | pbcopy

# Minify and copy to clipboard (Linux)
python3 -c "import json; print(json.dumps(json.load(open('markets-config.example.json')), separators=(',', ':')))" | xclip
```

## Step 3: Add Secrets to GitHub

Navigate to: **Repository → Settings → Secrets and variables → Actions → New repository secret**

Add the following secrets:

1. **SANITY_MARKETS** - paste the minified JSON from clipboard
2. **S3_BUCKET** - your S3 bucket name (e.g., `my-sanity-backups`)
3. **AWS_ACCESS_KEY_ID** - your AWS access key
4. **AWS_SECRET_ACCESS_KEY** - your AWS secret key
5. **AWS_REGION** - AWS region (e.g., `eu-central-1`)

## Step 4: Create S3 Bucket

```bash
aws s3 mb s3://my-sanity-backups
```

Optional - enable versioning:
```bash
aws s3api put-bucket-versioning --bucket my-sanity-backups --versioning-configuration Status=Enabled
```

## Step 5: Run Manual Test

1. Go to: **Actions → Sanity Daily Backup**
2. Click **Run workflow**
3. Select branch `main`
4. Click green **Run workflow** button

You should see jobs appear for each market!

## ✅ Done!

Backups will now run automatically every day at 3:00 AM UTC.

### Important Notes:

- **Backups include documents only** (not image files)
- Image references are preserved, images remain on Sanity CDN
- Backup time: ~2 minutes per market (fast!)
- Archive size: typically < 10 MB per market

**Want to include images?** See `BACKUP_WITH_ASSETS.md` for instructions.
- Note: Including assets increases backup time to 30+ minutes per market
- Total workflow time would be 2-3 hours for all markets

---

## 📝 How to Add a New Market Later?

1. Get current JSON from secret `SANITY_MARKETS`
2. Save it to a file (e.g., `config.json`)
3. Add new market object to the array
4. Minify using the helper script:
```bash
./minify-config.sh config.json
```
5. Paste from clipboard to `SANITY_MARKETS` secret
6. Done!

---

## 🔍 How to Verify It's Working?

After running the workflow, check your S3 bucket:

```bash
aws s3 ls s3://my-sanity-backups/backups/ --recursive
```

You should see folders for each market with `.tar.gz` files.

Example output:
```
2025-10-28 03:15:42   45678901 backups/spain/sanity-backup-spain-2025-10-28_03-00-00.tar.gz
2025-10-28 03:16:23   32456789 backups/brazil/sanity-backup-brazil-2025-10-28_03-00-00.tar.gz
2025-10-28 03:17:01   28901234 backups/mexico/sanity-backup-mexico-2025-10-28_03-00-00.tar.gz
```

---

## 🆘 Troubleshooting

### Secret not parsing correctly?

Make sure the JSON is properly minified (no newlines, no extra spaces):
```bash
# This is correct:
[{"market":"Spain","id":"abc123","key":"sk..."}]

# This is WRONG (has newlines):
[
  {"market":"Spain","id":"abc123","key":"sk..."}
]
```

### Backup failing for specific market?

1. Check the job logs in GitHub Actions
2. Verify the Sanity token has read permissions
3. Verify the project ID is correct
4. Test the token manually:
```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
  "https://YOUR_PROJECT_ID.api.sanity.io/v1/data/export/production"
```

### S3 upload failing?

1. Verify AWS credentials are correct
2. Check IAM permissions include `s3:PutObject`
3. Verify bucket exists and region is correct
