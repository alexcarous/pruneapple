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
    
    public func analyze(files: [FileItem]) async -> [URL: SmartPruneAnalysis] {
        var results: [URL: SmartPruneAnalysis] = [:]
        
        // Filter rules: files only, >= 50MB, sorted by size, top 15
        let candidateFiles = files
            .filter { !$0.isDirectory && $0.physicalSize >= 50_000_000 }
            .sorted { $0.physicalSize > $1.physicalSize }
            .prefix(15)
            
        guard !candidateFiles.isEmpty else { return results }
        
        // Attempt AI generation
        if checkAvailability() {
            #if canImport(FoundationModels)
            if #available(macOS 26.0, *) {
                do {
                    let paths = candidateFiles.map { $0.url.path }.joined(separator: "\n")
                    let prompt = """
                    You are a macOS disk cleanup detective. You strictly do read-only analysis. Analyze these files and assign a Pruneability Score (0.0 to 1.0) and a 1-sentence reason.
                    
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
                        // Apply safety override
                        if result.path.contains(".xcodeproj") || result.path.contains(".xcworkspace") || result.path.contains(".git") {
                            results[fileURL] = SmartPruneAnalysis(score: 0.1, reason: "Safety filter: Important development workspace or project file; should be kept.", isFallback: false)
                        } else {
                            results[fileURL] = SmartPruneAnalysis(score: result.pruneabilityScore, reason: result.reason, isFallback: false)
                        }
                    }
                } catch {
                    print("AI Generation failed: \(error), using fallback.")
                }
            }
            #endif
        }
        
        for file in candidateFiles where results[file.url] == nil {
            results[file.url] = applyFallbackHeuristic(to: file)
        }
        
        return results
    }
    
    private func applyFallbackHeuristic(to file: FileItem) -> SmartPruneAnalysis {
        let ext = file.url.pathExtension.lowercased()
        let name = file.url.lastPathComponent.lowercased()
        
        if name.contains(".xcodeproj") || name.contains(".xcworkspace") || ext == "swift" || ext == "json" {
            return SmartPruneAnalysis(score: 0.1, reason: "Important development workspace or project file; should be kept.", isFallback: true)
        }
        
        switch ext {
        case "dmg", "pkg", "iso":
            return SmartPruneAnalysis(score: 0.9, reason: "Installer file that is usually safe to remove once the application has been installed.", isFallback: true)
        case "tmp", "log", "cache":
            return SmartPruneAnalysis(score: 0.85, reason: "Temporary log/cache file which can be recreated by the system/application.", isFallback: true)
        case "zip", "tar", "gz", "mp4", "mov":
            return SmartPruneAnalysis(score: 0.5, reason: "Large media/archive file; verify if you have backed this up elsewhere before moving/deleting.", isFallback: true)
        default:
            return SmartPruneAnalysis(score: 0.4, reason: "Large file of type [\(ext.isEmpty ? "unknown" : ext)]; inspect if this file is still needed.", isFallback: true)
        }
    }
}
