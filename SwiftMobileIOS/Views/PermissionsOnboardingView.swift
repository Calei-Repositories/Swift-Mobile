import SwiftUI

/// Vista de onboarding para explicar y solicitar permisos
struct PermissionsOnboardingView: View {
    @StateObject private var locationService = LocationService.shared
    @StateObject private var notificationService = RecordingNotificationService.shared
    
    @State private var currentStep = 0
    @Binding var isPresented: Bool
    
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Spacer()
                Button {
                    skipOnboarding()
                } label: {
                    Text("Omitir")
                        .font(CaleiTypography.button)
                        .foregroundColor(CaleiColors.textSecondary)
                }
            }
            .padding()
            
            Spacer()
            
            // Content
            TabView(selection: $currentStep) {
                locationPermissionStep
                    .tag(0)
                
                notificationPermissionStep
                    .tag(1)
                
                readyStep
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            Spacer()
            
            // Page indicator
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(currentStep == index ? CaleiColors.accent : CaleiColors.gray300)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.bottom, 20)
            
            // Action button
            actionButton
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
        }
        .background(CaleiColors.background)
    }
    
    // MARK: - Location Permission Step
    
    private var locationPermissionStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "location.fill")
                .font(.system(size: 80))
                .foregroundColor(CaleiColors.accent)
            
            Text("Acceso a tu ubicación")
                .font(CaleiTypography.h2)
                .foregroundColor(CaleiColors.textPrimary)
                .multilineTextAlignment(.center)
            
            Text("Necesitamos tu ubicación para:\n\n• Grabar tus recorridos en tiempo real\n• Marcar puntos de venta automáticamente\n• Calcular distancias recorridas")
                .font(CaleiTypography.body)
                .foregroundColor(CaleiColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            // Status indicator
            if locationService.authorizationStatus == .authorizedAlways ||
               locationService.authorizationStatus == .authorizedWhenInUse {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(CaleiColors.success)
                    Text("Permiso otorgado")
                        .font(CaleiTypography.caption)
                        .foregroundColor(CaleiColors.success)
                }
                .padding(.top, 8)
            }
        }
        .padding()
    }
    
    // MARK: - Notification Permission Step
    
    private var notificationPermissionStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 80))
                .foregroundColor(CaleiColors.warning)
            
            Text("Notificaciones")
                .font(CaleiTypography.h2)
                .foregroundColor(CaleiColors.textPrimary)
                .multilineTextAlignment(.center)
            
            Text("Las notificaciones te permiten:\n\n• Ver que la grabación está activa\n• Pausar o detener desde la notificación\n• Marcar puntos sin abrir la app")
                .font(CaleiTypography.body)
                .foregroundColor(CaleiColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            // Status indicator
            if notificationService.isAuthorized {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(CaleiColors.success)
                    Text("Permiso otorgado")
                        .font(CaleiTypography.caption)
                        .foregroundColor(CaleiColors.success)
                }
                .padding(.top, 8)
            }
        }
        .padding()
    }
    
    // MARK: - Ready Step
    
    private var readyStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(CaleiColors.success)
            
            Text("¡Todo listo!")
                .font(CaleiTypography.h2)
                .foregroundColor(CaleiColors.textPrimary)
                .multilineTextAlignment(.center)
            
            Text("Ya podés comenzar a grabar tus recorridos.\n\nRecordá que la grabación funciona en segundo plano, así que podés usar otras apps mientras trabajás.")
                .font(CaleiTypography.body)
                .foregroundColor(CaleiColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding()
    }
    
    // MARK: - Action Button
    
    private var actionButton: some View {
        Button {
            handleAction()
        } label: {
            Text(buttonTitle)
                .font(CaleiTypography.button)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(CaleiColors.accent)
                .cornerRadius(12)
        }
    }
    
    private var buttonTitle: String {
        switch currentStep {
        case 0:
            if locationService.authorizationStatus == .authorizedAlways ||
               locationService.authorizationStatus == .authorizedWhenInUse {
                return "Continuar"
            }
            return "Permitir ubicación"
        case 1:
            if notificationService.isAuthorized {
                return "Continuar"
            }
            return "Permitir notificaciones"
        case 2:
            return "Comenzar"
        default:
            return "Continuar"
        }
    }
    
    // MARK: - Actions
    
    private func handleAction() {
        switch currentStep {
        case 0:
            if locationService.authorizationStatus == .authorizedAlways ||
               locationService.authorizationStatus == .authorizedWhenInUse {
                withAnimation { currentStep = 1 }
            } else {
                locationService.requestPermission()
                // Observer para cuando cambie el estado
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 segundo
                    if locationService.authorizationStatus != .notDetermined {
                        withAnimation { currentStep = 1 }
                    }
                }
            }
            
        case 1:
            if notificationService.isAuthorized {
                withAnimation { currentStep = 2 }
            } else {
                Task {
                    _ = await notificationService.requestAuthorization()
                    await MainActor.run {
                        withAnimation { currentStep = 2 }
                    }
                }
            }
            
        case 2:
            completeOnboarding()
            
        default:
            break
        }
    }
    
    private func skipOnboarding() {
        UserDefaults.standard.set(true, forKey: "permissions_onboarding_shown")
        isPresented = false
    }
    
    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "permissions_onboarding_shown")
        isPresented = false
        onComplete()
    }
}

// MARK: - Preview

#Preview {
    PermissionsOnboardingView(isPresented: .constant(true), onComplete: {})
}
