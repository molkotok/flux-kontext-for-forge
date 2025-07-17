#!/usr/bin/env bash
set -euo pipefail

# Проверка наличия необходимых утилит
check_dependencies() {
    local deps=("jq" "curl" "git" "sha256sum")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            echo "❌ Required dependency '$dep' not found"
            exit 1
        fi
    done
}

# Проверка наличия assets.json
if [ ! -f "assets.json" ]; then
    echo "❌ assets.json not found"
    exit 1
fi

check_dependencies

# Попытка определить расположение Forge
if [ -z "${FORGE_HOME:-}" ]; then
  if [ -f "./webui.sh" ] || [ -f "./launch.py" ]; then
    FORGE_HOME=$(pwd)
    echo "✅ Detected Forge location: $FORGE_HOME"
  else
    FORGE_HOME="$HOME/stable-diffusion-webui-forge"
    echo "⚠️ Using default path: $FORGE_HOME"
  fi
fi

if [ ! -d "$FORGE_HOME" ]; then
  echo "❌ Forge not found at $FORGE_HOME"
  exit 1
fi

# Автоматическая установка gdown, если понадобится GDrive
need_gdown() { 
    [ -f "assets.json" ] && grep -q '"gdrive://' assets.json; 
}

if need_gdown && ! command -v gdown &>/dev/null; then
    echo "📦 Installing gdown for Google Drive support..."
    python -m pip install --user --upgrade gdown
fi

# Безопасная замена переменных окружения
expand_path() {
    local path="$1"
    # Заменяем только известные безопасные переменные
    path="${path//\$FORGE_HOME/$FORGE_HOME}"
    path="${path//\$HOME/$HOME}"
    echo "$path"
}

download() {
    local url="$1" dst="$2" sum="$3"
    mkdir -p "$dst"
    local fname="$dst/$(basename "$url")"

    # Если файл уже корректный – ничего не делаем
    if [ -f "$fname" ] && sha256sum -c <<<"$sum  $fname" 2>/dev/null; then
        echo "✔ $(basename "$fname") already OK"
        return 0
    fi

    echo "↓ Downloading $(basename "$fname") ..."
    case "$url" in
      gdrive://*)
          # gdown умеет резюмировать по -c
          if ! gdown -c --no-cookies "${url#gdrive://}" -O "$fname"; then
              echo "❌ Failed to download from Google Drive: $url"
              return 1
          fi
          ;;
      http*|https*)
          # curl с timeout и лучшей обработкой ошибок
          if ! curl -L --connect-timeout 30 --max-time 3600 --retry 3 --retry-delay 5 --continue-at - -o "$fname" "$url"; then
              echo "❌ Failed to download: $url"
              return 1
          fi
          ;;
      *)
          echo "❌ Unsupported URL format: $url"
          return 1
          ;;
    esac

    # Проверяем хеш после загрузки
    if ! sha256sum -c <<<"$sum  $fname" 2>/dev/null; then
        echo "❌ Checksum failed for $(basename "$fname")"
        echo "Expected: $sum"
        echo "Got: $(sha256sum "$fname" | cut -d' ' -f1)"
        return 1
    fi
}

clone_or_update() {
    local giturl="$1" tgt="$2"
    
    if [ -d "$tgt/.git" ]; then
        echo "🔄 Updating repository: $(basename "$tgt")"
        if ! git -C "$tgt" pull --ff-only; then
            echo "❌ Failed to update repository: $tgt"
            return 1
        fi
    else
        echo "📥 Cloning repository: $(basename "$tgt")"
        if ! git clone --depth 1 "$giturl" "$tgt"; then
            echo "❌ Failed to clone repository: $giturl"
            return 1
        fi
    fi
}

# Основной цикл обработки
failed_count=0
total_count=0

while IFS= read -r entry; do
    total_count=$((total_count + 1))
    
    url=$(jq -r '.url? // empty' <<<"$entry")
    giturl=$(jq -r '.git? // empty' <<<"$entry")
    target_raw=$(jq -r '.target' <<<"$entry")
    tgt=$(expand_path "$target_raw")
    
    if [ -n "$url" ]; then
        sha256=$(jq -r '.sha256' <<<"$entry")
        if [ "$sha256" = "null" ] || [ -z "$sha256" ]; then
            echo "❌ Missing sha256 for URL: $url"
            failed_count=$((failed_count + 1))
            continue
        fi
        
        if ! download "$url" "$tgt" "$sha256"; then
            failed_count=$((failed_count + 1))
        fi
    elif [ -n "$giturl" ]; then
        if ! clone_or_update "$giturl" "$tgt"; then
            failed_count=$((failed_count + 1))
        fi
    else
        echo "❌ Invalid entry: no URL or git repository specified"
        failed_count=$((failed_count + 1))
    fi
done < <(jq -c '.[]' assets.json)

# Финальный отчет
echo ""
if [ $failed_count -eq 0 ]; then
    echo "✅ Forge bootstrap complete! All $total_count items processed successfully."
else
    echo "⚠️ Bootstrap completed with $failed_count failures out of $total_count items."
    exit 1
fi
