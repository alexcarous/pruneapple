import SwiftUI
import UniformTypeIdentifiers

@main
struct CleanAppleApp: App {
    @State private var diskAnalyzer = DiskAnalyzer()
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(diskAnalyzer)
                .frame(minWidth: 600, minHeight: 400)
        }
        .windowStyle(.hiddenTitleBar)
        
        MenuBarExtra {
            MenuBarView()
                .environment(diskAnalyzer)
                .frame(width: 280, height: 160)
        } label: {
            MenuBarLabel()
                .environment(diskAnalyzer)
        }
        .menuBarExtraStyle(.window)
    }
}

struct MainView: View {
    @Environment(DiskAnalyzer.self) private var diskAnalyzer
    @State private var dragOver = false
    
    var body: some View {
        VStack(spacing: 0) {
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
            Task {
                await diskAnalyzer.startScan(at: firstURL)
            }
            return true
        } isTargeted: { targeted in
            dragOver = targeted
        }
        .alert("Scan Failed", isPresented: Binding(
            get: { diskAnalyzer.errorMessage != nil },
            set: { show in
                if !show {
                    diskAnalyzer.errorMessage = nil
                }
            }
        )) {
            Button("OK", role: .cancel) {}
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
        VStack(spacing: 20) {
            Image(systemName: "internaldrive.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .foregroundColor(dragOver ? .accentColor : .secondary)
                .scaleEffect(dragOver ? 1.1 : 1.0)
                .animation(.spring(), value: dragOver)
            
            Text("CleanApple Disk Analyzer")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Drag and drop a folder here, or select one below to scan physical disk usage.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button("Select Folder to Scan...") {
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
        openPanel.prompt = "Scan Folder"
        
        openPanel.begin { response in
            if response == .OK, let url = openPanel.url {
                Task {
                    await diskAnalyzer.startScan(at: url)
                }
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
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(.circular)
            
            Text("Scanning Disk...")
                .font(.headline)
            
            VStack(spacing: 4) {
                Text("Files Scanned: \(diskAnalyzer.progressFiles)")
                Text("Space Tallied: \(byteFormatter.string(fromByteCount: diskAnalyzer.progressBytes))")
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
                    .padding(.horizontal, 40)
            }
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

struct MenuBarView: View {
    @Environment(DiskAnalyzer.self) private var diskAnalyzer
    
    private let byteFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("CleanApple Scan")
                    .font(.headline)
                Spacer()
                if diskAnalyzer.isScanning {
                    ProgressView()
                        .controlSize(.small)
                }
            }
            
            Divider()
            
            if diskAnalyzer.isScanning {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Scanned: \(byteFormatter.string(fromByteCount: diskAnalyzer.progressBytes))")
                    Text("Files: \(diskAnalyzer.progressFiles)")
                }
                .font(.body)
                .monospacedDigit()
            } else if let rootItem = diskAnalyzer.rootItem {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Last Scan: \(rootItem.name)")
                        .fontWeight(.semibold)
                    Text("Total Space: \(byteFormatter.string(fromByteCount: rootItem.physicalSize))")
                }
                .font(.body)
            } else {
                Text("No active scans.")
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
    }
}
