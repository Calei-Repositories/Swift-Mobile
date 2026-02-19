import SwiftUI

// MARK: - Rounded Corner Shape

/// Shape personalizada para redondear esquinas específicas
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

extension View {
    /// Aplica radio de esquina a esquinas específicas
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

// MARK: - Map Annotation Item

struct MapAnnotationItem: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

// MARK: - Haptic Feedback

struct HapticFeedback {
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    static func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
}

// MARK: - View Modifiers

/// Modifier para shimmer effect (loading placeholder)
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.clear,
                            Color.white.opacity(0.5),
                            Color.clear
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + (geometry.size.width * 2 * phase))
                }
            )
            .mask(content)
            .onAppear {
                Task { @MainActor in
                    withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        phase = 1
                    }
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Skeleton Loading View

struct SkeletonView: View {
    var height: CGFloat = 20
    var cornerRadius: CGFloat = 8
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(CaleiColors.gray200)
            .frame(height: height)
            .shimmer()
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: CaleiSpacing.space6) {
            ZStack {
                Circle()
                    .fill(CaleiColors.accentSoft)
                    .frame(width: 100, height: 100)
                
                Image(systemName: icon)
                    .font(.system(size: 44))
                    .foregroundColor(CaleiColors.accent)
            }
            
            VStack(spacing: CaleiSpacing.space2) {
                Text(title)
                    .font(CaleiTypography.h3)
                    .foregroundColor(CaleiColors.dark)
                
                Text(message)
                    .font(CaleiTypography.body)
                    .foregroundColor(CaleiColors.gray500)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .caleiPrimaryButton()
                }
            }
        }
    }
}

// MARK: - Loading Overlay

struct LoadingOverlay: View {
    let message: String
    
    var body: some View {
        ZStack {
            CaleiColors.dark.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: CaleiSpacing.space4) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text(message)
                    .font(CaleiTypography.body)
                    .foregroundColor(.white)
            }
            .padding(CaleiSpacing.space8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(CaleiColors.brandDark.opacity(0.85))
            )
        }
    }
}

// MARK: - Badge View

struct BadgeView: View {
    let text: String
    var color: Color = CaleiColors.accent
    
    var body: some View {
        Text(text)
            .font(CaleiTypography.caption)
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .cornerRadius(8)
    }
}

// MARK: - Status Indicator

struct StatusIndicator: View {
    let isActive: Bool
    var activeColor: Color = CaleiColors.success
    var inactiveColor: Color = CaleiColors.gray400
    
    var body: some View {
        Circle()
            .fill(isActive ? activeColor : inactiveColor)
            .frame(width: 8, height: 8)
    }
}

// MARK: - Offline Banner

struct OfflineBanner: View {
    @ObservedObject var offlineService = OfflineSyncService.shared
    
    var body: some View {
        if !offlineService.isOnline {
            HStack(spacing: 8) {
                Image(systemName: "wifi.slash")
                    .font(.caption)
                
                Text("Sin conexión")
                    .font(CaleiTypography.caption)
                
                if offlineService.hasPendingData {
                    Text("• \(offlineService.totalPendingCount) pendientes")
                        .font(CaleiTypography.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(CaleiColors.warning)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

// MARK: - Import CoreLocation for MapAnnotationItem

import CoreLocation
