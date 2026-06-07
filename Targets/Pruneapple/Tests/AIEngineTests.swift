import XCTest
@testable import Pruneapple
import Foundation

final class AIEngineTests: XCTestCase {
    
    @MainActor
    func testCandidateFilteringAndSorting() async throws {
        // Prepare mock files
        let rootURL = URL(fileURLWithPath: "/test")
        
        let smallFile = FileItem(url: rootURL.appendingPathComponent("small.txt"), isDirectory: false, physicalSize: 10_000_000) // 10MB
        let bigFile1 = FileItem(url: rootURL.appendingPathComponent("big1.dmg"), isDirectory: false, physicalSize: 100_000_000) // 100MB
        let bigFile2 = FileItem(url: rootURL.appendingPathComponent("big2.zip"), isDirectory: false, physicalSize: 200_000_000) // 200MB
        let directory = FileItem(url: rootURL.appendingPathComponent("folder"), isDirectory: true, physicalSize: 500_000_000) // 500MB
        
        let files = [smallFile, bigFile1, bigFile2, directory]
        
        // Analyze using AIEngine (this will trigger fallback heuristics since it is a mock environment)
        let insights = await AIEngine.shared.analyze(files: files)
        
        // We expect only bigFile1 and bigFile2 to be analyzed
        XCTAssertEqual(insights.count, 2)
        XCTAssertNotNil(insights[bigFile1.url])
        XCTAssertNotNil(insights[bigFile2.url])
        XCTAssertNil(insights[smallFile.url])
        XCTAssertNil(insights[directory.url])
    }
    
    @MainActor
    func testFallbackHeuristicsDMG() async throws {
        let rootURL = URL(fileURLWithPath: "/test")
        let dmgFile = FileItem(url: rootURL.appendingPathComponent("installer.dmg"), isDirectory: false, physicalSize: 60_000_000)
        
        let insights = await AIEngine.shared.analyze(files: [dmgFile])
        let dmgInsight = try XCTUnwrap(insights[dmgFile.url])
        
        XCTAssertEqual(dmgInsight.score, 0.9)
        XCTAssertTrue(dmgInsight.reason.contains("Installer file") == true)
        XCTAssertTrue(dmgInsight.isFallback == true)
    }
    
    @MainActor
    func testFallbackHeuristicsTemp() async throws {
        let rootURL = URL(fileURLWithPath: "/test")
        let tmpFile = FileItem(url: rootURL.appendingPathComponent("temp.tmp"), isDirectory: false, physicalSize: 60_000_000)
        
        let insights = await AIEngine.shared.analyze(files: [tmpFile])
        let tmpInsight = try XCTUnwrap(insights[tmpFile.url])
        
        XCTAssertEqual(tmpInsight.score, 0.85)
        XCTAssertTrue(tmpInsight.reason.contains("Temporary log/cache file") == true)
    }
    
    @MainActor
    func testFallbackHeuristicsArchive() async throws {
        let rootURL = URL(fileURLWithPath: "/test")
        let zipFile = FileItem(url: rootURL.appendingPathComponent("backup.zip"), isDirectory: false, physicalSize: 60_000_000)
        
        let insights = await AIEngine.shared.analyze(files: [zipFile])
        let zipInsight = try XCTUnwrap(insights[zipFile.url])
        
        XCTAssertEqual(zipInsight.score, 0.5)
        XCTAssertTrue(zipInsight.reason.contains("Large media/archive file") == true)
    }
    
    @MainActor
    func testFallbackHeuristicsDefault() async throws {
        let rootURL = URL(fileURLWithPath: "/test")
        let customFile = FileItem(url: rootURL.appendingPathComponent("unknown.xyz"), isDirectory: false, physicalSize: 60_000_000)
        
        let insights = await AIEngine.shared.analyze(files: [customFile])
        let customInsight = try XCTUnwrap(insights[customFile.url])
        
        XCTAssertEqual(customInsight.score, 0.4)
        XCTAssertTrue(customInsight.reason.contains("Large file of type [xyz]") == true)
    }
    
    @MainActor
    func testSafetyOverride() async throws {
        let rootURL = URL(fileURLWithPath: "/test")
        let projectFile = FileItem(url: rootURL.appendingPathComponent("MyProj.xcodeproj"), isDirectory: false, physicalSize: 60_000_000)
        let workspaceFile = FileItem(url: rootURL.appendingPathComponent("MyWorkspace.xcworkspace"), isDirectory: false, physicalSize: 60_000_000)
        
        let insights = await AIEngine.shared.analyze(files: [projectFile, workspaceFile])
        
        let projInsight = try XCTUnwrap(insights[projectFile.url])
        XCTAssertEqual(projInsight.score, 0.1)
        XCTAssertTrue(projInsight.reason.contains("Important development workspace") == true)
        
        let wsInsight = try XCTUnwrap(insights[workspaceFile.url])
        XCTAssertEqual(wsInsight.score, 0.1)
        XCTAssertTrue(wsInsight.reason.contains("Important development workspace") == true)
    }
    
    @MainActor
    func testCandidateCapAt15() async throws {
        let rootURL = URL(fileURLWithPath: "/test")
        var files: [FileItem] = []
        for i in 1...20 {
            files.append(FileItem(url: rootURL.appendingPathComponent("file\(i).dmg"), isDirectory: false, physicalSize: 60_000_000))
        }
        
        let insights = await AIEngine.shared.analyze(files: files)
        XCTAssertEqual(insights.count, 15)
    }
}
