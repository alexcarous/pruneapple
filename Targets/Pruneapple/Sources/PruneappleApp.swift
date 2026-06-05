import SwiftUI
import UniformTypeIdentifiers

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}

@main
struct PruneappleApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var diskAnalyzer = DiskAnalyzer()
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(diskAnalyzer)
                .frame(minWidth: Metrics.minWindowWidth, minHeight: Metrics.minWindowHeight)
        }
        .windowStyle(.hiddenTitleBar)
        
        Settings {
            SettingsView()
                .environment(diskAnalyzer)
        }
        
        MenuBarExtra {
            Button(String(localized: "Open Pruneapple")) {
                NSApp.activate(ignoringOtherApps: true)
                if let window = NSApp.windows.first {
                    window.makeKeyAndOrderFront(nil)
                }
            }
            
            Divider()
            
            Button(String(localized: "Quit Pruneapple")) {
                NSApplication.shared.terminate(nil)
            }
        } label: {
            MenuBarLabel()
                .environment(diskAnalyzer)
        }
    }
}

struct MainView: View {
    @Environment(DiskAnalyzer.self) private var diskAnalyzer
    @State private var dragOver = false
    
    var body: some View {
        VStack(spacing: Metrics.spacingNone) {
            // Drag-and-Drop overlay if dragging
            if diskAnalyzer.isScanning {
                ScanningProgressView()
            } else if let rootItem = diskAnalyzer.rootItem {
                ResultTableView(rootItem: rootItem)
                    .transition(.opacity)
            } else {
                WelcomeView(dragOver: $dragOver)
            }
        }
        .dropDestination(for: URL.self) { items, _ in
            guard let firstURL = items.first else { return false }
            diskAnalyzer.startScan(at: firstURL)
            return true
        } isTargeted: { targeted in
            dragOver = targeted
        }
        .alert(String(localized: "Scan Failed"), isPresented: Binding(
            get: { diskAnalyzer.errorMessage != nil },
            set: { show in
                if !show {
                    diskAnalyzer.errorMessage = nil
                }
            }
        )) {
            Button(String(localized: "OK"), role: .cancel) {}
        } message: {
            if let errorMessage = diskAnalyzer.errorMessage {
                Text(errorMessage)
            }
        }
    }
}

struct WelcomeView: View {
    @Environment(DiskAnalyzer.self) private var diskAnalyzer
    @Binding var dragOver: Bool
    
    var body: some View {
        VStack(spacing: Metrics.spacingExtraLarge) {
            Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: Metrics.iconHuge, height: Metrics.iconHuge)
                .foregroundColor(dragOver ? .accentColor : .secondary)
                .scaleEffect(dragOver ? 1.1 : 1.0)
                .animation(.spring(), value: dragOver)
            
            Text(String(localized: "Pruneapple Disk Analyzer"))
                .font(.title)
                .fontWeight(.bold)
            
            Text(String(localized: "Drag and drop a folder here, or select one below to scan physical disk usage."))
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Metrics.paddingDoubleExtraLarge)
            
            Button(String(localized: "Select Folder to Scan...")) {
                selectFolderAndScan()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(dragOver ? Color.accentColor.opacity(0.05) : Color.clear)
    }
    
    private func selectFolderAndScan() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.prompt = String(localized: "Scan Folder")
        
        openPanel.begin { response in
            if response == .OK, let url = openPanel.url {
                diskAnalyzer.startScan(at: url)
            }
        }
    }
}

struct ScanningProgressView: View {
    @Environment(DiskAnalyzer.self) private var diskAnalyzer
    
    private let byteFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: Metrics.spacingLarge) {
            ProgressView()
                .progressViewStyle(.circular)
            
            Text(String(localized: "Scanning Disk..."))
                .font(.headline)
            
            VStack(spacing: Metrics.spacingVerySmall) {
                Text(String(localized: "Files Scanned: \(diskAnalyzer.progressFiles)"))
                Text(String(localized: "Space Tallied: \(byteFormatter.string(fromByteCount: diskAnalyzer.progressBytes))"))
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            .monospacedDigit()
            
            if !diskAnalyzer.currentScanningPath.isEmpty {
                Text(diskAnalyzer.currentScanningPath)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .padding(.horizontal, Metrics.paddingDoubleExtraLarge)
            }
            
            Button(String(localized: "Stop Scan"), role: .destructive) {
                diskAnalyzer.cancelScan()
            }
            .buttonStyle(.bordered)
            .padding(.top, Metrics.paddingMedium)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct MenuBarLabel: View {
    @Environment(DiskAnalyzer.self) private var diskAnalyzer
    
    var body: some View {
        if diskAnalyzer.isScanning {
            // Animated pie chart / progress simulator
            Image(systemName: "chart.pie.fill")
                .symbolEffect(.bounce, options: .repeating)
        } else {
            Image(systemName: "internaldrive")
        }
    }
}


