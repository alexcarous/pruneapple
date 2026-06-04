import Foundation
let temp = FileManager.default.temporaryDirectory
let canonical = try? temp.resourceValues(forKeys: [.canonicalPathKey]).canonicalPath
print(canonical ?? "nil")
