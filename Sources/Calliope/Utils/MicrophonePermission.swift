//
//  MicrophonePermission.swift
//  Calliope
//
//  Created on [Date]
//

import AVFoundation
import Combine
#if canImport(AppKit)
import AppKit
#endif

enum MicrophonePermissionState: Equatable {
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
            return "Microphone access is granted."
        case .notDetermined:
            return "Microphone access is required for live coaching."
        case .denied:
            return "Microphone access is denied. Enable it in System Settings > Privacy & Security > Microphone."
        case .restricted:
            return "Microphone access is restricted by system policy."
        }
    }
}

protocol MicrophonePermissionProviding {
    func authorizationState() -> MicrophonePermissionState
    func requestAccess(_ completion: @escaping (MicrophonePermissionState) -> Void)
}

struct SystemMicrophonePermissionProvider: MicrophonePermissionProviding {
    func authorizationState() -> MicrophonePermissionState {
        mapStatus(AVCaptureDevice.authorizationStatus(for: .audio))
    }

    func requestAccess(_ completion: @escaping (MicrophonePermissionState) -> Void) {
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            completion(granted ? .authorized : .denied)
        }
    }

    private func mapStatus(_ status: AVAuthorizationStatus) -> MicrophonePermissionState {
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

final class MicrophonePermissionManager: ObservableObject {
    @Published private(set) var state: MicrophonePermissionState

    private let provider: MicrophonePermissionProviding
    private let notificationCenter: NotificationCenter
    private let appActivationNotification: Notification.Name
    private var observers: [NSObjectProtocol] = []

    init(
        provider: MicrophonePermissionProviding = SystemMicrophonePermissionProvider(),
        notificationCenter: NotificationCenter = .default,
        appActivationNotification: Notification.Name = MicrophonePermissionManager.defaultAppActivationNotification
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
