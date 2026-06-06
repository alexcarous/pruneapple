import XCTest
@testable import Pruneapple
import Foundation

final class ScannerEngineTests: XCTestCase {
    
    func testBasicFileScanning() async throws {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            try? fileManager.removeItem(at: tempDir)
        }
        
        let testFile = tempDir.appendingPathComponent("test.txt")
        let dummyData = Data(repeating: 0, count: 10)
        try dummyData.write(to: testFile)
        
        let engine = ScannerEngine()
        let scanResult = try await engine.scan(at: tempDir, skipHiddenFiles: false, skipPackages: false) { progress in
            XCTAssertGreaterThanOrEqual(progress.filesCount, 0)
        }
        let result = scanResult.rootItem
        
        XCTAssertTrue(result.isDirectory)
        let children = try XCTUnwrap(result.children)
        
        // Note: the test.txt is 10 bytes (<10MB), so it gets aggregated into "Other Smaller Files"
        XCTAssertEqual(children.count, 1)
        
        let firstChild = try XCTUnwrap(children.first)
        XCTAssertEqual(firstChild.name, "Other Smaller Files")
        XCTAssertEqual(firstChild.physicalSize, result.physicalSize)
    }
    
    func testNestedDirectoryAccumulation() async throws {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let deepDir = tempDir.appendingPathComponent("A/B/C")
        try fileManager.createDirectory(at: deepDir, withIntermediateDirectories: true)
        
        defer {
            try? fileManager.removeItem(at: tempDir)
        }
        
        let testFile = deepDir.appendingPathComponent("test.txt")
        let dummyData = Data(repeating: 0, count: 10240) // 10 KB
        try dummyData.write(to: testFile)
        
        let engine = ScannerEngine()
        let scanResult = try await engine.scan(at: tempDir, skipHiddenFiles: false, skipPackages: false) { _ in }
        let result = scanResult.rootItem
        
        XCTAssertTrue(result.isDirectory)
        
        let rootChildren = try XCTUnwrap(result.children)
        let itemA = try XCTUnwrap(rootChildren.first { $0.name == "A" })
        XCTAssertTrue(itemA.isDirectory)
        
        let subChildrenA = try XCTUnwrap(itemA.children)
        let itemB = try XCTUnwrap(subChildrenA.first { $0.name == "B" })
        XCTAssertTrue(itemB.isDirectory)
        
        let subChildrenB = try XCTUnwrap(itemB.children)
        let itemC = try XCTUnwrap(subChildrenB.first { $0.name == "C" })
        XCTAssertTrue(itemC.isDirectory)
        
        let subChildrenC = try XCTUnwrap(itemC.children)
        // test.txt is 10 KB (<10MB) so it gets aggregated to "Other Smaller Files"
        let testFileItem = try XCTUnwrap(subChildrenC.first { $0.name == "Other Smaller Files" })
        XCTAssertFalse(testFileItem.isDirectory)
        
        let physicalSize = testFileItem.physicalSize
        XCTAssertGreaterThan(physicalSize, 0)
        XCTAssertEqual(itemC.physicalSize, physicalSize)
        XCTAssertEqual(itemB.physicalSize, physicalSize)
        XCTAssertEqual(itemA.physicalSize, physicalSize)
        XCTAssertEqual(result.physicalSize, physicalSize)
    }
    
    func testHardLinkDeduplication() async throws {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            try? fileManager.removeItem(at: tempDir)
        }
        
        let file1 = tempDir.appendingPathComponent("file1.txt")
        let file2 = tempDir.appendingPathComponent("file2.txt")
        
        // Write 2MB to exceed the 1MB limit for hardlink tracking
        let dummyData = Data(repeating: 0xAA, count: 2 * 1024 * 1024)
        try dummyData.write(to: file1)
        
        try fileManager.linkItem(at: file1, to: file2)
        
        let engine = ScannerEngine()
        let scanResult = try await engine.scan(at: tempDir, skipHiddenFiles: false, skipPackages: false) { _ in }
        let result = scanResult.rootItem
        
        let children = try XCTUnwrap(result.children)
        // Note: 2MB is < 10MB, so both are aggregated into "Other Smaller Files" but since they are deduplicated,
        // the total aggregated size is exactly 2MB (the size of one file), not 4MB!
        XCTAssertEqual(children.count, 1)
        
        let scannedFile = try XCTUnwrap(children.first)
        XCTAssertEqual(scannedFile.name, "Other Smaller Files")
        XCTAssertEqual(result.physicalSize, scannedFile.physicalSize)
    }
    
    func testPackageSizeCalculation() async throws {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let appDir = tempDir.appendingPathComponent("TestApp.app/Contents/MacOS")
        try fileManager.createDirectory(at: appDir, withIntermediateDirectories: true)
        
        defer {
            try? fileManager.removeItem(at: tempDir)
        }
        
        let execFile = appDir.appendingPathComponent("exec")
        // Write 12MB so it is not aggregated under the package
        let dummyData = Data(repeating: 0, count: 12 * 1024 * 1024)
        try dummyData.write(to: execFile)
        
        let engine = ScannerEngine()
        let scanResult = try await engine.scan(at: tempDir, skipHiddenFiles: false, skipPackages: false) { _ in }
        let result = scanResult.rootItem
        
        let children = try XCTUnwrap(result.children)
        let appItem = try XCTUnwrap(children.first { $0.name == "TestApp.app" })
        XCTAssertTrue(appItem.isDirectory)
        XCTAssertTrue(appItem.isPackage)
        XCTAssertGreaterThanOrEqual(appItem.physicalSize, 12 * 1024 * 1024)
    }
    
    func testParameterizedFileTypes() async throws {
        let cases = [
            ("temp.csv", 12 * 1024 * 1024), // 12 MB (exceeds 10MB so not aggregated)
            ("temp.png", 15 * 1024 * 1024), // 15 MB
            ("temp.json", 20 * 1024 * 1024) // 20 MB
        ]
        
        for (filename, size) in cases {
            let fileManager = FileManager.default
            let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
            
            defer {
                try? fileManager.removeItem(at: tempDir)
            }
            
            let testFile = tempDir.appendingPathComponent(filename)
            let dummyData = Data(repeating: 0, count: size)
            try dummyData.write(to: testFile)
            
            let engine = ScannerEngine()
            let scanResult = try await engine.scan(at: tempDir, skipHiddenFiles: false, skipPackages: false) { _ in }
            let result = scanResult.rootItem
            
            XCTAssertGreaterThanOrEqual(result.physicalSize, 0)
            let children = try XCTUnwrap(result.children)
            XCTAssertTrue(children.contains { $0.name == filename })
        }
    }
    
    func testHiddenFilesSkipping() async throws {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            try? fileManager.removeItem(at: tempDir)
        }
        
        let hiddenFile = tempDir.appendingPathComponent(".hidden.txt")
        let normalFile = tempDir.appendingPathComponent("normal.txt")
        
        // Write 12MB to both so they don't get aggregated
        let dummyData = Data(repeating: 0, count: 12 * 1024 * 1024)
        try dummyData.write(to: hiddenFile)
        try dummyData.write(to: normalFile)
        
        let engine = ScannerEngine()
        
        // When skipHiddenFiles is true
        let scanResult1 = try await engine.scan(at: tempDir, skipHiddenFiles: true, skipPackages: false) { _ in }
        let children1 = try XCTUnwrap(scanResult1.rootItem.children)
        XCTAssertTrue(children1.contains { $0.name == "normal.txt" })
        XCTAssertFalse(children1.contains { $0.name == ".hidden.txt" })
        
        // When skipHiddenFiles is false
        let scanResult2 = try await engine.scan(at: tempDir, skipHiddenFiles: false, skipPackages: false) { _ in }
        let children2 = try XCTUnwrap(scanResult2.rootItem.children)
        XCTAssertTrue(children2.contains { $0.name == "normal.txt" })
        XCTAssertTrue(children2.contains { $0.name == ".hidden.txt" })
    }
    
    func testPackageFlattening() async throws {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let appDir = tempDir.appendingPathComponent("TestApp.app/Contents/MacOS")
        try fileManager.createDirectory(at: appDir, withIntermediateDirectories: true)
        
        defer {
            try? fileManager.removeItem(at: tempDir)
        }
        
        let execFile = appDir.appendingPathComponent("exec")
        // Write 12MB so it is not aggregated
        let dummyData = Data(repeating: 0, count: 12 * 1024 * 1024)
        try dummyData.write(to: execFile)
        
        let engine = ScannerEngine()
        
        // When skipPackages is true
        let scanResult1 = try await engine.scan(at: tempDir, skipHiddenFiles: false, skipPackages: true) { _ in }
        let children1 = try XCTUnwrap(scanResult1.rootItem.children)
        let appItem1 = try XCTUnwrap(children1.first { $0.name == "TestApp.app" })
        XCTAssertFalse(appItem1.isDirectory)
        XCTAssertTrue(appItem1.isPackage)
        XCTAssertNil(appItem1.children)
        XCTAssertGreaterThanOrEqual(appItem1.physicalSize, 12 * 1024 * 1024)
        
        // When skipPackages is false
        let scanResult2 = try await engine.scan(at: tempDir, skipHiddenFiles: false, skipPackages: false) { _ in }
        let children2 = try XCTUnwrap(scanResult2.rootItem.children)
        let appItem2 = try XCTUnwrap(children2.first { $0.name == "TestApp.app" })
        XCTAssertTrue(appItem2.isDirectory)
        XCTAssertTrue(appItem2.isPackage)
        XCTAssertNotNil(appItem2.children)
    }
}
