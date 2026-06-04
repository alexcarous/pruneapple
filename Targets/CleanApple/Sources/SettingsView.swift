import SwiftUI

struct SettingsView: View {
    @Environment(DiskAnalyzer.self) private var diskAnalyzer
    private let permissionManager = PermissionManager.shared
    @State private var activeTab: Tab = .permissions
    
    enum Tab: String, CaseIterable, Identifiable {
        case permissions = "Permissions"
        case advanced = "Advanced"
        
        var id: String { self.rawValue }
        
        var icon: String {
            switch self {
            case .permissions: return "lock.shield"
            case .advanced: return "gearshape.2"
            }
        }
    }
    
    var body: some View {
        TabView(selection: $activeTab) {
            PermissionsTab()
                .tabItem {
                    Label(Tab.permissions.rawValue, systemImage: Tab.permissions.icon)
                }
                .tag(Tab.permissions)
            
            AdvancedTab()
                .tabItem {
                    Label(Tab.advanced.rawValue, systemImage: Tab.advanced.icon)
                }
                .tag(Tab.advanced)
        }
        .environment(permissionManager)
        .frame(width: 520, height: 420)
        .padding()
    }
}

struct PermissionsTab: View {
    @Environment(DiskAnalyzer.self) private var diskAnalyzer
    @Environment(PermissionManager.self) private var permissionManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Status Card
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(permissionManager.hasFullDiskAccess ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: permissionManager.hasFullDiskAccess ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                        .font(.title2)
                        .foregroundColor(permissionManager.hasFullDiskAccess ? .green : .orange)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Full Disk Access")
                        .font(.headline)
                    
                    Text(permissionManager.hasFullDiskAccess 
                         ? "CleanApple has full permission to analyze files and folders on your disk."
                         : "CleanApple lacks Full Disk Access. Some system and user directories will be skipped during analysis.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
            )
            
            // Instruction panel if FDA not granted
            if !permissionManager.hasFullDiskAccess {
                VStack(alignment: .leading, spacing: 10) {
                    Text("How to grant access:")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        InstructionRow(step: "1", text: "Click the \"Open System Settings\" button below.")
                        InstructionRow(step: "2", text: "Locate or add \"CleanApple\" in the Full Disk Access list.")
                        InstructionRow(step: "3", text: "Enable the switch next to CleanApple to grant access.")
                        InstructionRow(step: "4", text: "Restart CleanApple if permissions do not apply immediately.")
                    }
                    
                    Button(action: {
                        permissionManager.openSystemSettings()
                    }) {
                        Label("Open System Settings", systemImage: "arrow.up.forward.app")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.top, 4)
                }
                .padding(.horizontal, 4)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Permissions Active")
                        .font(.headline)
                    Text("All scanned folders will be parsed correctly. Note: If folders are still being skipped after granting access, you may need to restart CleanApple for the System FDA permissions to take full effect.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 4)
            }
            
            Divider()
            
            // Skipped Paths list
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Skipped Folders from Last Scan (\(diskAnalyzer.skippedURLs.count))")
                        .font(.headline)
                    Spacer()
                    if !diskAnalyzer.skippedURLs.isEmpty {
                        Button("Clear List") {
                            diskAnalyzer.skippedURLs = []
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.accentColor)
                    }
                }
                
                if diskAnalyzer.skippedURLs.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "folder.badge.checkmark")
                            .font(.title)
                            .foregroundColor(.secondary)
                        Text("No folders were skipped due to permission errors.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                    .cornerRadius(8)
                } else {
                    ScrollView {
                        VStack(spacing: 1) {
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
                                    .help("Reveal Parent in Finder")
                                }
                                .padding(.vertical, 6)
                                .padding(.horizontal, 8)
                                .background(Color(NSColor.controlBackgroundColor))
                            }
                        }
                    }
                    .frame(maxHeight: .infinity)
                    .border(Color.secondary.opacity(0.2), width: 1)
                    .cornerRadius(4)
                }
            }
        }
        .padding(.vertical, 8)
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
        HStack(alignment: .top, spacing: 8) {
            Text(step)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 18, height: 18)
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
            Section(header: Text("Scan Rules").font(.headline)) {
                Toggle("Ignore hidden files and folders", isOn: $skipHiddenFiles)
                    .help("When enabled, CleanApple will skip over system hidden items like .DS_Store, .git, etc.")
                
                Toggle("Ignore macOS package contents", isOn: $skipPackages)
                    .help("When enabled, application bundles (.app) and frameworks (.framework) will be catalogued as simple files rather than directories.")
            }
            .padding(.vertical, 8)
            
            Spacer()
            
            HStack {
                Spacer()
                Text("CleanApple v1.0.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}
