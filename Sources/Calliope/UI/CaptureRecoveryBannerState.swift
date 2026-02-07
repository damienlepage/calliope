//
//  CaptureRecoveryBannerState.swift
//  Calliope
//
//  Created on [Date]
//

struct CaptureRecoveryBannerState: Equatable {
    let title: String
    let message: String
    let primaryActionTitle: String
    let secondaryActionTitle: String

    static func from(status: AudioCaptureStatus) -> CaptureRecoveryBannerState? {
        guard case .error(let error) = status else {
            return nil
        }

        if error == .voiceIsolationRiskNotAcknowledged {
            return nil
        }

        return CaptureRecoveryBannerState(
            title: "Capture needs attention",
            message: error.message,
            primaryActionTitle: "Retry Capture",
            secondaryActionTitle: "Open Settings"
        )
    }
}
