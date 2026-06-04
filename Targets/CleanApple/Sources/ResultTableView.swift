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
    let rootItem: FileItem
    @State private var selectedItem: FileItem? = nil
    
    private let byteFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Physical Space Used")
                    .font(.headline)
                
                Button(action: {}) {
                    Image(systemName: "info.circle")
                }
                .buttonStyle(.plain)
                .help("APFS physical allocated size. This may differ from Finder's logical size due to sparse files and clones.")
                
                Spacer()
                
                Button("Export CSV") {
                    CSVExporter.export(rootItem)
                }
            }
            .padding(.horizontal)
            
            List(rootItem.children ?? [], children: \.children) { item in
                HStack {
                    Image(systemName: item.isDirectory ? "folder" : "doc")
                        .foregroundColor(item.isDirectory ? .accentColor : .secondary)
                    
                    Text(item.name)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(byteFormatter.string(fromByteCount: item.physicalSize))
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                    
                    Button(action: {
                        revealInFinder(item.url)
                    }) {
                        Image(systemName: "magnifyingglass")
                            .help("Reveal in Finder")
                    }
                    .buttonStyle(.borderless)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(accessibilityString(for: item))
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedItem = item
                }
            }
            .onKeyPress(.space) {
                if let selected = selectedItem {
                    QuickLookController.shared.showPreview(url: selected.url)
                    return .handled
                }
                return .ignored
            }
        }
    }
    
    private func revealInFinder(_ url: URL) {
        NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: "")
    }
    
    private func accessibilityString(for item: FileItem) -> String {
        let type = item.isDirectory ? "Folder" : "File"
        let size = byteFormatter.string(fromByteCount: item.physicalSize)
        return "\(type), \(item.name), \(size)"
    }
}
