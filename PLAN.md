# CleanApple Development Plan

## Objective
Convert the terminal-based disk space analysis script into a native, standalone macOS application with a graphical user interface (GUI). The app will allow users to scan their disk space, view results interactively, and export the report without needing to use the terminal.

## Architecture & Tech Stack
*   **Platform:** macOS 13.0+
*   **Language:** Swift 5.x
*   **UI Framework:** SwiftUI
*   **Execution:** `Process` (formerly `NSTask`) to execute the underlying Unix commands (`df`, `du`, `find`) securely from within the app.
*   **Packaging:** Standard `.app` bundle, which can be moved to the Applications folder.

## Core Components
1.  **ShellManager:** A Swift class responsible for asynchronously executing the shell commands and returning standard output.
2.  **DiskAnalyzer:** A view model (ObservableObject) that orchestrates the scans:
    *   System Overall Usage (`df -h /`)
    *   Top 20 Folders (`du -sh "$HOME"/* | sort -hr | head -n 20`)
    *   Large Files > 1GB (`find "$HOME" -type f -size +1G`)
    *   Cache Size (`du -sh "$HOME/Library/Caches"`)
3.  **UI/UX (SwiftUI Views):**
    *   *Main View:* A clean, modern interface with a "Start Analysis" button.
    *   *Progress State:* A loading indicator/spinner during the scan (as `du` and `find` can take a moment).
    *   *Results View:* Tabbed or segmented view showing the categorized results (Overall, Large Folders, Large Files, Caches).
    *   *Export Button:* Prompts an `NSSavePanel` to save the results as a `.txt` report.

## Implementation Steps
1.  **Scaffolding:** Initialize a Swift Package or raw Swift files and compile them into a `.app` bundle using `swiftc` or standard Xcode project structures (via `xcodegen` for CLI-friendly setup).
2.  **Permissions:** Add the required entitlements/Info.plist keys (e.g., Full Disk Access instructions, if necessary, though querying `$HOME` usually requires standard user permissions or prompting).
3.  **Core Logic Implementation:** Write the `ShellManager` and `DiskAnalyzer`.
4.  **UI Implementation:** Build the SwiftUI interface.
5.  **Build & Package:** Compile the Swift code, structure the `CleanApple.app/Contents/MacOS` directory, copy the binary, and create the `Info.plist`.
6.  **Testing:** Run the app to verify it successfully reads disk space and formats the output without hanging the main thread.

## Future Considerations
*   Add functionality to securely delete selected files (requires elevated privileges and careful sandboxing).
*   Implement data visualization (pie charts for disk usage).
