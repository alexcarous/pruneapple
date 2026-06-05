import Foundation
import AppKit
import SwiftUI

@Observable
@MainActor
public final class PermissionManager {
    public static let shared = PermissionManager()
    
    public var hasFullDiskAccess: Bool = false
    private var observer: NSObjectProtocol?
    
    private init() {
        checkFullDiskAccess()
        setupObserver()
    }
    
    private func setupObserver() {
        observer = NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.checkFullDiskAccess()
            }
        }
    }
    
    public func checkFullDiskAccess() {
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        let protectedPaths = [
            "/Library/Application Support/com.apple.TCC/TCC.db",
            homeDirectory.appendingPathComponent("Library/Messages").path,
            homeDirectory.appendingPathComponent("Library/Safari").path
        ]
        
        var accessGranted = false
        
        for path in protectedPaths {
            // 1. Try to open using FileHandle
            if let fileHandle = FileHandle(forReadingAtPath: path) {
                try? fileHandle.close()
                accessGranted = true
                break
            }
            
            // 2. Try to list directory contents if it is a directory
            var isDirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory), isDirectory.boolValue {
                if (try? FileManager.default.contentsOfDirectory(atPath: path)) != nil {
                    accessGranted = true
                    break
                }
            }
            
            // 3. POSIX raw open check
            let fd = open(path, O_RDONLY)
            if fd != -1 {
                close(fd)
                accessGranted = true
                break
            }
        }
        
        self.hasFullDiskAccess = accessGranted
    }
    
    public func openSystemSettings() {
        let urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
}
