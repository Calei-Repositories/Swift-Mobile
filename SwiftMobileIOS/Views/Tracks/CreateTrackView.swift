import SwiftUI

struct CreateTrackView: View {
    @StateObject private var viewModel = CreateTrackViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var animateButton = false
    
    var onCreated: ((Track) -> Void)?
    
    var body: some View {
        NavigationView {
            ZStack {
                // Fondo con gradiente sutil
                LinearGradient(
                    colors: [CaleiColors.gray50, Color.white],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: CaleiSpacing.space6) {
                        // Ilustración
                        headerIllustration
                        
                        // Formulario
                        formSection
                        
                        // Error
                        if case let .error(message) = viewModel.state {
                            errorBanner(message: message)
                        }
                        
                        // Botón crear
                        createButton
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, CaleiSpacing.space6)
                    .padding(.top, CaleiSpacing.space4)
                }
            }
            .navigationTitle("Nuevo recorrido")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(CaleiColors.gray500)
                            .frame(width: 32, height: 32)
                            .background(CaleiColors.gray100)
                            .clipShape(Circle())
                    }
                }
            }
        }
    }
    
    // MARK: - Header Illustration
    
    private var headerIllustration: some View {
        ZStack {
            // Fondo decorativo
            Circle()
                .fill(CaleiColors.accentSoft)
                .frame(width: 140, height: 140)
                .offset(x: -30, y: 20)
            
            Circle()
                .fill(CaleiColors.accent.opacity(0.15))
                .frame(width: 100, height: 100)
                .offset(x: 40, y: -10)
            
            // Ícono principal
            VStack(spacing: CaleiSpacing.space3) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [CaleiColors.accent, CaleiColors.accentHover],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .shadow(color: CaleiColors.accent.opacity(0.4), radius: 20, x: 0, y: 10)
                    
                    Image(systemName: "map.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.white)
                }
                
                Text("Crear recorrido")
                    .font(CaleiTypography.h2)
                    .foregroundColor(CaleiColors.dark)
                
                Text("Definí el nombre de tu recorrido para empezar a grabar tu ruta")
                    .font(CaleiTypography.bodySmall)
                    .foregroundColor(CaleiColors.gray500)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
        }
        .frame(height: 220)
    }
    
    // MARK: - Form Section
    
    private var formSection: some View {
        VStack(spacing: CaleiSpacing.space5) {
            // Campo nombre
            VStack(alignment: .leading, spacing: CaleiSpacing.space2) {
                HStack {
                    Text("Nombre del recorrido")
                        .font(CaleiTypography.caption)
                        .foregroundColor(CaleiColors.gray600)
                    
                    Text("*")
                        .foregroundColor(CaleiColors.error)
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "pencil.line")
                        .foregroundColor(CaleiColors.gray400)
                    
                    TextField("Ej: Zona Centro - Lunes", text: $viewModel.name)
                        .font(CaleiTypography.body)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            viewModel.name.isEmpty ? CaleiColors.gray200 : CaleiColors.accent,
                            lineWidth: 1.5
                        )
                )
                .animation(CaleiAnimations.quick, value: viewModel.name.isEmpty)
            }
            
            // Campo descripción
            VStack(alignment: .leading, spacing: CaleiSpacing.space2) {
                Text("Descripción (opcional)")
                    .font(CaleiTypography.caption)
                    .foregroundColor(CaleiColors.gray600)
                
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "text.alignleft")
                        .foregroundColor(CaleiColors.gray400)
                        .padding(.top, 4)
                    
                    TextField("Detalles del recorrido", text: $viewModel.description, axis: .vertical)
                        .font(CaleiTypography.body)
                        .lineLimit(3...6)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(CaleiColors.gray200, lineWidth: 1)
                )
            }
        }
        .caleiCard()
    }
    
    // MARK: - Error Banner
    
    private func errorBanner(message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(CaleiColors.error)
            
            Text(message)
                .font(CaleiTypography.bodySmall)
                .foregroundColor(CaleiColors.error)
            
            Spacer()
        }
        .padding(16)
        .background(CaleiColors.error.opacity(0.1))
        .cornerRadius(12)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    // MARK: - Create Button
    
    private var createButton: some View {
        Button {
            Task {
                if let track = await viewModel.createTrack() {
                    // Haptic feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    
                    onCreated?(track)
                }
            }
        } label: {
            HStack(spacing: 10) {
                if viewModel.state == .creating {
                    ProgressView()
                        .tint(CaleiColors.dark)
                } else {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                    Text("Crear recorrido")
                }
            }
            .font(CaleiTypography.button)
            .foregroundColor(CaleiColors.dark)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Group {
                    if viewModel.isFormValid {
                        CaleiColors.accentGradient
                    } else {
                        LinearGradient(
                            colors: [CaleiColors.gray300, CaleiColors.gray300],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    }
                }
            )
            .cornerRadius(14)
            .shadow(
                color: viewModel.isFormValid ? CaleiColors.accent.opacity(0.4) : Color.clear,
                radius: 12,
                x: 0,
                y: 6
            )
            .scaleEffect(animateButton ? 1.02 : 1.0)
        }
        .disabled(!viewModel.isFormValid || viewModel.state == .creating)
        .animation(CaleiAnimations.spring, value: viewModel.isFormValid)
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                animateButton = true
            }
        }
    }
}

#Preview {
    CreateTrackView()
}
