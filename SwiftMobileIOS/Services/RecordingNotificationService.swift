import Foundation
import UserNotifications
import UIKit

/// Servicio para manejar notificaciones de grabación en background
final class RecordingNotificationService: NSObject, ObservableObject {
    static let shared = RecordingNotificationService()
    
    // MARK: - Constants
    
    private let recordingCategoryId = "RECORDING_CATEGORY"
    private let recordingNotificationId = "recording_active_notification"
    private let markPointActionId = "MARK_POINT_ACTION"
    private let pauseActionId = "PAUSE_ACTION"
    private let resumeActionId = "RESUME_ACTION"
    
    // MARK: - Published Properties
    
    @Published private(set) var isAuthorized = false
    
    // MARK: - Callbacks
    
    var onMarkPointRequested: (() -> Void)?
    var onPauseRequested: (() -> Void)?
    var onResumeRequested: (() -> Void)?
    
    // MARK: - Private Properties
    
    private var isRecordingPaused = false
    private var currentTrackName = ""
    private var recordingStartTime: Date?
    private var pointsCount = 0
    
    // MARK: - Init
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        setupNotificationCategories()
        checkAuthorizationStatus()
        setupAppLifecycleObservers()
    }
    
    // MARK: - App Lifecycle
    
    private func setupAppLifecycleObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    @objc private func appDidEnterBackground() {
        // Re-publicar la notificación cuando la app va a background
        if !currentTrackName.isEmpty {
            DLog("📱 App went to background - publishing notification for:", currentTrackName)
            // Delay pequeño para asegurar que la app esté completamente en background
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.republishNotification()
            }
        }
    }
    
    @objc private func appWillEnterForeground() {
        // No hacer nada al volver - la notificación ya está en el centro de notificaciones
        DLog("📱 App will enter foreground")
    }
    
    private func republishNotification() {
        guard !currentTrackName.isEmpty else {
            DLog("⚠️ republishNotification called but currentTrackName is empty")
            return
        }
        DLog("🔄 Republishing notification for:", currentTrackName)
        publishNotification(
            trackName: currentTrackName,
            isPaused: isRecordingPaused,
            startTime: recordingStartTime,
            points: pointsCount
        )
    }
    
    // MARK: - Authorization
    
    /// Solicita permiso para mostrar notificaciones
    func requestAuthorization() async -> Bool {
        do {
            let options: UNAuthorizationOptions = [.alert, .sound, .badge]
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: options)
            
            await MainActor.run {
                isAuthorized = granted
            }
            
            return granted
        } catch {
            DLog("Error requesting notification authorization:", error)
            return false
        }
    }
    
    /// Verifica el estado de autorización actual
    private func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            Task { @MainActor in
                self?.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Notification Category Setup
    
    private func setupNotificationCategories() {
        // Acción: Agregar punto (abre la app para marcar ubicación)
        let markPointAction = UNNotificationAction(
            identifier: markPointActionId,
            title: "Agregar punto",
            options: [.foreground],  // Abre la app
            icon: UNNotificationActionIcon(systemImageName: "mappin.and.ellipse")
        )
        
        // Acción: Pausar grabación (sin abrir la app)
        let pauseAction = UNNotificationAction(
            identifier: pauseActionId,
            title: "Pausar",
            options: [],  // No abre la app
            icon: UNNotificationActionIcon(systemImageName: "pause.fill")
        )
        
        // Categoría para grabación activa
        let recordingCategory = UNNotificationCategory(
            identifier: recordingCategoryId,
            actions: [pauseAction, markPointAction],
            intentIdentifiers: [],
            options: [.customDismissAction, .hiddenPreviewsShowTitle]
        )
        
        // Acción: Continuar grabación (sin abrir la app)
        let resumeAction = UNNotificationAction(
            identifier: resumeActionId,
            title: "Continuar",
            options: [],
            icon: UNNotificationActionIcon(systemImageName: "play.fill")
        )
        
        // Categoría para grabación pausada
        let pausedCategory = UNNotificationCategory(
            identifier: "\(recordingCategoryId)_PAUSED",
            actions: [resumeAction, markPointAction],
            intentIdentifiers: [],
            options: [.customDismissAction, .hiddenPreviewsShowTitle]
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([recordingCategory, pausedCategory])
        DLog("📋 Notification categories registered")
    }
    
    // MARK: - Recording Notification
    
    /// Muestra la notificación persistente de grabación
    func showRecordingNotification(
        trackName: String,
        isPaused: Bool = false,
        startTime: Date? = nil,
        points: Int = 0
    ) {
        DLog("🔔 showRecordingNotification called - trackName:", trackName + ", isAuthorized:", isAuthorized)
        
        // Verificar autorización dinámicamente
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            guard let self = self else { return }
            
            let authorized = settings.authorizationStatus == .authorized
            DLog("🔔 Notification settings - status:", settings.authorizationStatus.rawValue, "authorized:", authorized)
            
            if !authorized {
                Task {
                    let granted = await self.requestAuthorization()
                    if granted {
                        self.publishNotification(trackName: trackName, isPaused: isPaused, startTime: startTime, points: points)
                    }
                }
                return
            }
            
            self.publishNotification(trackName: trackName, isPaused: isPaused, startTime: startTime, points: points)
        }
    }
    
    private func publishNotification(
        trackName: String,
        isPaused: Bool,
        startTime: Date?,
        points: Int
    ) {
        // Guardar estado
        currentTrackName = trackName
        isRecordingPaused = isPaused
        recordingStartTime = startTime ?? recordingStartTime ?? Date()
        pointsCount = points
        
        let content = UNMutableNotificationContent()
        
        // Título según estado
        if isPaused {
            content.title = "Recorrido en pausa"
            content.subtitle = trackName
            content.body = "Toca para continuar grabando"
            content.categoryIdentifier = "\(recordingCategoryId)_PAUSED"
        } else {
            content.title = "Recorrido en curso"
            content.subtitle = "Grabando recorrido"
            content.body = buildNotificationBody(trackName: trackName, points: points)
            content.categoryIdentifier = recordingCategoryId
        }
        
        content.sound = nil // Sin sonido para notificación persistente
        content.interruptionLevel = .active
        
        // Agregar información extra
        content.userInfo = [
            "trackName": trackName,
            "isPaused": isPaused,
            "pointsCount": points,
            "type": "recording"
        ]
        
        // Crear trigger inmediato (1 segundo para dar tiempo)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        // Crear request
        let request = UNNotificationRequest(
            identifier: recordingNotificationId,
            content: content,
            trigger: trigger
        )
        
        // Remover notificación anterior y agregar nueva
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [recordingNotificationId])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [recordingNotificationId])
        
        DLog("🔔 Adding recording notification:", trackName + ", isPaused:", isPaused)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                DLog("❌ Error showing recording notification:", error)
            } else {
                DLog("✅ Recording notification scheduled successfully")
            }
        }
    }
    
    /// Construye el cuerpo de la notificación
    private func buildNotificationBody(trackName: String, points: Int) -> String {
        var parts: [String] = []
        
        // Nombre del recorrido
        parts.append(trackName)
        
        // Puntos marcados
        if points > 0 {
            parts.append("• \(points) punto\(points == 1 ? "" : "s") marcado\(points == 1 ? "" : "s")")
        }
        
        return parts.joined(separator: "\n")
    }
    
    /// Actualiza la notificación cuando se pausa/reanuda
    func updateRecordingState(isPaused: Bool) {
        isRecordingPaused = isPaused
        republishNotification()
    }
    
    /// Actualiza la información de la notificación (puntos, etc.)
    func updateNotificationInfo(points: Int) {
        pointsCount = points
        republishNotification()
    }
    
    /// Remueve la notificación de grabación
    func removeRecordingNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [recordingNotificationId])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [recordingNotificationId])
        currentTrackName = ""
        isRecordingPaused = false
        recordingStartTime = nil
        pointsCount = 0
    }
    
    // MARK: - Point Marked Notification
    
    /// Muestra una notificación breve cuando se marca un punto
    func showPointMarkedNotification(pointName: String) {
        guard isAuthorized else { return }
        
        // Actualizar contador de puntos
        pointsCount += 1
        
        let content = UNMutableNotificationContent()
        content.title = "Punto marcado"
        content.body = pointName
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "point_marked_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { [weak self] _ in
            // Actualizar la notificación de grabación con el nuevo contador
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self?.republishNotification()
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension RecordingNotificationService: UNUserNotificationCenterDelegate {
    
    /// Maneja las acciones de la notificación
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        switch response.actionIdentifier {
        case markPointActionId:
            onMarkPointRequested?()
            
        case pauseActionId:
            isRecordingPaused = true
            onPauseRequested?()
            republishNotification()
            
        case resumeActionId:
            isRecordingPaused = false
            onResumeRequested?()
            republishNotification()
            
        case UNNotificationDefaultActionIdentifier:
            // Usuario tocó la notificación - abrir la app
            break
            
        default:
            break
        }
        
        completionHandler()
    }
    
    /// Permite mostrar notificaciones cuando la app está en foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let identifier = notification.request.identifier
        
        // Verificar si la app está realmente en foreground
        let isInForeground = UIApplication.shared.applicationState == .active
        
        if identifier == recordingNotificationId {
            // Notificación de grabación:
            // - En foreground: no mostrar banner (el usuario ya ve la UI)
            // - En background: mostrar para que aparezca en el centro de notificaciones
            if isInForeground {
                completionHandler([])
            } else {
                completionHandler([.banner, .list])
            }
        } else {
            // Otras notificaciones (punto marcado): siempre mostrar
            completionHandler([.banner, .sound, .list])
        }
    }
}
