import SwiftUI

// MARK: - Zone Sale Point Detail Sheet

struct ZoneSalePointDetailSheet: View {
    let salePoint: MarkedSalePoint
    let onSave: (UpdateSalePointRequest) -> Void
    let onClose: () -> Void
    
    @State private var selectedTab = 0
    
    // MARK: - Campos Básicos
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var hasWhatsApp: Bool = false
    @State private var notes: String = ""
    @State private var competition: String = ""
    
    // MARK: - Campos Contacto
    @State private var managerName: String = ""
    @State private var phone: String = ""
    @State private var email: String = ""
    @State private var openingTimeFrom: Date = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    @State private var openingTimeTo: Date = Calendar.current.date(from: DateComponents(hour: 18, minute: 0)) ?? Date()
    @State private var workingDays: String = ""
    
    // MARK: - Campos Exhibidor
    @State private var exhibitorType: String = ""
    @State private var supportType: String = ""
    @State private var installationNotes: String = ""
    
    private let tabTitles = ["Basico", "Contacto", "Exibidor"]
    
    init(salePoint: MarkedSalePoint, onSave: @escaping (UpdateSalePointRequest) -> Void, onClose: @escaping () -> Void) {
        self.salePoint = salePoint
        self.onSave = onSave
        self.onClose = onClose
        
        // Inicializar campos básicos
        _name = State(initialValue: salePoint.name)
        _description = State(initialValue: salePoint.description ?? "")
        _hasWhatsApp = State(initialValue: salePoint.hasWhatsApp ?? false)
        _notes = State(initialValue: salePoint.notes ?? "")
        _competition = State(initialValue: salePoint.competition ?? "")
        
        // Inicializar campos de contacto
        _managerName = State(initialValue: salePoint.managerName ?? "")
        _phone = State(initialValue: salePoint.phone ?? "")
        _email = State(initialValue: salePoint.email ?? "")
        _workingDays = State(initialValue: salePoint.workingDays ?? "")
        
        // Parsear horas si existen
        if let fromTime = salePoint.openingTimeFrom, let parsed = Self.parseTime(fromTime) {
            _openingTimeFrom = State(initialValue: parsed)
        }
        if let toTime = salePoint.openingTimeTo, let parsed = Self.parseTime(toTime) {
            _openingTimeTo = State(initialValue: parsed)
        }
        
        // Inicializar campos de exhibidor
        _exhibitorType = State(initialValue: salePoint.exhibitorType ?? "")
        _supportType = State(initialValue: salePoint.supportType ?? "")
        _installationNotes = State(initialValue: salePoint.installationNotes ?? "")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header con info del punto
            headerView
            
            // Tab selector
            tabSelector
            
            // Content
            TabView(selection: $selectedTab) {
                basicTab
                    .tag(0)
                
                contactTab
                    .tag(1)
                
                exhibitorTab
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // Botón cerrar
            closeButton
        }
        .background(CaleiColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 20)
        .padding(.vertical, 40)
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack(spacing: 12) {
            // Icono
            RoundedRectangle(cornerRadius: 10)
                .fill(CaleiColors.accent.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "storefront.fill")
                        .font(.title2)
                        .foregroundColor(CaleiColors.accent)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(salePoint.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(CaleiColors.dark)
                
                Text("Estado: \(salePoint.status ?? "no_visitado")")
                    .font(.subheadline)
                    .foregroundColor(CaleiColors.gray500)
            }
            
            Spacer()
        }
        .padding()
        .background(CaleiColors.cardBackground)
    }
    
    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(0..<3, id: \.self) { index in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = index
                    }
                } label: {
                    VStack(spacing: 8) {
                        Text(tabTitles[index])
                            .font(.subheadline)
                            .fontWeight(selectedTab == index ? .semibold : .regular)
                            .foregroundColor(selectedTab == index ? CaleiColors.accent : CaleiColors.gray500)
                        
                        Rectangle()
                            .fill(selectedTab == index ? CaleiColors.accent : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
        .background(CaleiColors.cardBackground)
    }
    
    // MARK: - Basic Tab
    
    private var basicTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Nombre del punto de venta
                FormTextField(
                    label: "Nombre del punto de venta",
                    text: $name
                )
                
                // Descripción
                FormTextEditor(
                    label: "Descripción",
                    text: $description,
                    placeholder: "Descripción del punto de venta"
                )
                
                // Envío WhatsApp
                FormToggle(
                    label: "Envío por WhatsApp",
                    isOn: $hasWhatsApp
                )
                
                // Notas sobre el estado
                FormTextEditor(
                    label: "Nota sobre el estado",
                    text: $notes,
                    placeholder: "Notas adicionales sobre este punto"
                )
            }
            .padding()
        }
        .background(CaleiColors.gray50)
    }
    
    // MARK: - Contact Tab
    
    private var contactTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Nombre del encargado
                FormTextField(
                    label: "Nombre del dueño/encargado",
                    text: $managerName,
                    placeholder: "Nombre completo"
                )
                
                // Teléfono
                FormTextField(
                    label: "Teléfono del local",
                    text: $phone,
                    placeholder: "+54 9 351 123-4567",
                    keyboardType: .phonePad
                )
                
                // Email
                FormTextField(
                    label: "Email del negocio",
                    text: $email,
                    placeholder: "contacto@negocio.com",
                    keyboardType: .emailAddress
                )
                
                // Horario de atención
                VStack(alignment: .leading, spacing: 12) {
                    Text("Horario de atención")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(CaleiColors.dark)
                    
                    HStack(spacing: 12) {
                        FormTimePicker(
                            label: "Abre",
                            time: $openingTimeFrom
                        )
                        
                        FormTimePicker(
                            label: "Cierra",
                            time: $openingTimeTo
                        )
                    }
                }
                
                // Días de atención
                FormTextField(
                    label: "Días de atención",
                    text: $workingDays,
                    placeholder: "Ej: Lunes a Viernes"
                )
            }
            .padding()
        }
        .background(CaleiColors.gray50)
    }
    
    // MARK: - Exhibitor Tab
    
    private var exhibitorTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Tipo de exhibidor
                FormTextField(
                    label: "Tipo de exhibidor",
                    text: $exhibitorType,
                    placeholder: "Ej: Góndola, Refrigerador, etc."
                )
                
                // Tipo de soporte
                FormTextField(
                    label: "Tipo de soporte",
                    text: $supportType,
                    placeholder: "Ej: Piso, Pared, Mostrador"
                )
                
                // Notas de instalación
                FormTextEditor(
                    label: "Notas de instalación",
                    text: $installationNotes,
                    placeholder: "Detalles sobre la instalación del exhibidor"
                )
            }
            .padding()
        }
        .background(CaleiColors.gray50)
    }
    
    // MARK: - Close Button
    
    private var closeButton: some View {
        Button {
            saveAndClose()
        } label: {
            Text("Cerrar")
                .font(.headline)
                .foregroundColor(CaleiColors.accent)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(CaleiColors.accent, lineWidth: 1.5)
                )
        }
        .padding()
    }
    
    // MARK: - Actions
    
    private func saveAndClose() {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        let request = UpdateSalePointRequest(
            name: name.isEmpty ? nil : name,
            description: description.isEmpty ? nil : description,
            hasWhatsApp: hasWhatsApp,
            notes: notes.isEmpty ? nil : notes,
            competition: competition.isEmpty ? nil : competition,
            status: nil,
            managerName: managerName.isEmpty ? nil : managerName,
            phone: phone.isEmpty ? nil : phone,
            email: email.isEmpty ? nil : email,
            openingTimeFrom: timeFormatter.string(from: openingTimeFrom),
            openingTimeTo: timeFormatter.string(from: openingTimeTo),
            workingDays: workingDays.isEmpty ? nil : workingDays,
            exhibitorType: exhibitorType.isEmpty ? nil : exhibitorType,
            supportType: supportType.isEmpty ? nil : supportType,
            installationNotes: installationNotes.isEmpty ? nil : installationNotes,
            address: nil,
            openingHours: nil
        )
        
        onSave(request)
        onClose()
    }
    
    // MARK: - Helper
    
    private static func parseTime(_ timeString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.date(from: timeString)
    }
}

// MARK: - Form Components (Colores legibles)

private struct FormTextField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(CaleiColors.dark)
            
            TextField(placeholder.isEmpty ? label : placeholder, text: $text)
                .keyboardType(keyboardType)
                .padding()
                .background(Color.white)
                .foregroundColor(CaleiColors.dark)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(CaleiColors.gray300, lineWidth: 1)
                )
        }
    }
}

private struct FormTextEditor: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(CaleiColors.dark)
            
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundColor(CaleiColors.gray400)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }
                
                TextEditor(text: $text)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(minHeight: 80)
                    .foregroundColor(CaleiColors.dark)
            }
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(CaleiColors.gray300, lineWidth: 1)
            )
        }
    }
}

private struct FormToggle: View {
    let label: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(CaleiColors.dark)
                
                Text(isOn ? "Sí" : "No")
                    .font(.caption)
                    .foregroundColor(CaleiColors.gray500)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .tint(CaleiColors.accent)
                .labelsHidden()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(CaleiColors.gray300, lineWidth: 1)
        )
    }
}

private struct FormTimePicker: View {
    let label: String
    @Binding var time: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(CaleiColors.gray500)
            
            HStack {
                DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .tint(CaleiColors.accent)
                
                Image(systemName: "clock")
                    .foregroundColor(CaleiColors.gray400)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(CaleiColors.gray300, lineWidth: 1)
            )
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        CaleiColors.background.ignoresSafeArea()
        
        ZoneSalePointDetailSheet(
            salePoint: MarkedSalePoint(
                id: 1,
                name: "17 1",
                latitude: -31.42,
                longitude: -64.18,
                description: "Punto marcado automáticamente",
                status: "no_visitado"
            ),
            onSave: { _ in },
            onClose: { }
        )
    }
}
