# Pruneapple ✂🍍

[![Download Pre-Compiled App](https://img.shields.io/badge/Download-Ready--to--Run%20(.app)--$9.99-brightgreen?style=for-the-badge&logo=apple)](https://alex.caro.us)
[![Build from Source](https://img.shields.io/badge/Source%20Code-Open--Source-orange?style=for-the-badge&logo=github)](https://github.com/alexcarous/pruneapple)

Pruneapple is a beautiful Liquid Glass, open-source, read-only macOS application that scans your disk to find forgotten files and folders. It is designed for safety: it never deletes anything or modifies your system, allowing you to audit your files risk-free and reveal them in Finder when you're ready to clean up.

---

## Download Options: Convenience vs. Code

Pruneapple is fully open-source. We believe in transparency and giving you total control over your system. You can choose to download our ready-to-run release or build it yourself.

| Feature | Pre-Compiled (`.app` download) | Build from Source (Free) |
| :--- | :---: | :---: |
| **Ready-to-Run** | ✅ One-click install | ❌ Requires Xcode, Tuist, & Mise |
| **Gatekeeper Signed** | ✅ Safe out-of-the-box | ❌ Requires self-signing / bypass |
| **Auto-Updates** | ✅ Seamless via Sparkle | ❌ Requires manual `git pull` & rebuild |
| **Supports Dev** | ✅ Direct Support | 💛 (Spread the word!) |

### [👉 Get the Pre-Compiled App ($9.99)](https://alex.caro.us)
*Directly supports independent development, includes automatic updates, and runs securely without macOS security warning overrides.*

---

## Why Pruneapple?

- **Designed for Safety:** Because it is read-only, you don't have to worry about a bug or misclick deleting system-critical files. Review suggestions, use QuickLook, and delete files yourself in Finder.
- **Finder-Accurate Scanning:** macOS APFS volume structures utilize clone-files and sparse files, making standard calculators inaccurate. Pruneapple calculates exact physical disk usage to match Finder values.
- **Smart Prune AI Heuristics:** Employs local, on-device Apple Intelligence heuristics to automatically analyze and suggest large candidate files for pruning without compromising your privacy.
- **Background Execution:** Long scans run quietly. Pruneapple rests in your menu bar, prevents system sleep while analyzing, and delivers a haptic tap on your trackpad when finished.
- **CSV Data Export:** Export full directories and details to CSV formats with automatic delimiter detection based on your locale.

---

## Building from Source (Free)

If you prefer to compile Pruneapple yourself, you will need macOS 15.0+ and Xcode 16.0+ installed.

### 1. Install Dependencies
Ensure you have `mise` installed, then run:
```bash
mise install
```

### 2. Generate Xcode Project
Create the local workspace and project configurations using Tuist:
```bash
mise exec -- tuist generate
```

### 3. Build & Run
Open the generated `Pruneapple.xcworkspace` in Xcode, select the `Pruneapple` scheme, and click **Run** (Cmd + R).

### Running Tests
To run the automated test suite locally:
```bash
make test
```

---

## License

This project is licensed under the MIT License - see the LICENSE file for details.
