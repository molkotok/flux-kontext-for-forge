# 🚀 Forge + Flux Kontext Installer

This is a simple one-command installer that sets up everything needed to use **Flux Kontext** in [Forge (Stable Diffusion WebUI)](https://github.com/lllyasviel/stable-diffusion-webui-forge).

It automatically downloads:
- ✅ Flux checkpoint
- ✅ VAE
- ✅ CLIP + T5 encoders
- ✅ `forge2_flux_kontext` extension

## 📦 How to install

> Prerequisite: You already have Forge installed and launched at least once.

```bash
git clone https://github.com/<your-username>/forge-flux-installer.git
cd forge-flux-installer
bash bootstrap.sh
