//
//  MicrophoneDeviceManager.swift
//  Calliope
//
//  Created on [Date]
//

import AVFoundation
import Combine

protocol MicrophoneDeviceProviding {
    func availableMicrophoneNames() -> [String]
}

struct SystemMicrophoneDeviceProvider: MicrophoneDeviceProviding {
    func availableMicrophoneNames() -> [String] {
        AVCaptureDevice.devices(for: .audio).map(\.localizedName)
    }
}

final class MicrophoneDeviceManager: ObservableObject {
    @Published private(set) var hasMicrophoneInput: Bool

    private let provider: MicrophoneDeviceProviding
    private let notificationCenter: NotificationCenter
    private var observers: [NSObjectProtocol] = []

    init(
        provider: MicrophoneDeviceProviding = SystemMicrophoneDeviceProvider(),
        notificationCenter: NotificationCenter = .default
    ) {
        self.provider = provider
        self.notificationCenter = notificationCenter
        self.hasMicrophoneInput = !provider.availableMicrophoneNames().isEmpty
        startMonitoring()
    }

    deinit {
        observers.forEach(notificationCenter.removeObserver)
        observers.removeAll()
    }

    func refresh() {
        updateAvailability()
    }

    private func startMonitoring() {
        let handler: (Notification) -> Void = { [weak self] _ in
            self?.updateAvailability()
        }
        observers = [
            notificationCenter.addObserver(
                forName: .AVCaptureDeviceWasConnected,
                object: nil,
                queue: .main,
                using: handler
            ),
            notificationCenter.addObserver(
                forName: .AVCaptureDeviceWasDisconnected,
                object: nil,
                queue: .main,
                using: handler
            )
        ]
    }

    private func updateAvailability() {
        let hasInput = !provider.availableMicrophoneNames().isEmpty
        if Thread.isMainThread {
            hasMicrophoneInput = hasInput
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.hasMicrophoneInput = hasInput
            }
        }
    }
}
