#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"

if [ ! -f "$ENV_FILE" ]; then
  echo ""
  echo "❌ .env dosyası bulunamadı."
  echo ""
  echo ".env dosyasını şuraya koymalısın:"
  echo ""
  echo "  sanayi-servis-flutter-app/"
  echo "  ├── .env          ← BURAYA"
  echo "  ├── pubspec.yaml"
  echo "  └── ..."
  echo ""
  echo "Mevcut dizin: $ROOT_DIR"
  echo ".env dosyasını bu klasöre koy, sonra tekrar çalıştır."
  echo ""
  exit 1
fi

MAPS_KEY=""
while IFS='=' read -r key value || [ -n "$key" ]; do
  [[ "$key" =~ ^#.*$ || -z "$key" ]] && continue
  key="${key// /}"
  value="${value// /}"
  if [ "$key" = "GOOGLE_MAPS_KEY" ]; then
    MAPS_KEY="$value"
  fi
done < "$ENV_FILE"

if [ -z "$MAPS_KEY" ]; then
  echo ""
  echo "❌ .env içinde GOOGLE_MAPS_KEY bulunamadı."
  echo ""
  echo ".env dosyasının içeriği şöyle olmalı:"
  echo ""
  echo "  GOOGLE_MAPS_KEY=buraya_key_yaz"
  echo ""
  exit 1
fi

# Android local.properties
LOCAL_PROPS="$ROOT_DIR/android/local.properties"
if [ -f "$LOCAL_PROPS" ]; then
  if grep -q "MAPS_API_KEY" "$LOCAL_PROPS"; then
    sed -i '' "s|MAPS_API_KEY=.*|MAPS_API_KEY=$MAPS_KEY|" "$LOCAL_PROPS"
  else
    echo "" >> "$LOCAL_PROPS"
    echo "MAPS_API_KEY=$MAPS_KEY" >> "$LOCAL_PROPS"
  fi
else
  echo "MAPS_API_KEY=$MAPS_KEY" > "$LOCAL_PROPS"
fi

# iOS Maps.xcconfig
XCCONFIG_DIR="$ROOT_DIR/ios/Flutter"
mkdir -p "$XCCONFIG_DIR"
cat > "$XCCONFIG_DIR/Maps.xcconfig" <<EOF
MAPS_API_KEY=$MAPS_KEY
EOF

echo ""
echo "✅ Native config dosyaları oluşturuldu:"
echo "   android/local.properties  → MAPS_API_KEY set edildi"
echo "   ios/Flutter/Maps.xcconfig → MAPS_API_KEY set edildi"
echo ""
