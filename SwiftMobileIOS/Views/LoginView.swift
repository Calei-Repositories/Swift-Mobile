import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = LoginViewModel()
    @State private var isPasswordVisible = false

    var body: some View {
        let caleiDark = Color(red: 0.118, green: 0.145, blue: 0.188)
        let caleiDark2 = Color(red: 0.059, green: 0.090, blue: 0.165)
        let caleiAccent = Color(red: 0.310, green: 0.820, blue: 0.773)
        let gray400 = Color(red: 0.580, green: 0.639, blue: 0.722)
        let gray200 = Color(red: 0.886, green: 0.910, blue: 0.941)

        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                LinearGradient(
                    colors: [caleiDark, caleiDark2],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 24) {
                Spacer(minLength: 32)

                VStack(alignment: .leading, spacing: 6) {
                    Text("¡Hola!")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    Text("Control total de tu distribuidora")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)

                VStack(spacing: 18) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Iniciar sesión")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(caleiDark)

                        VStack(spacing: 12) {
                            HStack(spacing: 10) {
                                Image(systemName: "person")
                                    .foregroundColor(gray400)
                                TextField("Usuario", text: $viewModel.username)
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
                        }
                    }

                    HStack {
                        Button("¿Olvidaste tu contraseña?") {}
                            .font(.footnote)
                            .foregroundColor(caleiAccent)
                    }
                    .font(.footnote)

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundColor(.red)
                    }

                    Button {
                        Task {
                            if let user = await viewModel.login() {
                                appState.currentUser = user
                            }
                        }
                    } label: {
                        Text(viewModel.isLoading ? "Ingresando..." : "Ingresar")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(caleiDark)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(caleiAccent)
                            .cornerRadius(12)
                    }
                    .disabled(viewModel.isLoading)

                    HStack(spacing: 4) {
                        Text("¿No tenés cuenta?")
                            .foregroundColor(gray400)
                        NavigationLink("Registrate", destination: RegisterView())
                            .foregroundColor(caleiAccent)
                    }
                    .font(.footnote)
                }
                .padding(24)
                .background(Color.white)
                .cornerRadius(24)
                .padding(.horizontal, 20)

                Spacer(minLength: 4)
            }

                VStack(alignment: .trailing, spacing: 6) {
                    Text("Hecho por")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.85))

                    HStack {
                        Image("LogotipoDark")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 24)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.white)
                    .cornerRadius(10)
                }
                .padding(.trailing, 16)
                .padding(.bottom, 16)
            }
        }
    }
}
