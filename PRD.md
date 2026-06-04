# Product Requirement Document (PRD) - CleanApple

## Problem Statement
Users frequently run out of disk space on macOS but struggle to identify which files or folders are the main culprits. Existing tools are either expensive, require command-line knowledge, or perform dangerous, automated cleaning operations that risk deleting important user files.

## Proposed Solution
CleanApple is a lightweight, Native Swift macOS application that provides visual, interactive disk analysis. It operates in a strict read-only mode to guarantee user safety and leverages modern macOS capabilities (like MenuBarExtra, App Sandbox drag-and-drop, and Spotlight metadata querying) to provide a premium, modern experience.

## Key Features
1. **Interactive Hierarchical File List:** A SwiftUI Tree Table showing the physical size of items, permitting users to drill down into large directories.
2. **Drag-and-Drop Dropzone:** Seamless directory targeting by dropping folders directly onto the main window or the Menu Bar icon.
3. **Menu Bar Status Extra:** Real-time visual progress indicator in the status bar that prevents App Nap when the main window is closed.
4. **Spotlight Core Index Integration:** Immediate results for files larger than 1GB.
5. **Haptic Notifications & QuickLook:** Spacebar file preview inside the app, and physical trackpad haptic pulses on scan completion.
6. **Privacy-Conscious Export:** Generates CSV exports utilizing localized decimal separators and warns users about PII leakage.

## Success Criteria
- Flat memory footprint during deep scans of >1,000,000 files.
- Accurate reporting of APFS physical size.
- 100% test coverage for the core `ScannerEngine`.
