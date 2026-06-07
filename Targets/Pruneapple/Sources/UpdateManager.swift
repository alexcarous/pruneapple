import Foundation
import Sparkle
import SwiftUI

public final class UpdateManager: NSObject, ObservableObject, SPUUpdaterDelegate {
    public var updaterController: SPUStandardUpdaterController!
    @Published public var showUpdateErrorAlert = false
    
    public override init() {
        super.init()
        self.updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: self, userDriverDelegate: nil)
    }
    
    public func updater(_ updater: SPUUpdater, didAbortWithError error: Error) {
        let nsError = error as NSError
        // Ignore user cancellation errors (4001: Sparkle user cancel, 3072: Cocoa user cancel)
        if nsError.code == 4001 || nsError.code == 3072 {
            return
        }
        
        DispatchQueue.main.async {
            self.showUpdateErrorAlert = true
        }
    }
}

public struct CheckForUpdatesView: View {
    @ObservedObject private var viewModel: CheckForUpdatesViewModel
    private let updater: SPUUpdater

    public init(updater: SPUUpdater) {
        self.updater = updater
        self.viewModel = CheckForUpdatesViewModel(updater: updater)
    }

    public var body: some View {
        Button(String(localized: "Check for Updates…")) {
            updater.checkForUpdates()
        }
        .disabled(!viewModel.canCheckForUpdates)
    }
}

public final class CheckForUpdatesViewModel: ObservableObject {
    @Published public var canCheckForUpdates = false
    
    public init(updater: SPUUpdater) {
        updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }
}
