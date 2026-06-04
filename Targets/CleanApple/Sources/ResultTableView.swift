import SwiftUI
import QuickLookUI

@MainActor
class QuickLookController: NSObject, @preconcurrency QLPreviewPanelDataSource, @preconcurrency QLPreviewPanelDelegate {
    static let shared = QuickLookController()
    
    private var currentPreviewURL: URL?
    
    func showPreview(url: URL) {
        currentPreviewURL = url
        if QLPreviewPanel.sharedPreviewPanelExists() && QLPreviewPanel.shared().isVisible {
            QLPreviewPanel.shared().reloadData()
        } else {
            QLPreviewPanel.shared().dataSource = self
            QLPreviewPanel.shared().delegate = self
            QLPreviewPanel.shared().makeKeyAndOrderFront(nil)
        }
    }
    
    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        return currentPreviewURL != nil ? 1 : 0
    }
    
    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
        return currentPreviewURL as QLPreviewItem?
    }
}

struct ResultTableView: View {
    @Environment(DiskAnalyzer.self) private var diskAnalyzer
    @Environment(\.openSettings) private var openSettings
    
    let rootItem: FileItem
    
    @State private var displayItem: FileItem
    @State private var sortOrder = [KeyPathComparator(\FileItem.physicalSize, order: .reverse)]
    @State private var selectedItem: FileItem.ID? = nil
    @State private var showInfoPopover = false
    
    @State private var displayMode: DisplayMode = .outline
    
    enum DisplayMode {
        case outline
        case sunburst
    }
    
    private let byteFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter
    }()
    
    init(rootItem: FileItem) {
        self.rootItem = rootItem
        self._displayItem = State(initialValue: rootItem)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Picker("Display", selection: $displayMode) {
                    Image(systemName: "list.bullet.indent").tag(DisplayMode.outline)
                    Image(systemName: "chart.pie").tag(DisplayMode.sunburst)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 100)
                
                Text("Physical Space Used")
                    .font(.headline)
                    .padding(.leading, 8)
                
                Button(action: {
                    showInfoPopover.toggle()
                }) {
                    Image(systemName: "info.circle")
                }
                .buttonStyle(.plain)
                .help("APFS physical allocated size. This may differ from Finder's logical size due to sparse files and clones.")
                .popover(isPresented: $showInfoPopover, arrowEdge: .bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Physical Disk Space")
                            .font(.headline)
                        Text("CleanApple measures the actual physical sectors allocated on disk by APFS. This accounts for:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Sparse Files: files that take less space than their logical size.", systemImage: "doc.text.fill")
                            Label("APFS Clones: duplicated files that share blocks and use zero additional space.", systemImage: "doc.on.doc.fill")
                            Label("Compression: system-compressed files.", systemImage: "arrow.down.forward.and.arrow.up.backward")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(width: 320)
                }
                
                Spacer()
                
                Button("Export CSV") {
                    CSVExporter.export(rootItem)
                }
            }
            .padding(.horizontal)
            .padding(.top, 10)
            
            if !diskAnalyzer.skippedURLs.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Some folders were skipped because CleanApple lacks permission to read them.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("Fix in Settings...") {
                        if #available(macOS 14.0, *) {
                            openSettings()
                        } else {
                            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                        }
                    }
                    .buttonStyle(.link)
                    
                    Button(action: {
                        diskAnalyzer.skippedURLs = []
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(6)
                .padding(.horizontal)
            }
            
            if displayMode == .outline {
                Table(displayItem.children ?? [], children: \.children, selection: $selectedItem, sortOrder: $sortOrder) {
                    TableColumn("Name", value: \.name) { item in
                        HStack(spacing: 6) {
                            if item.isDatalessCloudItem {
                                Image(systemName: "icloud.and.arrow.down")
                                    .foregroundColor(.secondary)
                            }
                            Image(nsImage: NSWorkspace.shared.icon(forFile: item.url.path))
                                .resizable()
                                .frame(width: 16, height: 16)
                            Text(item.name)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    }
                    TableColumn("Size", value: \.physicalSize) { item in
                        Text(byteFormatter.string(fromByteCount: item.physicalSize))
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                    .width(min: 80, ideal: 100, max: 150)
                    
                    TableColumn("") { item in
                        Button(action: {
                            revealInFinder(item.url)
                        }) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("Reveal in Finder")
                    }
                    .width(30)
                }
                .onChange(of: sortOrder) {
                    displayItem.sort(using: sortOrder)
                }
                .contextMenu(forSelectionType: FileItem.ID.self) { items in
                    if let first = items.first, let item = findItem(id: first, in: displayItem) {
                        Button("Reveal in Finder") {
                            revealInFinder(item.url)
                        }
                        Button("Quick Look") {
                            QuickLookController.shared.showPreview(url: item.url)
                        }
                    }
                } primaryAction: { items in
                    if let first = items.first, let item = findItem(id: first, in: displayItem) {
                        QuickLookController.shared.showPreview(url: item.url)
                    }
                }
            } else {
                DiskMapView(rootItem: rootItem)
                    .padding()
            }
        }
    }
    
    private func revealInFinder(_ url: URL) {
        NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: "")
    }
    
    private func findItem(id: FileItem.ID, in node: FileItem) -> FileItem? {
        if node.id == id { return node }
        if let children = node.children {
            for child in children {
                if let found = findItem(id: id, in: child) {
                    return found
                }
            }
        }
        return nil
    }
}
