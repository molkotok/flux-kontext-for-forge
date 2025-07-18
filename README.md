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

You can easily add your own models to the installer. Supported sources:
- **Hugging Face** links
- **Google Drive** links 
- **Direct HTTP/HTTPS** links
- **Git repositories**

### 🎨 Adding Lora models

1. **Open `assets.json`** and add a new entry:

   **For Hugging Face:**
   ```json
   {
     "url": "https://huggingface.co/user/model/resolve/main/lora.safetensors",
     "target": "$FORGE_HOME/models/Lora/",
     "size": 0.5
   }
   ```

   **For Google Drive:**
   ```json
   {
     "url": "gdrive://1Vfr7GEt-3vlGKoa29dQKPxY6ahGk_bGc",
     "target": "$FORGE_HOME/models/Lora/",
     "size": 0.2
   }
   ```

   **For direct links:**
   ```json
   {
     "url": "https://example.com/my-lora.safetensors",
     "target": "$FORGE_HOME/models/Lora/",
     "size": 0.3
   }
   ```

### 🔗 How to get the correct Google Drive link

1. **Your link looks like this:**
   ```
   https://drive.google.com/file/d/1Vfr7GEt-3vlGKoa29dQKPxY6ahGk_bGc/view?usp=drive_link
   ```

2. **Extract the file ID** (part between `/d/` and `/view`):
   ```
   1Vfr7GEt-3vlGKoa29dQKPxY6ahGk_bGc
   ```

3. **Use the format `gdrive://ID`:**
   ```
   gdrive://1Vfr7GEt-3vlGKoa29dQKPxY6ahGk_bGc
   ```

### 📁 Model types and folders

| Model Type | Folder | Example |
|------------|--------|---------|
| **Lora** | `$FORGE_HOME/models/Lora/` | Styles, characters |
| **Checkpoint** | `$FORGE_HOME/models/Stable-diffusion/` | Base models |
| **VAE** | `$FORGE_HOME/models/VAE/` | Autoencoders |
| **Embedding** | `$FORGE_HOME/embeddings/` | Text embeddings |
| **ControlNet** | `$FORGE_HOME/models/ControlNet/` | ControlNet models |

### 🔧 Running after adding

**Run the installer again** - only new files will be downloaded:
```bash
bash bootstrap.sh
```

**Important:** Make sure files on Google Drive have public access or link sharing enabled!

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
