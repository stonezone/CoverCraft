import SwiftUI

@available(iOS 18.0, macOS 15.0, *)
public enum CoverCraftTone: Sendable, Equatable {
    case neutral
    case accent
    case success
    case warning

    fileprivate var tint: Color {
        switch self {
        case .neutral:
            return Color(red: 0.31, green: 0.37, blue: 0.46)
        case .accent:
            return Color(red: 0.06, green: 0.44, blue: 0.79)
        case .success:
            return Color(red: 0.16, green: 0.60, blue: 0.35)
        case .warning:
            return Color(red: 0.82, green: 0.47, blue: 0.08)
        }
    }

    fileprivate var softFill: Color {
        tint.opacity(0.10)
    }
}

@available(iOS 18.0, macOS 15.0, *)
public struct CoverCraftScreenBackground: View {
    public init() {}

    public var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.97, green: 0.98, blue: 0.99),
                    Color(red: 0.93, green: 0.95, blue: 0.98),
                    Color(red: 0.96, green: 0.94, blue: 0.91)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color(red: 0.10, green: 0.54, blue: 0.86).opacity(0.13))
                .frame(width: 320, height: 320)
                .blur(radius: 24)
                .offset(x: -120, y: -220)

            Circle()
                .fill(Color(red: 0.98, green: 0.66, blue: 0.23).opacity(0.11))
                .frame(width: 260, height: 260)
                .blur(radius: 24)
                .offset(x: 130, y: 260)
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
public struct CoverCraftCard<Content: View>: View {
    private let tone: CoverCraftTone
    private let content: Content

    public init(
        tone: CoverCraftTone = .neutral,
        @ViewBuilder content: () -> Content
    ) {
        self.tone = tone
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            content
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(tone.softFill)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(tone.tint.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 24, x: 0, y: 12)
    }
}

@available(iOS 18.0, macOS 15.0, *)
public struct CoverCraftStatusChip: View {
    private let title: String
    private let systemImage: String
    private let tone: CoverCraftTone

    public init(
        _ title: String,
        systemImage: String,
        tone: CoverCraftTone = .neutral
    ) {
        self.title = title
        self.systemImage = systemImage
        self.tone = tone
    }

    public var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .lineLimit(1)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .foregroundStyle(tone.tint)
            .background(
                Capsule(style: .continuous)
                    .fill(tone.softFill)
            )
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(tone.tint.opacity(0.16), lineWidth: 1)
            )
    }
}

@available(iOS 18.0, macOS 15.0, *)
public struct CoverCraftMetricTile: View {
    private let title: String
    private let value: String
    private let subtitle: String?
    private let systemImage: String
    private let tone: CoverCraftTone

    public init(
        title: String,
        value: String,
        subtitle: String? = nil,
        systemImage: String,
        tone: CoverCraftTone = .accent
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.tone = tone
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(tone.tint)

            Text(value)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)

            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.thinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(tone.softFill.opacity(0.9))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(tone.tint.opacity(0.16), lineWidth: 1)
        )
    }
}

@available(iOS 18.0, macOS 15.0, *)
public struct CoverCraftSectionHeading: View {
    private let step: String
    private let title: String
    private let subtitle: String
    private let statusTitle: String?
    private let statusImage: String?
    private let tone: CoverCraftTone

    public init(
        step: String,
        title: String,
        subtitle: String,
        statusTitle: String? = nil,
        statusImage: String? = nil,
        tone: CoverCraftTone = .neutral
    ) {
        self.step = step
        self.title = title
        self.subtitle = subtitle
        self.statusTitle = statusTitle
        self.statusImage = statusImage
        self.tone = tone
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(step.uppercased())
                    .font(.caption.weight(.bold))
                    .foregroundStyle(tone.tint)

                Text(title)
                    .font(.title3.weight(.semibold))

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 12)

            if let statusTitle, let statusImage {
                CoverCraftStatusChip(statusTitle, systemImage: statusImage, tone: tone)
            }
        }
    }
}
