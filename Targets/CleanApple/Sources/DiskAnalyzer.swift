import Foundation
import SwiftUI
import AppKit

@Observable
@MainActor
public final class DiskAnalyzer: Sendable {
    public var isScanning: Bool = false
    public var progressBytes: Int64 = 0
    public var progressFiles: Int = 0
    public var currentScanningPath: String = ""
    public var rootItem: FileItem? = nil
    public var selectedURL: URL? = nil
    public var errorMessage: String? = nil
    public var skippedURLs: [URL] = []
    
    private let engine = ScannerEngine()
    
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
                let result = try await self.engine.scan(at: url) { progress in
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
                
                // Trigger physical trackpad feedback on completion
                NSHapticFeedbackManager.defaultPerformer.perform(
                    .alignment,
                    performanceTime: .default
                )
            } catch is CancellationError {
                print("Scan cancelled.")
            } catch {
                print("Scan failed: \(error)")
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
}
