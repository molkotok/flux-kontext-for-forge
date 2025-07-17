# 🚀 Flux Kontext Installer for Forge

*Simple one-command setup of the Flux Kontext model inside Forge (Stable Diffusion WebUI).*

---

## 📋 What this repo does

| ✅ Installs automatically | 📂 Target folder in Forge |
|--------------------------|---------------------------|
| Flux checkpoint (`.safetensors`) | `models/Stable-diffusion/` |
| Flux VAE | `models/VAE/` |
| T5-XXL text encoder | `models/text_encoder/` |
| CLIP-L text encoder | `models/clip/` |
| `forge2_flux_kontext` extension | `extensions/forge2_flux_kontext/` |

*Existing files are **verified** and **never re-downloaded** if already correct.*

---

## 🚀 Quick Start Guide

### 📋 Prerequisites

- **[Forge (Stable Diffusion WebUI)](https://github.com/lllyasviel/stable-diffusion-webui-forge)** installed and working
- **Git** installed on your system
- **Internet connection** for downloading files (~8GB total)

> **Don't have Forge yet?** Install it from the [official repository](https://github.com/lllyasviel/stable-diffusion-webui-forge) first. Make sure it runs at least once without errors before using this installer.

### 🪟 Windows Users (Step-by-Step)

#### Method 1: Using Command Prompt (Recommended for beginners)

1. **Navigate to your Forge folder:**
   - Open Windows Explorer
   - Go to your Forge installation folder (usually `C:\Users\YourName\stable-diffusion-webui-forge`)
   - Click in the address bar and type `cmd`, then press Enter
   - Command Prompt will open in that folder

2. **Run the installer:**
   ```cmd
   git clone https://github.com/molkotok/flux-kontext-for-forge.git
   cd flux-kontext-for-forge
   bootstrap.bat
   ```
   
   **Alternative method:**
```cmd
bootstrap.bat
```

#### Method 2: Using Git Bash (If bootstrap.bat doesn't work)

1. **Navigate to your Forge folder:**
   - Open Windows Explorer
   - Go to your Forge installation folder
   - Right-click in empty space → "Git Bash Here"

2. **Run the installer:**
   ```bash
   git clone https://github.com/molkotok/flux-kontext-for-forge.git
   cd flux-kontext-for-forge
   bash bootstrap.sh
   ```

#### Method 3: Using PowerShell

1. **Open PowerShell as user (not administrator needed):**
   - Press `Win + X` and select "Windows PowerShell"
   - Or search "PowerShell" in Start menu

2. **Navigate to Forge and run:**
   ```powershell
   cd "C:\path\to\your\stable-diffusion-webui-forge"
   git clone https://github.com/molkotok/flux-kontext-for-forge.git
   cd flux-kontext-for-forge
   ./bootstrap.bat
   ```

#### Method 4: Double-click installer (Easiest)

1. **Download this repository:**
   - Click the green "Code" button → "Download ZIP"
   - Extract to your Forge folder

2. **Double-click `bootstrap.bat`** and wait for completion

### 🐧 Linux Users (Step-by-Step)

#### Method 1: Using File Manager + Terminal

1. **Open your file manager** (Nautilus, Dolphin, etc.)
2. **Navigate to your Forge folder** (usually `~/stable-diffusion-webui-forge`)
3. **Right-click in empty space** → "Open in Terminal" (or similar option)
4. **Run the installer:**
   ```bash
   git clone https://github.com/molkotok/flux-kontext-for-forge.git
   cd flux-kontext-for-forge
   bash bootstrap.sh
   ```

#### Method 2: Using Terminal only

1. **Open Terminal** (`Ctrl+Alt+T`)
2. **Navigate to Forge and run:**
   ```bash
   cd ~/stable-diffusion-webui-forge  # or your custom path
   git clone https://github.com/molkotok/flux-kontext-for-forge.git
   cd flux-kontext-for-forge
   bash bootstrap.sh
   ```

### 🍎 macOS Users

1. **Open Terminal** (`Cmd+Space`, type "Terminal")
2. **Navigate to Forge and run:**
   ```bash
   cd ~/stable-diffusion-webui-forge  # or your custom path
   git clone https://github.com/molkotok/flux-kontext-for-forge.git
   cd flux-kontext-for-forge
   bash bootstrap.sh
   ```

---

## 🔄 What to expect during installation

The installer will:

1. **Check dependencies** (git, curl, jq)
2. **Auto-install missing dependencies** if needed:
   - Linux: Uses apt-get/yum/pacman
   - macOS: Uses Homebrew (installs it if needed)
   - Windows: Uses winget/choco/scoop or downloads binaries
3. **Detect your Forge location** automatically
4. **Download required files** with progress indicators:
   - Flux model checkpoint (~4GB)
   - VAE file (~300MB)
   - Text encoders (~2GB each)
   - Clone extension repository
5. **Verify file integrity** using size checks
6. **Report completion status**

**Total download:** ~8GB (first run only)  
**Time:** 10-25 minutes (depends on internet speed)

**File verification:** Instant (size check only)

**Note:** File verification ensures basic integrity and is very fast.

---

## 🚨 Troubleshooting

### What is jq and why do I need it?

**jq** is a command-line JSON processor that the installer uses to:
- Parse the `assets.json` file (read URLs, paths)
- Extract specific fields from JSON data
- Process each file entry for downloading

**Good news:** The installer automatically installs jq if it's missing!

### "Command not found" errors

**The installer now auto-installs missing dependencies!** But if you encounter issues:

**Windows:**
- Install [Git for Windows](https://git-scm.com/download/win) (includes bash)
- **Important:** In regular Command Prompt, use `bootstrap.bat` instead of `bash bootstrap.sh`
- If you want to use `bash bootstrap.sh`, right-click in folder → "Git Bash Here"
- Restart Command Prompt after Git installation

**If you see "WSL ERROR: CreateProcessCommon" when running `bash bootstrap.sh`:**
```cmd
# Instead of this (which causes WSL error):
bash bootstrap.sh

# Use this in Command Prompt:
bootstrap.bat

# Or switch to Git Bash:
# Right-click in folder → "Git Bash Here", then run: bash bootstrap.sh
```

**Linux/macOS (manual installation if auto-install fails):**
```bash
# Ubuntu/Debian
sudo apt install git curl jq

# CentOS/RHEL
sudo yum install git curl jq

# macOS
brew install git curl jq
```

### "Forge not found" error

The script tries to find Forge in these locations:
1. Current directory (if contains `webui.sh` or `launch.py`)
2. Parent directory (if contains `webui.sh`, `launch.py`, `webui-user.bat`, etc.)
3. Two levels up (for deeply nested folders)
4. `~/stable-diffusion-webui-forge` (default fallback)

**To specify custom location:**
```bash
FORGE_HOME="/path/to/your/forge" bash bootstrap.sh
```

**Example for your case:**
```bash
FORGE_HOME="D:/~Модели/Forge-StableDif/webui" bash bootstrap.sh
```

### "Failed to create directory" or "No such file or directory" errors

If you see curl errors like `Failed to open the file`, this usually means:

**On Windows:**
- The script couldn't create the target directories
- **Solution:** The script now automatically creates all required directories and converts paths properly for Windows
- If it still fails, try running Command Prompt as Administrator

**Common fixes:**
1. **Check disk space** - you need ~8GB free
2. **Check permissions** - make sure you can write to the Forge directory
3. **Try different location** - avoid paths with special characters or spaces
4. **Re-run the script** - it will show detailed directory creation info

### Download interruptions

If download fails or is interrupted:
1. **Simply re-run the script** - it will resume where it left off
2. Already downloaded files are verified and skipped
3. Only missing/corrupted files are re-downloaded

**Common recovery scenarios:**
- **Internet connection dropped:** Re-run the script - downloads will resume from where they stopped
- **Window was closed accidentally:** No problem! Just run the script again
- **Computer was shut down:** All progress is saved, restart the script normally
- **Specific file failed:** The script will skip good files and re-download only the failed ones

**What happens during recovery:**
- ✅ **Good files:** `✔ filename.safetensors already OK` (skipped)
- ⚠️ **Partial downloads:** Downloads resume from the last byte
- ❌ **Corrupted files:** Re-downloaded completely with integrity verification
- 🔄 **Git repositories:** Automatically pulled to latest version

**Example recovery process:**
```bash
# If installation was interrupted, just run the same commands again:
cd flux-kontext-for-forge
bash bootstrap.sh
# The script will show: "✔ filename.safetensors already OK" for completed files
# and download only the missing ones
```

**Recovery is automatic** - no manual intervention needed!

### File verification is fast

File verification now uses size checks only and completes in under 1 second per file:
- ✅ **Checks file size** (instant)
- ✅ **Compares with server file size** (when available)

**No waiting required** - verification is now instant!

---

## ➕ Adding extra models or LoRAs

1. Open **`assets.json`** and append:

```json
{
  "url": "https://your.host.com/my-lora.safetensors",
  "target": "$FORGE_HOME/models/Lora/",
  "size": 1.5
}
```

**JSON fields:**
- `url`: Download URL (required)
- `target`: Installation directory (required)
- `size`: Expected file size in GB (optional, improves display)

2. Run **`bash bootstrap.sh`** again – only the new file will be downloaded.

> **How to check file info**
>
> *Linux / Git Bash / macOS*
> ```bash
> ls -la my-lora.safetensors
> ```
> *Windows PowerShell*
> ```powershell
> Get-ItemProperty .\my-lora.safetensors | Select-Object Name, Length
> ```

Use the file size info to add to `assets.json`.

---

## 📑 bootstrap.bat (Windows users)

The `bootstrap.bat` file automatically:
- **Finds Git Bash** on your system (checks common installation locations)
- **Validates files** (ensures bootstrap.sh and assets.json exist)
- **Runs the installer** with proper error handling
- **Shows helpful messages** if something goes wrong

**Features:**
- ✅ Automatically detects Git Bash installation
- ✅ Provides clear error messages and solutions
- ✅ Shows installation progress and results
- ✅ Handles common installation issues

**If bootstrap.bat doesn't work:**
1. Install [Git for Windows](https://git-scm.com/download/win)
2. Right-click in folder → "Git Bash Here"
3. Run: `bash bootstrap.sh`

---

## 🤝 Why this repo exists

Setting up Flux Kontext manually involves:
- Finding and downloading multiple large files from different sources
- Placing them in correct Forge directories  
- Verifying files
- Installing the required extension

This installer reduces the whole process to **one command** (or one double-click) and ensures file integrity.

Enjoy your creative journey with **Flux Kontext in Forge**! 🌀

---

## 📞 Support

If you encounter issues:
1. Check the troubleshooting section above
2. Ensure all prerequisites are installed
3. Try running the script again (it's designed to be re-runnable)
4. Open an issue on GitHub with error details
