import Foundation
import CoreGraphics

public enum Metrics {
    // Window Sizes
    public static let minWindowWidth: CGFloat = 600
    public static let minWindowHeight: CGFloat = 400
    
    public static let settingsWindowWidth: CGFloat = 520
    public static let settingsWindowHeight: CGFloat = 440

    // Spacing
    public static let spacingNone: CGFloat = 0
    public static let spacingTiny: CGFloat = 1
    public static let spacingVerySmall: CGFloat = 4
    public static let spacingSmall: CGFloat = 6
    public static let spacingStandard: CGFloat = 8
    public static let spacingMedium: CGFloat = 10
    public static let spacingLarge: CGFloat = 16
    public static let spacingExtraLarge: CGFloat = 20
    
    // Padding
    public static let paddingNone: CGFloat = 0
    public static let paddingVerySmall: CGFloat = 2
    public static let paddingSmall: CGFloat = 4
    public static let paddingMedium: CGFloat = 8
    public static let paddingStandard: CGFloat = 10
    public static let paddingLarge: CGFloat = 12
    public static let paddingExtraLarge: CGFloat = 16
    public static let paddingDoubleExtraLarge: CGFloat = 40
    
    // Corner Radius
    public static let cornerRadiusSmall: CGFloat = 4
    public static let cornerRadiusStandard: CGFloat = 6
    public static let cornerRadiusMedium: CGFloat = 8
    public static let cornerRadiusLarge: CGFloat = 12
    
    // Icon & Image Sizes
    public static let iconMini: CGFloat = 16
    public static let iconSmall: CGFloat = 18
    public static let iconStatus: CGFloat = 48
    public static let iconLarge: CGFloat = 64
    public static let iconHuge: CGFloat = 80
    
    // Custom sizes / limits
    public static let infoPopoverWidth: CGFloat = 320
    public static let tableActionColumnWidth: CGFloat = 30
    public static let tableSizeColumnMin: CGFloat = 80
    public static let tableSizeColumnIdeal: CGFloat = 100
    public static let tableSizeColumnMax: CGFloat = 150
    public static let diskMapTooltipWidth: CGFloat = 250
    
    public static let aboutLicensingHeight: CGFloat = 120
    
    // Disk Map Constants
    public static let diskMapLineWidth: CGFloat = 0.5
    public static let diskMapMaxDepth: Int = 4
    public static let diskMapCenterRadiusRatio: CGFloat = 0.2
    public static let diskMapMaxRadiusRatio: CGFloat = 0.95
    public static let diskMapMinFraction: Double = 0.005
    public static let diskMapMinAngle: Double = 0.008

    // Pineapple Chart Shape
    public static let pineappleScaleX: CGFloat = 0.76        // horizontal squish (< 1 = narrower)
    public static let pineappleScaleY: CGFloat = 1.0         // vertical scale
    public static let pineappleBottomBulge: CGFloat = 0.07   // extra width for lower half
    public static let pineappleArcSteps: Int = 3             // degrees per line segment (lower = smoother)

    // Pineapple Segment Gaps
    public static let pineappleSegmentGap: CGFloat = 1.5     // stroke width between segments
    public static let pineappleAngleInset: Double = 0.006    // radians inset per wedge edge
    public static let pineappleRadiusInset: CGFloat = 0.5    // pt inset on inner/outer radius

    // Pineapple Crown
    public static let pineappleCrownHeadroom: CGFloat = 0.18 // how far body shifts down as fraction of maxRadius
    public static let pineappleBodyScale: CGFloat = 0.84     // body shrinks to leave room for crown
    public static let pineappleLeafHeightRatio: CGFloat = 0.38  // leaf height as fraction of maxRadius
    public static let pineappleLeafWidthRatio: CGFloat = 0.16   // leaf width as fraction of maxRadius
}
