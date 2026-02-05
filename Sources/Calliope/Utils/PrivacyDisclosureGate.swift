//
//  PrivacyDisclosureGate.swift
//  Calliope
//
//  Created on [Date]
//

struct PrivacyDisclosureGate {
    static func requiresDisclosure(hasAcceptedDisclosure: Bool) -> Bool {
        !hasAcceptedDisclosure
    }
}
