import SwiftUI

struct DiskMapView: View {
    let rootItem: FileItem
    
    @State private var hoveredPath: [FileItem] = []
    
    private let maxDepth = 6
    
    private let byteFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter
    }()
    
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let maxRadius = min(size.width, size.height) / 2 * 0.95
            
            ZStack {
                Canvas { context, size in
                    drawNode(item: rootItem, context: &context, center: center, radius: maxRadius, startAngle: .zero, endAngle: .degrees(360), depth: 0)
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
                    VStack(spacing: 4) {
                        Text(hovered.name)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                        Text(byteFormatter.string(fromByteCount: hovered.physicalSize))
                            .font(.subheadline)
                            .monospacedDigit()
                        
                        if hoveredPath.count > 1 {
                            Text(hoveredPath.dropLast().map { $0.name }.joined(separator: " ▸ "))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .truncationMode(.head)
                        }
                    }
                    .padding(10)
                    .background(.regularMaterial)
                    .cornerRadius(8)
                    .shadow(radius: 4)
                    .frame(width: 250)
                    .position(x: center.x, y: center.y)
                    .allowsHitTesting(false)
                }
            }
        }
    }
    
    private func ringWidth(for depth: Int, maxRadius: CGFloat) -> CGFloat {
        let centerRadius = maxRadius * 0.2
        let remaining = maxRadius - centerRadius
        return remaining / CGFloat(maxDepth)
    }
    
    private func radiusRange(for depth: Int, maxRadius: CGFloat) -> ClosedRange<CGFloat> {
        let centerRadius = maxRadius * 0.2
        if depth == 0 {
            return 0...centerRadius
        }
        let width = ringWidth(for: depth, maxRadius: maxRadius)
        let inner = centerRadius + CGFloat(depth - 1) * width
        return inner...(inner + width)
    }
    
    private func drawNode(item: FileItem, context: inout GraphicsContext, center: CGPoint, radius: CGFloat, startAngle: Angle, endAngle: Angle, depth: Int) {
        if depth > maxDepth { return }
        
        let range = radiusRange(for: depth, maxRadius: radius)
        let path = Path { p in
            p.addArc(center: center, radius: range.upperBound, startAngle: startAngle, endAngle: endAngle, clockwise: false)
            p.addArc(center: center, radius: range.lowerBound, startAngle: endAngle, endAngle: startAngle, clockwise: true)
            p.closeSubpath()
        }
        
        let isHovered = hoveredPath.contains(where: { $0.id == item.id })
        let color = colorForDepth(depth, item: item, isHovered: isHovered)
        
        context.fill(path, with: .color(color))
        context.stroke(path, with: .color(Color.primary.opacity(0.15)), lineWidth: 0.5)
        
        guard let children = item.children, !children.isEmpty, depth < maxDepth else { return }
        
        let totalAngle = endAngle.radians - startAngle.radians
        let totalSize = max(item.physicalSize, children.reduce(0) { $0 + $1.physicalSize })
        
        var currentStart = startAngle.radians
        for child in children {
            let childFraction = totalSize > 0 ? Double(child.physicalSize) / Double(totalSize) : 0
            let childAngle = totalAngle * childFraction
            
            // Only draw slices that are large enough to be visible (e.g. > 0.5 degrees)
            if childAngle > 0.008 {
                let childEnd = currentStart + childAngle
                drawNode(item: child, context: &context, center: center, radius: radius, startAngle: .radians(currentStart), endAngle: .radians(childEnd), depth: depth + 1)
            }
            
            currentStart += childAngle
        }
    }
    
    private func colorForDepth(_ depth: Int, item: FileItem, isHovered: Bool) -> Color {
        let baseHue = Double(item.id % 255) / 255.0
        let saturation = depth == 0 ? 0.0 : 0.6
        let brightness = isHovered ? 1.0 : (0.9 - Double(depth) * 0.1)
        return Color(hue: baseHue, saturation: saturation, brightness: brightness)
    }
    
    private func hitTest(location: CGPoint, center: CGPoint, radius: CGFloat) -> [FileItem] {
        let dx = location.x - center.x
        let dy = location.y - center.y
        let r = sqrt(dx * dx + dy * dy)
        
        var angle = atan2(dy, dx)
        if angle < 0 { angle += 2 * .pi }
        
        var result: [FileItem] = []
        hitTestNode(item: rootItem, r: r, angle: angle, startAngle: 0, endAngle: 2 * .pi, depth: 0, maxRadius: radius, result: &result)
        return result
    }
    
    private func hitTestNode(item: FileItem, r: CGFloat, angle: CGFloat, startAngle: CGFloat, endAngle: CGFloat, depth: Int, maxRadius: CGFloat, result: inout [FileItem]) {
        if depth > maxDepth { return }
        
        let range = radiusRange(for: depth, maxRadius: maxRadius)
        
        if r >= range.lowerBound && r <= range.upperBound {
            result.append(item)
            return
        }
        
        if r > range.upperBound {
            result.append(item)
            guard let children = item.children, !children.isEmpty, depth < maxDepth else { return }
            
            let totalAngle = endAngle - startAngle
            let totalSize = max(item.physicalSize, children.reduce(0) { $0 + $1.physicalSize })
            
            var currentStart = startAngle
            for child in children {
                let childFraction = totalSize > 0 ? Double(child.physicalSize) / Double(totalSize) : 0
                let childAngle = totalAngle * childFraction
                
                if childAngle > 0.008 {
                    let childEnd = currentStart + childAngle
                    if angle >= currentStart && angle <= childEnd {
                        hitTestNode(item: child, r: r, angle: angle, startAngle: currentStart, endAngle: childEnd, depth: depth + 1, maxRadius: maxRadius, result: &result)
                        return
                    }
                }
                currentStart += childAngle
            }
        }
    }
}
