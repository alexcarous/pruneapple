# CleanApple 🍎

Hey there! I'm [Alexander Caro](https://alex.caro.us), and I built CleanApple because I was honestly just tired of not knowing what was eating up all my Mac's storage. 

CleanApple is a native macOS app that scans your disk to find those massive, forgotten files and folders. The best part? It's completely read-only, which means it will never accidentally delete anything important. It's just a tool to help you see what's going on, and then you can decide what to do with that information by revealing it in Finder.

## Why this app?

- **It's safe:** Since it doesn't have a "delete" button, you don't have to sweat about accidentally trashing a critical system file. Just hit Spacebar to QuickLook, or reveal the file in Finder to handle it yourself.
- **It's accurate:** Macs use APFS, which can be tricky with clones and sparse files. CleanApple calculates physical disk usage just like Finder does, so the numbers actually match up.
- **It runs quietly in the background:** Deep scans can take a minute. CleanApple sits in your menu bar, prevents your Mac from napping while it works, and gives you a nice haptic tap when it's done. 
- **Exporting that actually works:** If you want to dump the data to a CSV, it automatically figures out your local delimiters so it doesn't scramble your spreadsheet if you're in Europe.

## Getting Started

You'll need macOS 15.0+ and Swift 6. I use [Mise](https://mise.jdx.dev/) to manage the Tuist version, so make sure you grab that first.

1. **Install Tuist via Mise:**
   ```bash
   mise install
   ```

2. **Generate the Xcode Project:**
   ```bash
   mise exec -- tuist generate
   ```

3. **Build and Run:**
   Open up the generated `.xcodeproj` or `.xcworkspace` in Xcode, select the `CleanApple` scheme, and hit run!

## Running Tests

If you want to run the automated `swift-testing` suite, just run:
```bash
mise exec -- tuist test
```

---
*Built with ❤️ (and a lot of coffee) by [Alexander Caro](https://alex.caro.us).*
