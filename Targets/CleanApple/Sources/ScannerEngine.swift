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
    
    public init() {}
    
    public func scan(
        at rootURL: URL,
        onProgress: @Sendable @escaping (ScanProgress) -> Void
    ) async throws -> FileItem {
        
        struct FileIdentity: Hashable, Sendable {
            let volumeID: String
            let inodeData: Data
        }
        
        var seenInodes = Set<FileIdentity>()
        
        let activity = ProcessInfo.processInfo.beginActivity(
            options: [.userInitiated, .latencyCritical],
            reason: "Performing deep disk space analysis"
        )
        
        defer {
            ProcessInfo.processInfo.endActivity(activity)
        }
        
        var bytesScanned: Int64 = 0
        var filesCount = 0
        var lastUpdate = CFAbsoluteTimeGetCurrent()
        
        let keys: [URLResourceKey] = [
            .totalFileAllocatedSizeKey,
            .fileResourceIdentifierKey,
            .isDirectoryKey,
            .nameKey,
            .isUbiquitousItemKey,
            .ubiquitousItemDownloadingStatusKey,
            .volumeUUIDStringKey
        ]
        
        guard let enumerator = FileManager.default.enumerator(
            at: rootURL,
            includingPropertiesForKeys: keys,
            options: [], // Traverses inside packages to get accurate size metrics
            errorHandler: { (url, error) -> Bool in
                // Gracefully continue scanning on permission/read errors
                return true
            }
        ) else {
            throw CocoaError(.fileReadUnknown)
        }
        
        // Tree building classes / helper structures
        final class DirectoryNode {
            let url: URL
            let name: String
            let isDirectory: Bool
            var physicalSize: Int64
            let isDatalessCloudItem: Bool
            
            var subdirectories: [URL: DirectoryNode] = [:]
            var files: [FileItem] = []
            var trimmedFilesSize: Int64 = 0
            
            init(url: URL, isDirectory: Bool = true, physicalSize: Int64 = 0, isDatalessCloudItem: Bool = false) {
                self.url = url
                self.name = url.lastPathComponent
                self.isDirectory = isDirectory
                self.physicalSize = physicalSize
                self.isDatalessCloudItem = isDatalessCloudItem
            }
            
            func addFile(_ file: FileItem) {
                files.append(file)
                if files.count > 300 {
                    files.sort { $0.physicalSize > $1.physicalSize }
                    let keep = Array(files.prefix(250))
                    let discarded = files.suffix(from: 250)
                    trimmedFilesSize += discarded.reduce(0) { $0 + $1.physicalSize }
                    files = keep
                }
            }
            
            func toFileItem() -> FileItem {
                let subDirItems = subdirectories.values.map { $0.toFileItem() }
                var allChildren = files + subDirItems
                allChildren.sort { $0.physicalSize > $1.physicalSize }
                
                var finalChildren = allChildren
                if trimmedFilesSize > 0 || finalChildren.count > 250 {
                    let top = Array(finalChildren.prefix(250))
                    let remaining = finalChildren.suffix(from: 250)
                    let remainingSize = remaining.reduce(0) { $0 + $1.physicalSize } + trimmedFilesSize
                    let otherURL = url.appendingPathComponent("Other Smaller Files")
                    let otherItem = FileItem(url: otherURL, isDirectory: false, physicalSize: remainingSize)
                    finalChildren = top + [otherItem]
                }
                
                return FileItem(
                    url: url,
                    isDirectory: isDirectory,
                    physicalSize: physicalSize,
                    isDatalessCloudItem: isDatalessCloudItem,
                    children: finalChildren.isEmpty ? nil : finalChildren
                )
            }
        }
        
        let rootNode = DirectoryNode(url: rootURL)
        var dirNodes: [URL: DirectoryNode] = [rootURL: rootNode]
        
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
                    let node = DirectoryNode(url: url)
                    dirNodes[url] = node
                    
                    let parentURL = url.deletingLastPathComponent()
                    if let parentNode = dirNodes[parentURL] {
                        parentNode.subdirectories[url] = node
                    }
                } else {
                    let isUbiquitous = resourceValues.isUbiquitousItem ?? false
                    let downloadStatus = resourceValues.ubiquitousItemDownloadingStatus
                    let isDataless = isUbiquitous && downloadStatus == .notDownloaded
                    
                    // Check physical size and inode for hard links
                    let physicalSize = isDataless ? 0 : Int64(resourceValues.totalFileAllocatedSize ?? 0)
                    let inode = resourceValues.fileResourceIdentifier
                    let volumeID = resourceValues.volumeUUIDString ?? ""
                    
                    var shouldCount = true
                    if let inodeData = inode as? Data {
                        let identity = FileIdentity(volumeID: volumeID, inodeData: inodeData)
                        if seenInodes.contains(identity) {
                            shouldCount = false
                        } else {
                            seenInodes.insert(identity)
                        }
                    }
                    
                    if shouldCount {
                        bytesScanned += physicalSize
                        filesCount += 1
                        
                        // Bubble up sizes to all parent directories
                        var parentURL = url.deletingLastPathComponent()
                        while parentURL.path != rootURL.path {
                            if let parentNode = dirNodes[parentURL] {
                                parentNode.physicalSize += physicalSize
                            }
                            parentURL = parentURL.deletingLastPathComponent()
                        }
                        rootNode.physicalSize += physicalSize
                        
                        // Store file item (limit memory size by only storing files of size > 0 or cloud placeholders)
                        if physicalSize > 0 || isDataless {
                            let parentURL = url.deletingLastPathComponent()
                            if let parentNode = dirNodes[parentURL] {
                                let fileItem = FileItem(url: url, isDirectory: false, physicalSize: physicalSize, isDatalessCloudItem: isDataless)
                                parentNode.addFile(fileItem)
                            }
                        }
                    }
                }
                
                // Throttle progress updates to UI using CFAbsoluteTimeGetCurrent
                let now = CFAbsoluteTimeGetCurrent()
                if now - lastUpdate >= 0.25 {
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
        
        return rootNode.toFileItem()
    }
}
