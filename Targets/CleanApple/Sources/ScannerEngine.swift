import Foundation

public struct FileItem: Identifiable, Sendable, Hashable {
    public let id: Int
    public let url: URL
    public let name: String
    public let isDirectory: Bool
    public let isPackage: Bool
    public let physicalSize: Int64
    public let isDatalessCloudItem: Bool
    public var children: [FileItem]?
    
    public init(url: URL, isDirectory: Bool, isPackage: Bool = false, physicalSize: Int64, isDatalessCloudItem: Bool = false, children: [FileItem]? = nil) {
        self.id = url.standardizedFileURL.hashValue
        self.url = url
        self.name = url.lastPathComponent
        self.isDirectory = isDirectory
        self.isPackage = isPackage
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
            .isPackageKey,
            .nameKey,
            .isUbiquitousItemKey,
            .ubiquitousItemDownloadingStatusKey,
            .volumeUUIDStringKey
        ]
        
        guard let enumerator = FileManager.default.enumerator(
            at: rootURL,
            includingPropertiesForKeys: keys,
            options: [],
            errorHandler: { (url, error) -> Bool in
                return true
            }
        ) else {
            throw CocoaError(.fileReadUnknown)
        }
        
        final class DirectoryNode {
            let url: URL
            let name: String
            let isDirectory: Bool
            let isPackage: Bool
            var physicalSize: Int64
            let isDatalessCloudItem: Bool
            
            var subdirectories: [URL: DirectoryNode] = [:]
            var files: [FileItem] = []
            var trimmedFilesSize: Int64 = 0
            
            init(url: URL, isDirectory: Bool = true, isPackage: Bool = false, physicalSize: Int64 = 0, isDatalessCloudItem: Bool = false) {
                self.url = url
                self.name = url.lastPathComponent
                self.isDirectory = isDirectory
                self.isPackage = isPackage
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
                
                // Trim only files, NEVER directories
                var finalFiles = files
                if trimmedFilesSize > 0 || finalFiles.count > 250 {
                    finalFiles.sort { $0.physicalSize > $1.physicalSize }
                    let top = Array(finalFiles.prefix(250))
                    let remaining = finalFiles.suffix(from: 250)
                    let remainingSize = remaining.reduce(0) { $0 + $1.physicalSize } + trimmedFilesSize
                    let otherURL = url.appendingPathComponent("Other Smaller Files")
                    let otherItem = FileItem(url: otherURL, isDirectory: false, isPackage: false, physicalSize: remainingSize)
                    finalFiles = top + [otherItem]
                }
                
                var allChildren = finalFiles + subDirItems
                allChildren.sort { $0.physicalSize > $1.physicalSize }
                
                return FileItem(
                    url: url,
                    isDirectory: isDirectory,
                    isPackage: isPackage,
                    physicalSize: physicalSize,
                    isDatalessCloudItem: isDatalessCloudItem,
                    children: allChildren.isEmpty ? nil : allChildren
                )
            }
        }
        
        let rootNode = DirectoryNode(url: rootURL)
        var dirNodes: [URL: DirectoryNode] = [rootURL: rootNode]
        
        var counter = 0
        
        while let url = enumerator.nextObject() as? URL {
            counter += 1
            if counter % 1000 == 0 { await Task.yield() }
            try Task.checkCancellation()
            
            autoreleasepool {
                guard let resourceValues = try? url.resourceValues(forKeys: Set(keys)) else { return }
                
                let isDirectory = resourceValues.isDirectory ?? false
                let isPackage = resourceValues.isPackage ?? false
                let isUbiquitous = resourceValues.isUbiquitousItem ?? false
                let downloadStatus = resourceValues.ubiquitousItemDownloadingStatus
                let isDataless = isUbiquitous && downloadStatus == .notDownloaded
                
                if isDirectory {
                    let node = DirectoryNode(url: url, isDirectory: true, isPackage: isPackage, isDatalessCloudItem: isDataless)
                    dirNodes[url] = node
                    
                    let parentURL = url.deletingLastPathComponent()
                    if let parentNode = dirNodes[parentURL] {
                        parentNode.subdirectories[url] = node
                    }
                } else {
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
                        
                        var parentURL = url.deletingLastPathComponent()
                        while parentURL.path != rootURL.path && parentURL.path != "/" {
                            if let parentNode = dirNodes[parentURL] {
                                parentNode.physicalSize += physicalSize
                            }
                            parentURL = parentURL.deletingLastPathComponent()
                        }
                        
                        if parentURL.path == rootURL.path {
                            rootNode.physicalSize += physicalSize
                        }
                        
                        if physicalSize > 0 || isDataless {
                            let immediateParent = url.deletingLastPathComponent()
                            if let parentNode = dirNodes[immediateParent] {
                                let fileItem = FileItem(url: url, isDirectory: false, isPackage: isPackage, physicalSize: physicalSize, isDatalessCloudItem: isDataless)
                                parentNode.addFile(fileItem)
                            }
                        }
                    }
                }
                
                let now = CFAbsoluteTimeGetCurrent()
                if now - lastUpdate >= 0.25 {
                    lastUpdate = now
                    onProgress(ScanProgress(bytesScanned: bytesScanned, filesCount: filesCount, currentScanningPath: url.lastPathComponent))
                }
            }
        }
        
        return rootNode.toFileItem()
    }
}
