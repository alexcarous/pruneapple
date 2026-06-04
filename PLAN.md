# CleanApple Development Plan

## Objective
Convert the terminal-based disk space analysis script into a native, standalone macOS application with a graphical user interface (GUI). The app will allow users to scan their disk space, view results interactively, and export the report without needing to use the terminal.

**CRITICAL SAFETY MANDATE:** The application must operate in a **100% read-only mode**. The analysis methodology must guarantee that absolutely no files are deleted, modified, or moved during the scanning process. All destructive actions are explicitly delegated to the macOS Finder to ensure maximum user safety.

## Architecture & Tech Stack
*   **Platform:** macOS 14.0+ (Mandatory for `@Observable` and modern concurrency).
*   **Language:** Swift 6.
*   **UI Framework:** SwiftUI.
*   **Execution:** 100% Native Apple Frameworks (`Foundation`, `CoreServices`). **No shell processes or Unix binaries are used.**
*   **Packaging:** Standard `.app` bundle.
*   **Security & Stability Protocols:**
    *   *App Sandbox Compatibility:* Because the app uses native `FileManager` APIs rather than invoking shell binaries, it is fundamentally compatible with strict App Store sandboxing (requiring user-selected directories) or Developer ID distribution with Full Disk Access.
    *   *Memory-Safe Concurrency:* Utilizes Swift 6 `withThrowingDiscardingTaskGroup` for recursive directory sizing. This guarantees that file paths are continuously destroyed after their size is tallied, keeping the heap memory footprint flat even when scanning millions of files.
    *   *APFS Physical Sizing:* Queries `URLResourceValues.totalFileAllocatedSizeKey` to calculate true physical disk usage, accurately accounting for APFS clones and sparse files rather than misleading logical sizes.
    *   *Spotlight Integration:* Replaces slow recursive file crawls for large files with `NSMetadataQuery` (CoreSpotlight), returning instantaneous results for files > 1GB.
    *   *UI Throttling:* Main Actor UI updates during recursive scans are chunked (e.g., every 250ms) using Async-Algorithms to prevent main thread blocking and ensure buttery smooth rendering.
    *   *Execution Timeouts:* Hard 300-second timeout on background `Task` execution to prevent hangs on unresponsive network drives or degraded APFS clusters.
    *   *Traversal Bounding:* Explicit application of `.skipsSubdirectoryDescendants` on opaque system volumes to avert permission lockups.

## Core Components
1.  **ScannerEngine:** A Swift `actor` ensuring strict thread safety during concurrent disk I/O operations.
2.  **DiskAnalyzer:** A view model using the `@Observable` macro to manage state:
    *   System Overall Usage (`URLResourceValues.volumeAvailableCapacityForImportantUsageKey` on `/`)
    *   Top Folders (Native `FileManager.default.enumerator` aggregating sizes using `totalFileAllocatedSizeKey`)
    *   Large Files > 1GB (Native `NSMetadataQuery` filtering by `kMDItemFSSize`)
    *   *Optional System Scans:* `/Library/Caches` and `/Library/Application Support`
3.  **UI/UX (SwiftUI Views):**
    *   *Main View:* Clean interface with "Start Analysis" and "Include System Folders" toggle.
    *   *TCC Privacy Guidance:* Banner prompting users to grant "Full Disk Access" in System Settings to analyze protected folders (Downloads, Documents).
    *   *APFS Warning:* UI indicator clarifying that due to APFS cloning, deleting a file may not yield 1:1 physical storage reclamation.
    *   *Progress State:* Spinning `ProgressView` with throttled status updates.
    *   *Interactive Rows:* Formatted using `ByteCountFormatter(.countStyle = .file)` to match Finder's Base-10 math. Includes a "Reveal in Finder" button (via `NSWorkspace`).
    *   *Export Button:* Prompts `NSSavePanel` to save the results.

## Implementation Steps
1.  **Scaffolding:** Initialize a Swift Package or raw Swift files and compile them into a `.app` bundle using `swiftc` or standard Xcode project structures (via `xcodegen` for CLI-friendly setup).
2.  **Permissions:** Add the required entitlements/Info.plist keys (e.g., Full Disk Access usage description).
3.  **Core Logic Implementation:** Write the `ScannerEngine` actor and `DiskAnalyzer` observable class.
4.  **UI Implementation:** Build the SwiftUI interface with `ByteCountFormatter` and throttled updates.
5.  **Build & Package:** Compile the Swift code, structure the `CleanApple.app/Contents/MacOS` directory, copy the binary, and create the `Info.plist`.
6.  **Testing:** Run the app to verify it successfully reads disk space via native APIs and formats the output without hanging the main thread.

## Future Considerations
*   Implement data visualization (pie charts for disk usage).
