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
    @State private var selectedItem: FileItem.ID?
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
        VStack(alignment: .leading, spacing: Metrics.spacingMedium) {
            HStack(alignment: .center) {
                Picker(String(localized: "Display"), selection: $displayMode) {
                    Image(systemName: "list.bullet").tag(DisplayMode.outline)
                    Image(systemName: "chart.pie").tag(DisplayMode.sunburst)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                
                Text(String(localized: "Physical Space Used"))
                    .font(.headline)
                    .padding(.leading, Metrics.paddingMedium)
                
                Button(action: {
                    showInfoPopover.toggle()
                }) {
                    Image(systemName: "info.circle")
                }
                .buttonStyle(.plain)
                .help(String(localized: "APFS physical allocated size. This may differ from Finder's logical size due to sparse files and clones."))
                .popover(isPresented: $showInfoPopover, arrowEdge: .bottom) {
                    VStack(alignment: .leading, spacing: Metrics.spacingStandard) {
                        Text(String(localized: "Physical Disk Space"))
                            .font(.headline)
                        Text(String(localized: "Pruneapple measures the actual physical sectors allocated on disk by APFS. This accounts for:"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        VStack(alignment: .leading, spacing: Metrics.spacingSmall) {
                            Label(String(localized: "Sparse Files: files that take less space than their logical size."), systemImage: "doc.text.fill")
                            Label(String(localized: "APFS Clones: duplicated files that share blocks and use zero additional space."), systemImage: "doc.on.doc.fill")
                            Label(String(localized: "Compression: system-compressed files."), systemImage: "arrow.down.forward.and.arrow.up.backward")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(width: Metrics.infoPopoverWidth)
                }
                
                Spacer()
                
                Button(String(localized: "New Scan"), systemImage: "arrow.counterclockwise") {
                    diskAnalyzer.reset()
                }
                .buttonStyle(.bordered)
                
                Button(String(localized: "Export CSV")) {
                    CSVExporter.export(rootItem)
                }
            }
            .padding(.horizontal)
            .padding(.top, Metrics.paddingStandard)
            
            if !diskAnalyzer.skippedURLs.isEmpty {
                HStack(spacing: Metrics.spacingStandard) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(String(localized: "Some folders were skipped due to permission errors. If you just granted access, please restart Pruneapple."))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Button(String(localized: "Fix in Settings...")) {
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
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, Metrics.paddingMedium)
                .padding(.horizontal, Metrics.paddingLarge)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(Metrics.cornerRadiusStandard)
                .padding(.horizontal)
            }
            
            if displayMode == .outline {
                Table(displayItem.children ?? [], children: \.children, selection: $selectedItem, sortOrder: $sortOrder) {
                    TableColumn(String(localized: "Name"), value: \.name) { item in
                        HStack(spacing: Metrics.spacingSmall) {
                            if item.isDatalessCloudItem {
                                Image(systemName: "icloud.and.arrow.down")
                                    .foregroundStyle(.secondary)
                            }
                            Image(nsImage: NSWorkspace.shared.icon(forFile: item.url.path))
                                .resizable()
                                .frame(width: Metrics.iconMini, height: Metrics.iconMini)
                            Text(item.name == "Other Smaller Files" ? String(localized: "Other Smaller Files") : item.name)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    }
                    TableColumn(String(localized: "Size"), value: \.physicalSize) { item in
                        Text(byteFormatter.string(fromByteCount: item.physicalSize))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    .width(min: Metrics.tableSizeColumnMin, ideal: Metrics.tableSizeColumnIdeal, max: Metrics.tableSizeColumnMax)
                    
                    TableColumn("") { item in
                        if item.name != "Other Smaller Files" {
                            Button(action: {
                                revealInFinder(item.url)
                            }) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .help(String(localized: "Reveal in Finder"))
                        }
                    }
                    .width(Metrics.tableActionColumnWidth)
                }
                .scrollContentBackground(.hidden)
                .onChange(of: sortOrder) {
                    displayItem.sort(using: sortOrder)
                }
                .contextMenu(forSelectionType: FileItem.ID.self) { items in
                    if let first = items.first, let item = findItem(id: first, in: displayItem), item.name != "Other Smaller Files" {
                        Button(String(localized: "Reveal in Finder")) {
                            revealInFinder(item.url)
                        }
                        Button(String(localized: "Quick Look")) {
                            QuickLookController.shared.showPreview(url: item.url)
                        }
                    }
                } primaryAction: { items in
                    if let first = items.first, let item = findItem(id: first, in: displayItem), item.name != "Other Smaller Files" {
                        QuickLookController.shared.showPreview(url: item.url)
                    }
                }
            } else {
                DiskMapView(rootItem: rootItem)
                    .padding(Metrics.paddingExtraLarge)
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
