import XCTest
@testable import Pruneapple
import Foundation

final class AIEngineTests: XCTestCase {
    
    @MainActor
    func testCandidateFilteringAndSorting() throws {
        // Prepare mock files
        let rootURL = URL(fileURLWithPath: "/test")
        
        let smallFile = FileItem(url: rootURL.appendingPathComponent("small.txt"), isDirectory: false, physicalSize: 10_000_000) // 10MB
        let bigFile1 = FileItem(url: rootURL.appendingPathComponent("big1.dmg"), isDirectory: false, physicalSize: 100_000_000) // 100MB
        let bigFile2 = FileItem(url: rootURL.appendingPathComponent("big2.zip"), isDirectory: false, physicalSize: 200_000_000) // 200MB
        let directory = FileItem(url: rootURL.appendingPathComponent("folder"), isDirectory: true, physicalSize: 500_000_000) // 500MB
        
        let files = [smallFile, bigFile1, bigFile2, directory]
        
        let candidates = AIEngine.shared.filterCandidates(files: files)
        
        // We expect only bigFile1 and bigFile2 to be candidates, sorted by size (big2 then big1)
        XCTAssertEqual(candidates.count, 2)
        XCTAssertEqual(candidates[0].url, bigFile2.url)
        XCTAssertEqual(candidates[1].url, bigFile1.url)
    }
    
    @MainActor
    func testCandidateCapAt15() throws {
        let rootURL = URL(fileURLWithPath: "/test")
        var files: [FileItem] = []
        for i in 1...20 {
            files.append(FileItem(url: rootURL.appendingPathComponent("file\(i).dmg"), isDirectory: false, physicalSize: 60_000_000))
        }
        
        let candidates = AIEngine.shared.filterCandidates(files: files)
        XCTAssertEqual(candidates.count, 15)
    }
    
    @MainActor
    func testSafetyFilter() throws {
        let rootURL = URL(fileURLWithPath: "/test")
        let projectPath = rootURL.appendingPathComponent("MyProj.xcodeproj").path
        let workspacePath = rootURL.appendingPathComponent("MyWorkspace.xcworkspace").path
        let gitPath = rootURL.appendingPathComponent(".git/config").path
        let regularPath = rootURL.appendingPathComponent("regular.dmg").path
        
        // Test project override
        let projAnalysis = AIEngine.shared.applySafetyFilter(to: projectPath, originalScore: 0.9, originalReason: "Delete it")
        XCTAssertEqual(projAnalysis.score, 0.1)
        XCTAssertTrue(projAnalysis.reason.contains("Safety filter"))
        
        // Test workspace override
        let wsAnalysis = AIEngine.shared.applySafetyFilter(to: workspacePath, originalScore: 0.8, originalReason: "Delete it")
        XCTAssertEqual(wsAnalysis.score, 0.1)
        
        // Test git folder override
        let gitAnalysis = AIEngine.shared.applySafetyFilter(to: gitPath, originalScore: 0.75, originalReason: "Delete it")
        XCTAssertEqual(gitAnalysis.score, 0.1)
        
        // Test regular file passes through
        let regAnalysis = AIEngine.shared.applySafetyFilter(to: regularPath, originalScore: 0.85, originalReason: "Safe to remove")
        XCTAssertEqual(regAnalysis.score, 0.85)
        XCTAssertEqual(regAnalysis.reason, "Safe to remove")
    }
    
    @MainActor
    func testAnalyzeIntegration() async throws {
        let rootURL = URL(fileURLWithPath: "/test")
        let bigFile = FileItem(url: rootURL.appendingPathComponent("big1.dmg"), isDirectory: false, physicalSize: 100_000_000)
        
        let (insights, error) = await AIEngine.shared.analyze(files: [bigFile])
        
        if AIEngine.shared.checkAvailability() {
            // If Apple Intelligence is available, we expect it to either succeed or return a specific execution failure
            if let error = error {
                XCTAssertTrue(error.contains("failed to evaluate") || error.contains("unavailable"))
            } else {
                XCTAssertFalse(insights.isEmpty)
            }
        } else {
            // If Apple Intelligence is unavailable, it must return the correct error string
            let err = try XCTUnwrap(error)
            XCTAssertTrue(err.contains("unavailable") || err.contains("not supported"))
            XCTAssertTrue(insights.isEmpty)
        }
    }
}
