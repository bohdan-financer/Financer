# Backup Script with Assets (Images)

This file contains the backup mechanism that includes downloading all images and assets from Sanity CDN.

## Why We Don't Use This Currently

- Asset downloads significantly increase backup time (can take 30+ minutes per market)
- Assets are already stored on Sanity CDN with high reliability
- For most recovery scenarios, document data is sufficient
- Can be re-enabled in the future if needed

## How to Re-enable Asset Downloads

Replace the backup script creation step in `.github/workflows/sanity-backup.yml` with this version:

```yaml
      - name: Create backup script
        run: |
          cat > backup.js << 'ENDOFFILE'
          import https from 'https';
          import fs from 'fs';
          import path from 'path';
          import { createWriteStream } from 'fs';
          import { pipeline } from 'stream/promises';
          
          const PROJECT_ID = process.env.SANITY_PROJECT_ID;
          const TOKEN = process.env.SANITY_TOKEN;
          const DATASET = 'production';
          
          async function downloadFile(url, dest) {
            return new Promise((resolve, reject) => {
              https.get(url, (response) => {
                if (response.statusCode === 302 || response.statusCode === 301) {
                  downloadFile(response.headers.location, dest).then(resolve).catch(reject);
                  return;
                }
                const file = createWriteStream(dest);
                response.pipe(file);
                file.on('finish', () => {
                  file.close();
                  resolve();
                });
                file.on('error', (err) => {
                  fs.unlink(dest, () => reject(err));
                });
              }).on('error', reject);
            });
          }
          
          async function exportData() {
            console.log('Exporting documents...');
            
            // Export documents via Sanity HTTP API
            const exportUrl = `https://${PROJECT_ID}.api.sanity.io/v1/data/export/${DATASET}`;
            
            await new Promise((resolve, reject) => {
              https.get(exportUrl, {
                headers: { 'Authorization': `Bearer ${TOKEN}` }
              }, (response) => {
                const file = createWriteStream('data.ndjson');
                response.pipe(file);
                file.on('finish', () => {
                  file.close();
                  console.log('Documents exported successfully');
                  resolve();
                });
                file.on('error', reject);
              }).on('error', reject);
            });
            
            // Parse documents and extract asset references
            console.log('Parsing assets...');
            const data = fs.readFileSync('data.ndjson', 'utf8');
            const lines = data.split('\n').filter(line => line.trim());
            
            const assetRefs = new Set();
            for (const line of lines) {
              try {
                const doc = JSON.parse(line);
                const jsonStr = JSON.stringify(doc);
                
                // Find all image asset references
                const matches = jsonStr.matchAll(/"_ref":"(image-[a-f0-9]+-\d+x\d+-[a-z]+)"/g);
                for (const match of matches) {
                  assetRefs.add(match[1]);
                }
              } catch (e) {
                // Skip invalid lines
              }
            }
            
            console.log(`Found ${assetRefs.size} unique assets`);
            
            // Create assets directory
            if (!fs.existsSync('assets')) {
              fs.mkdirSync('assets');
            }
            
            // Download all assets from CDN
            let downloaded = 0;
            for (const ref of assetRefs) {
              try {
                // Convert ref to CDN URL: image-abc123-1920x1080-jpg -> abc123-1920x1080.jpg
                const parts = ref.replace('image-', '').split('-');
                const hash = parts[0];
                const dimensions = parts[1];
                const ext = parts[2];
                const filename = `${hash}-${dimensions}.${ext}`;
                const url = `https://cdn.sanity.io/images/${PROJECT_ID}/${DATASET}/${filename}`;
                
                await downloadFile(url, path.join('assets', filename));
                downloaded++;
                if (downloaded % 10 === 0) {
                  console.log(`Downloaded ${downloaded}/${assetRefs.size} assets...`);
                }
              } catch (err) {
                console.error(`Failed to download ${ref}: ${err.message}`);
              }
            }
            
            console.log(`Successfully downloaded ${downloaded} assets`);
          }
          
          exportData().catch(console.error);
          ENDOFFILE
          
          # Create minimal package.json for ES modules support
          echo '{"type": "module"}' > package.json
```

Also update the tar command in backup-all.js to include assets:

```javascript
await execAsync(`tar -czf ${filename} -C ${workDir} data.ndjson assets/`);
```

## Performance Considerations

When re-enabling:
- Backup time will increase from ~2 minutes to 30+ minutes per market
- Total workflow time for 23 markets: 2-3 hours (with 5 concurrent)
- S3 storage costs will increase significantly
- Consider implementing:
  - Differential backups (only new/changed assets)
  - Separate daily document backups + weekly asset backups
  - Asset backup only for critical markets

## Alternative: Asset Recovery Without Backups

In most cases, assets can be recovered from:
1. Sanity CDN - assets remain accessible even after document deletion
2. Sanity API - query `_type == "sanity.imageAsset"` to list all assets
3. Re-import from production if needed

## Testing

To test asset backup locally:

```bash
export SANITY_PROJECT_ID="your_project_id"
export SANITY_TOKEN="your_token"

node backup.js

# Check results
ls -lh data.ndjson
ls -lh assets/
```

