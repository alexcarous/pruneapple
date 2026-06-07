import Foundation
import SwiftUI

#if canImport(FoundationModels)
import FoundationModels
#endif

// 1. Define the data structures
public struct SmartPruneAnalysis: Sendable, Codable, Equatable {
    public let score: Double
    public let reason: String
    public let isFallback: Bool
}

#if canImport(FoundationModels)
@available(macOS 26.0, *)
@Generable
public struct ItemAnalysis: Sendable, Codable {
    public let path: String
    public let pruneabilityScore: Double
    public let reason: String
}

@available(macOS 26.0, *)
@Generable
public struct FileAnalysisResponse: Sendable, Codable {
    public let results: [ItemAnalysis]
}
#endif

// 2. Create the Engine
@MainActor
public class AIEngine {
    public static let shared = AIEngine()
    
    private init() {}
    
    public func checkAvailability() -> Bool {
        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            if case .available = SystemLanguageModel.default.availability {
                return true
            }
        }
        #endif
        return false
    }
    
    public func analyze(files: [FileItem]) async -> (insights: [URL: SmartPruneAnalysis], error: String?) {
        var results: [URL: SmartPruneAnalysis] = [:]
        
        let candidateFiles = filterCandidates(files: files)
        guard !candidateFiles.isEmpty else {
            return (results, nil)
        }
        
        // Attempt AI generation
        if checkAvailability() {
            #if canImport(FoundationModels)
            if #available(macOS 26.0, *) {
                do {
                    let paths = candidateFiles.map { item -> String in
                        let sizeMB = item.physicalSize / 1_000_000
                        let created = item.creationDate?.formatted(date: .abbreviated, time: .omitted) ?? "Unknown"
                        let accessed = item.lastAccessedDate?.formatted(date: .abbreviated, time: .omitted) ?? "Unknown"
                        let cloud = item.isUbiquitousItem ? "Yes" : "No"
                        let dataless = item.isDatalessCloudItem ? "Yes (0 local bytes)" : "No"
                        
                        return "- \(item.url.path) | Size: \(sizeMB)MB | Created: \(created) | Accessed: \(accessed) | iCloud: \(cloud) | Dataless: \(dataless)"
                    }.joined(separator: "\n")
                    
                    let prompt = """
                    You are a macOS disk cleanup detective. You strictly do read-only analysis. Analyze these files and assign a Pruneability Score (0.0 to 1.0) and a 1-sentence reason.
                    Weigh the 'Accessed' date heavily. If 'Dataless' is Yes, give a pruneability score of 0.0 because deleting it frees no local space. If 'iCloud' is Yes, lower the score slightly as deletion is permanent across all devices.
                    
                    Files:
                    \(paths)
                    """
                    
                    let model = SystemLanguageModel.default
                    let session = LanguageModelSession(model: model)
                    let response = try await session.respond(to: prompt, generating: FileAnalysisResponse.self)
                    let generated = response.content
                    
                    // Map generated results back to URLs
                    for result in generated.results {
                        let fileURL = URL(fileURLWithPath: result.path)
                        results[fileURL] = applySafetyFilter(to: result.path, originalScore: result.pruneabilityScore, originalReason: result.reason)
                    }
                } catch {
                    print("AI Generation failed: \(error)")
                    return ([:], "AI analysis failed to evaluate files: \(error.localizedDescription)")
                }
            } else {
                return ([:], "Apple Intelligence requires macOS 26.0 or later.")
            }
            #else
            return ([:], "Apple Intelligence model compilation is not supported in this build.")
            #endif
        } else {
            return ([:], "Apple Intelligence is unavailable on this device (still downloading or unsupported).")
        }
        
        return (results, nil)
    }
    
    internal func filterCandidates(files: [FileItem]) -> [FileItem] {
        return Array(files
            .filter { !$0.isDirectory && !$0.isPackage && !$0.isVirtual && $0.physicalSize >= 50_000_000 }
            .sorted { $0.physicalSize > $1.physicalSize }
            .prefix(15))
    }
    
    internal func applySafetyFilter(to path: String, originalScore: Double, originalReason: String) -> SmartPruneAnalysis {
        if path.contains(".xcodeproj") || path.contains(".xcworkspace") || path.contains(".git") {
            return SmartPruneAnalysis(
                score: 0.1,
                reason: "Safety filter: Important development workspace or project file; should be kept.",
                isFallback: false
            )
        }
        return SmartPruneAnalysis(score: originalScore, reason: originalReason, isFallback: false)
    }
}
