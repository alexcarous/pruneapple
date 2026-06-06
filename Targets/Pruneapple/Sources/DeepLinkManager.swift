import Foundation
import SwiftUI

@Observable
@MainActor
final class DeepLinkManager {
    static let shared = DeepLinkManager()
    
    var openThankYouWindow: Bool = false
    
    private init() {}
}
