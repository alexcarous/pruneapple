# Pruneapple ✂🍍

Pruneapple is a native, read-only macOS app that scans your disk to find those forgotten files and folders. It never deletes anything or modifies your system. It's just a tool to help you see what's going on, and then you can decide what to do by revealing the files in Finder.

## Why this app?

- **It's safe:** Since it doesn't have a "delete" button, you don't have to worry about accidentally trashing a critical system file. Just hit Spacebar to QuickLook, or reveal the file in Finder to handle it yourself.
- **It's accurate:** Macs use APFS, which can be tricky with clones and sparse files. Pruneapple calculates physical disk usage just like Finder does, so the numbers actually match up.
- **It runs quietly in the background:** Deep scans can take a minute. Pruneapple sits in your menu bar, prevents your Mac from napping while it works, and gives you a nice haptic tap when it's done. 
- **Exporting that actually works:** You can export your data to a CSV for analysis in Excel, Numbers, Google Sheets, etc. It also features internationalisation so it automatically figures out your local delimiters if you're in Europe.

## Getting Started

You'll need macOS 15.0+ and Swift 6.

1. **Install Tuist via Mise:**
   ```bash
   mise install
   ```

2. **Generate the Xcode Project:**
   ```bash
   mise exec -- tuist generate
   ```

3. **Build and Run:**
   Open up the generated `.xcodeproj` or `.xcworkspace` in Xcode, select the `Pruneapple` scheme, and hit run!

## Running Tests

If you want to run the automated `swift-testing` suite, just run:
```bash
make test
```
