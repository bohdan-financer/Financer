#!/bin/bash

# Simple script to minify markets config for GitHub Secrets
# Usage: ./minify-config.sh [input-file]

INPUT_FILE="${1:-markets-config.json}"

if [ ! -f "$INPUT_FILE" ]; then
    echo "❌ Error: File '$INPUT_FILE' not found"
    echo ""
    echo "Usage: ./minify-config.sh [input-file]"
    echo "Example: ./minify-config.sh markets-config.json"
    exit 1
fi

echo "📦 Minifying $INPUT_FILE..."
echo ""

# Minify using Python
OUTPUT=$(python3 -c "import json; print(json.dumps(json.load(open('$INPUT_FILE')), separators=(',', ':')))")

if [ $? -ne 0 ]; then
    echo "❌ Error: Failed to parse JSON. Please check your file format."
    exit 1
fi

echo "✅ Success! Minified JSON:"
echo ""
echo "$OUTPUT"
echo ""
echo "📋 Copied to clipboard!"
echo ""

# Copy to clipboard based on OS
if command -v pbcopy &> /dev/null; then
    # macOS
    echo "$OUTPUT" | pbcopy
elif command -v xclip &> /dev/null; then
    # Linux with xclip
    echo "$OUTPUT" | xclip -selection clipboard
elif command -v xsel &> /dev/null; then
    # Linux with xsel
    echo "$OUTPUT" | xsel --clipboard --input
else
    echo "⚠️  Clipboard tool not found. Please copy the output above manually."
fi

echo "Next steps:"
echo "1. Go to GitHub → Settings → Secrets → Actions"
echo "2. Create or update secret 'SANITY_MARKETS'"
echo "3. Paste the minified JSON from clipboard"

