//
//  MicrophoneDeviceManager.swift
//  Calliope
//
//  Created on [Date]
//

import AVFoundation
import Combine
import Foundation

protocol MicrophoneDeviceProviding {
    func availableMicrophones() -> [AudioInputDevice]
    func defaultMicrophone() -> AudioInputDevice?
}

struct SystemMicrophoneDeviceProvider: MicrophoneDeviceProviding {
    func availableMicrophones() -> [AudioInputDevice] {
        AudioInputDeviceLookup.inputDevices()
    }

    func defaultMicrophone() -> AudioInputDevice? {
        AudioInputDeviceLookup.defaultInputDevice()
    }
}

final class MicrophoneDeviceManager: ObservableObject {
    @Published private(set) var hasMicrophoneInput: Bool
    @Published private(set) var availableMicrophoneDevices: [AudioInputDevice]
    @Published private(set) var defaultMicrophoneDevice: AudioInputDevice?

    private let provider: MicrophoneDeviceProviding
    private let notificationCenter: NotificationCenter
    private var observers: [NSObjectProtocol] = []

    init(
        provider: MicrophoneDeviceProviding = SystemMicrophoneDeviceProvider(),
        notificationCenter: NotificationCenter = .default
    ) {
        self.provider = provider
        self.notificationCenter = notificationCenter
        let devices = provider.availableMicrophones()
        self.hasMicrophoneInput = !devices.isEmpty
        self.availableMicrophoneDevices = devices
        self.defaultMicrophoneDevice = provider.defaultMicrophone()
        startMonitoring()
    }

    deinit {
        observers.forEach(notificationCenter.removeObserver)
        observers.removeAll()
    }

    func refresh() {
        updateAvailability()
    }

    var availableMicrophoneNames: [String] {
        availableMicrophoneDevices.map(\.name)
    }

    var defaultMicrophoneName: String? {
        defaultMicrophoneDevice?.name
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
        let devices = provider.availableMicrophones()
        let hasInput = !devices.isEmpty
        let defaultDevice = provider.defaultMicrophone()
        if Thread.isMainThread {
            hasMicrophoneInput = hasInput
            availableMicrophoneDevices = devices
            defaultMicrophoneDevice = defaultDevice
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.hasMicrophoneInput = hasInput
                self?.availableMicrophoneDevices = devices
                self?.defaultMicrophoneDevice = defaultDevice
            }
        }
    }
}
