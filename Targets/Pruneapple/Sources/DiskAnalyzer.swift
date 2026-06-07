import Foundation
import SwiftUI
import AppKit
import os

@Observable
@MainActor
public final class DiskAnalyzer {
    public var isScanning: Bool = false
    public var progressBytes: Int64 = 0
    public var progressFiles: Int = 0
    public var currentScanningPath: String = ""
    public var rootItem: FileItem?
    public var selectedURL: URL?
    public var errorMessage: String?
    public var skippedURLs: [URL] = []
    
    private let engine = ScannerEngine()
    private let logger = Logger(subsystem: "us.caro.alex.Pruneapple", category: "Scanner")
    
    public init() {}
    
    private var scanTask: Task<Void, Never>?
    
    public func startScan(at url: URL) {
        scanTask?.cancel()
        
        isScanning = true
        progressBytes = 0
        progressFiles = 0
        currentScanningPath = ""
        rootItem = nil
        selectedURL = url
        errorMessage = nil
        skippedURLs = []
        
        scanTask = Task { [weak self] in
            guard let self = self else { return }
            do {
                let skipHidden = UserDefaults.standard.bool(forKey: AppStorageKeys.skipHiddenFiles.rawValue)
                let skipPackages = UserDefaults.standard.bool(forKey: AppStorageKeys.skipPackages.rawValue)
                
                let result = try await self.engine.scan(
                    at: url,
                    skipHiddenFiles: skipHidden,
                    skipPackages: skipPackages
                ) { progress in
                    Task { @MainActor in
                        guard !Task.isCancelled else { return }
                        self.progressBytes = progress.bytesScanned
                        self.progressFiles = progress.filesCount
                        self.currentScanningPath = progress.currentScanningPath
                    }
                }
                
                guard !Task.isCancelled else { return }
                
                self.rootItem = result.rootItem
                self.skippedURLs = result.skippedURLs
                self.progressBytes = result.rootItem.physicalSize
                
                // Track successful scan count for donation prompt
                let key = AppStorageKeys.successfulScanCount.rawValue
                let count = UserDefaults.standard.integer(forKey: key)
                UserDefaults.standard.set(count + 1, forKey: key)
                
                // Trigger physical trackpad feedback on completion
                NSHapticFeedbackManager.defaultPerformer.perform(
                    .alignment,
                    performanceTime: .default
                )
            } catch is CancellationError {
                self.logger.info("Scan cancelled.")
            } catch {
                self.logger.error("Scan failed: \(error.localizedDescription)")
                self.errorMessage = error.localizedDescription
            }
            
            self.isScanning = false
        }
    }
    
    public func cancelScan() {
        scanTask?.cancel()
        scanTask = nil
        isScanning = false
        rootItem = nil
    }
    
    public func reset() {
        scanTask?.cancel()
        scanTask = nil
        isScanning = false
        rootItem = nil
        selectedURL = nil
        errorMessage = nil
        skippedURLs = []
    }
}
