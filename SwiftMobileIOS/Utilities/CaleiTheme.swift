import SwiftUI

// MARK: - Calei Colors
/// Sistema de colores Calei optimizado para iOS 17+
/// Soporta modo claro y oscuro siguiendo las guías de Apple Human Interface
///
/// DECISIONES DE DISEÑO:
/// - Evitamos negro puro (#000) y blanco puro (#FFF) para reducir fatiga visual
/// - En Dark Mode las superficies elevadas son más claras (elevation = brightness)
/// - Colores semánticos ajustados para mantener contraste WCAG AA
/// - Acento teal mantiene identidad de marca con ajuste de saturación en dark
struct CaleiColors {
    
    // ═══════════════════════════════════════════════════════════════════════════
    // MARK: - Colores de Marca (Estáticos)
    // ═══════════════════════════════════════════════════════════════════════════
    
    /// Color principal oscuro de marca - #1e2530
    static let brandDark = Color(red: 0.118, green: 0.145, blue: 0.188)
    
    /// Color oscuro secundario de marca - #0f172a
    static let brandDark2 = Color(red: 0.059, green: 0.090, blue: 0.165)
    
    /// Color de acento principal (teal) - #4fd1c5
    static let brandAccent = Color(red: 0.310, green: 0.820, blue: 0.773)
    
    // ═══════════════════════════════════════════════════════════════════════════
    // MARK: - Colores Adaptativos (Light/Dark Mode)
    // ═══════════════════════════════════════════════════════════════════════════
    
    // MARK: Backgrounds
    
    /// Fondo principal de la app
    /// Light: Off-white cálido (#FAFBFC) - Dark: Gris azulado profundo (#121620)
    static var background: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.071, green: 0.086, blue: 0.125, alpha: 1) // #121620
                : UIColor(red: 0.980, green: 0.984, blue: 0.988, alpha: 1) // #FAFBFC
        })
    }
    
    /// Fondo secundario (secciones agrupadas, listas)
    /// Light: Gris muy claro (#F1F5F9) - Dark: Gris elevado (#1A1F2E)
    static var backgroundSecondary: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.102, green: 0.122, blue: 0.180, alpha: 1) // #1A1F2E
                : UIColor(red: 0.945, green: 0.961, blue: 0.976, alpha: 1) // #F1F5F9
        })
    }
    
    /// Fondo terciario (elementos flotantes, popovers)
    /// Light: Blanco suave (#FFFFFF) - Dark: Superficie elevada (#242B3D)
    static var backgroundTertiary: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.141, green: 0.169, blue: 0.239, alpha: 1) // #242B3D
                : UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1)
        })
    }
    
    /// Fondo de cards y contenedores elevados
    /// En Dark Mode: más claro que el fondo para crear jerarquía visual
    static var cardBackground: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.129, green: 0.153, blue: 0.212, alpha: 1) // #212736
                : UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1)
        })
    }
    
    /// Alias para cardBackground - Superficie de elementos UI
    static var surface: Color { cardBackground }
    
    /// Fondo de inputs y campos de texto
    static var inputBackground: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.102, green: 0.122, blue: 0.180, alpha: 1) // #1A1F2E
                : UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1)
        })
    }
    
    // MARK: Text Colors
    
    /// Texto primario (títulos, contenido principal)
    /// Light: Gris muy oscuro (#1A1F2E) - Dark: Off-white (#F0F2F5)
    static var textPrimary: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.941, green: 0.949, blue: 0.961, alpha: 1) // #F0F2F5
                : UIColor(red: 0.102, green: 0.122, blue: 0.180, alpha: 1) // #1A1F2E
        })
    }
    
    /// Texto secundario (descripciones, subtítulos)
    static var textSecondary: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.627, green: 0.678, blue: 0.761, alpha: 1) // #A0ADC2
                : UIColor(red: 0.357, green: 0.412, blue: 0.506, alpha: 1) // #5B6981
        })
    }
    
    /// Texto terciario (placeholders, hints)
    static var textTertiary: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.459, green: 0.514, blue: 0.608, alpha: 1) // #75839B
                : UIColor(red: 0.518, green: 0.576, blue: 0.675, alpha: 1) // #8493AC
        })
    }
    
    /// Texto invertido (sobre fondos de acento)
    static var textInverse: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.071, green: 0.086, blue: 0.125, alpha: 1) // #121620
                : UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1)
        })
    }
    
    // MARK: Accent Colors
    
    /// Color de acento principal - adaptado para contraste
    /// Light: Teal original - Dark: Teal ligeramente más brillante
    static var accent: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.380, green: 0.875, blue: 0.820, alpha: 1) // #61DFD1 - más brillante
                : UIColor(red: 0.310, green: 0.820, blue: 0.773, alpha: 1) // #4FD1C5 - original
        })
    }
    
    /// Acento hover/pressed
    static var accentHover: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.310, green: 0.820, blue: 0.773, alpha: 1) // Más oscuro al presionar
                : UIColor(red: 0.220, green: 0.698, blue: 0.675, alpha: 1) // #38B2AC
        })
    }
    
    /// Fondo suave de acento (badges, chips, highlights)
    static var accentSoft: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.310, green: 0.820, blue: 0.773, alpha: 0.15)
                : UIColor(red: 0.310, green: 0.820, blue: 0.773, alpha: 0.10)
        })
    }
    
    // MARK: Semantic Colors
    
    /// Success - Verde adaptivo
    static var success: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.204, green: 0.780, blue: 0.565, alpha: 1) // #34C790 - más brillante
                : UIColor(red: 0.063, green: 0.725, blue: 0.506, alpha: 1) // #10B981
        })
    }
    
    /// Warning - Amarillo/Naranja adaptivo
    static var warning: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.984, green: 0.690, blue: 0.220, alpha: 1) // #FBB038 - más brillante
                : UIColor(red: 0.961, green: 0.620, blue: 0.043, alpha: 1) // #F59E0B
        })
    }
    
    /// Error - Rojo adaptivo
    static var error: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.973, green: 0.396, blue: 0.396, alpha: 1) // #F86565 - más brillante
                : UIColor(red: 0.937, green: 0.267, blue: 0.267, alpha: 1) // #EF4444
        })
    }
    
    /// Info - Azul adaptivo
    static var info: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.376, green: 0.584, blue: 0.984, alpha: 1) // #6095FB - más brillante
                : UIColor(red: 0.231, green: 0.510, blue: 0.965, alpha: 1) // #3B82F6
        })
    }
    
    // MARK: Borders & Separators
    
    /// Borde principal (cards, inputs)
    static var border: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.200, green: 0.235, blue: 0.318, alpha: 1) // #333C51
                : UIColor(red: 0.886, green: 0.910, blue: 0.941, alpha: 1) // #E2E8F0
        })
    }
    
    /// Separador (dividers, líneas de lista)
    static var separator: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.169, green: 0.200, blue: 0.275, alpha: 1) // #2B3346
                : UIColor(red: 0.918, green: 0.937, blue: 0.957, alpha: 1) // #EAEFF4
        })
    }
    
    /// Borde de focus (inputs activos)
    static var borderFocus: Color { accent }
    
    // MARK: Interactive States
    
    /// Estado deshabilitado
    static var disabled: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.357, green: 0.400, blue: 0.490, alpha: 1) // #5B667D
                : UIColor(red: 0.796, green: 0.835, blue: 0.882, alpha: 1) // #CBD5E1
        })
    }
    
    /// Overlay para modals y sheets
    static var overlay: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.70)
                : UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.50)
        })
    }
    
    // ═══════════════════════════════════════════════════════════════════════════
    // MARK: - Escala de Grises (Estáticos - Usar con precaución)
    // ═══════════════════════════════════════════════════════════════════════════
    
    /// Usar los colores adaptativos siempre que sea posible
    /// Estos grises estáticos son para casos especiales
    
    static let gray50 = Color(red: 0.973, green: 0.980, blue: 0.988)
    static let gray100 = Color(red: 0.945, green: 0.961, blue: 0.976)
    static let gray200 = Color(red: 0.886, green: 0.910, blue: 0.941)
    static let gray300 = Color(red: 0.796, green: 0.835, blue: 0.882)
    static let gray400 = Color(red: 0.580, green: 0.639, blue: 0.722)
    static let gray500 = Color(red: 0.392, green: 0.455, blue: 0.545)
    static let gray600 = Color(red: 0.278, green: 0.333, blue: 0.412)
    static let gray700 = Color(red: 0.200, green: 0.255, blue: 0.333)
    static let gray800 = Color(red: 0.118, green: 0.161, blue: 0.231)
    static let gray900 = Color(red: 0.059, green: 0.090, blue: 0.165)
    
    // Aliases para compatibilidad
    static var dark: Color { brandDark }
    static var dark2: Color { brandDark2 }
    
    // ═══════════════════════════════════════════════════════════════════════════
    // MARK: - Gradientes
    // ═══════════════════════════════════════════════════════════════════════════
    
    /// Gradiente hero para headers y splash
    static var heroGradient: LinearGradient {
        LinearGradient(
            colors: [brandDark, brandDark2],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Gradiente de acento para botones destacados
    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [brandAccent, accentHover],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Gradiente sutil para cards en dark mode
    static func cardGradient(for colorScheme: ColorScheme) -> LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
                colors: [
                    Color(red: 0.141, green: 0.169, blue: 0.239), // #242B3D
                    Color(red: 0.129, green: 0.153, blue: 0.212)  // #212736
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        return LinearGradient(colors: [.white, .white], startPoint: .top, endPoint: .bottom)
    }
}

// MARK: - Calei Typography
/// Tipografía oficial Saira según el manual de marca
struct CaleiTypography {
    
    // MARK: - Fuentes Custom (Saira)
    
    /// Intenta cargar Saira, si no está disponible usa SF Pro
    static func saira(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let fontName: String
        switch weight {
        case .bold:
            fontName = "Saira-Bold"
        case .semibold:
            fontName = "Saira-SemiBold"
        case .medium:
            fontName = "Saira-Medium"
        default:
            fontName = "Saira-Regular"
        }
        
        // Intenta cargar la fuente custom, si falla usa el sistema
        if let _ = UIFont(name: fontName, size: size) {
            return .custom(fontName, size: size)
        }
        return .system(size: size, weight: weight)
    }
    
    // MARK: - Estilos Mobile
    
    /// H1 - 28px Bold - Títulos principales
    static var h1: Font { saira(28, weight: .bold) }
    
    /// H2 - 24px Bold - Subtítulos
    static var h2: Font { saira(24, weight: .bold) }
    
    /// H3 - 20px SemiBold - Secciones
    static var h3: Font { saira(20, weight: .semibold) }
    
    /// H4 - 18px SemiBold - Sub-secciones
    static var h4: Font { saira(18, weight: .semibold) }
    
    /// Body Large - 18px Regular - Texto destacado
    static var bodyLarge: Font { saira(18, weight: .regular) }
    
    /// Body - 16px Regular - Texto normal
    static var body: Font { saira(16, weight: .regular) }
    
    /// Body Small - 14px Regular - Texto secundario
    static var bodySmall: Font { saira(14, weight: .regular) }
    
    /// Caption - 12px Medium - Etiquetas
    static var caption: Font { saira(12, weight: .medium) }
    
    /// Overline - 12px SemiBold - Categorías
    static var overline: Font { saira(12, weight: .semibold) }
    
    /// Button - 16px SemiBold - Botones
    static var button: Font { saira(16, weight: .semibold) }
    
    /// Button Small - 14px SemiBold - Botones pequeños
    static var buttonSmall: Font { saira(14, weight: .semibold) }
}

// MARK: - View Extensions

extension View {
    /// Aplica el estilo de botón primario de Calei
    /// Usa textInverse para garantizar contraste en ambos modos
    func caleiPrimaryButton() -> some View {
        self
            .font(CaleiTypography.button)
            .foregroundColor(CaleiColors.textInverse)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(CaleiColors.accent)
            .cornerRadius(12)
    }
    
    /// Aplica el estilo de botón secundario de Calei
    func caleiSecondaryButton() -> some View {
        self
            .font(CaleiTypography.button)
            .foregroundColor(CaleiColors.accent)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(CaleiColors.accentSoft)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(CaleiColors.accent.opacity(0.3), lineWidth: 1)
            )
    }
    
    /// Aplica el estilo de botón ghost (solo texto)
    func caleiGhostButton() -> some View {
        self
            .font(CaleiTypography.button)
            .foregroundColor(CaleiColors.accent)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
    }
    
    /// Aplica el estilo de botón destructivo
    func caleiDestructiveButton() -> some View {
        self
            .font(CaleiTypography.button)
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(CaleiColors.error)
            .cornerRadius(12)
    }
    
    /// Aplica el estilo de card de Calei (adaptivo a modo oscuro)
    /// En dark mode: sombra más sutil, borde visible
    func caleiCard() -> some View {
        self
            .padding(16)
            .background(CaleiColors.cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(CaleiColors.border.opacity(0.5), lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
    }
    
    /// Aplica el estilo de card elevada (más prominente)
    func caleiCardElevated() -> some View {
        self
            .padding(16)
            .background(CaleiColors.backgroundTertiary)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.15), radius: 16, x: 0, y: 8)
    }
    
    /// Aplica el estilo de input field de Calei (adaptivo a modo oscuro)
    func caleiTextField() -> some View {
        self
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(CaleiColors.inputBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(CaleiColors.border, lineWidth: 1)
            )
    }
    
    /// Aplica el estilo de chip/badge
    func caleiChip() -> some View {
        self
            .font(CaleiTypography.caption)
            .foregroundColor(CaleiColors.accent)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(CaleiColors.accentSoft)
            .cornerRadius(8)
    }
    
    /// Aplica el estilo de status badge (success, warning, error, info)
    func caleiStatusBadge(status: CaleiStatus) -> some View {
        self
            .font(CaleiTypography.caption)
            .foregroundColor(status.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(status.color.opacity(0.12))
            .cornerRadius(6)
    }
}

// MARK: - Status Enum

enum CaleiStatus {
    case success, warning, error, info
    
    var color: Color {
        switch self {
        case .success: return CaleiColors.success
        case .warning: return CaleiColors.warning
        case .error: return CaleiColors.error
        case .info: return CaleiColors.info
        }
    }
}

// MARK: - Spacing System (4-point grid)

struct CaleiSpacing {
    static let space1: CGFloat = 4
    static let space2: CGFloat = 8
    static let space3: CGFloat = 12
    static let space4: CGFloat = 16
    static let space5: CGFloat = 20
    static let space6: CGFloat = 24
    static let space8: CGFloat = 32
    static let space10: CGFloat = 40
    static let space12: CGFloat = 48
    static let space16: CGFloat = 64
}

// MARK: - Animation Presets

struct CaleiAnimations {
    /// Animación suave para transiciones
    static let smooth = Animation.easeInOut(duration: 0.3)
    
    /// Animación spring para elementos interactivos
    static let spring = Animation.spring(response: 0.4, dampingFraction: 0.75)
    
    /// Animación rápida para feedback
    static let quick = Animation.easeOut(duration: 0.15)
    
    /// Animación para elementos que aparecen
    static let appear = Animation.easeOut(duration: 0.4)
}

// MARK: - Environment Helpers

extension View {
    /// Aplica el fondo principal de la app respetando el modo actual
    func caleiBackground() -> some View {
        self.background(CaleiColors.background.ignoresSafeArea())
    }
    
    /// Aplica el fondo secundario para secciones agrupadas
    func caleiBackgroundSecondary() -> some View {
        self.background(CaleiColors.backgroundSecondary.ignoresSafeArea())
    }
}

// MARK: - Preview Helpers

#if DEBUG
/// Preview wrapper que muestra la vista en ambos modos (claro y oscuro)
struct CaleiPreviewContainer<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        HStack(spacing: 0) {
            content
                .environment(\.colorScheme, .light)
            
            content
                .environment(\.colorScheme, .dark)
        }
    }
}

/// Vista de preview para verificar todos los colores del sistema
struct CaleiColorPalettePreview: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Group {
                    colorRow("Background", CaleiColors.background)
                    colorRow("Background Secondary", CaleiColors.backgroundSecondary)
                    colorRow("Background Tertiary", CaleiColors.backgroundTertiary)
                    colorRow("Card Background", CaleiColors.cardBackground)
                    colorRow("Input Background", CaleiColors.inputBackground)
                }
                
                Divider()
                
                Group {
                    colorRow("Text Primary", CaleiColors.textPrimary)
                    colorRow("Text Secondary", CaleiColors.textSecondary)
                    colorRow("Text Tertiary", CaleiColors.textTertiary)
                }
                
                Divider()
                
                Group {
                    colorRow("Accent", CaleiColors.accent)
                    colorRow("Success", CaleiColors.success)
                    colorRow("Warning", CaleiColors.warning)
                    colorRow("Error", CaleiColors.error)
                    colorRow("Info", CaleiColors.info)
                }
                
                Divider()
                
                Group {
                    colorRow("Border", CaleiColors.border)
                    colorRow("Separator", CaleiColors.separator)
                    colorRow("Disabled", CaleiColors.disabled)
                }
            }
            .padding()
        }
        .background(CaleiColors.background)
    }
    
    private func colorRow(_ name: String, _ color: Color) -> some View {
        HStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(width: 44, height: 44)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(CaleiColors.border, lineWidth: 1)
                )
            
            Text(name)
                .font(CaleiTypography.body)
                .foregroundColor(CaleiColors.textPrimary)
            
            Spacer()
        }
    }
}

#Preview("Color Palette - Light") {
    CaleiColorPalettePreview()
        .environment(\.colorScheme, .light)
}

#Preview("Color Palette - Dark") {
    CaleiColorPalettePreview()
        .environment(\.colorScheme, .dark)
}

#Preview("Buttons") {
    VStack(spacing: 16) {
        Text("Primary")
            .caleiPrimaryButton()
        
        Text("Secondary")
            .caleiSecondaryButton()
        
        Text("Ghost")
            .caleiGhostButton()
        
        Text("Destructive")
            .caleiDestructiveButton()
    }
    .padding()
    .caleiBackground()
}
#endif
