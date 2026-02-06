//
//  PerformanceValidationChecklist.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

enum PerformanceValidationChecklist {
    struct Section: Identifiable {
        let id = UUID()
        let title: String
        let items: [String]
    }

    static let sections: [Section] = [
        Section(
            title: "Targets",
            items: [
                "CPU (Apple Silicon): 3-8% avg while recording, <=15% peaks.",
                "CPU (Intel): 5-12% avg while recording, <=20% peaks.",
                "Energy Impact: stays Low, only brief Medium spikes.",
                "Memory: <=20 MB drift after 10 minutes.",
                "Latency: in-app processing stays OK (no sustained High)."
            ]
        ),
        Section(
            title: "Validation Steps",
            items: [
                "Idle baseline: 2 minutes on Session screen without recording.",
                "Steady-state: 5 minutes recording with normal speech.",
                "Stress burst: 2 minutes of continuous faster speech.",
                "Memory drift: compare 1-minute vs 10-minute footprint.",
                "Instruments: 30s idle + 2 min recording (Time Profiler, Energy Log)."
            ]
        ),
        Section(
            title: "Documentation",
            items: [
                "Record date, machine, macOS version, mic, and results."
            ]
        )
    ]
}
