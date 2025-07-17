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

*Existing files are **verified by SHA-256** and **never re-downloaded** if already correct.*

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
   bash bootstrap.sh
   ```

#### Method 2: Using PowerShell

1. **Open PowerShell as user (not administrator needed):**
   - Press `Win + X` and select "Windows PowerShell"
   - Or search "PowerShell" in Start menu

2. **Navigate to Forge and run:**
   ```powershell
   cd "C:\path\to\your\stable-diffusion-webui-forge"
   git clone https://github.com/molkotok/flux-kontext-for-forge.git
   cd flux-kontext-for-forge
   bash bootstrap.sh
   ```

#### Method 3: Double-click installer (Easiest)

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

1. **Check dependencies** (git, curl, jq, sha256sum)
2. **Detect your Forge location** automatically
3. **Download required files** with progress indicators:
   - Flux model checkpoint (~4GB)
   - VAE file (~300MB)
   - Text encoders (~2GB each)
   - Clone extension repository
4. **Verify file integrity** using SHA-256 checksums
5. **Report completion status**

**Total download:** ~8GB (first run only)  
**Time:** 10-30 minutes depending on internet speed

---

## 🚨 Troubleshooting

### "Command not found" errors

**Windows:**
- Install [Git for Windows](https://git-scm.com/download/win) (includes bash)
- Restart Command Prompt after installation

**Linux/macOS:**
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
2. `~/stable-diffusion-webui-forge`

**To specify custom location:**
```bash
FORGE_HOME="/path/to/your/forge" bash bootstrap.sh
```

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
- ❌ **Corrupted files:** Re-downloaded completely with new SHA-256 verification
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

---

## ➕ Adding extra models or LoRAs

1. Open **`assets.json`** and append:

```json
{
  "url": "https://your.host.com/my-lora.safetensors",
  "target": "$FORGE_HOME/models/Lora/",
  "sha256": "PUT_SHA256_HASH_HERE"
}
```

2. Run **`bash bootstrap.sh`** again – only the new file will be downloaded.

> **How to get a SHA-256 hash**
>
> *Linux / Git Bash / macOS*
> ```bash
> sha256sum my-lora.safetensors
> ```
> *Windows PowerShell*
> ```powershell
> Get-FileHash .\my-lora.safetensors -Algorithm SHA256
> ```

Copy the 64-character hash into `assets.json`.

---

## 📑 bootstrap.bat (Windows users)

```bat
@echo off
REM === Flux Kontext installer for Forge (Windows) ===
if not exist "%~dp0bootstrap.sh" (
    echo Please run this file from inside the "flux-kontext-for-forge" folder.
    pause
    exit /b 1
)

for /F %%i in ('where bash ^2^>nul') do set "BASH=%%i"
if "%BASH%"=="" (
    echo Git Bash not found. Install Git for Windows: https://git-scm.com/download/win
    pause
    exit /b 1
)

"%BASH%" "%~dp0bootstrap.sh"
echo.
echo === Installation finished ===
pause
```

---

## 🤝 Why this repo exists

Setting up Flux Kontext manually involves:
- Finding and downloading multiple large files from different sources
- Placing them in correct Forge directories  
- Verifying file integrity
- Installing the required extension

This installer reduces the whole process to **one command** (or one double-click) and guarantees file integrity via SHA-256.

Enjoy your creative journey with **Flux Kontext in Forge**! 🌀

---

## 📞 Support

If you encounter issues:
1. Check the troubleshooting section above
2. Ensure all prerequisites are installed
3. Try running the script again (it's designed to be re-runnable)
4. Open an issue on GitHub with error details
