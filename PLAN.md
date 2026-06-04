# CleanApple Development Plan

## Objective
Convert the terminal-based disk space analysis script into a native, standalone macOS application with a graphical user interface (GUI). The app will allow users to scan their disk space, view results interactively, and export the report without needing to use the terminal.

**CRITICAL SAFETY MANDATE:** The application must operate in a **100% read-only mode**. The analysis methodology must guarantee that absolutely no files are deleted, modified, or moved during the scanning process. All destructive actions are explicitly delegated to the macOS Finder to ensure maximum user safety.

## Architecture & Tech Stack
*   **Platform:** macOS 13.0+
*   **Language:** Swift 5.x
*   **UI Framework:** SwiftUI
*   **Execution:** `Process` (formerly `NSTask`) to execute the underlying Unix commands securely from within the app.
*   **Packaging:** Standard `.app` bundle, which can be moved to the Applications folder. *(Note: This architecture explicitly relies on Developer ID signing for outside-the-App-Store distribution, as wrapping Unix binaries via `Process` violates strict App Store sandbox rules).*
*   **Security & Stability Protocols:**
    *   *App Sandbox:* Enforced read-only file access via OS-level Entitlements.
    *   *Hardcoded System Binaries:* Direct invocation of `/bin/df`, `/usr/bin/du`, and `/usr/bin/find` to prevent shell injection or aliasing attacks.
    *   *Argument Isolation:* Command arguments passed as explicit data arrays via the `Process` API, never as concatenated shell strings.
    *   *Process Timeouts:* Hard limits on execution time (e.g., 60 seconds) to prevent CPU lockups on massive or network-mounted drives.
    *   *Process Cancellation (Orphan Prevention):* Strict lifecycle management. If the user cancels the scan or quits the app, the Swift application will explicitly send a termination signal (`SIGTERM`) to the underlying Unix `Process` to prevent zombie processes from leaking memory or CPU in the background.
    *   *Stream Parsing (OOM Prevention):* The application will read standard output (`stdout`) asynchronously line-by-line via a `Pipe` and `FileHandle`, rather than buffering the entire output into memory. This ensures a flat memory footprint even if millions of files are scanned.
    *   *Lossy String Encoding:* Output parsing will utilize `String(decoding: data, as: UTF8.self)` to prevent the parser from crashing when encountering malformed bytes, emojis, or legacy MacRoman characters in filenames.
    *   *Graceful Error Handling:* Explicit redirection and isolation of `stderr` to prevent permission-denied errors from crashing the parser.
    *   *Symlink Safety:* Strict enforcement of non-traversal for symbolic links (avoiding `-L` flags) to prevent infinite loops and memory exhaustion.
    *   *Concurrency Locks:* Strict state management to ensure only one scan operation can exist in memory or access disk I/O at any given time, preventing thread explosion or disk thrashing if the user spams the UI.
    *   *APFS Sparse File Awareness:* Documentation/flags to account for APFS logical vs. physical sizes, ensuring the app reports actionable disk space rather than phantom clone space.

## Core Components
1.  **ShellManager:** A Swift class responsible for asynchronously executing the shell commands and returning standard output.
2.  **DiskAnalyzer:** A view model (ObservableObject) that orchestrates the scans:
    *   System Overall Usage (`df -h /`)
    *   Top 20 Folders (`du -sh "$HOME"/* | sort -hr | head -n 20`)
    *   Large Files > 1GB (`find "$HOME" -type f -size +1G`)
    *   Cache Size (`du -sh "$HOME/Library/Caches"`)
    *   *Optional System Scans:* `/Library/Caches` and `/Library/Application Support` (if toggled by user).
3.  **UI/UX (SwiftUI Views):**
    *   *Main View:* A clean interface with a "Start Analysis" button and an "Include System Shared Folders" toggle.
    *   *TCC Privacy Guidance:* If the scan detects it is being blocked by macOS from reading standard folders (Downloads, Documents), the UI will display a helper banner prompting the user to grant "Full Disk Access" in System Settings.
    *   *Progress State:* A spinning `ProgressView` during background execution.
    *   *Results View:* Tabbed or list view showing the categorized results.
    *   *Interactive Rows:* Parsed output allowing users to click a "Reveal in Finder" button (via `NSWorkspace`) to locate the file/folder immediately.
    *   *Export Button:* Prompts an `NSSavePanel` to save the raw results as a `.txt` report.

## Implementation Steps
1.  **Scaffolding:** Initialize a Swift Package or raw Swift files and compile them into a `.app` bundle using `swiftc` or standard Xcode project structures (via `xcodegen` for CLI-friendly setup).
2.  **Permissions:** Add the required entitlements/Info.plist keys (e.g., Full Disk Access instructions, if necessary, though querying `$HOME` usually requires standard user permissions or prompting).
3.  **Core Logic Implementation:** Write the `ShellManager` and `DiskAnalyzer`.
4.  **UI Implementation:** Build the SwiftUI interface.
5.  **Build & Package:** Compile the Swift code, structure the `CleanApple.app/Contents/MacOS` directory, copy the binary, and create the `Info.plist`.
6.  **Testing:** Run the app to verify it successfully reads disk space and formats the output without hanging the main thread.

## Future Considerations
*   Implement data visualization (pie charts for disk usage).
