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
    
    public let isVirtual: Bool
    public let isUbiquitousItem: Bool
    public let creationDate: Date?
    public let lastModifiedDate: Date?
    public let lastAccessedDate: Date?
    
    public init(
        url: URL,
        isDirectory: Bool,
        isPackage: Bool = false,
        physicalSize: Int64,
        isDatalessCloudItem: Bool = false,
        children: [FileItem]? = nil,
        isVirtual: Bool = false,
        isUbiquitousItem: Bool = false,
        creationDate: Date? = nil,
        lastModifiedDate: Date? = nil,
        lastAccessedDate: Date? = nil
    ) {
        self.id = url.standardizedFileURL.hashValue
        self.url = url
        self.name = url.lastPathComponent
        self.isDirectory = isDirectory
        self.isPackage = isPackage
        self.physicalSize = physicalSize
        self.isDatalessCloudItem = isDatalessCloudItem
        self.children = children
        self.isVirtual = isVirtual
        self.isUbiquitousItem = isUbiquitousItem
        self.creationDate = creationDate
        self.lastModifiedDate = lastModifiedDate
        self.lastAccessedDate = lastAccessedDate
    }
}

public struct ScanProgress: Sendable {
    public let bytesScanned: Int64
    public let filesCount: Int
    public let currentScanningPath: String
}

public struct ScanResult: Sendable, Hashable {
    public let rootItem: FileItem
    public let skippedURLs: [URL]
}

private struct FileIdentity: Hashable, Sendable {
    let volumeID: String
    let inodeData: Data
}

private final class DirectoryNode {
    let url: URL
    let name: String
    let isDirectory: Bool
    let isPackage: Bool
    var physicalSize: Int64
    let isDatalessCloudItem: Bool
    
    var subdirectories: [URL: DirectoryNode] = [:]
    var files: [FileItem] = []
    var smallerFilesSize: Int64 = 0
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
        // Prune empty directories (0 bytes and not dataless cloud items) to mitigate memory explosion
        let subDirItems = subdirectories.values
            .filter { $0.physicalSize > 0 || $0.isDatalessCloudItem }
            .map { $0.toFileItem() }
        
        var finalFiles = files
        let totalSmallAndTrimmed = smallerFilesSize + trimmedFilesSize
        if totalSmallAndTrimmed > 0 || finalFiles.count > 250 {
            finalFiles.sort { $0.physicalSize > $1.physicalSize }
            let limit = min(250, finalFiles.count)
            let top = Array(finalFiles.prefix(limit))
            let remainingSize: Int64
            if finalFiles.count > limit {
                let remaining = finalFiles.suffix(from: limit)
                remainingSize = remaining.reduce(0) { $0 + $1.physicalSize } + totalSmallAndTrimmed
            } else {
                remainingSize = totalSmallAndTrimmed
            }
            
            if remainingSize > 0 {
                let otherURL = url.appendingPathComponent("Other Smaller Files")
                let otherItem = FileItem(
                    url: otherURL,
                    isDirectory: false,
                    isPackage: false,
                    physicalSize: remainingSize,
                    isVirtual: true
                )
                finalFiles = top + [otherItem]
            } else {
                finalFiles = top
            }
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

public actor ScannerEngine {
    
    public init() {}
    
    // swiftlint:disable:next function_body_length cyclomatic_complexity
    public func scan(
        at rootURL: URL,
        skipHiddenFiles: Bool,
        skipPackages: Bool,
        onProgress: @Sendable @escaping (ScanProgress) -> Void
    ) async throws -> ScanResult {
        
        let activity = ProcessInfo.processInfo.beginActivity(
            options: [.userInitiated, .latencyCritical],
            reason: "Performing deep disk space analysis"
        )
        
        defer {
            ProcessInfo.processInfo.endActivity(activity)
        }
        
        let canonicalPath = (try? rootURL.resourceValues(forKeys: [.canonicalPathKey]))?.canonicalPath ?? rootURL.path
        let resolvedRootURL = URL(fileURLWithPath: canonicalPath)
        
        let rootResourceValues = try? resolvedRootURL.resourceValues(forKeys: [.volumeUUIDStringKey])
        let rootVolumeUUID = rootResourceValues?.volumeUUIDString
        
        final class SkippedTracking: @unchecked Sendable {
            var urls = [URL]()
            private let lock = NSLock()
            func add(_ url: URL) {
                lock.lock()
                urls.append(url)
                lock.unlock()
            }
        }
        let skippedTracking = SkippedTracking()
        
        let keys: [URLResourceKey] = [
            .totalFileAllocatedSizeKey,
            .fileAllocatedSizeKey,
            .fileResourceIdentifierKey,
            .isDirectoryKey,
            .isPackageKey,
            .nameKey,
            .isUbiquitousItemKey,
            .ubiquitousItemDownloadingStatusKey,
            .volumeUUIDStringKey,
            .creationDateKey,
            .contentModificationDateKey,
            .contentAccessDateKey
        ]
        
        let detachedTask = Task.detached(priority: .userInitiated) { () -> ScanResult in
            guard let enumerator = FileManager.default.enumerator(
                at: resolvedRootURL,
                includingPropertiesForKeys: keys,
                options: [],
                errorHandler: { (url, error) -> Bool in
                    let nsError = error as NSError
                    let isPerm = nsError.domain == NSCocoaErrorDomain && nsError.code == CocoaError.fileReadNoPermission.rawValue
                        || nsError.domain == NSPOSIXErrorDomain && (nsError.code == EACCES || nsError.code == EPERM)
                    if isPerm {
                        skippedTracking.add(url)
                    }
                    return true
                }
            ) else {
                throw CocoaError(.fileReadUnknown)
            }
            
            func calculateDirectorySize(at url: URL) -> Int64 {
                let sizeKeys: [URLResourceKey] = [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey, .isDirectoryKey]
                guard let sizeEnumerator = FileManager.default.enumerator(
                    at: url,
                    includingPropertiesForKeys: sizeKeys,
                    options: [],
                    errorHandler: nil
                ) else { return 0 }
                
                var totalSize: Int64 = 0
                while let fileURL = sizeEnumerator.nextObject() as? URL {
                    if skipHiddenFiles && fileURL.lastPathComponent.hasPrefix(".") {
                        continue
                    }
                    if let resourceValues = try? fileURL.resourceValues(forKeys: Set(sizeKeys)),
                       !(resourceValues.isDirectory ?? false) {
                        let size = resourceValues.totalFileAllocatedSize ?? resourceValues.fileAllocatedSize ?? 0
                        totalSize += Int64(size)
                    }
                }
                return totalSize
            }
            
            var seenInodes = Set<FileIdentity>()
            var bytesScanned: Int64 = 0
            var filesCount = 0
            var lastUpdate = CFAbsoluteTimeGetCurrent()
            
            let rootNode = DirectoryNode(url: resolvedRootURL)
            var dirNodes: [URL: DirectoryNode] = [resolvedRootURL: rootNode]
            
            var counter = 0
            
            while let url = enumerator.nextObject() as? URL {
                counter += 1
                try Task.checkCancellation()
                
                try autoreleasepool {
                    let resourceValues: URLResourceValues
                    do {
                        resourceValues = try url.resourceValues(forKeys: Set(keys))
                    } catch {
                        let nsError = error as NSError
                        let isPerm = nsError.domain == NSCocoaErrorDomain && nsError.code == CocoaError.fileReadNoPermission.rawValue
                            || nsError.domain == NSPOSIXErrorDomain && (nsError.code == EACCES || nsError.code == EPERM)
                        if isPerm {
                            skippedTracking.add(url)
                        }
                        return
                    }
                    
                    let isDirectory = resourceValues.isDirectory ?? false
                    
                    // Skip hidden files/folders if configured
                    if skipHiddenFiles && url.lastPathComponent.hasPrefix(".") {
                        if isDirectory {
                            enumerator.skipDescendants()
                        }
                        return
                    }
                    
                    // Volume Boundary Check: Skip items on different volumes to prevent scanning external disks / firmlink loops
                    let volumeID = resourceValues.volumeUUIDString
                    if let rootVolumeUUID = rootVolumeUUID, let volumeID = volumeID, volumeID != rootVolumeUUID {
                        if isDirectory {
                            enumerator.skipDescendants()
                        }
                        return
                    }
                    
                    let isPackage = resourceValues.isPackage ?? false
                    let isUbiquitous = resourceValues.isUbiquitousItem ?? false
                    let downloadStatus = resourceValues.ubiquitousItemDownloadingStatus
                    let isDataless = isUbiquitous && downloadStatus == .notDownloaded
                    
                    let creationDate = resourceValues.creationDate
                    let lastModifiedDate = resourceValues.contentModificationDate
                    let lastAccessedDate = resourceValues.contentAccessDate
                    
                    if isDirectory {
                        // If skipPackages is true and this is a package, treat it as a flattened file
                        if skipPackages && isPackage {
                            enumerator.skipDescendants()
                            
                            let packageSize = calculateDirectorySize(at: url)
                            bytesScanned += packageSize
                            filesCount += 1
                            
                            var parentURL = url.deletingLastPathComponent()
                            while parentURL.path != resolvedRootURL.path && parentURL.path != "/" {
                                if let parentNode = dirNodes[parentURL] {
                                    parentNode.physicalSize += packageSize
                                }
                                parentURL = parentURL.deletingLastPathComponent()
                            }
                            
                            if parentURL.path == resolvedRootURL.path {
                                rootNode.physicalSize += packageSize
                            }
                            
                            let immediateParent = url.deletingLastPathComponent()
                            if let parentNode = dirNodes[immediateParent] {
                                let fileItem = FileItem(
                                    url: url,
                                    isDirectory: false,
                                    isPackage: true,
                                    physicalSize: packageSize,
                                    isDatalessCloudItem: false,
                                    children: nil,
                                    isVirtual: false,
                                    isUbiquitousItem: isUbiquitous,
                                    creationDate: creationDate,
                                    lastModifiedDate: lastModifiedDate,
                                    lastAccessedDate: lastAccessedDate
                                )
                                parentNode.addFile(fileItem)
                            }
                            return
                        }
                        
                        let node = DirectoryNode(url: url, isDirectory: true, isPackage: isPackage, isDatalessCloudItem: isDataless)
                        dirNodes[url] = node
                        
                        let parentURL = url.deletingLastPathComponent()
                        if let parentNode = dirNodes[parentURL] {
                            parentNode.subdirectories[url] = node
                        }
                    } else {
                        let allocatedSize = resourceValues.totalFileAllocatedSize
                        let fileAllocatedSize = resourceValues.fileAllocatedSize
                        let physicalSize = isDataless ? 0 : Int64(allocatedSize ?? fileAllocatedSize ?? 0)
                        let inode = resourceValues.fileResourceIdentifier
                        let volumeUUID = volumeID ?? ""
                        
                        var shouldCount = true
                        // Only track hard links for files larger than 1MB to avoid inode set memory explosion
                        if physicalSize > 1_024_000, let inodeData = inode as? Data {
                            let identity = FileIdentity(volumeID: volumeUUID, inodeData: inodeData)
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
                            while parentURL.path != resolvedRootURL.path && parentURL.path != "/" {
                                if let parentNode = dirNodes[parentURL] {
                                    parentNode.physicalSize += physicalSize
                                }
                                parentURL = parentURL.deletingLastPathComponent()
                            }
                            
                            if parentURL.path == resolvedRootURL.path {
                                rootNode.physicalSize += physicalSize
                            }
                            
                            if physicalSize > 0 || isDataless {
                                let immediateParent = url.deletingLastPathComponent()
                                if let parentNode = dirNodes[immediateParent] {
                                    // Files smaller than 10MB are aggregated to avoid memory footprint bloat
                                    if physicalSize >= 10 * 1024 * 1024 || isDataless {
                                        let fileItem = FileItem(
                                            url: url,
                                            isDirectory: false,
                                            isPackage: isPackage,
                                            physicalSize: physicalSize,
                                            isDatalessCloudItem: isDataless,
                                            children: nil,
                                            isVirtual: false,
                                            isUbiquitousItem: isUbiquitous,
                                            creationDate: creationDate,
                                            lastModifiedDate: lastModifiedDate,
                                            lastAccessedDate: lastAccessedDate
                                        )
                                        parentNode.addFile(fileItem)
                                    } else {
                                        parentNode.smallerFilesSize += physicalSize
                                    }
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
            
            return ScanResult(rootItem: rootNode.toFileItem(), skippedURLs: skippedTracking.urls)
        }
        
        return try await withTaskCancellationHandler {
            try await detachedTask.value
        } onCancel: {
            detachedTask.cancel()
        }
    }
}
