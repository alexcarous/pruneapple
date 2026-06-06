import SwiftUI

struct SettingsView: View {
    @Environment(DiskAnalyzer.self) private var diskAnalyzer
    private let permissionManager = PermissionManager.shared
    @State private var activeTab: Tab = .permissions
    
    enum Tab: String, CaseIterable, Identifiable {
        case permissions = "Permissions"
        case advanced = "Advanced"
        case donation = "Support"
        case about = "About"
        
        var id: String { self.rawValue }
        
        var icon: String {
            switch self {
            case .permissions: return "lock.shield"
            case .advanced: return "gearshape.2"
            case .donation: return "heart.fill"
            case .about: return "info.circle"
            }
        }
    }
    
    var body: some View {
        TabView(selection: $activeTab) {
            PermissionsTab()
                .tabItem {
                    Label(activeTabTitle(for: .permissions), systemImage: Tab.permissions.icon)
                }
                .tag(Tab.permissions)
            
            AdvancedTab()
                .tabItem {
                    Label(activeTabTitle(for: .advanced), systemImage: Tab.advanced.icon)
                }
                .tag(Tab.advanced)
            
            DonationView()
                .tabItem {
                    Label(activeTabTitle(for: .donation), systemImage: Tab.donation.icon)
                }
                .tag(Tab.donation)

            AboutTab()
                .tabItem {
                    Label(activeTabTitle(for: .about), systemImage: Tab.about.icon)
                }
                .tag(Tab.about)
        }
        .environment(permissionManager)
        .frame(width: Metrics.settingsWindowWidth, height: Metrics.settingsWindowHeight)
        .padding(Metrics.paddingExtraLarge)
    }
    
    private func activeTabTitle(for tab: Tab) -> String {
        switch tab {
        case .permissions: return String(localized: "Permissions")
        case .advanced: return String(localized: "Advanced")
        case .donation: return String(localized: "Support")
        case .about: return String(localized: "About")
        }
    }
}

struct PermissionsTab: View {
    @Environment(DiskAnalyzer.self) private var diskAnalyzer
    @Environment(PermissionManager.self) private var permissionManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.spacingLarge) {
            // Status Card
            HStack(spacing: Metrics.spacingLarge) {
                ZStack {
                    Circle()
                        .fill(permissionManager.hasFullDiskAccess ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                        .frame(width: Metrics.iconStatus, height: Metrics.iconStatus)
                    
                    Image(systemName: permissionManager.hasFullDiskAccess ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                        .font(.title2)
                        .foregroundColor(permissionManager.hasFullDiskAccess ? .green : .orange)
                }
                
                VStack(alignment: .leading, spacing: Metrics.spacingVerySmall) {
                    Text(String(localized: "Full Disk Access"))
                        .font(.headline)
                    
                    Text(permissionManager.hasFullDiskAccess 
                         ? String(localized: "Pruneapple has full permission to analyze files and folders on your disk.")
                         : String(localized: "Pruneapple lacks Full Disk Access. Some system and user directories will be skipped during analysis."))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(Metrics.cornerRadiusLarge)
            .overlay(
                RoundedRectangle(cornerRadius: Metrics.cornerRadiusLarge)
                    .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
            )
            
            // Instruction panel if FDA not granted
            if !permissionManager.hasFullDiskAccess {
                VStack(alignment: .leading, spacing: Metrics.spacingMedium) {
                    Text(String(localized: "How to grant access:"))
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: Metrics.spacingSmall) {
                        InstructionRow(step: "1", text: String(localized: "Click the \"Open System Settings\" button below."))
                        InstructionRow(step: "2", text: String(localized: "Locate or add \"Pruneapple\" in the Full Disk Access list."))
                        InstructionRow(step: "3", text: String(localized: "Enable the switch next to Pruneapple to grant access."))
                        InstructionRow(step: "4", text: String(localized: "Restart Pruneapple if permissions do not apply immediately."))
                    }
                    
                    Button(action: {
                        permissionManager.openSystemSettings()
                    }) {
                        Label(String(localized: "Open System Settings"), systemImage: "arrow.up.forward.app")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.top, Metrics.paddingSmall)
                }
                .padding(.horizontal, Metrics.paddingSmall)
            } else {
                VStack(alignment: .leading, spacing: Metrics.spacingStandard) {
                    Text(String(localized: "Permissions Active"))
                        .font(.headline)
                    Text(String(localized: "All scanned folders will be parsed correctly. Note: If folders are still being skipped after granting access, you may need to restart Pruneapple for the System FDA permissions to take full effect."))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, Metrics.paddingSmall)
            }
            
            Divider()
            
            // Skipped Paths list
            VStack(alignment: .leading, spacing: Metrics.spacingStandard) {
                HStack {
                    Text(String(localized: "Skipped Folders from Last Scan (\(diskAnalyzer.skippedURLs.count))"))
                        .font(.headline)
                    Spacer()
                    if !diskAnalyzer.skippedURLs.isEmpty {
                        Button(String(localized: "Clear List")) {
                            diskAnalyzer.skippedURLs = []
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.accentColor)
                    }
                }
                
                if diskAnalyzer.skippedURLs.isEmpty {
                    VStack(spacing: Metrics.spacingStandard) {
                        Image(systemName: "folder.badge.checkmark")
                            .font(.title)
                            .foregroundColor(.secondary)
                        Text(String(localized: "No folders were skipped due to permission errors."))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                    .cornerRadius(Metrics.cornerRadiusMedium)
                } else {
                    ScrollView {
                        VStack(spacing: Metrics.spacingTiny) {
                            ForEach(diskAnalyzer.skippedURLs, id: \.self) { url in
                                HStack {
                                    Image(systemName: "folder.badge.minus")
                                        .foregroundColor(.orange)
                                    Text(url.path)
                                        .font(.system(.body, design: .monospaced))
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                    Spacer()
                                    Button(action: {
                                        revealInFinder(url)
                                    }) {
                                        Image(systemName: "magnifyingglass")
                                    }
                                    .buttonStyle(.plain)
                                    .help(String(localized: "Reveal Parent in Finder"))
                                }
                                .padding(.vertical, Metrics.paddingSmall + 2)
                                .padding(.horizontal, Metrics.paddingMedium)
                                .background(Color(NSColor.controlBackgroundColor))
                            }
                        }
                    }
                    .frame(maxHeight: .infinity)
                    .border(Color.secondary.opacity(0.2), width: 1)
                    .cornerRadius(Metrics.cornerRadiusSmall)
                }
            }
        }
        .padding(.vertical, Metrics.paddingMedium)
    }
    
    private func revealInFinder(_ url: URL) {
        let parentURL = url.deletingLastPathComponent()
        NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: parentURL.path)
    }
}

struct InstructionRow: View {
    let step: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: Metrics.spacingStandard) {
            Text(step)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: Metrics.iconSmall, height: Metrics.iconSmall)
                .background(Circle().fill(Color.accentColor))
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

struct AdvancedTab: View {
    @State private var skipHiddenFiles = false
    @State private var skipPackages = false
    
    var body: some View {
        Form {
            Section(header: Text(String(localized: "Scan Rules")).font(.headline)) {
                Toggle(String(localized: "Ignore hidden files and folders"), isOn: $skipHiddenFiles)
                    .help(String(localized: "When enabled, Pruneapple will skip over system hidden items like .DS_Store, .git, etc."))
                
                Toggle(String(localized: "Ignore macOS package contents"), isOn: $skipPackages)
                    .help(String(localized: "When enabled, application bundles (.app) and frameworks (.framework) will be catalogued as simple files rather than directories."))
            }
            .padding(.vertical, Metrics.paddingMedium)
            
            Spacer()
            
            HStack {
                Spacer()
                Text(String(localized: "Pruneapple v1.0.0"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

struct AboutTab: View {
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        VStack(spacing: Metrics.spacingLarge) {
            Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: Metrics.iconLarge, height: Metrics.iconLarge)
                .foregroundColor(.accentColor)
            
            VStack(spacing: Metrics.spacingVerySmall) {
                Text(String(localized: "Pruneapple"))
                    .font(.title)
                    .fontWeight(.bold)
                Text(String(localized: "Version 1.0.0 (Build 1)"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Link("Alexander Caro", destination: URL(string: "https://alex.caro.us")!)
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
                    .padding(.top, Metrics.paddingVerySmall)
                
                Button(action: {
                    openWindow(id: "donation")
                }) {
                    Label(String(localized: "Support Developer"), systemImage: "heart.fill")
                        .foregroundColor(.pink)
                }
                .buttonStyle(.bordered)
                .padding(.top, Metrics.paddingSmall)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: Metrics.spacingStandard) {
                Text(String(localized: "Legalese & Licensing"))
                    .font(.headline)
                
                ScrollView {
                    Text("""
                    MIT License

                    Copyright (c) 2026 Alexander Caro

                    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

                    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

                    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
                    """)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                    .padding(Metrics.paddingMedium)
                }
                .frame(height: Metrics.aboutLicensingHeight)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(Metrics.cornerRadiusSmall)
                .border(Color.secondary.opacity(0.2), width: 0.5)
            }
            
            Spacer()
        }
        .padding(.vertical, Metrics.paddingMedium)
    }
}
