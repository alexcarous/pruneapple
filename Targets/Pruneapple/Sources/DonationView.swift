import SwiftUI

struct DonationView: View {
    @State private var hoveredTierID: String? = nil
    
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
            name: String(localized: "Buy me a coffee"),
            price: "$5",
            description: String(localized: "Fuel active development and support minor releases."),
            url: "https://buy.stripe.com/test_555_coffee",
            icon: "cup.and.saucer.fill",
            gradientColors: [Color.brown, Color.orange]
        ),
        DonationTier(
            id: "matcha",
            name: String(localized: "Buy me a matcha"),
            price: "$10",
            description: String(localized: "Keep the codebase optimized and the servers running."),
            url: "https://buy.stripe.com/test_555_matcha",
            icon: "leaf.fill",
            gradientColors: [Color.green, Color.mint]
        ),
        DonationTier(
            id: "mokapot",
            name: String(localized: "Buy me a moka pot"),
            price: "$50",
            description: String(localized: "A substantial contribution to unlock major future updates."),
            url: "https://buy.stripe.com/test_555_mokapot",
            icon: "flame.fill",
            gradientColors: [Color.red, Color.orange]
        ),
        DonationTier(
            id: "espresso",
            name: String(localized: "Espresso Machine"),
            price: String(localized: "Custom"),
            description: String(localized: "Choose your own level of support for Pruneapple."),
            url: "https://buy.stripe.com/test_555_espresso",
            icon: "star.fill",
            gradientColors: [Color.purple, Color.indigo]
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: Metrics.spacingLarge) {
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
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Metrics.spacingMedium) {
                    ForEach(tiers) { tier in
                        Button(action: {
                            if let url = URL(string: tier.url) {
                                NSWorkspace.shared.open(url)
                            }
                        }) {
                            HStack(alignment: .top, spacing: Metrics.spacingStandard) {
                                // Icon container with colored gradient background
                                ZStack {
                                    RoundedRectangle(cornerRadius: Metrics.cornerRadiusStandard)
                                        .fill(.linearGradient(colors: tier.gradientColors, startPoint: .top, endPoint: .bottom))
                                        .frame(width: 36, height: 36)
                                    
                                    Image(systemName: tier.icon)
                                        .font(.title3)
                                        .foregroundColor(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: Metrics.spacingVerySmall) {
                                    HStack {
                                        Text(tier.name)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Text(tier.price)
                                            .font(.subheadline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.accentColor)
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
                                RoundedRectangle(cornerRadius: Metrics.cornerRadiusMedium)
                                    .fill(Color(NSColor.controlBackgroundColor))
                                    .shadow(color: Color.black.opacity(hoveredTierID == tier.id ? 0.15 : 0.05), radius: hoveredTierID == tier.id ? 4 : 2)
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
    }
}
