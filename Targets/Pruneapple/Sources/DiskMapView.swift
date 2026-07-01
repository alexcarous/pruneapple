// swiftlint:disable identifier_name
// swiftlint:disable file_length
// swiftlint:disable function_parameter_count
import SwiftUI

struct DiskMapView: View {
    let rootItem: FileItem

    @State private var hoveredPath: [FileItem] = []

    private let byteFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter
    }()

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let baseRadius = min(size.width, size.height) / 2 * Metrics.diskMapMaxRadiusRatio
            let maxRadius = baseRadius * Metrics.pineappleBodyScale
            let crownHeadroom = baseRadius * Metrics.pineappleCrownHeadroom
            let center = CGPoint(x: size.width / 2, y: size.height / 2 + crownHeadroom)

            ZStack {
                Canvas { context, _ in
                    // Draw pineapple body
                    drawNode(
                        item: rootItem,
                        context: &context,
                        center: center,
                        radius: maxRadius,
                        startAngle: .zero,
                        endAngle: .degrees(360),
                        depth: 0
                    )
                    // Draw decorative crown on top
                    drawCrown(context: &context, center: center, maxRadius: maxRadius)
                }
                .onContinuousHover { phase in
                    switch phase {
                    case .active(let location):
                        let hit = hitTest(location: location, center: center, radius: maxRadius)
                        if hit.last?.id != hoveredPath.last?.id {
                            hoveredPath = hit
                        }
                    case .ended:
                        hoveredPath = []
                    }
                }
                .onTapGesture { location in
                    let hit = hitTest(location: location, center: center, radius: maxRadius)
                    if let tapped = hit.last {
                        NSWorkspace.shared.selectFile(tapped.url.path, inFileViewerRootedAtPath: "")
                    }
                }

                if let hovered = hoveredPath.last {
                    VStack(spacing: Metrics.spacingVerySmall) {
                        Text(hovered.name == "Other Smaller Files"
                             ? String(localized: "Other Smaller Files")
                             : hovered.name)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                        Text(byteFormatter.string(fromByteCount: hovered.physicalSize))
                            .font(.subheadline)
                            .monospacedDigit()

                        if hoveredPath.count > 1 {
                            Text(
                                hoveredPath.dropLast().map {
                                    $0.name == "Other Smaller Files"
                                        ? String(localized: "Other Smaller Files")
                                        : $0.name
                                }.joined(separator: " ▸ ")
                            )
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.head)
                        }
                    }
                    .padding(Metrics.paddingStandard)
                    .modifier(TooltipBackgroundModifier())
                    .shadow(radius: Metrics.cornerRadiusSmall)
                    .frame(width: Metrics.diskMapTooltipWidth)
                    .position(x: center.x, y: center.y)
                    .allowsHitTesting(false)
                }
            }
        }
    }

    // MARK: - Pineapple Shape Helpers

    /// Converts polar coordinates to a pineapple-shaped (ovoid) cartesian point.
    /// The bottom half is slightly wider via `bottomBulge`.
    private func pineapplePoint(center: CGPoint, radius: CGFloat, angle: Double) -> CGPoint {
        var sx = Metrics.pineappleScaleX
        let sy = Metrics.pineappleScaleY
        // Bottom half (sin > 0 in screen coords) is slightly wider
        if sin(angle) > 0 {
            sx += Metrics.pineappleBottomBulge
        }
        let x = center.x + radius * CGFloat(cos(angle)) * sx
        let y = center.y + radius * CGFloat(sin(angle)) * sy
        return CGPoint(x: x, y: y)
    }

    /// Builds a wedge Path using distorted pineapple coordinates instead of circular arcs.
    private func pineappleWedge(
        center: CGPoint,
        innerRadius: CGFloat,
        outerRadius: CGFloat,
        startAngle: Double,
        endAngle: Double
    ) -> Path {
        let spanDegrees = (endAngle - startAngle) * 180 / .pi
        let steps = max(Int(spanDegrees / Double(Metrics.pineappleArcSteps)), 4)

        return Path { path in
            // Outer arc — forward
            for i in 0...steps {
                let t = Double(i) / Double(steps)
                let a = startAngle + t * (endAngle - startAngle)
                let pt = pineapplePoint(center: center, radius: outerRadius, angle: a)
                if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
            }
            // Inner arc — backward
            for i in stride(from: steps, through: 0, by: -1) {
                let t = Double(i) / Double(steps)
                let a = startAngle + t * (endAngle - startAngle)
                let pt = pineapplePoint(center: center, radius: innerRadius, angle: a)
                path.addLine(to: pt)
            }
            path.closeSubpath()
        }
    }

    // MARK: - Radius Helpers

    private func ringWidth(for depth: Int, maxRadius: CGFloat) -> CGFloat {
        let centerRadius = maxRadius * Metrics.diskMapCenterRadiusRatio
        let remaining = maxRadius - centerRadius
        return remaining / CGFloat(Metrics.diskMapMaxDepth)
    }

    private func radiusRange(for depth: Int, maxRadius: CGFloat) -> ClosedRange<CGFloat> {
        let centerRadius = maxRadius * Metrics.diskMapCenterRadiusRatio
        if depth == 0 {
            return 0...centerRadius
        }
        let width = ringWidth(for: depth, maxRadius: maxRadius)
        let inner = centerRadius + CGFloat(depth - 1) * width
        return inner...(inner + width)
    }

    // MARK: - Drawing

    private func drawNode(
        item: FileItem,
        context: inout GraphicsContext,
        center: CGPoint,
        radius: CGFloat,
        startAngle: Angle,
        endAngle: Angle,
        depth: Int
    ) {
        if depth > Metrics.diskMapMaxDepth { return }

        let range = radiusRange(for: depth, maxRadius: radius)

        // Apply inset to create visible gaps between segments
        let insetAngle = Metrics.pineappleAngleInset
        let insetRadius = Metrics.pineappleRadiusInset
        let insetStart = startAngle.radians + (depth == 0 ? 0 : insetAngle)
        let insetEnd = endAngle.radians - (depth == 0 ? 0 : insetAngle)
        let innerR = max(0, range.lowerBound + (depth == 0 ? 0 : insetRadius))
        let outerR = range.upperBound - (depth == 0 ? 0 : insetRadius)

        let path = pineappleWedge(
            center: center,
            innerRadius: innerR,
            outerRadius: outerR,
            startAngle: insetStart,
            endAngle: max(insetStart + 0.001, insetEnd)
        )

        let isHovered = hoveredPath.contains(where: { $0.id == item.id })
        let color = colorForDepth(depth, item: item, isHovered: isHovered)

        context.blendMode = .hardLight
        context.fill(path, with: .color(color.opacity(0.88)))
        context.blendMode = .normal

        // Dark amber stroke to evoke pineapple skin texture
        let strokeColor = depth == 0
            ? Color.clear
            : Color(hue: 0.08, saturation: 0.5, brightness: 0.28).opacity(0.55)
        context.stroke(path, with: .color(strokeColor), lineWidth: Metrics.pineappleSegmentGap)

        guard let children = item.children, !children.isEmpty, depth < Metrics.diskMapMaxDepth else { return }

        let totalAngle = endAngle.radians - startAngle.radians
        let totalSize = max(item.physicalSize, children.reduce(0) { $0 + $1.physicalSize })

        var currentStart = startAngle.radians
        for child in children {
            let childFraction = totalSize > 0 ? Double(child.physicalSize) / Double(totalSize) : 0
            let childAngle = totalAngle * childFraction

            if childFraction >= Metrics.diskMapMinFraction && childAngle > Metrics.diskMapMinAngle {
                let childEnd = currentStart + childAngle
                drawNode(
                    item: child,
                    context: &context,
                    center: center,
                    radius: radius,
                    startAngle: .radians(currentStart),
                    endAngle: .radians(childEnd),
                    depth: depth + 1
                )
            }
            currentStart += childAngle
        }
    }

    // MARK: - Crown

    private func drawLeaf(
        path: inout Path,
        base: CGPoint,
        tip: CGPoint,
        width: CGFloat
    ) {
        let midX = (base.x + tip.x) / 2
        let midY = (base.y + tip.y) / 2
        let controlL = CGPoint(x: midX - width, y: midY)
        let controlR = CGPoint(x: midX + width, y: midY)

        path.move(to: base)
        path.addQuadCurve(to: tip, control: controlL)
        path.addQuadCurve(to: base, control: controlR)
    }

    private func crownPath(center: CGPoint, maxRadius: CGFloat) -> Path {
        // Crown fans from just above the oval top
        let leafH = maxRadius * Metrics.pineappleLeafHeightRatio
        let leafW = maxRadius * Metrics.pineappleLeafWidthRatio
        let topY = center.y - maxRadius * Metrics.pineappleScaleY
        let base = CGPoint(x: center.x, y: topY)

        return Path { path in
            // Centre leaf — tallest, straight up
            drawLeaf(
                path: &path,
                base: base,
                tip: CGPoint(x: center.x, y: topY - leafH),
                width: leafW * 0.55
            )
            // Inner left
            drawLeaf(
                path: &path,
                base: base,
                tip: CGPoint(x: center.x - leafW * 1.1, y: topY - leafH * 0.72),
                width: leafW * 0.45
            )
            // Outer left
            drawLeaf(
                path: &path,
                base: base,
                tip: CGPoint(x: center.x - leafW * 2.0, y: topY - leafH * 0.42),
                width: leafW * 0.35
            )
            // Inner right
            drawLeaf(
                path: &path,
                base: base,
                tip: CGPoint(x: center.x + leafW * 1.1, y: topY - leafH * 0.72),
                width: leafW * 0.45
            )
            // Outer right
            drawLeaf(
                path: &path,
                base: base,
                tip: CGPoint(x: center.x + leafW * 2.0, y: topY - leafH * 0.42),
                width: leafW * 0.35
            )
        }
    }

    private func drawCrown(context: inout GraphicsContext, center: CGPoint, maxRadius: CGFloat) {
        let crown = crownPath(center: center, maxRadius: maxRadius)
        let topY = center.y - maxRadius * Metrics.pineappleScaleY - maxRadius * Metrics.pineappleLeafHeightRatio
        let baseY = center.y - maxRadius * Metrics.pineappleScaleY

        let gradient = Gradient(colors: [
            Color(hue: 0.30, saturation: 0.85, brightness: 0.45),  // deep forest green (tip)
            Color(hue: 0.33, saturation: 0.78, brightness: 0.62)   // lighter green (base)
        ])
        context.fill(crown, with: .linearGradient(
            gradient,
            startPoint: CGPoint(x: center.x, y: topY),
            endPoint: CGPoint(x: center.x, y: baseY)
        ))
        // Subtle dark green stroke on crown
        context.stroke(
            crown,
            with: .color(Color(hue: 0.32, saturation: 0.7, brightness: 0.3).opacity(0.5)),
            lineWidth: 0.8
        )
    }

    // MARK: - Color Palette

    private static let pineapplePalette: [Color] = [
        Color(hue: 0.12, saturation: 0.88, brightness: 0.96),  // golden yellow
        Color(hue: 0.08, saturation: 0.82, brightness: 0.91),  // amber
        Color(hue: 0.10, saturation: 0.76, brightness: 0.86),  // dark gold
        Color(hue: 0.06, saturation: 0.72, brightness: 0.82),  // orange-brown
        Color(hue: 0.14, saturation: 0.68, brightness: 0.93),  // light gold
        Color(hue: 0.05, saturation: 0.78, brightness: 0.87),  // warm orange
        Color(hue: 0.11, saturation: 0.92, brightness: 0.89),  // rich gold
        Color(hue: 0.15, saturation: 0.62, brightness: 0.96)   // pale yellow
    ]

    private func colorForDepth(_ depth: Int, item: FileItem, isHovered: Bool) -> Color {
        if depth == 0 {
            // Soft creamy yellow core
            return isHovered
                ? Color(hue: 0.14, saturation: 0.28, brightness: 1.0)
                : Color(hue: 0.14, saturation: 0.22, brightness: 0.97)
        }

        let index = abs(item.id) % Self.pineapplePalette.count
        let base = Self.pineapplePalette[index]

        if isHovered {
            // Brighten on hover using a lightened version
            return base.opacity(1.0)
        }

        // Darken slightly at deeper depths
        let depthFactor = 1.0 - Double(depth - 1) * 0.09
        var hue: CGFloat = 0, sat: CGFloat = 0, bri: CGFloat = 0, alpha: CGFloat = 0
        NSColor(base).usingColorSpace(.sRGB)?.getHue(&hue, saturation: &sat, brightness: &bri, alpha: &alpha)
        return Color(hue: Double(hue), saturation: Double(sat), brightness: min(Double(bri) * depthFactor, 1.0))
    }

    // MARK: - Hit Testing

    private func hitTest(location: CGPoint, center: CGPoint, radius: CGFloat) -> [FileItem] {
        let deltaX = location.x - center.x
        let deltaY = location.y - center.y

        // Reverse the pineapple oval distortion to get logical polar coords.
        // Use average scaleX (bottom bulge applies to lower half only — approximate).
        let avgSX = Metrics.pineappleScaleX + (deltaY > 0 ? Metrics.pineappleBottomBulge : 0)
        let logicalX = deltaX / avgSX
        let logicalY = deltaY / Metrics.pineappleScaleY

        let distance = sqrt(logicalX * logicalX + logicalY * logicalY)
        var angle = atan2(logicalY, logicalX)
        if angle < 0 { angle += 2 * .pi }

        var result: [FileItem] = []
        hitTestNode(
            item: rootItem,
            distance: distance,
            angle: angle,
            startAngle: 0,
            endAngle: 2 * .pi,
            depth: 0,
            maxRadius: radius,
            result: &result
        )
        return result
    }

    private func hitTestNode(
        item: FileItem,
        distance: CGFloat,
        angle: CGFloat,
        startAngle: CGFloat,
        endAngle: CGFloat,
        depth: Int,
        maxRadius: CGFloat,
        result: inout [FileItem]
    ) {
        if depth > Metrics.diskMapMaxDepth { return }

        let range = radiusRange(for: depth, maxRadius: maxRadius)

        if distance >= range.lowerBound && distance <= range.upperBound {
            result.append(item)
            return
        }

        if distance > range.upperBound {
            result.append(item)
            guard let children = item.children, !children.isEmpty, depth < Metrics.diskMapMaxDepth else { return }

            let totalAngle = endAngle - startAngle
            let totalSize = max(item.physicalSize, children.reduce(0) { $0 + $1.physicalSize })

            var currentStart = startAngle
            for child in children {
                let childFraction = totalSize > 0 ? Double(child.physicalSize) / Double(totalSize) : 0
                let childAngle = totalAngle * childFraction

                if childFraction >= Metrics.diskMapMinFraction && childAngle > Metrics.diskMapMinAngle {
                    let childEnd = currentStart + childAngle
                    if angle >= currentStart && angle <= childEnd {
                        hitTestNode(
                            item: child,
                            distance: distance,
                            angle: angle,
                            startAngle: currentStart,
                            endAngle: childEnd,
                            depth: depth + 1,
                            maxRadius: maxRadius,
                            result: &result
                        )
                        return
                    }
                }
                currentStart += childAngle
            }
        }
    }
}

// MARK: - Tooltip Background

struct TooltipBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        #if compiler(>=6.3)
        if #available(macOS 26.0, *) {
            content.glassEffect(.regular, in: .rect(cornerRadius: Metrics.cornerRadiusMedium))
        } else {
            content
                .background(.regularMaterial)
                .cornerRadius(Metrics.cornerRadiusMedium)
        }
        #else
        content
            .background(.regularMaterial)
            .cornerRadius(Metrics.cornerRadiusMedium)
        #endif
    }
}
