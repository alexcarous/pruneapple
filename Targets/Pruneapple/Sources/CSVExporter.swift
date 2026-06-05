import Foundation
import AppKit
import UniformTypeIdentifiers

@MainActor
public struct CSVExporter {
    
    public static func export(_ rootItem: FileItem) {
        // 1. Privacy/PII Warning Alert
        let alert = NSAlert()
        alert.messageText = "Privacy Warning"
        alert.informativeText = "This export will contain the exact names, sizes, and file paths of items on your disk. Do not share this exported CSV file with third parties if you have sensitive data."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Continue")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        guard response == .alertFirstButtonReturn else { return }
        
        // 2. Determine localized delimiter to avoid European spreadsheet corruption
        // In Europe, where decimals use commas, the CSV list separator is usually a semicolon.
        let separator = Locale.current.decimalSeparator == "," ? ";" : ","
        
        // 3. Gather and flatten files to export the top 10,000 largest items
        var allFiles: [FileItem] = []
        flatten(rootItem, into: &allFiles)
        
        // Sort descending by size
        let topFiles = allFiles
            .sorted { $0.physicalSize > $1.physicalSize }
            .prefix(10000)
        
        // Build CSV Content
        var csvString = "Path\(separator)Item Type\(separator)Size (Bytes)\(separator)Size Formatted\(separator)Cloud Placeholder\n"
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        
        for file in topFiles {
            let path = file.url.path
            let itemType = file.isDirectory ? "Folder" : "File"
            let size = file.physicalSize
            let formattedSize = formatter.string(fromByteCount: size)
            let isCloudPlaceholder = file.isDatalessCloudItem ? "Yes" : "No"
            
            // Clean path of quotes or separators to keep CSV valid
            let sanitizedPath = path.replacingOccurrences(of: "\"", with: "\"\"")
            csvString += "\"\(sanitizedPath)\"\(separator)\(itemType)\(separator)\(size)\(separator)\"\(formattedSize)\"\(separator)\(isCloudPlaceholder)\n"
        }
        
        // 4. NSSavePanel presentation
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.commaSeparatedText]
        
        let formatterDate = DateFormatter()
        formatterDate.dateFormat = "yyyy-MM-dd"
        let dateString = formatterDate.string(from: Date())
        savePanel.nameFieldStringValue = "DiskReport_\(rootItem.name)_\(dateString).csv"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    try csvString.write(to: url, atomically: true, encoding: .utf8)
                } catch {
                    let errorAlert = NSAlert(error: error)
                    errorAlert.runModal()
                }
            }
        }
    }
    
    private static func flatten(_ item: FileItem, into list: inout [FileItem]) {
        list.append(item)
        if let children = item.children {
            for child in children {
                flatten(child, into: &list)
            }
        }
    }
}

