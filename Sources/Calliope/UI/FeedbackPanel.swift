//
//  FeedbackPanel.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation
import SwiftUI

struct FeedbackPanel: View {
    let pace: Double // words per minute
    let crutchWords: Int
    let pauseCount: Int
    let pauseAverageDuration: TimeInterval
    let speakingTimeSeconds: TimeInterval
    let speakingTimeTargetPercent: Double
    let inputLevel: Double
    let showSilenceWarning: Bool
    let showWaitingForSpeech: Bool
    let paceMin: Double
    let paceMax: Double
    let sessionDurationText: String?
    let sessionDurationSeconds: Int?
    let storageStatus: RecordingStorageStatus
    let liveTranscript: String
    let coachingProfiles: [CoachingProfile]
    let activeProfileLabel: String?
    @Binding var selectedCoachingProfileID: UUID?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private enum SupplementaryLayout {
        static let captionLineLimit = 3
        static let profilePickerWidth: CGFloat = 200
        static let spacing: CGFloat = 12
    }
    
    var body: some View {
        let pauseRateText = PauseRateFormatter.rateText(
            pauseCount: pauseCount,
            durationSeconds: sessionDurationSeconds
        )
        let speakingTimeText = SessionDurationFormatter.format(
            seconds: max(0, Int(speakingTimeSeconds.rounded()))
        )
        let cardSpacing: CGFloat = 12
        let metricColumns = FeedbackPanelLayout.metricColumns(
            dynamicTypeSize: dynamicTypeSize,
            spacing: cardSpacing
        )
        let crutchLevel = CrutchWordFeedback.level(for: crutchWords)
        let statusMessages = FeedbackStatusMessages.build(
            storageStatus: storageStatus,
            interruptionMessage: nil,
            showSilenceWarning: showSilenceWarning,
            showWaitingForSpeech: showWaitingForSpeech
        )
        let crutchStatusText = CrutchWordFeedback.statusText(for: crutchWords)
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text("Real-time Feedback")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
            }

            FeedbackCard(title: "Input Level") {
                VStack(alignment: .leading, spacing: 6) {
                    InputLevelMeterView(level: inputLevel)
                    Text(inputLevelStatusText())
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Input level")
            .accessibilityValue(
                AccessibilityFormatting.inputLevelValue(
                    level: inputLevel,
                    statusText: inputLevelStatusText()
                )
            )

            FeedbackCard(title: "Pace") {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(PaceFeedback.valueText(for: pace))
                            .font(.title3)
                            .foregroundColor(paceColor(pace))
                        Text(PaceFeedback.label(for: pace, minPace: paceMin, maxPace: paceMax))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(PaceFeedback.targetRangeText(minPace: paceMin, maxPace: paceMax))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(PaceFeedback.valueText(for: pace))
                            .font(.title3)
                            .foregroundColor(paceColor(pace))
                        Text(PaceFeedback.label(for: pace, minPace: paceMin, maxPace: paceMax))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(PaceFeedback.targetRangeText(minPace: paceMin, maxPace: paceMax))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                PaceRangeBar(
                    pace: pace,
                    paceMin: paceMin,
                    paceMax: paceMax,
                    indicatorColor: paceColor(pace)
                )
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Pace")
            .accessibilityValue(
                AccessibilityFormatting.paceValue(
                    pace: pace,
                    minPace: paceMin,
                    maxPace: paceMax
                )
            )

            LazyVGrid(columns: metricColumns, spacing: cardSpacing) {
                FeedbackStatCard(
                    title: "Elapsed",
                    value: sessionDurationText ?? "—",
                    valueColor: .primary,
                    subtitle: "Session time"
                )
                FeedbackStatCard(
                    title: "Speaking",
                    value: speakingTimeText,
                    valueColor: .primary,
                    subtitle: "Talk time · \(speakingTargetText())"
                )
                FeedbackStatCard(
                    title: "Pauses",
                    value: "\(pauseCount)",
                    valueColor: .primary,
                    subtitle: pauseDetailsText(rateText: pauseRateText),
                    accessibilitySupplement: pauseRateText
                ) {
                    if let pauseRateText {
                        PauseRateBadge(text: pauseRateText)
                            .padding(.top, 2)
                    }
                }
                FeedbackStatCard(
                    title: "Crutch Words",
                    value: "\(crutchWords)",
                    valueColor: crutchColor(crutchLevel),
                    subtitle: "Status: \(crutchStatusText) · Target: \u{2264} 5"
                )
            }

            if shouldShowSupplementaryPanel {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: SupplementaryLayout.spacing) {
                        captionsCard()
                        profileCard()
                    }
                    VStack(alignment: .leading, spacing: SupplementaryLayout.spacing) {
                        captionsCard()
                        profileCard()
                    }
                }
            }

            if !statusMessages.isEmpty {
                FeedbackCard(title: "Session Status") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(statusMessages.warnings, id: \.self) { message in
                            feedbackWarning(message)
                        }
                        ForEach(statusMessages.notes, id: \.self) { message in
                            feedbackNote(message)
                        }
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Session status")
                .accessibilityValue(
                    AccessibilityFormatting.statusValue(
                        warnings: statusMessages.warnings,
                        notes: statusMessages.notes
                    )
                )
            }
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.15))
        )
        .cornerRadius(12)
    }
    
    private func paceColor(_ pace: Double) -> Color {
        switch PaceFeedback.level(for: pace, minPace: paceMin, maxPace: paceMax) {
        case .idle:
            return .secondary
        case .slow:
            return Color(NSColor.systemBlue)
        case .target:
            return Color(NSColor.systemGreen)
        case .fast:
            return Color(NSColor.systemOrange)
        }
    }

    private func pauseDetailsText(rateText: String?) -> String {
        PauseDetailsFormatter.detailsText(
            pauseCount: pauseCount,
            averageDuration: pauseAverageDuration,
            rateText: rateText
        )
    }

    private func crutchColor(_ level: CrutchWordFeedbackLevel) -> Color {
        switch level {
        case .calm:
            return Color(NSColor.systemGreen)
        case .caution:
            return Color(NSColor.systemOrange)
        }
    }

    private func speakingTargetText() -> String {
        let target = Int(speakingTimeTargetPercent.rounded())
        return "Target: \(target)% of session"
    }

    private var shouldShowSupplementaryPanel: Bool {
        true
    }

    @ViewBuilder
    private func captionsCard() -> some View {
        FeedbackCard(title: "Live captions") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Closed captions")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(captionBodyText(for: liveTranscript))
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .lineLimit(SupplementaryLayout.captionLineLimit)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color.secondary.opacity(0.08))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.secondary.opacity(0.12))
                    )
                    .accessibilityLabel("Live captions")
                    .accessibilityValue(captionBodyText(for: liveTranscript))
            }
        }
    }

    @ViewBuilder
    private func profileCard() -> some View {
        FeedbackCard(title: "Coaching profile") {
            let selectedProfileName = coachingProfiles.first(where: { $0.id == selectedCoachingProfileID })?.name
            let fallbackProfileText = "Profile: \(selectedProfileName ?? "Default")"
            let profileText = activeProfileLabel ?? fallbackProfileText
            VStack(alignment: .leading, spacing: 6) {
                if coachingProfiles.count > 1 {
                    Picker("Coaching profile", selection: $selectedCoachingProfileID) {
                        ForEach(coachingProfiles) { profile in
                            Text(profile.name)
                                .tag(profile.id as UUID?)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: SupplementaryLayout.profilePickerWidth, alignment: .leading)
                    .accessibilityLabel("Coaching profile")
                    .accessibilityHint("Choose which coaching profile to apply to this session.")
                    Text(profileText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityLabel("Active profile")
                        .accessibilityValue(profileText)
                } else {
                    Text(profileText)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityLabel("Active profile")
                        .accessibilityValue(profileText)
                }
            }
        }
    }

    private func feedbackNote(_ text: String) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundColor(.secondary)
    }

    private func captionBodyText(for transcript: String) -> String {
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Listening for speech..." : trimmed
    }

    private func feedbackWarning(_ text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.footnote)
            Text(text)
                .font(.footnote)
        }
        .foregroundColor(Color(NSColor.systemOrange))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.systemOrange).opacity(0.12))
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Warning")
        .accessibilityValue(AccessibilityFormatting.warningValue(text: text))
    }

    private func inputLevelStatusText() -> String {
        inputLevel < InputLevelMeter.meaningfulThreshold ? "Low signal" : "Active"
    }
}

enum FeedbackPanelLayout {
    static func usesSingleColumn(dynamicTypeSize: DynamicTypeSize) -> Bool {
        dynamicTypeSize.isAccessibilitySize
    }

    static func metricColumns(
        dynamicTypeSize: DynamicTypeSize,
        spacing: CGFloat
    ) -> [GridItem] {
        if usesSingleColumn(dynamicTypeSize: dynamicTypeSize) {
            return [GridItem(.flexible(), spacing: spacing)]
        }
        return [
            GridItem(.flexible(), spacing: spacing),
            GridItem(.flexible(), spacing: spacing)
        ]
    }
}

private struct FeedbackCard<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            content
        }
        .padding(12)
        .background(Color(NSColor.windowBackgroundColor).opacity(0.85))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.secondary.opacity(0.12))
        )
        .cornerRadius(10)
    }
}

private struct FeedbackStatCard<Accessory: View>: View {
    let title: String
    let value: String
    let valueColor: Color
    let subtitle: String?
    let accessibilitySupplement: String?
    let accessory: Accessory

    init(
        title: String,
        value: String,
        valueColor: Color,
        subtitle: String? = nil,
        accessibilitySupplement: String? = nil,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.title = title
        self.value = value
        self.valueColor = valueColor
        self.subtitle = subtitle
        self.accessibilitySupplement = accessibilitySupplement
        self.accessory = accessory()
    }

    var body: some View {
        FeedbackCard(title: title) {
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title3)
                    .foregroundColor(valueColor)
                    .fixedSize(horizontal: false, vertical: true)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                accessory
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(
            AccessibilityFormatting.metricValue(
                value: value,
                subtitle: subtitle,
                accessory: accessibilitySupplement
            )
        )
    }
}

private extension FeedbackStatCard where Accessory == EmptyView {
    init(
        title: String,
        value: String,
        valueColor: Color,
        subtitle: String? = nil,
        accessibilitySupplement: String? = nil
    ) {
        self.init(
            title: title,
            value: value,
            valueColor: valueColor,
            subtitle: subtitle,
            accessibilitySupplement: accessibilitySupplement,
            accessory: { EmptyView() }
        )
    }
}

private struct PauseRateBadge: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(Color.secondary.opacity(0.12))
            )
            .accessibilityLabel("Pause rate \(text)")
    }
}

#if DEBUG
struct FeedbackPanel_Previews: PreviewProvider {
    private struct PreviewWrapper: View {
        @State private var selectedProfileID: UUID? = CoachingProfile.default().id
        private let profiles = [
            CoachingProfile.default(),
            CoachingProfile(id: UUID(), name: "Focused", preferences: .default)
        ]

        var body: some View {
            FeedbackPanel(
                pace: 150,
                crutchWords: 3,
                pauseCount: 2,
                pauseAverageDuration: 1.4,
                speakingTimeSeconds: 72,
                speakingTimeTargetPercent: Constants.speakingTimeTargetPercent,
                inputLevel: 0.4,
                showSilenceWarning: false,
                showWaitingForSpeech: false,
                paceMin: Constants.targetPaceMin,
                paceMax: Constants.targetPaceMax,
                sessionDurationText: "02:15",
                sessionDurationSeconds: 135,
                storageStatus: .ok,
                liveTranscript: "Let's focus on the key takeaways for the next steps.",
                coachingProfiles: profiles,
                activeProfileLabel: "Profile: Default (App: Default)",
                selectedCoachingProfileID: $selectedProfileID
            )
            .padding()
        }
    }

    static var previews: some View {
        PreviewWrapper()
    }
}
#endif
