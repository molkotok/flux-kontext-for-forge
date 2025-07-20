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
    local url="$1" dst="$2" entry="$3"
    
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
    
    # Get the expected final filename - check if specified in JSON first
    local final_filename=""
    
    # Check if filename is specified in the JSON entry
    local specified_filename=$(echo "$entry" | jq -r '.filename? // empty' 2>/dev/null)
    
    if [ -n "$specified_filename" ]; then
        final_filename="$specified_filename"
        echo "✅ Using filename from JSON: $final_filename"
    elif [[ "$url" == gdrive://* ]]; then
        # For Google Drive without specified filename, use ID-based name
        local drive_id="${url#gdrive://}"
        final_filename="google-drive-${drive_id}.safetensors"
        echo "⚠️ No filename specified, using generic: $final_filename"
    else
        # For other URLs, use the basename
        final_filename="$(basename "$url")"
        echo "✅ Using filename from URL: $final_filename"
    fi
    
    # Create temporary filename (final name + .part)
    local temp_filename="${final_filename}.part"
    local temp_file="$dst/$temp_filename"
    local final_file="$dst/$final_filename"
    
    # Set fname to final file path for later use
    fname="$final_file"
    
    # Convert path for curl if needed
    local curl_path=$(convert_path_for_curl "$temp_file")
    
    echo "📄 Final file: $final_file"
    echo "📄 Temp file: $temp_file"

    # Universal file checking logic for all URL types
    echo "🔍 Checking for existing files..."
    
    # First, check if final file already exists
    if [ -f "$final_file" ]; then
        echo "✅ Found existing file: $(basename "$final_file")"
        if verify_file_integrity "$final_file" "$url"; then
            echo "✔ $(basename "$final_file") already OK"
            return 0
        else
            echo "⚠️ $(basename "$final_file") seems corrupted, will re-download"
            rm -f "$final_file" 2>/dev/null
        fi
    fi
    
    # Then check for .part file to recover
    if [ -f "$temp_file" ]; then
        local part_size=$(stat -c%s "$temp_file" 2>/dev/null || stat -f%z "$temp_file" 2>/dev/null || echo "0")
        echo "📁 Found existing .part file: $(basename "$temp_file") ($(format_file_size "$part_size"))"
        
        # If file is reasonably large (>50MB), it might be complete
        if [ "$part_size" -gt 52428800 ]; then
            echo "🔄 Trying to recover complete .part file..."
            
            # Try to rename .part file to final name
            if mv "$temp_file" "$final_file" 2>/dev/null; then
                echo "✅ Recovered file as: $(basename "$final_file")"
                # Verify the recovered file
                echo "🔍 Verifying recovered file integrity..."
                if verify_file_integrity "$final_file" "$url"; then
                    echo "✅ $(basename "$final_file") recovered and verified successfully"
                    return 0
                else
                    echo "⚠️ Recovered file seems corrupted, will re-download"
                    rm -f "$final_file" 2>/dev/null
                fi
            else
                echo "⚠️ Could not rename .part file, will clean up and re-download"
                rm -f "$temp_file" 2>/dev/null
            fi
                 else
             echo "⚠️ .part file exists but is small ($(format_file_size "$part_size"))"
             echo "   Will resume download from where it left off"
         fi
     fi
     
     # Clean up any old .part files that don't match our naming scheme
     local old_part_files=$(find "$dst" -maxdepth 1 -name "*.part" -type f ! -name "$(basename "$temp_file")" 2>/dev/null)
     if [ -n "$old_part_files" ]; then
         echo "🧹 Cleaning up old .part files..."
         while IFS= read -r old_part; do
             echo "   • Removing: $(basename "$old_part")"
             rm -f "$old_part" 2>/dev/null || true
         done <<< "$old_part_files"
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

    echo "↓ Downloading $(basename "$final_filename") ..."
    local download_success=false
    
    case "$url" in
      gdrive://*)
          local drive_id="${url#gdrive://}"
          
          # Check if we already have a partial download
          if [ -f "$temp_file" ]; then
              local temp_size=$(stat -c%s "$temp_file" 2>/dev/null || stat -f%z "$temp_file" 2>/dev/null || echo "0")
              echo "🔄 Resuming download from $(format_file_size "$temp_size")"
          fi
          
          # Method 1: Try gdown directly
          if command -v gdown &>/dev/null; then
              if gdown -c --no-cookies "https://drive.google.com/uc?id=${drive_id}" -O "$curl_path"; then
                  download_success=true
              fi
          fi
          
          # Method 2: Try python -m gdown
          if [ "$download_success" = false ]; then
              if python -m gdown -c --no-cookies "https://drive.google.com/uc?id=${drive_id}" -O "$curl_path"; then
                  download_success=true
              fi
          fi
          
          # Method 3: Try python3 -m gdown
          if [ "$download_success" = false ]; then
              if python3 -m gdown -c --no-cookies "https://drive.google.com/uc?id=${drive_id}" -O "$curl_path" 2>/dev/null; then
                  download_success=true
              fi
          fi
          
          if [ "$download_success" = false ]; then
              echo "❌ Failed to download from Google Drive: $url"
              echo "💡 Troubleshooting:"
              echo "   • Make sure the file has public access or link sharing enabled"
              echo "   • Try running: python -m pip install --user --upgrade gdown"
              echo "   • Check if the Google Drive link is correct"
              return 1
          fi
          ;;
      http*|https*)
          # curl with timeout and better error handling
          if curl -L --connect-timeout 30 --max-time 3600 --retry 3 --retry-delay 5 --continue-at - -o "$curl_path" "$url"; then
              download_success=true
          else
              echo "❌ Failed to download: $url"
              return 1
          fi
          ;;
      *)
          echo "❌ Unsupported URL format: $url"
          return 1
          ;;
    esac
    
    # After successful download, rename temp file to final name
    if [ "$download_success" = true ] && [ -f "$temp_file" ]; then
        echo "🔄 Finalizing download..."
        if mv "$temp_file" "$final_file" 2>/dev/null; then
            echo "✅ Successfully saved as: $(basename "$final_file")"
            fname="$final_file"
        else
            echo "⚠️ Could not rename file, but download succeeded"
            fname="$temp_file"
        fi
    elif [ "$download_success" = true ]; then
        echo "⚠️ Download reported success but temporary file not found"
        echo "📁 Directory contents:"
        ls -la "$dst" 2>/dev/null || echo "   (empty or inaccessible)"
        return 1
    fi

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

# Function to install Python requirements
install_python_requirements() {
    local requirements_json="$1"
    local extension_name="$2"
    
    if [ -z "$requirements_json" ] || [ "$requirements_json" = "null" ]; then
        return 0
    fi
    
    echo "📦 Installing Python requirements for $(basename "$extension_name")..."
    
    # Parse requirements from JSON
    local packages=$(echo "$requirements_json" | jq -r 'to_entries[] | "\(.key)==\(.value)"' 2>/dev/null)
    
    if [ -z "$packages" ]; then
        echo "   ⚠️ No valid requirements found"
        return 0
    fi
    
    local success_count=0
    local total_count=0
    
    while IFS= read -r package_spec; do
        if [ -n "$package_spec" ]; then
            total_count=$((total_count + 1))
            echo "   📦 Installing: $package_spec"
            
            # Try different pip commands
            if python -m pip install --user "$package_spec" 2>/dev/null; then
                echo "   ✅ Successfully installed: $package_spec"
                success_count=$((success_count + 1))
            elif python3 -m pip install --user "$package_spec" 2>/dev/null; then
                echo "   ✅ Successfully installed: $package_spec"
                success_count=$((success_count + 1))
            else
                echo "   ❌ Failed to install: $package_spec"
                echo "   💡 You may need to install this manually: pip install $package_spec"
            fi
        fi
    done <<< "$packages"
    
    if [ $success_count -eq $total_count ]; then
        echo "✅ All Python requirements installed successfully for $(basename "$extension_name")"
        return 0
    else
        echo "⚠️ Some Python requirements failed to install for $(basename "$extension_name")"
        echo "   Success: $success_count/$total_count"
        return 1
    fi
}

clone_or_update() {
    local giturl="$1" tgt="$2" commit="$3" requirements="$4"
    
    # Convert path for git if needed
    local git_path=$(convert_path_for_curl "$tgt")
    
    if [ -d "$tgt/.git" ]; then
        echo "✅ Repository already exists: $(basename "$tgt")"
        echo "   Skipping update to preserve compatibility"
        echo "   💡 To update manually: cd '$tgt' && git pull"
        return 0
    else
        echo "📥 Cloning repository: $(basename "$tgt")"
        if [ -n "$commit" ]; then
            echo "   📌 Using specific commit: $commit"
            if ! git clone --depth 1 "$giturl" "$git_path"; then
                echo "❌ Failed to clone repository: $giturl"
                return 1
            fi
            # Checkout specific commit
            cd "$git_path" || {
                echo "❌ Failed to change to repository directory: $git_path"
                return 1
            }
            if ! git checkout "$commit" 2>/dev/null; then
                echo "⚠️ Failed to checkout commit $commit, trying to fetch and checkout..."
                if ! git fetch origin "$commit" && git checkout "$commit"; then
                    echo "❌ Failed to checkout specific commit: $commit"
                    echo "   Repository cloned but may be at different commit"
                    cd - > /dev/null || true
                    return 1
                fi
            fi
            cd - > /dev/null || true
            echo "✅ Successfully cloned and checked out commit: $(basename "$tgt") @ $commit"
        else
            echo "   📌 Using latest commit (no specific commit specified)"
            if ! git clone --depth 1 "$giturl" "$git_path"; then
                echo "❌ Failed to clone repository: $giturl"
                return 1
            fi
            echo "✅ Successfully cloned: $(basename "$tgt")"
        fi
        
        # Install Python requirements if specified
        if [ -n "$requirements" ] && [ "$requirements" != "null" ]; then
            install_python_requirements "$requirements" "$tgt"
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
    commit=$(jq -r '.commit? // empty' <<<"$entry")
    python_requirements=$(jq -r '.python_requirements? // empty' <<<"$entry")
    target_raw=$(jq -r '.target' <<<"$entry")
    tgt=$(expand_path "$target_raw")
    
    if [ -n "$url" ]; then
        if ! download "$url" "$tgt" "$entry"; then
            failed_count=$((failed_count + 1))
        fi
    elif [ -n "$giturl" ]; then
        if ! clone_or_update "$giturl" "$tgt" "$commit" "$python_requirements"; then
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
    echo "⚠️ Note: Extensions were installed with specific commits for compatibility"
    echo "   To update manually: cd extension_folder && git pull"
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
