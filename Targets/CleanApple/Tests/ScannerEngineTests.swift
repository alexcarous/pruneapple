import Testing
@testable import CleanApple
import Foundation

@Suite("Scanner Engine Tests")
struct ScannerEngineTests {
    
    @Test("Basic File Scanning")
    func basicFileScanning() async throws {
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
        let result = try await engine.scan(at: tempDir) { progress in
            #expect(progress.filesCount >= 0)
        }
        
        #expect(result.isDirectory)
        let children = try #require(result.children)
        #expect(children.count == 1)
        
        let firstChild = try #require(children.first)
        #expect(firstChild.name == "test.txt")
        #expect(firstChild.physicalSize >= 0)
    }
    
    @Test("Nested Directory Accumulation")
    func nestedDirectoryAccumulation() async throws {
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
        let result = try await engine.scan(at: tempDir) { _ in }
        
        #expect(result.isDirectory)
        
        let rootChildren = try #require(result.children)
        let itemA = try #require(rootChildren.first { $0.name == "A" })
        #expect(itemA.isDirectory)
        
        let subChildrenA = try #require(itemA.children)
        let itemB = try #require(subChildrenA.first { $0.name == "B" })
        #expect(itemB.isDirectory)
        
        let subChildrenB = try #require(itemB.children)
        let itemC = try #require(subChildrenB.first { $0.name == "C" })
        #expect(itemC.isDirectory)
        
        let subChildrenC = try #require(itemC.children)
        let testFileItem = try #require(subChildrenC.first { $0.name == "test.txt" })
        #expect(!testFileItem.isDirectory)
        
        let physicalSize = testFileItem.physicalSize
        #expect(physicalSize > 0)
        #expect(itemC.physicalSize == physicalSize)
        #expect(itemB.physicalSize == physicalSize)
        #expect(itemA.physicalSize == physicalSize)
        #expect(result.physicalSize == physicalSize)
    }
    
    @Test("Hard Link Deduplication")
    func hardLinkDeduplication() async throws {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            try? fileManager.removeItem(at: tempDir)
        }
        
        let file1 = tempDir.appendingPathComponent("file1.txt")
        let file2 = tempDir.appendingPathComponent("file2.txt")
        
        let dummyData = Data(repeating: 0xAA, count: 100 * 1024) // 100 KB
        try dummyData.write(to: file1)
        
        try fileManager.linkItem(at: file1, to: file2)
        
        let engine = ScannerEngine()
        let result = try await engine.scan(at: tempDir) { _ in }
        
        let children = try #require(result.children)
        #expect(children.count == 1)
        
        let scannedFile = try #require(children.first)
        #expect(scannedFile.name == "file1.txt" || scannedFile.name == "file2.txt")
        #expect(result.physicalSize == scannedFile.physicalSize)
    }
    
    @Test("Parameterization over File Types", arguments: [
        ("temp.csv", 50),
        ("temp.png", 500),
        ("temp.json", 1000)
    ])
    func parameterizedFileTypes(filename: String, size: Int) async throws {
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
        let result = try await engine.scan(at: tempDir) { _ in }
        
        #expect(result.physicalSize >= 0)
        let children = try #require(result.children)
        #expect(children.contains { $0.name == filename })
    }
}
