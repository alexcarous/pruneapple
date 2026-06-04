# CleanApple

CleanApple is a native, standalone macOS application built to safely and rapidly analyze disk space. It identifies large files and folders that are consuming storage without requiring the user to use the terminal.

## Key Features
- **100% Read-Only Scanning:** Completely safe execution model. Absolutely no files are modified, moved, or deleted by the application.
- **Physical Size Accuracy:** Accurately calculates physical disk usage (accounting for APFS clones and sparse files) matching Finder base-10 metrics.
- **Background Status Indicator:** Integrates with the macOS Menu Bar (`MenuBarExtra`) so deep scans can run in the background with live progress tracking and App Nap prevention.
- **Interactive Results:** Sortable, drill-down hierarchical tree with QuickLook (Spacebar) previews and haptic feedback notifications upon completion.
- **Safe Resolution:** Provides a "Reveal in Finder" action for all items, leaving file trashing to native macOS flows.
- **Localized Delimiters:** Privacy-conscious CSV exports that dynamically adapt separators according to local numerical formatting (avoiding spreadsheet corruption in Europe).

## Prerequisites
- macOS 15.0+
- Swift 6
- [Mise](https://mise.jdx.dev/) (for managing the Tuist version)

## Installation & Setup

1. **Install Dependencies:**
   Ensure you have `mise` installed on your machine. Run the following command in the project root to install Tuist:
   ```bash
   mise install
   ```

2. **Generate Xcode Project:**
   Generate the local `.xcodeproj` or `.xcworkspace` structure using:
   ```bash
   mise exec -- tuist generate
   ```

3. **Build & Run:**
   Open the generated project workspace in Xcode and run the `CleanApple` scheme.

## Testing
To run the automated `swift-testing` suite:
```bash
mise exec -- tuist test
```
