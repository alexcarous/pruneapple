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
    
    public func startScan(at url: URL) async {
        isScanning = true
        progressBytes = 0
        progressFiles = 0
        currentScanningPath = ""
        rootItem = nil
        selectedURL = url
        errorMessage = nil
        skippedURLs = []
        
        do {
            let result = try await engine.scan(at: url) { [weak self] progress in
                guard let self = self else { return }
                Task { @MainActor in
                    self.progressBytes = progress.bytesScanned
                    self.progressFiles = progress.filesCount
                    self.currentScanningPath = progress.currentScanningPath
                }
            }
            
            self.rootItem = result.rootItem
            self.skippedURLs = result.skippedURLs
            self.progressBytes = result.rootItem.physicalSize
            
            // Trigger physical trackpad feedback on completion
            NSHapticFeedbackManager.defaultPerformer.perform(
                .alignment,
                performanceTime: .default
            )
        } catch {
            print("Scan failed: \(error)")
            errorMessage = error.localizedDescription
        }
        
        isScanning = false
    }
}
