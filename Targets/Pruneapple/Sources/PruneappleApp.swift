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
    @Environment(\.openWindow) private var openWindow
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var diskAnalyzer = DiskAnalyzer()
    @StateObject private var updateManager = UpdateManager()
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(diskAnalyzer)
                .frame(minWidth: Metrics.minWindowWidth, minHeight: Metrics.minWindowHeight)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button(String(localized: "New Scan")) {
                    diskAnalyzer.reset()
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(updater: updateManager.updaterController.updater)
            }
            CommandGroup(replacing: .help) {
                Button(String(localized: "Pruneapple Help")) {
                    if let url = URL(string: "https://alex.caro.us") {
                        NSWorkspace.shared.open(url)
                    }
                }
                
                Divider()
                
                Button(String(localized: "Support Pruneapple")) {
                    openWindow(id: "donation")
                }
            }
        }
        
        Window(String(localized: "Support Pruneapple"), id: "donation") {
            DonationView()
                .frame(width: 520, height: 380)
        }
        .windowResizability(.contentSize)
        
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
    @State private var showThankYou = false
    
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
        .onOpenURL { url in
            if url.scheme == "pruneapple" && url.host == "donate-success" {
                NSApp.activate(ignoringOtherApps: true)
                showThankYou = true
            }
        }
        .sheet(isPresented: $showThankYou) {
            ThankYouView()
        }
    }
}

struct ThankYouView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var animatePopper = false
    
    var body: some View {
        VStack(spacing: Metrics.spacingLarge) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.pink, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: .pink.opacity(0.3), radius: 8)
                
                Image(systemName: "heart.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.white)
                    .scaleEffect(animatePopper ? 1.15 : 0.85)
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.3)
                        .repeatForever(autoreverses: true),
                        value: animatePopper
                    )
            }
            .padding(.top, Metrics.paddingExtraLarge)
            .onAppear {
                animatePopper = true
            }
            
            VStack(spacing: Metrics.spacingVerySmall) {
                Text(String(localized: "Thank You!"))
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(String(localized: "Your donation directly supports the development of Pruneapple. We appreciate your generosity!"))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Metrics.paddingExtraLarge)
            }
            
            Button(String(localized: "You're Welcome")) {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
            .padding(.bottom, Metrics.paddingExtraLarge)
        }
        .frame(width: 380, height: 260)
        .padding()
    }
}

struct WelcomeView: View {
    @Environment(DiskAnalyzer.self) private var diskAnalyzer
    @Binding var dragOver: Bool
    @Environment(\.openWindow) private var openWindow
    
    @AppStorage("successfulScanCount") private var successfulScanCount = 0
    @AppStorage("hasDismissedDonationBanner") private var hasDismissedDonationBanner = false
    
    var body: some View {
        VStack(spacing: Metrics.spacingNone) {
            if successfulScanCount >= 3 && !hasDismissedDonationBanner {
                donationBanner
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            VStack(spacing: Metrics.spacingExtraLarge) {
                Spacer()
                
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
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(dragOver ? Color.accentColor.opacity(0.05) : Color.clear)
        }
    }
    
    private var donationBanner: some View {
        HStack(spacing: Metrics.spacingLarge) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.pink, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                
                Image(systemName: "heart.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: "Enjoying Pruneapple?"))
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(String(localized: "You've completed \(successfulScanCount) successful scans! Please consider supporting development."))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(String(localized: "Support Developer")) {
                openWindow(id: "donation")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            
            Button(action: {
                withAnimation(.spring()) {
                    hasDismissedDonationBanner = true
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .help(String(localized: "Dismiss"))
        }
        .padding(.horizontal, Metrics.paddingExtraLarge)
        .padding(.vertical, Metrics.paddingLarge)
        .background(
            RoundedRectangle(cornerRadius: Metrics.cornerRadiusMedium)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: Color.black.opacity(0.08), radius: 6, y: 2)
        )
        .padding([.horizontal, .top], Metrics.paddingExtraLarge)
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


