import SwiftUI

struct RegisterView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = RegisterViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var isPasswordVisible = false
    @State private var isConfirmPasswordVisible = false

    var body: some View {
        let caleiDark = Color(red: 0.118, green: 0.145, blue: 0.188)
        let caleiDark2 = Color(red: 0.059, green: 0.090, blue: 0.165)
        let caleiAccent = Color(red: 0.310, green: 0.820, blue: 0.773)
        let gray400 = Color(red: 0.580, green: 0.639, blue: 0.722)
        let gray200 = Color(red: 0.886, green: 0.910, blue: 0.941)

        ZStack {
            LinearGradient(
                colors: [caleiDark, caleiDark2],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer(minLength: 24)

                VStack(alignment: .leading, spacing: 6) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.left")
                            Text("Volver a iniciar sesión")
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                    }

                    Text("Crear cuenta")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)

                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Registro")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(caleiDark)

                        VStack(spacing: 12) {
                            HStack(spacing: 10) {
                                Image(systemName: "person")
                                    .foregroundColor(gray400)
                                TextField("Usuario (mínimo 3 caracteres)", text: $viewModel.username)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled(true)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(gray200, lineWidth: 1)
                            )

                            HStack(spacing: 10) {
                                Image(systemName: "envelope")
                                    .foregroundColor(gray400)
                                TextField("Correo", text: $viewModel.email)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled(true)
                                    .keyboardType(.emailAddress)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(gray200, lineWidth: 1)
                            )

                            HStack(spacing: 10) {
                                Image(systemName: "lock")
                                    .foregroundColor(gray400)
                                if isPasswordVisible {
                                    TextField("Contraseña", text: $viewModel.password)
                                } else {
                                    SecureField("Contraseña", text: $viewModel.password)
                                }
                                Button {
                                    isPasswordVisible.toggle()
                                } label: {
                                    Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                        .foregroundColor(gray400)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(gray200, lineWidth: 1)
                            )

                            HStack(spacing: 10) {
                                Image(systemName: "lock")
                                    .foregroundColor(gray400)
                                if isConfirmPasswordVisible {
                                    TextField("Confirmar contraseña", text: $viewModel.confirmPassword)
                                } else {
                                    SecureField("Confirmar contraseña", text: $viewModel.confirmPassword)
                                }
                                Button {
                                    isConfirmPasswordVisible.toggle()
                                } label: {
                                    Image(systemName: isConfirmPasswordVisible ? "eye.slash" : "eye")
                                        .foregroundColor(gray400)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(gray200, lineWidth: 1)
                            )
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Requisitos de contraseña:")
                                .font(.caption)
                                .foregroundColor(gray400)
                            Text("• Mínimo 8 caracteres, una mayúscula y un número")
                                .font(.caption)
                                .foregroundColor(gray400)
                        }
                    }

                    HStack {
                        Button {
                            viewModel.termsAccepted.toggle()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: viewModel.termsAccepted ? "checkmark.square.fill" : "square")
                                    .foregroundColor(caleiAccent)
                                Text("Acepto los términos y condiciones")
                                    .foregroundColor(gray400)
                            }
                        }
                        .buttonStyle(.plain)

                        Spacer()
                    }
                    .font(.footnote)

                    if case let .error(message) = viewModel.state {
                        Text(message)
                            .font(.footnote)
                            .foregroundColor(.red)
                    }

                    Button {
                        Task {
                            if let user = await viewModel.register() {
                                appState.currentUser = user
                            }
                        }
                    } label: {
                        Text(viewModel.state == .loading ? "Creando..." : "Registrarme")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(caleiDark)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(caleiAccent)
                            .cornerRadius(12)
                    }
                    .disabled(!viewModel.isFormValid || viewModel.state == .loading)

                    HStack(spacing: 4) {
                        Text("¿Ya tenés cuenta?")
                            .foregroundColor(gray400)
                        Button("Iniciar sesión") {
                            dismiss()
                        }
                        .foregroundColor(caleiAccent)
                    }
                    .font(.footnote)
                }
                .padding(24)
                .background(Color.white)
                .cornerRadius(24)
                .padding(.horizontal, 20)

                Spacer(minLength: 24)
            }
        }
        .navigationBarHidden(true)
    }
}
