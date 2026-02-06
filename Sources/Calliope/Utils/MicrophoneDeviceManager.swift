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
    func defaultMicrophoneName() -> String?
}

struct SystemMicrophoneDeviceProvider: MicrophoneDeviceProviding {
    func availableMicrophoneNames() -> [String] {
        AVCaptureDevice.devices(for: .audio).map(\.localizedName)
    }

    func defaultMicrophoneName() -> String? {
        AVCaptureDevice.default(for: .audio)?.localizedName
    }
}

final class MicrophoneDeviceManager: ObservableObject {
    @Published private(set) var hasMicrophoneInput: Bool
    @Published private(set) var availableMicrophoneNames: [String]
    @Published private(set) var defaultMicrophoneName: String?

    private let provider: MicrophoneDeviceProviding
    private let notificationCenter: NotificationCenter
    private var observers: [NSObjectProtocol] = []

    init(
        provider: MicrophoneDeviceProviding = SystemMicrophoneDeviceProvider(),
        notificationCenter: NotificationCenter = .default
    ) {
        self.provider = provider
        self.notificationCenter = notificationCenter
        let names = provider.availableMicrophoneNames()
        self.hasMicrophoneInput = !names.isEmpty
        self.availableMicrophoneNames = names
        self.defaultMicrophoneName = provider.defaultMicrophoneName()
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
        let names = provider.availableMicrophoneNames()
        let hasInput = !names.isEmpty
        let defaultName = provider.defaultMicrophoneName()
        if Thread.isMainThread {
            hasMicrophoneInput = hasInput
            availableMicrophoneNames = names
            defaultMicrophoneName = defaultName
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.hasMicrophoneInput = hasInput
                self?.availableMicrophoneNames = names
                self?.defaultMicrophoneName = defaultName
            }
        }
    }
}
