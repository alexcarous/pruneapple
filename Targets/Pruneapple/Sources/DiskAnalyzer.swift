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
    public var isAnalyzingAI: Bool = false
    public var aiInsights: [URL: SmartPruneAnalysis] = [:]
    public var aiAnalysisError: String?
    
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
                
                // Trigger Smart Prune AI analysis
                let flatFiles = self.flatten(node: result.rootItem)
                self.isAnalyzingAI = true
                self.aiInsights = [:]
                self.aiAnalysisError = nil
                
                let (insights, error) = await AIEngine.shared.analyze(files: flatFiles)
                guard !Task.isCancelled else { return }
                self.aiInsights = insights
                self.aiAnalysisError = error
                self.isAnalyzingAI = false
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
        isAnalyzingAI = false
        aiInsights = [:]
        aiAnalysisError = nil
        rootItem = nil
    }
    
    public func reset() {
        scanTask?.cancel()
        scanTask = nil
        isScanning = false
        isAnalyzingAI = false
        aiInsights = [:]
        aiAnalysisError = nil
        rootItem = nil
        selectedURL = nil
        errorMessage = nil
        skippedURLs = []
    }
    
    private func flatten(node: FileItem) -> [FileItem] {
        var result: [FileItem] = [node]
        if let children = node.children {
            for child in children {
                result.append(contentsOf: flatten(node: child))
            }
        }
        return result
    }
}
