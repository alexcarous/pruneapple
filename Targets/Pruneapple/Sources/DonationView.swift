import SwiftUI

struct DonationView: View {
    @State private var hoveredTierID: String?
    
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
            url: "https://buy.stripe.com/3cs3fXaST6uy9MI006",
            icon: "coffee-donation",
            gradientColors: [Color.brown, Color.orange]
        ),
        DonationTier(
            id: "matcha",
            name: String(localized: "Buy me a matcha"),
            price: "$10",
            description: String(localized: "Keep the codebase optimized and the servers running."),
            url: "https://donate.stripe.com/bJeaEY5Fe5Nw6LHdC9bV607",
            icon: "matcha-donation",
            gradientColors: [Color.green, Color.mint]
        ),
        DonationTier(
            id: "mokapot",
            name: String(localized: "Buy me a moka pot"),
            price: "$50",
            description: String(localized: "A substantial contribution to unlock major future updates."),
            url: "https://buy.stripe.com/4gMcN61oYa3M8TPgOlbV608",
            icon: "mokapot-donation",
            gradientColors: [Color.red, Color.orange]
        ),
        DonationTier(
            id: "espresso",
            name: String(localized: "Espresso Machine"),
            price: String(localized: "Custom"),
            description: String(localized: "Choose your own level of support for Pruneapple."),
            url: "https://donate.stripe.com/cNi5kE9Vu4Js8TPgOlbV609",
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
}
