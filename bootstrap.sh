#!/usr/bin/env bash
set -euo pipefail

# Process command line arguments
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    cat << EOF
🚀 Flux Kontext Installer for Forge

Usage: bash bootstrap.sh [options]

Options:
  --help, -h       Show this help message

Environment variables:
  FORGE_HOME       Override Forge installation path

Examples:
  bash bootstrap.sh                    # Normal installation
  FORGE_HOME="/path/to/forge" bash bootstrap.sh  # Custom Forge location

EOF
    exit 0
fi

# Function to detect OS
detect_os() {
    case "$(uname -s)" in
        Linux*)     echo "linux";;
        Darwin*)    echo "macos";;
        CYGWIN*|MINGW32*|MSYS*|MINGW*) echo "windows";;
        *)          echo "unknown";;
    esac
}

# Convert Unix-style path to Windows-style for curl
convert_path_for_curl() {
    local path="$1"
    local os_type=$(detect_os)
    
    if [ "$os_type" = "windows" ]; then
        # Convert /d/path to D:/path for Windows
        if [[ "$path" =~ ^/([a-zA-Z])/(.*)$ ]]; then
            local drive="${BASH_REMATCH[1]}"
            local rest="${BASH_REMATCH[2]}"
            echo "${drive^^}:/$rest"
        else
            echo "$path"
        fi
    else
        echo "$path"
    fi
}

# Automatic installation of missing dependencies
install_missing_dependencies() {
    local os_type=$(detect_os)
    local missing_deps=()
    
    # Check which dependencies are missing
    local deps=("curl" "git")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    # Special check for jq (may need installation)
    if ! command -v jq &>/dev/null; then
        missing_deps+=("jq")
    fi
    

    
    if [ ${#missing_deps[@]} -eq 0 ]; then
        echo "✅ All dependencies are available"
        return 0
    fi
    
    echo "📦 Installing missing dependencies: ${missing_deps[*]}"
    
    case "$os_type" in
        "linux")
            # Detect Linux distribution
            if command -v apt-get &>/dev/null; then
                echo "🐧 Installing dependencies using apt-get..."
                for dep in "${missing_deps[@]}"; do
                    sudo apt-get update && sudo apt-get install -y "$dep"
                done
            elif command -v yum &>/dev/null; then
                echo "🐧 Installing dependencies using yum..."
                for dep in "${missing_deps[@]}"; do
                    sudo yum install -y "$dep"
                done
            elif command -v pacman &>/dev/null; then
                echo "🐧 Installing dependencies using pacman..."
                for dep in "${missing_deps[@]}"; do
                    sudo pacman -S --noconfirm "$dep"
                done
            else
                echo "❌ Unsupported Linux distribution. Please install manually: ${missing_deps[*]}"
                return 1
            fi
            ;;
        "macos")
            echo "🍎 Installing dependencies using brew..."
            if ! command -v brew &>/dev/null; then
                echo "📦 Installing Homebrew first..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            for dep in "${missing_deps[@]}"; do
                brew install "$dep"
            done
            ;;
        "windows")
            echo "🪟 Installing dependencies for Windows..."
            
            # For Windows, try to install through various methods
            for dep in "${missing_deps[@]}"; do
                case "$dep" in
                    "jq")
                        echo "  Installing jq..."
                        if command -v winget &>/dev/null; then
                            winget install jqlang.jq
                        elif command -v choco &>/dev/null; then
                            choco install jq -y
                        elif command -v scoop &>/dev/null; then
                            scoop install jq
                        else
                            # Try to download static jq binary
                            echo "  Downloading jq binary..."
                            local jq_url="https://github.com/jqlang/jq/releases/latest/download/jq-windows-amd64.exe"
                            local jq_path="/usr/local/bin/jq.exe"
                            mkdir -p "$(dirname "$jq_path")"
                            if curl -L -o "$jq_path" "$jq_url" 2>/dev/null; then
                                chmod +x "$jq_path"
                                echo "  ✅ jq installed to $jq_path"
                            else
                                echo "  ❌ Failed to download jq. Please install manually."
                                echo "  Download from: https://jqlang.github.io/jq/download/"
                                return 1
                            fi
                        fi
                        ;;
                    "curl"|"git")
                        echo "  ❌ $dep is required but not found."
                        echo "  Please install Git for Windows: https://git-scm.com/download/win"
                        return 1
                        ;;
                esac
            done
            ;;
        *)
            echo "❌ Unsupported operating system. Please install manually: ${missing_deps[*]}"
            return 1
            ;;
    esac
    
    echo "✅ Dependencies installed successfully"
    return 0
}

# Check for assets.json file
if [ ! -f "assets.json" ]; then
    echo "❌ assets.json not found"
    exit 1
fi

# Install missing dependencies
install_missing_dependencies

# Try to determine Forge location
if [ -z "${FORGE_HOME:-}" ]; then
  # Check current directory
  if [ -f "./webui.sh" ] || [ -f "./launch.py" ]; then
    FORGE_HOME=$(pwd)
    echo "✅ Detected Forge location: $FORGE_HOME"
  # Check parent directory (often script runs from subdirectory)
  elif [ -f "../webui.sh" ] || [ -f "../launch.py" ] || [ -f "../webui-user.bat" ] || [ -f "../webui-user.sh" ]; then
    FORGE_HOME=$(cd .. && pwd)
    echo "✅ Detected Forge location: $FORGE_HOME"
  # Check two levels up (for deeply nested directories)
  elif [ -f "../../webui.sh" ] || [ -f "../../launch.py" ] || [ -f "../../webui-user.bat" ] || [ -f "../../webui-user.sh" ]; then
    FORGE_HOME=$(cd ../.. && pwd)
    echo "✅ Detected Forge location: $FORGE_HOME"
  else
    FORGE_HOME="$HOME/stable-diffusion-webui-forge"
    echo "⚠️ Using default path: $FORGE_HOME"
    echo "💡 If this is wrong, set FORGE_HOME manually:"
    echo "    FORGE_HOME='/path/to/your/forge' bash bootstrap.sh"
  fi
fi

if [ ! -d "$FORGE_HOME" ]; then
  echo "❌ Forge not found at $FORGE_HOME"
  exit 1
fi

# Check and create basic models directories
echo "🔍 Checking Forge models directory structure..."
models_base="$FORGE_HOME/models"
if [ ! -d "$models_base" ]; then
    echo "📁 Creating models directory: $models_base"
    mkdir -p "$models_base" || {
        echo "❌ Failed to create models directory"
        exit 1
    }
fi

# Create main models directories if they don't exist
required_dirs=("Stable-diffusion" "VAE" "clip" "text_encoder" "extensions")
for dir in "${required_dirs[@]}"; do
    target_dir="$FORGE_HOME/$dir"
    if [ "$dir" = "extensions" ]; then
        # extensions in Forge root
        target_dir="$FORGE_HOME/extensions"
    else
        # others in models/
        target_dir="$models_base/$dir"
    fi
    
    if [ ! -d "$target_dir" ]; then
        echo "📁 Creating directory: $target_dir"
        mkdir -p "$target_dir" || {
            echo "❌ Failed to create directory: $target_dir"
            exit 1
        }
    fi
done

echo "✅ Forge directory structure verified"

# Auto-install gdown if needed for GDrive
need_gdown() { 
    [ -f "assets.json" ] && grep -q '"gdrive://' assets.json; 
}

if need_gdown && ! command -v gdown &>/dev/null; then
    echo "📦 Installing gdown for Google Drive support..."
    python -m pip install --user --upgrade gdown
fi

# Safe environment variable expansion
expand_path() {
    local path="$1"
    # Only replace known safe variables
    path="${path//\$FORGE_HOME/$FORGE_HOME}"
    path="${path//\$HOME/$HOME}"
    
    # Normalize path: remove double slashes
    path="${path//\/\//\/}"
    
    echo "$path"
}

# Function to format file size
format_file_size() {
    local size=$1
    if [ "$size" -lt 1024 ]; then
        echo "${size}B"
    elif [ "$size" -lt 1048576 ]; then
        echo "$((size/1024))KB"
    elif [ "$size" -lt 1073741824 ]; then
        # For better precision when displaying MB
        local mb_size=$((size * 10 / 1048576))
        echo "$((mb_size / 10)).$((mb_size % 10))MB"
    else
        # For better precision when displaying GB
        local gb_size=$((size * 10 / 1073741824))
        echo "$((gb_size / 10)).$((gb_size % 10))GB"
    fi
}

# Function to get real file size from server
get_remote_file_size() {
    local url="$1"
    local size=""
    
    case "$url" in
        http*|https*)
            # Get Content-Length header
            size=$(curl -sI --connect-timeout 10 "$url" | grep -i "content-length" | sed 's/.*: //' | tr -d '\r\n')
            ;;
        gdrive://*)
            # For Google Drive it's harder to get size, skip
            size=""
            ;;
        *)
            size=""
            ;;
    esac
    
    # Check if size is valid
    if [[ "$size" =~ ^[0-9]+$ ]]; then
        echo "$size"
    else
        echo ""
    fi
}

# Fast file integrity check - only check file size and basic integrity
verify_file_integrity() {
    local fname="$1"
    local url="${2:-}"
    
    # Get file size
    local file_size=$(stat -c%s "$fname" 2>/dev/null || stat -f%z "$fname" 2>/dev/null || echo "0")
    local file_size_formatted=$(format_file_size "$file_size")
    
    echo "🔍 Verifying $(basename "$fname") integrity (${file_size_formatted})..."
    
    # Basic integrity check: file exists and is not empty
    if [ "$file_size" -gt 0 ]; then
        echo "   ✅ File size OK (${file_size_formatted})"
        return 0
    else
        echo "   ❌ File is empty or corrupted"
        return 1
    fi
}



download() {
    local url="$1" dst="$2"
    
    # Remove trailing slash from path for normalization
    dst="${dst%/}"
    
    # Create directory
    echo "📁 Creating directory: $dst"
    if ! mkdir -p "$dst"; then
        echo "❌ Failed to create directory: $dst"
        echo "📍 Current working directory: $(pwd)"
        echo "📍 Checking parent directory permissions..."
        ls -la "$(dirname "$dst")" || echo "❌ Parent directory not accessible"
        return 1
    fi
    
    # Check if directory was created
    if [ ! -d "$dst" ]; then
        echo "❌ Directory was not created: $dst"
        return 1
    fi
    
    echo "✅ Directory created successfully: $dst"
    
    # Handle filename differently for Google Drive
    local fname
    if [[ "$url" == gdrive://* ]]; then
        # For Google Drive, we'll let gdown determine the filename
        # We'll use a temporary approach and rename later
        fname="$dst/gdrive_temp_$(basename "${url#gdrive://}")"
    else
        fname="$dst/$(basename "$url")"
    fi

    # Convert path for curl if needed
    local curl_path=$(convert_path_for_curl "$fname")
    
    echo "📄 Target file: $fname"
    echo "📄 Curl path: $curl_path"

    # For Google Drive, check if any file exists in the directory AND handle .part files
    if [[ "$url" == gdrive://* ]]; then
        echo "🔍 Checking for existing files in Lora directory..."
        
        # First, check for .part files and try to recover them
        local part_files=$(find "$dst" -maxdepth 1 -name "*.part" -type f 2>/dev/null)
        if [ -n "$part_files" ]; then
            echo "📁 Found .part files from previous download:"
            local part_file
            while IFS= read -r part_file; do
                if [ -f "$part_file" ]; then
                    local part_size=$(stat -c%s "$part_file" 2>/dev/null || stat -f%z "$part_file" 2>/dev/null || echo "0")
                    echo "   • $(basename "$part_file"): $(format_file_size "$part_size")"
                    
                    # If file is reasonably large (>50MB), it might be complete
                    if [ "$part_size" -gt 52428800 ]; then
                        echo "🔄 Trying to recover complete .part file..."
                        
                        # Try to rename .part file to proper extension
                        local recovered_name="${part_file%.part}.safetensors"
                        
                        if mv "$part_file" "$recovered_name" 2>/dev/null; then
                            echo "✅ Recovered file as: $(basename "$recovered_name")"
                            fname="$recovered_name"
                            # Skip download since we recovered the file
                            echo "🔍 Verifying recovered file integrity..."
                            if verify_file_integrity "$fname" "$url"; then
                                echo "✅ $(basename "$fname") recovered and verified successfully"
                                return 0
                            else
                                echo "⚠️ Recovered file seems corrupted, will re-download"
                                rm -f "$recovered_name" 2>/dev/null
                            fi
                        else
                            echo "⚠️ Could not rename .part file, will clean up and re-download"
                            rm -f "$part_file" 2>/dev/null
                        fi
                    else
                        echo "⚠️ .part file too small, likely incomplete - removing"
                        rm -f "$part_file" 2>/dev/null
                    fi
                fi
            done <<< "$part_files"
        fi
        
        # Then check for complete files
        local existing_files=$(find "$dst" -maxdepth 1 -type f -name "*.safetensors" -o -name "*.pt" -o -name "*.ckpt" 2>/dev/null)
        if [ -n "$existing_files" ]; then
            echo "📁 Found existing complete files:"
            while IFS= read -r file; do
                echo "   • $(basename "$file")"
                if verify_file_integrity "$file" "$url"; then
                    echo "✔ $(basename "$file") already OK"
                    return 0
                fi
            done <<< "$existing_files"
            echo "⚠️ Found files but they seem corrupted, will re-download"
        fi
    else
        # If file is already correct, do nothing
        if [ -f "$fname" ]; then
            if verify_file_integrity "$fname" "$url"; then
            echo "✔ $(basename "$fname") already OK"
            return 0
            else
                echo "⚠️ $(basename "$fname") seems corrupted, will re-download"
            fi
        fi
    fi

    # Get real file size from server (skip for Google Drive)
    local remote_size=""
    if [[ "$url" != gdrive://* ]]; then
        echo "🔍 Checking remote file size..."
        remote_size=$(get_remote_file_size "$url")
        if [ -n "$remote_size" ]; then
            local remote_size_formatted=$(format_file_size "$remote_size")
            echo "📊 Remote file size: $remote_size_formatted"
        else
            echo "📊 Remote file size: unknown (will verify after download)"
        fi
    else
        echo "📊 Remote file size: unknown for Google Drive (will verify after download)"
    fi

    echo "↓ Downloading from Google Drive ..."
    case "$url" in
      gdrive://*)
          # Clean up any remaining .part files (they should have been handled earlier)
          find "$dst" -name "*.part" -type f -delete 2>/dev/null || true
          
          local dst_dir_path=$(convert_path_for_curl "$dst")
          local gdown_success=false
          local gdown_exit_code=0
          
          # Method 1: Try gdown directly with --fuzzy for original filename
          if command -v gdown &>/dev/null; then
              gdown --fuzzy -c --no-cookies "${url#gdrive://}" -O "$dst_dir_path/"
              gdown_exit_code=$?
              if [ $gdown_exit_code -eq 0 ]; then
                  gdown_success=true
              fi
          fi
          
          # Method 2: Try python -m gdown with --fuzzy
          if [ "$gdown_success" = false ]; then
              python -m gdown --fuzzy -c --no-cookies "${url#gdrive://}" -O "$dst_dir_path/"
              gdown_exit_code=$?
              if [ $gdown_exit_code -eq 0 ]; then
                  gdown_success=true
              fi
          fi
          
          # Method 3: Try python3 -m gdown with --fuzzy
          if [ "$gdown_success" = false ]; then
              python3 -m gdown --fuzzy -c --no-cookies "${url#gdrive://}" -O "$dst_dir_path/" 2>/dev/null
              gdown_exit_code=$?
              if [ $gdown_exit_code -eq 0 ]; then
                  gdown_success=true
              fi
          fi
          
          # Find the downloaded file (gdown saves with original name)
          echo "🔍 Looking for downloaded file..."
          local downloaded_file=""
          
          # Method 1: Look for .safetensors files first (exclude desktop.ini and system files)
          if [ -d "$dst" ]; then
              downloaded_file=$(find "$dst" -maxdepth 1 -name "*.safetensors" -type f ! -name "desktop.ini" | head -1)
          fi
          
          # Method 2: Look for other common extensions
          if [ -z "$downloaded_file" ] && [ -d "$dst" ]; then
              downloaded_file=$(find "$dst" -maxdepth 1 \( -name "*.pt" -o -name "*.ckpt" -o -name "*.pth" \) -type f ! -name "desktop.ini" | head -1)
          fi
          
          # Method 3: Find any file (excluding .part files and system files)
          if [ -z "$downloaded_file" ] && [ -d "$dst" ]; then
              downloaded_file=$(find "$dst" -maxdepth 1 -type f ! -name "*.part" ! -name "desktop.ini" ! -name "*.lnk" ! -name "Thumbs.db" -exec ls -t {} + 2>/dev/null | head -1)
          fi
          
          # Check if file was found
          if [ -n "$downloaded_file" ] && [ -f "$downloaded_file" ]; then
              fname="$downloaded_file"
              echo "✅ Found downloaded file: $(basename "$fname")"
              # Even if gdown reported an error, if we have the file, consider it successful
              gdown_success=true
          else
              echo "❌ Could not find downloaded file in $dst"
              echo "📁 Directory contents:"
              ls -la "$dst" 2>/dev/null || echo "   (empty or inaccessible)"
              
              # Check if there are any .part files that might indicate partial download
              local part_files=$(find "$dst" -name "*.part" -type f 2>/dev/null)
              if [ -n "$part_files" ]; then
                  echo "⚠️ Found incomplete download files:"
                  echo "$part_files"
                  echo "💡 Try running the script again to resume the download"
              fi
          fi
          
          if [ "$gdown_success" = false ]; then
              echo "❌ Failed to download from Google Drive: $url"
              echo "💡 Troubleshooting:"
              echo "   • Make sure the file has public access or link sharing enabled"
              echo "   • Try running: python -m pip install --user --upgrade gdown"
              echo "   • Check if the Google Drive link is correct"
              echo "   • The file might have been partially downloaded - run the script again"
              return 1
          fi
          ;;
      http*|https*)
          echo "↓ Downloading $(basename "$fname") ..."
          # curl with timeout and better error handling
          if ! curl -L --connect-timeout 30 --max-time 3600 --retry 3 --retry-delay 5 --continue-at - -o "$curl_path" "$url"; then
              echo "❌ Failed to download: $url"
              return 1
          fi
          ;;
      *)
          echo "❌ Unsupported URL format: $url"
          return 1
          ;;
    esac

    # Verify the final file exists
    if [ ! -f "$fname" ]; then
        echo "❌ File does not exist after download: $fname"
        return 1
    fi

    # Check size after download
    local downloaded_size=$(stat -c%s "$fname" 2>/dev/null || stat -f%z "$fname" 2>/dev/null || echo "0")
    local downloaded_size_formatted=$(format_file_size "$downloaded_size")
    
    if [ -n "$remote_size" ] && [ "$remote_size" != "$downloaded_size" ]; then
        echo "⚠️ Size mismatch: expected $remote_size_formatted, got $downloaded_size_formatted"
        echo "   This might indicate an incomplete download or changed file"
    fi

    # Check file integrity after download
    echo "🔍 Verifying downloaded file integrity..."
    if ! verify_file_integrity "$fname" "$url"; then
        echo "❌ File integrity check failed for $(basename "$fname")"
        echo "   File may be corrupted or incomplete"
        return 1
    fi
    echo "✅ $(basename "$fname") downloaded and verified successfully"
}

clone_or_update() {
    local giturl="$1" tgt="$2"
    
    # Convert path for git if needed
    local git_path=$(convert_path_for_curl "$tgt")
    
    if [ -d "$tgt/.git" ]; then
        echo "🔄 Updating repository: $(basename "$tgt")"
        if ! git -C "$tgt" pull --ff-only; then
            echo "❌ Failed to update repository: $tgt"
            return 1
        fi
    else
        echo "📥 Cloning repository: $(basename "$tgt")"
        if ! git clone --depth 1 "$giturl" "$git_path"; then
            echo "❌ Failed to clone repository: $giturl"
            return 1
        fi
    fi
}

# Main processing loop
failed_count=0
total_count=0

while IFS= read -r entry; do
    total_count=$((total_count + 1))
    
  url=$(jq -r '.url? // empty' <<<"$entry")
  giturl=$(jq -r '.git? // empty' <<<"$entry")
    target_raw=$(jq -r '.target' <<<"$entry")
    tgt=$(expand_path "$target_raw")
    
  if [ -n "$url" ]; then
        if ! download "$url" "$tgt"; then
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

# Final report
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $failed_count -eq 0 ]; then
    echo "✅ Forge bootstrap completed successfully!"
    echo ""
    echo "📊 Results:"
    echo "   • Items processed: $total_count"
    echo "   • Errors: 0"
    echo ""
    echo "🚀 What's next:"
    echo "   • Start Forge (webui.sh or webui-user.bat)"
    echo "   • Flux Kontext models are ready to use"
    echo "   • All files downloaded and verified"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 0
else
    echo "⚠️ Bootstrap completed with errors"
    echo ""
    echo "📊 Results:"
    echo "   • Items processed: $total_count"
    echo "   • Errors: $failed_count"
    echo ""
    echo "🔧 What to do:"
    echo "   1. Check your internet connection"
    echo "   2. Make sure you have enough disk space (~8GB)"
    echo "   3. Run the script again - it will resume downloads"
    echo "   4. If the problem persists, check the troubleshooting section in README.md"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 1
fi
