import Foundation

public struct FileItem: Identifiable, Sendable, Hashable {
    public let id: Int
    public let url: URL
    public let name: String
    public let isDirectory: Bool
    public let physicalSize: Int64
    public let isDatalessCloudItem: Bool
    public var children: [FileItem]?
    
    public init(url: URL, isDirectory: Bool, physicalSize: Int64, isDatalessCloudItem: Bool = false, children: [FileItem]? = nil) {
        self.id = url.standardizedFileURL.hashValue
        self.url = url
        self.name = url.lastPathComponent
        self.isDirectory = isDirectory
        self.physicalSize = physicalSize
        self.isDatalessCloudItem = isDatalessCloudItem
        self.children = children
    }
}

public struct ScanProgress: Sendable {
    public let bytesScanned: Int64
    public let filesCount: Int
    public let currentScanningPath: String
}

public actor ScannerEngine {
    private var seenInodes = Set<Data>()
    
    public init() {}
    
    public func scan(
        at rootURL: URL,
        onProgress: @Sendable @escaping (ScanProgress) -> Void
    ) async throws -> FileItem {
        seenInodes.removeAll()
        
        let activity = ProcessInfo.processInfo.beginActivity(
            options: [.userInitiated, .latencyCritical],
            reason: "Performing deep disk space analysis"
        )
        
        defer {
            ProcessInfo.processInfo.endActivity(activity)
        }
        
        var bytesScanned: Int64 = 0
        var filesCount = 0
        var lastUpdate = Date()
        
        let keys: [URLResourceKey] = [
            .totalFileAllocatedSizeKey,
            .fileResourceIdentifierKey,
            .isDirectoryKey,
            .nameKey,
            .isUbiquitousItemKey,
            .ubiquitousItemDownloadingStatusKey
        ]
        
        guard let enumerator = FileManager.default.enumerator(
            at: rootURL,
            includingPropertiesForKeys: keys,
            options: [.skipsPackageDescendants],
            errorHandler: { (url, error) -> Bool in
                // Gracefully continue scanning on permission/read errors
                return true
            }
        ) else {
            throw CocoaError(.fileReadUnknown)
        }
        
        // Flat map to aggregate directory structures.
        // We'll keep track of sizes to build the tree.
        var sizeMap: [URL: Int64] = [:]
        var directories: [URL] = []
        var fileItems: [URL: FileItem] = [:]
        
        // Add rootURL as first directory
        sizeMap[rootURL] = 0
        directories.append(rootURL)
        
        var counter = 0
        
        while let url = enumerator.nextObject() as? URL {
            counter += 1
            
            // Yield cooperative execution block every 1000 files
            if counter % 1000 == 0 {
                await Task.yield()
            }
            
            try Task.checkCancellation()
            
            // ARC memory protection per-file
            autoreleasepool {
                guard let resourceValues = try? url.resourceValues(forKeys: Set(keys)) else {
                    return
                }
                
                let isDirectory = resourceValues.isDirectory ?? false
                
                if isDirectory {
                    sizeMap[url] = 0
                    directories.append(url)
                } else {
                    let isUbiquitous = resourceValues.isUbiquitousItem ?? false
                    let downloadStatus = resourceValues.ubiquitousItemDownloadingStatus
                    let isDataless = isUbiquitous && downloadStatus == .notDownloaded
                    
                    // Check physical size and inode for hard links
                    let physicalSize = isDataless ? 0 : Int64(resourceValues.totalFileAllocatedSize ?? 0)
                    let inode = resourceValues.fileResourceIdentifier
                    
                    var shouldCount = true
                    if let inodeData = inode as? Data {
                        if seenInodes.contains(inodeData) {
                            shouldCount = false
                        } else {
                            seenInodes.insert(inodeData)
                        }
                    }
                    
                    if shouldCount {
                        bytesScanned += physicalSize
                        filesCount += 1
                        
                        // Bubble up sizes to all parent directories
                        var parentURL = url.deletingLastPathComponent()
                        // Ensure we don't bubble past our scan root
                        while parentURL.path.hasPrefix(rootURL.path) {
                            sizeMap[parentURL, default: 0] += physicalSize
                            if parentURL.path == rootURL.path { break }
                            parentURL = parentURL.deletingLastPathComponent()
                        }
                        
                        // Store file item (limit memory size by only storing large files or dataless cloud files)
                        if physicalSize > 0 || isDataless {
                            fileItems[url] = FileItem(url: url, isDirectory: false, physicalSize: physicalSize, isDatalessCloudItem: isDataless)
                        }
                    }
                }
                
                // Throttle progress updates to UI
                let now = Date()
                if now.timeIntervalSince(lastUpdate) >= 0.25 {
                    lastUpdate = now
                    let progress = ScanProgress(
                        bytesScanned: bytesScanned,
                        filesCount: filesCount,
                        currentScanningPath: url.lastPathComponent
                    )
                    onProgress(progress)
                }
            }
        }
        
        // Build the hierarchical tree.
        // Sort directories by path depth (deepest first) to assemble child nodes into parents easily
        let sortedDirectories = directories.sorted { $0.path.count > $1.path.count }
        
        var urlToChildren: [URL: [FileItem]] = [:]
        
        // Group files into their respective parent directories
        for (fileURL, fileItem) in fileItems {
            let parent = fileURL.deletingLastPathComponent()
            urlToChildren[parent, default: []].append(fileItem)
        }
        
        // Assemble folder items
        for dirURL in sortedDirectories {
            let directChildrenFiles = urlToChildren[dirURL, default: []]
            
            // Find direct subdirectory children
            // A dir is a direct subdirectory if its parent is dirURL
            let subDirs = directories.filter { $0.deletingLastPathComponent() == dirURL && $0 != dirURL }
            
            var subDirItems: [FileItem] = []
            for subDirURL in subDirs {
                let size = sizeMap[subDirURL] ?? 0
                let children = urlToChildren[subDirURL]
                let folderItem = FileItem(url: subDirURL, isDirectory: true, physicalSize: size, children: children)
                subDirItems.append(folderItem)
            }
            
            let allChildren = (directChildrenFiles + subDirItems).sorted { $0.physicalSize > $1.physicalSize }
            
            // Limit children count per node to keep UI fast and memory low (e.g. top 250)
            let trimmedChildren: [FileItem]
            if allChildren.count > 250 {
                let top = Array(allChildren.prefix(250))
                let remainingSize = allChildren.suffix(from: 250).reduce(0) { $0 + $1.physicalSize }
                let otherURL = dirURL.appendingPathComponent("Other Smaller Files")
                let otherItem = FileItem(url: otherURL, isDirectory: false, physicalSize: remainingSize)
                trimmedChildren = top + [otherItem]
            } else {
                trimmedChildren = allChildren
            }
            
            urlToChildren[dirURL] = trimmedChildren
        }
        
        let rootChildren = urlToChildren[rootURL, default: []]
        return FileItem(url: rootURL, isDirectory: true, physicalSize: sizeMap[rootURL] ?? 0, children: rootChildren)
    }
}
