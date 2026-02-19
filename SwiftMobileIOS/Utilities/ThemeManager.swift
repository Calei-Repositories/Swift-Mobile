import SwiftUI

// MARK: - Theme Preference
enum ThemePreference: String, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var displayName: String {
        switch self {
        case .system: return "Automático"
        case .light: return "Claro"
        case .dark: return "Oscuro"
        }
    }
    
    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - Theme Manager
/// Gestiona las preferencias de tema de la app
/// Soporta modo claro, oscuro y automático según configuración del sistema
@MainActor
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    private let userDefaultsKey = "app_theme_preference"
    
    @Published var preference: ThemePreference {
        didSet {
            UserDefaults.standard.set(preference.rawValue, forKey: userDefaultsKey)
            applyTheme()
        }
    }
    
    @Published private(set) var currentColorScheme: ColorScheme?
    
    private init() {
        if let savedValue = UserDefaults.standard.string(forKey: userDefaultsKey),
           let pref = ThemePreference(rawValue: savedValue) {
            self.preference = pref
        } else {
            self.preference = .system
        }
        self.currentColorScheme = preference.colorScheme
    }
    
    /// Aplica el tema a toda la app
    private func applyTheme() {
        currentColorScheme = preference.colorScheme
        
        // Actualizar UIKit windows para compatibilidad
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            for window in windowScene.windows {
                switch preference {
                case .system:
                    window.overrideUserInterfaceStyle = .unspecified
                case .light:
                    window.overrideUserInterfaceStyle = .light
                case .dark:
                    window.overrideUserInterfaceStyle = .dark
                }
            }
        }
    }
    
    /// Indica si el tema actual es oscuro
    var isDarkMode: Bool {
        switch preference {
        case .system:
            return UITraitCollection.current.userInterfaceStyle == .dark
        case .light:
            return false
        case .dark:
            return true
        }
    }
    
    /// Cicla al siguiente tema (para un botón de toggle)
    func cycleTheme() {
        switch preference {
        case .system: preference = .light
        case .light: preference = .dark
        case .dark: preference = .system
        }
    }
}

// MARK: - Theme Colors (desde Assets.xcassets)
/// Colores adaptativos definidos en Assets.xcassets
/// Cambian automáticamente según modo claro/oscuro
struct ThemeColors {
    // MARK: - Backgrounds
    static let backgroundPrimary = Color("BackgroundPrimary")
    static let backgroundSecondary = Color("BackgroundSecondary")
    static let cardBackground = Color("CardBackground")
    
    // MARK: - Text
    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")
    static let textTertiary = Color("TextTertiary")
    
    // MARK: - Borders
    static let border = Color("Border")
    
    // MARK: - Accent
    static let accent = Color("Accent")
    
    // MARK: - Semantic Colors
    static let success = Color("Success")
    static let error = Color("Error")
    static let warning = Color("Warning")
    static let info = Color("Info")
    
    // MARK: - Polylines (para el mapa)
    static let polylineCurrent = Color("PolylineCurrent")     // Azul - grabación actual
    static let polylinePrevious = Color("PolylinePrevious")   // Morado - grabaciones previas
}

// MARK: - View Extension para aplicar tema
extension View {
    /// Aplica el color scheme según la preferencia del ThemeManager
    func withThemeManager(_ themeManager: ThemeManager) -> some View {
        self.preferredColorScheme(themeManager.currentColorScheme)
    }
}
