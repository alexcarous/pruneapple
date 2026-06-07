import SwiftUI
import QuickLookUI

struct SmartPruneView: View {
    @Environment(DiskAnalyzer.self) private var diskAnalyzer
    let rootItem: FileItem
    
    private let byteFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: Metrics.spacingNone) {
            if diskAnalyzer.isAnalyzingAI {
                VStack(spacing: Metrics.spacingLarge) {
                    ProgressView()
                        .progressViewStyle(.circular)
                    Text(String(localized: "AI is analyzing large files..."))
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let aiError = diskAnalyzer.aiAnalysisError {
                VStack(spacing: Metrics.spacingLarge) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: Metrics.iconLarge))
                        .foregroundStyle(.orange)
                    Text(aiError.contains("unavailable") ? String(localized: "AI Analysis Unavailable") : String(localized: "AI Analysis Failed"))
                        .font(.headline)
                    Text(aiError)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Metrics.paddingDoubleExtraLarge)
                    
                    if aiError.contains("unavailable") {
                        Button(String(localized: "Turn on in System Settings")) {
                            if let url = URL(string: "x-apple.systempreferences:com.apple.AppleIntelligence-Settings.extension") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top, Metrics.paddingSmall)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if diskAnalyzer.aiInsights.isEmpty {
                VStack(spacing: Metrics.spacingLarge) {
                    Image(systemName: "sparkles")
                        .font(.system(size: Metrics.iconLarge))
                        .foregroundStyle(.secondary)
                    Text(String(localized: "No Large Files Analyzed"))
                        .font(.headline)
                    Text(String(localized: "Only files larger than 50MB are evaluated by Smart Prune AI."))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Metrics.paddingDoubleExtraLarge)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: Metrics.spacingMedium) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(String(localized: "Apple Intelligence Recommendations"))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text(String(localized: "On-device AI analysis of top files larger than 50MB."))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Image(systemName: "cpu")
                                Text(String(localized: "Apple Intelligence Active"))
                            }
                            .font(.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .foregroundStyle(Color.accentColor)
                            .background(Color.accentColor.opacity(0.15))
                            .clipShape(Capsule())
                        }
                        .padding(.horizontal)
                        .padding(.top, Metrics.paddingLarge)
                        
                        ForEach(diskAnalyzer.aiInsights.keys.sorted(by: {
                            let scoreA = diskAnalyzer.aiInsights[$0]?.score ?? 0
                            let scoreB = diskAnalyzer.aiInsights[$1]?.score ?? 0
                            if scoreA != scoreB {
                                return scoreA > scoreB
                            }
                            return $0.lastPathComponent < $1.lastPathComponent
                        }), id: \.self) { url in
                            if let insight = diskAnalyzer.aiInsights[url] {
                                let item = findItem(by: url, in: rootItem)
                                SmartPruneRow(url: url, item: item, insight: insight, byteFormatter: byteFormatter)
                            }
                        }
                    }
                    .padding(.bottom, Metrics.paddingExtraLarge)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func findItem(by url: URL, in node: FileItem) -> FileItem? {
        if node.url.standardizedFileURL == url.standardizedFileURL { return node }
        if let children = node.children {
            for child in children {
                if let found = findItem(by: url, in: child) {
                    return found
                }
            }
        }
        return nil
    }
}

struct SmartPruneRow: View {
    let url: URL
    let item: FileItem?
    let insight: SmartPruneAnalysis
    let byteFormatter: ByteCountFormatter
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(alignment: .top, spacing: Metrics.spacingLarge) {
            // Icon
            Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                .resizable()
                .frame(width: Metrics.iconLarge, height: Metrics.iconLarge)
                .shadow(color: Color.black.opacity(0.1), radius: 2, y: 1)
            
            VStack(alignment: .leading, spacing: Metrics.spacingVerySmall) {
                HStack(alignment: .firstTextBaseline) {
                    Text(url.lastPathComponent)
                        .font(.headline)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    
                    if let size = item?.physicalSize {
                        Text(byteFormatter.string(fromByteCount: size))
                            .font(.subheadline)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    ScoreBadge(score: insight.score)
                }
                
                Text(insight.reason)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack(spacing: 8) {
                    Text(url.deletingLastPathComponent().path)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.head)
                }
                .padding(.top, 2)
            }
        }
        .padding(Metrics.paddingLarge)
        .background(
            RoundedRectangle(cornerRadius: Metrics.cornerRadiusLarge)
                .fill(Color(NSColor.controlBackgroundColor).opacity(isHovered ? 0.6 : 0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: Metrics.cornerRadiusLarge)
                        .stroke(Color.primary.opacity(isHovered ? 0.15 : 0.05), lineWidth: 1)
                )
        )
        .padding(.horizontal)
        .overlay(alignment: .trailing) {
            HStack(spacing: Metrics.spacingSmall) {
                Button(action: quickLook) {
                    Image(systemName: "eye.fill")
                        .font(.body.bold())
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                        .background(Color(NSColor.windowBackgroundColor))
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.15), radius: 3)
                }
                .buttonStyle(.plain)
                .help(String(localized: "Quick Look"))
                
                Button(action: revealInFinder) {
                    Image(systemName: "magnifyingglass")
                        .font(.body.bold())
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                        .background(Color(NSColor.windowBackgroundColor))
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.15), radius: 3)
                }
                .buttonStyle(.plain)
                .help(String(localized: "Reveal in Finder"))
            }
            .padding(.trailing, 80) // Offset from Score Badge
            .opacity(isHovered ? 1 : 0)
            .scaleEffect(isHovered ? 1.0 : 0.95)
            .allowsHitTesting(isHovered)
        }
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .contextMenu {
            Button(String(localized: "Reveal in Finder")) {
                revealInFinder()
            }
            Button(String(localized: "Quick Look")) {
                quickLook()
            }
        }
    }
    
    private func revealInFinder() {
        NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: "")
    }
    
    private func quickLook() {
        QuickLookController.shared.showPreview(url: url)
    }
}

struct ScoreBadge: View {
    let score: Double
    
    var color: Color {
        if score >= 0.8 { return .red } // High risk / high pruneability (easy to delete)
        if score >= 0.4 { return .orange } // Moderate risk
        return .green // Low risk / keep
    }
    
    var label: String {
        if score >= 0.8 { return String(localized: "High Pruning") }
        if score >= 0.4 { return String(localized: "Recommended") }
        return String(localized: "Keep Safe")
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(color)
            Text(String(format: "%.1f", score))
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(color.opacity(0.8))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }
}
