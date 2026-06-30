# Pruneapple ✂🍍

Pruneapple is an open-source, read-only macOS application that scans your disk to locate large files and folders. It does not delete or modify files directly, allowing you to safely audit disk space and reveal items in Finder when you are ready to clean them up.

## Installation

You can download the precompiled app or build it from source.

### Precompiled App
Download the latest `Pruneapple.zip` from the [Releases](https://github.com/alexcarous/pruneapple/releases) page and drag the app to your `/Applications` folder.

> [!NOTE]
> Because the precompiled binary is distributed directly and is unsigned, macOS will show a Gatekeeper warning on first launch. To open it, right-click (or Control-click) the application icon, select **Open**, and click **Open** in the confirmation dialog. Alternatively, clear the quarantine attribute:
> ```bash
> xattr -d com.apple.quarantine /Applications/Pruneapple.app
> ```

### Building from Source
You will need macOS 15.0+ and Xcode 16.0+ installed.

1. **Install Dependencies:**
   Ensure you have `mise` installed, then run:
   ```bash
   mise install
   ```
2. **Generate Xcode Project:**
   Create the local workspace and project configurations using Tuist:
   ```bash
   mise exec -- tuist generate
   ```
3. **Build & Run:**
   Open the generated `Pruneapple.xcworkspace` in Xcode, select the `Pruneapple` scheme, and run the project (Cmd + R).

### Running Tests
To run the automated test suite locally:
```bash
make test
```

## Supporting the Project
If you find Pruneapple useful and want to support its ongoing development, you can make a voluntary contribution:
* **Stripe Donations:** Donate via Stripe inside the app (**Help > Support Pruneapple**).
* **Star the Repository:** Support the project by starring the repository on GitHub.

## Why Pruneapple?
* **Designed for Safety:** Because it is read-only, you don't have to worry about a bug or misclick deleting system-critical files. Review suggestions, use QuickLook, and delete files yourself in Finder.
* **Finder-Accurate Scanning:** macOS APFS volume structures utilize clone-files and sparse files, making standard calculators inaccurate. Pruneapple calculates exact physical disk usage to match Finder values.
* **Smart Prune AI Heuristics:** Employs local, on-device Apple Intelligence heuristics to automatically analyze and suggest large candidate files for pruning without compromising your privacy.
* **Background Execution:** Long scans run quietly. Pruneapple rests in your menu bar, prevents system sleep while analyzing, and delivers a haptic tap on your trackpad when finished.
* **CSV Data Export:** Export full directories and details to CSV formats with automatic delimiter detection based on your locale.

## License
This project is licensed under the MIT License - see the LICENSE file for details.
