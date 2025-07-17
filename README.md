# 🚀 Flux Kontext Installer for Forge

*One-command setup of Flux Kontext model for Forge (Stable Diffusion WebUI).*

## 📋 What this installs

- **Flux checkpoint** (11.0GB) → `models/Stable-diffusion/`
- **VAE** (320MB) → `models/VAE/`
- **Text encoders** (4.5GB + 235MB) → `models/text_encoder/` + `models/clip/`
- **Extension** → `extensions/forge2_flux_kontext/`

**Total download:** ~16GB • **Time:** 15-30 minutes

---

## 🚀 Installation

### Prerequisites
- **[Forge](https://github.com/lllyasviel/stable-diffusion-webui-forge)** installed and working
- **Git** installed
- **~16GB free space**

### Windows
1. **Open Command Prompt in your Forge folder:**
   - Go to your Forge folder in Explorer
   - Type `cmd` in the address bar → Enter

2. **Run installer:**
   ```cmd
   git clone https://github.com/molkotok/flux-kontext-for-forge.git
   cd flux-kontext-for-forge
   bootstrap.bat
   ```

### Linux/macOS
1. **Navigate to your Forge folder:**
   ```bash
   cd ~/stable-diffusion-webui-forge
   ```

2. **Run installer:**
   ```bash
   git clone https://github.com/molkotok/flux-kontext-for-forge.git
   cd flux-kontext-for-forge
   bash bootstrap.sh
   ```

---

## 🚨 Troubleshooting

### "Git not found" or "bash not found" (Windows)
**Solution:** Install [Git for Windows](https://git-scm.com/download/win)

### "Forge not found" error
**Solution:** Set the correct path:
```bash
FORGE_HOME="/path/to/your/forge" bash bootstrap.sh
```

### Downloads fail or are slow
**Solution:** 
- Check internet connection
- Rerun the script - it will resume from where it stopped
- Make sure you have enough disk space (~16GB)

### Files verification is fast
File verification now uses size checks only and completes in under 1 second per file:
- ✅ **Checks file size** (instant)
- ✅ **Compares with server file size** (when available)

**No waiting required** - verification is now instant!

---

## ➕ Adding custom models

1. **Edit `assets.json`:**
   ```json
   {
     "url": "https://example.com/my-model.safetensors",
     "target": "$FORGE_HOME/models/Lora/",
     "size": 1.5
   }
   ```

2. **Run installer again** - only new files will be downloaded

---

## 📑 For Windows users: bootstrap.bat

The `bootstrap.bat` automatically:
- **Finds Git Bash** on your system
- **Validates files** (bootstrap.sh and assets.json exist)
- **Runs the installation**

Just double-click it!

---

## 🎯 What this installer does

Instead of manually:
- Finding and downloading multiple large files from different sources
- Placing them in correct Forge directories  
- Verifying files
- Installing the required extension

This installer reduces the whole process to **one command** (or one double-click) and ensures file integrity.

Enjoy your creative journey with **Flux Kontext in Forge**! 🌀
