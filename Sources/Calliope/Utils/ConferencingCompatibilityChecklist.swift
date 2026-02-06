//
//  ConferencingCompatibilityChecklist.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

enum ConferencingCompatibilityChecklist {
    struct Section: Identifiable {
        let id = UUID()
        let title: String
        let items: [String]
    }

    static let sections: [Section] = [
        Section(
            title: "Zoom",
            items: [
                "Select the same microphone in Zoom audio settings as Calliope.",
                "If audio sounds clipped or missing, reduce in-app noise suppression or auto-gain features.",
                "Run Zoom's mic test to confirm levels before starting a session."
            ]
        ),
        Section(
            title: "Google Meet",
            items: [
                "Confirm Meet is using the same microphone as Calliope in the browser mic menu.",
                "If speech is muffled, lower browser noise suppression or auto-gain controls.",
                "Reload the Meet tab if the microphone selection does not update."
            ]
        ),
        Section(
            title: "Microsoft Teams",
            items: [
                "Choose the same microphone in Teams device settings as Calliope.",
                "If voice sounds over-processed, reduce noise suppression or audio processing effects.",
                "Use Teams' test call or mic check to verify input levels."
            ]
        )
    ]
}
