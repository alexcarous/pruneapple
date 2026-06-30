import SwiftUI

struct DonationView: View {
    @AppStorage(AppStorageKeys.hasDonated.rawValue) private var hasDonated = false
    @State private var hoveredTierID: String?
    @State private var pressCount = 0
    @State private var eventMonitor: Any?
    @State private var testModeActive = false
    
    @State private var isRedeemExpanded = false
    @State private var enteredLicenseKey = ""
    @State private var redeemStatusMessage: String?
    @State private var redeemIsSuccess = false
    
    struct DonationTier: Identifiable {
        let id: String
        let name: String
        let price: String
        let description: String
        let url: String
        let icon: String
        let gradientColors: [Color]
    }
    
    let tiers: [DonationTier] = [
        DonationTier(
            id: "coffee",
            name: String(localized: "Buy Alex a coffee"),
            price: "$5",
            description: String(localized: "Fuel active development and support minor releases."),
            url: "https://donate.stripe.com/3cs3fXaST6uy9MI006?utm_source=pruneapple&utm_medium=app&utm_campaign=donation&utm_content=coffee",
            icon: "coffee-donation",
            gradientColors: [Color.brown, Color.orange]
        ),
        DonationTier(
            id: "matcha",
            name: String(localized: "Buy Alex a matcha"),
            price: "$10",
            description: String(localized: "Keep the codebase optimized and the servers running."),
            url: "https://donate.stripe.com/bJeaEY5Fe5Nw6LHdC9bV607?utm_source=pruneapple&utm_medium=app&utm_campaign=donation&utm_content=matcha",
            icon: "matcha-donation",
            gradientColors: [Color.green, Color.mint]
        ),
        DonationTier(
            id: "mokapot",
            name: String(localized: "Buy Alex a moka pot"),
            price: "$50",
            description: String(localized: "A substantial contribution to support major future updates."),
            url: "https://donate.stripe.com/aFaaEY2t2dfYfid55DbV60a?utm_source=pruneapple&utm_medium=app&utm_campaign=donation&utm_content=mokapot",
            icon: "mokapot-donation",
            gradientColors: [Color.red, Color.orange]
        ),
        DonationTier(
            id: "espresso",
            name: String(localized: "Buy Alex an espresso machine"),
            price: String(localized: "Custom"),
            description: String(localized: "Choose your own level of support for Pruneapple."),
            url: "https://donate.stripe.com/cNi5kE9Vu4Js8TPgOlbV609?utm_source=pruneapple&utm_medium=app&utm_campaign=donation&utm_content=espresso",
            icon: "espresso-donation",
            gradientColors: [Color.purple, Color.indigo]
        )
    ]
    
    var body: some View {
        GeometryReader { geo in
            let isCompact = geo.size.width < 480
            
            VStack(spacing: 0) {
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: Metrics.spacingLarge) {
                        if testModeActive {
                            HStack {
                                Image(systemName: "ladybug.fill")
                                    .foregroundColor(.green)
                                Text(String(localized: "Developer Test Mode: Supporter Status Activated (5 min)"))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.green)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color.green.opacity(0.15))
                            .cornerRadius(Metrics.cornerRadiusMedium)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        // Header
                        VStack(spacing: Metrics.spacingVerySmall) {
                            Image(systemName: "heart.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: Metrics.iconLarge, height: Metrics.iconLarge)
                                .foregroundStyle(
                                    .linearGradient(
                                        colors: [.pink, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .symbolEffect(.pulse, options: .repeating)
                                .padding(.bottom, Metrics.paddingSmall)
                            
                            Text(String(localized: "Support Pruneapple"))
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(String(localized: "Pruneapple is created with passion by an independent developer. Your support directly funds server costs and feature development!"))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, Metrics.paddingDoubleExtraLarge)
                        }
                        .padding(.top, Metrics.paddingMedium)
                        
                        // Grid of Donation Tiers
                        LazyVGrid(
                            columns: isCompact 
                                ? [GridItem(.flexible())] 
                                : [GridItem(.flexible()), GridItem(.flexible())],
                            spacing: Metrics.spacingMedium
                        ) {
                            ForEach(tiers) { tier in
                                Button(action: {
                                    if let url = URL(string: tier.url) {
                                        NSWorkspace.shared.open(url)
                                    }
                                }) {
                                    HStack(alignment: .top, spacing: Metrics.spacingStandard) {
                                        Image(tier.icon)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 44, height: 44)
                                        
                                        VStack(alignment: .leading, spacing: Metrics.spacingVerySmall) {
                                            HStack {
                                                Text(tier.name)
                                                    .font(.headline)
                                                    .foregroundColor(.primary)
                                                Spacer()
                                                Text(tier.price)
                                                    .font(.subheadline)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, Metrics.paddingMedium)
                                                    .padding(.vertical, Metrics.paddingVerySmall - 1)
                                                    .background(
                                                        Capsule()
                                                            .fill(
                                                                LinearGradient(
                                                                    colors: tier.gradientColors,
                                                                    startPoint: .topLeading,
                                                                    endPoint: .bottomTrailing
                                                                )
                                                            )
                                                    )
                                            }
                                            
                                            Text(tier.description)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .lineLimit(2)
                                                .multilineTextAlignment(.leading)
                                        }
                                    }
                                    .padding(Metrics.paddingStandard)
                                    .background(
                                        ZStack {
                                            RoundedRectangle(cornerRadius: Metrics.cornerRadiusMedium)
                                                .fill(Color(NSColor.controlBackgroundColor))
                                            
                                            RoundedRectangle(cornerRadius: Metrics.cornerRadiusMedium)
                                                .fill(
                                                    LinearGradient(
                                                        colors: tier.gradientColors,
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                                .opacity(hoveredTierID == tier.id ? 0.12 : 0.04)
                                        }
                                        .shadow(
                                            color: Color.black.opacity(hoveredTierID == tier.id ? 0.12 : 0.04),
                                            radius: hoveredTierID == tier.id ? 6 : 2
                                        )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Metrics.cornerRadiusMedium)
                                            .stroke(hoveredTierID == tier.id ? Color.accentColor : Color.clear, lineWidth: 1.5)
                                    )
                                    .scaleEffect(hoveredTierID == tier.id ? 1.02 : 1.0)
                                    .animation(.easeOut(duration: 0.15), value: hoveredTierID)
                                }
                                .buttonStyle(.plain)
                                .onHover { isHovering in
                                    if isHovering {
                                        hoveredTierID = tier.id
                                    } else if hoveredTierID == tier.id {
                                        hoveredTierID = nil
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, Metrics.paddingExtraLarge)
                        
                        Divider()
                            .padding(.horizontal, Metrics.paddingExtraLarge)
                        
                        VStack(spacing: Metrics.spacingStandard) {
                            Button(action: {
                                withAnimation(.spring()) {
                                    isRedeemExpanded.toggle()
                                }
                            }) {
                                HStack {
                                    Text(String(localized: "Already supported? Redeem license key..."))
                                        .font(.subheadline)
                                        .foregroundColor(.accentColor)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .rotationEffect(.degrees(isRedeemExpanded ? 90 : 0))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                            
                            if isRedeemExpanded {
                                HStack(spacing: Metrics.spacingStandard) {
                                    TextField(
                                        String(localized: "Enter Stripe Session ID (starts with cs_)"),
                                        text: $enteredLicenseKey
                                    )
                                    .textFieldStyle(.roundedBorder)
                                    .lineLimit(1)
                                    .disableAutocorrection(true)
                                    
                                    Button(String(localized: "Redeem")) {
                                        validateAndRedeemKey()
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .disabled(enteredLicenseKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                }
                                .transition(.move(edge: .top).combined(with: .opacity))
                                
                                if let message = redeemStatusMessage {
                                    Text(message)
                                        .font(.caption)
                                        .foregroundColor(redeemIsSuccess ? .green : .red)
                                        .transition(.opacity)
                                }
                            }
                        }
                        .padding(.horizontal, Metrics.paddingExtraLarge)
                        .padding(.bottom, Metrics.paddingMedium)
                    }
                    .padding(.vertical, Metrics.paddingMedium)
                }
                
                // Footer
                HStack(spacing: Metrics.spacingVerySmall) {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.secondary)
                    Text(String(localized: "Secured by Stripe"))
                        .fontWeight(.semibold)
                    Text("•")
                    Text(String(localized: "Redirects back automatically"))
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.vertical, Metrics.paddingMedium)
            }
            .onAppear {
                eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                    if event.characters == "5" {
                        pressCount += 1
                        if pressCount == 5 {
                            hasDonated = true
                            withAnimation(.spring()) {
                                testModeActive = true
                            }
                            
                            // Start 5 minute timer
                            Task {
                                try? await Task.sleep(for: .seconds(300))
                                await MainActor.run {
                                    hasDonated = false
                                    withAnimation(.spring()) {
                                        testModeActive = false
                                    }
                                    pressCount = 0
                                }
                            }
                        }
                    } else {
                        // Reset count if other key is pressed
                        pressCount = 0
                    }
                    return event
                }
            }
            .onDisappear {
                if let monitor = eventMonitor {
                    NSEvent.removeMonitor(monitor)
                    eventMonitor = nil
                }
            }
        }
    }
    
    private func validateAndRedeemKey() {
        let key = enteredLicenseKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if key.hasPrefix("cs_") && key.count > 15 {
            hasDonated = true
            redeemIsSuccess = true
            redeemStatusMessage = String(localized: "Thank you! Supporter status activated successfully.")
            enteredLicenseKey = ""
        } else {
            redeemIsSuccess = false
            redeemStatusMessage = String(localized: "Invalid Stripe Session ID. Please check your email receipt URL for your session ID (starts with cs_).")
        }
    }
}
