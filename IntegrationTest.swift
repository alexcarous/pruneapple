import Foundation
// In this script we compile alongside ScannerEngine.swift

func assert(_ condition: Bool, _ message: String, file: StaticString = #file, line: UInt = #line) {
    if !condition {
        print("❌ FAILURE: \(message) at line \(line)")
        exit(1)
    }
}

func runTests() async throws {
    print("Running Integration Tests...")
    
    // 1. Basic File Scanning
    do {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: tempDir) }
        
        let testFile = tempDir.appendingPathComponent("test.txt")
        let dummyData = Data(repeating: 0, count: 10)
        try dummyData.write(to: testFile)
        
        let engine = ScannerEngine()
        let result = try await engine.scan(at: tempDir) { _ in }
        
        assert(result.isDirectory, "Root should be directory")
        print("Result children: \(String(describing: result.children))")
        assert(result.children?.count == 1, "Should have 1 child")
        
        let firstChild = result.children!.first!
        assert(firstChild.name == "test.txt", "Name should be test.txt")
        assert(firstChild.physicalSize >= 0, "Physical size should be valid")
        print("✅ Basic File Scanning Passed")
    }
    
    // 2. Nested Directory Accumulation
    do {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let deepDir = tempDir.appendingPathComponent("A/B/C")
        try fileManager.createDirectory(at: deepDir, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: tempDir) }
        
        let testFile = deepDir.appendingPathComponent("test.txt")
        let dummyData = Data(repeating: 0, count: 10240)
        try dummyData.write(to: testFile)
        
        let engine = ScannerEngine()
        let result = try await engine.scan(at: tempDir) { _ in }
        
        let itemA = result.children!.first { $0.name == "A" }!
        let itemB = itemA.children!.first { $0.name == "B" }!
        let itemC = itemB.children!.first { $0.name == "C" }!
        let testFileItem = itemC.children!.first { $0.name == "test.txt" }!
        
        let pSize = testFileItem.physicalSize
        assert(pSize > 0, "File size should be > 0")
        assert(itemC.physicalSize == pSize, "C size mismatch")
        assert(itemB.physicalSize == pSize, "B size mismatch")
        assert(itemA.physicalSize == pSize, "A size mismatch")
        assert(result.physicalSize == pSize, "Root size mismatch")
        print("✅ Nested Directory Accumulation Passed")
    }
    
    // 3. Hard Link Deduplication
    do {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: tempDir) }
        
        let file1 = tempDir.appendingPathComponent("file1.txt")
        let file2 = tempDir.appendingPathComponent("file2.txt")
        let dummyData = Data(repeating: 0xAA, count: 100 * 1024)
        try dummyData.write(to: file1)
        try fileManager.linkItem(at: file1, to: file2)
        
        let engine = ScannerEngine()
        let result = try await engine.scan(at: tempDir) { _ in }
        
        assert(result.children?.count == 1, "Should only have 1 child due to deduplication")
        assert(result.physicalSize == result.children!.first!.physicalSize, "Sizes should match")
        print("✅ Hard Link Deduplication Passed")
    }
    
    // 4. Package Size Calculation
    do {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let appDir = tempDir.appendingPathComponent("TestApp.app/Contents/MacOS")
        try fileManager.createDirectory(at: appDir, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: tempDir) }
        
        let execFile = appDir.appendingPathComponent("exec")
        let dummyData = Data(repeating: 0, count: 10 * 1024)
        try dummyData.write(to: execFile)
        
        let engine = ScannerEngine()
        let result = try await engine.scan(at: tempDir) { _ in }
        
        let appItem = result.children!.first { $0.name == "TestApp.app" }!
        assert(appItem.isDirectory, "App should be directory")
        assert(appItem.isPackage, "App should be package")
        assert(appItem.physicalSize >= 10 * 1024, "Size should be valid")
        print("✅ Package Size Calculation Passed")
    }
    
    print("🎉 ALL TESTS COMPLETED SUCCESSFULLY!")
}

@main
struct TestRunner {
    static func main() async throws {
        try await runTests()
    }
}
