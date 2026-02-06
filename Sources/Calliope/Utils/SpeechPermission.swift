//
//  SpeechPermission.swift
//  Calliope
//
//  Created on [Date]
//

import Combine
import Speech
#if canImport(AppKit)
import AppKit
#endif

enum SpeechPermissionState: Equatable {
    case notDetermined
    case denied
    case restricted
    case authorized

    var shouldShowGrantAccess: Bool {
        self == .notDetermined
    }

    var description: String {
        switch self {
        case .authorized:
            return "Speech recognition access is granted."
        case .notDetermined:
            return "Speech recognition access is required for live coaching."
        case .denied:
            return "Speech recognition access is denied. Enable it in System Settings > Privacy & Security > Speech Recognition."
        case .restricted:
            return "Speech recognition access is restricted by system policy."
        }
    }
}

protocol SpeechPermissionStateProviding {
    var state: SpeechPermissionState { get }
}

protocol SpeechPermissionProviding {
    func authorizationState() -> SpeechPermissionState
    func requestAccess(_ completion: @escaping (SpeechPermissionState) -> Void)
}

struct SystemSpeechPermissionProvider: SpeechPermissionProviding {
    func authorizationState() -> SpeechPermissionState {
        mapStatus(SFSpeechRecognizer.authorizationStatus())
    }

    func requestAccess(_ completion: @escaping (SpeechPermissionState) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            completion(mapStatus(status))
        }
    }

    private func mapStatus(_ status: SFSpeechRecognizerAuthorizationStatus) -> SpeechPermissionState {
        switch status {
        case .authorized:
            return .authorized
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .denied
        }
    }
}

final class SpeechPermissionManager: ObservableObject, SpeechPermissionStateProviding {
    @Published private(set) var state: SpeechPermissionState

    private let provider: SpeechPermissionProviding
    private let notificationCenter: NotificationCenter
    private let appActivationNotification: Notification.Name
    private var observers: [NSObjectProtocol] = []

    init(
        provider: SpeechPermissionProviding = SystemSpeechPermissionProvider(),
        notificationCenter: NotificationCenter = .default,
        appActivationNotification: Notification.Name = SpeechPermissionManager.defaultAppActivationNotification
    ) {
        self.provider = provider
        self.notificationCenter = notificationCenter
        self.appActivationNotification = appActivationNotification
        self.state = provider.authorizationState()
        startMonitoring()
    }

    deinit {
        observers.forEach(notificationCenter.removeObserver)
        observers.removeAll()
    }

    func refresh() {
        state = provider.authorizationState()
    }

    func requestAccess() {
        provider.requestAccess { [weak self] newState in
            DispatchQueue.main.async {
                self?.state = newState
            }
        }
    }

    private func startMonitoring() {
        let handler: (Notification) -> Void = { [weak self] _ in
            self?.refresh()
        }
        let observer = notificationCenter.addObserver(
            forName: appActivationNotification,
            object: nil,
            queue: .main,
            using: handler
        )
        observers = [observer]
    }

    private static var defaultAppActivationNotification: Notification.Name {
#if canImport(AppKit)
        return NSApplication.didBecomeActiveNotification
#else
        return Notification.Name("CalliopeAppDidBecomeActive")
#endif
    }
}
