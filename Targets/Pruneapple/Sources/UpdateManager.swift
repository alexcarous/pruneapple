import Foundation
import Sparkle
import SwiftUI

public final class UpdateManager: ObservableObject {
    public let updaterController: SPUStandardUpdaterController
    
    public init() {
        self.updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
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
