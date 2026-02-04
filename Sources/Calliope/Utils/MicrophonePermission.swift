//
//  MicrophonePermission.swift
//  Calliope
//
//  Created on [Date]
//

import AVFoundation
import Combine

enum MicrophonePermissionState: Equatable {
    case notDetermined
    case denied
    case restricted
    case authorized
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

    init(provider: MicrophonePermissionProviding = SystemMicrophonePermissionProvider()) {
        self.provider = provider
        self.state = provider.authorizationState()
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
}
