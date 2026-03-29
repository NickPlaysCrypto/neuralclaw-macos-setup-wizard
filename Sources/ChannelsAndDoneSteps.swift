import SwiftUI

// MARK: - Step 4: Channels

struct ChannelsStep: View {
    @EnvironmentObject var state: SetupState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            stepIcon("antenna.radiowaves.left.and.right")
            stepTitle("Connect Channels")
            stepDesc("Enable messaging channels to interact with NeuralClaw. You can configure tokens later via the CLI or dashboard.")

            VStack(spacing: 8) {
                ForEach($state.channels) { $channel in
                    ChannelRow(channel: $channel)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 40)
        .padding(.top, 32)
    }
}

struct ChannelRow: View {
    @Binding var channel: ChannelInfo
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(DS.accent.opacity(channel.enabled ? 0.12 : 0.05))
                    .frame(width: 36, height: 36)

                Image(systemName: channel.icon)
                    .font(.system(size: 16))
                    .foregroundColor(channel.enabled ? DS.accent : DS.textDim)
            }

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(channel.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DS.text)

                Text(channel.hint)
                    .font(.system(size: 11))
                    .foregroundColor(DS.textMuted)
                    .lineLimit(1)
            }

            Spacer()

            Toggle("", isOn: $channel.enabled)
                .toggleStyle(.switch)
                .scaleEffect(0.75)
                .frame(width: 40)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isHovered ? DS.surfaceHover : Color.black.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(DS.border, lineWidth: 1)
                )
        )
        .onHover { isHovered = $0 }
    }
}

// MARK: - Step 5: Done

struct DoneStep: View {
    @EnvironmentObject var state: SetupState
    @State private var checkScale: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Checkmark
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [DS.accent3.opacity(0.2), Color(red: 0.18, green: 0.83, blue: 0.75).opacity(0.1)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .overlay(
                        Circle().stroke(DS.accent3.opacity(0.3), lineWidth: 2)
                    )

                Image(systemName: "checkmark")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(DS.accent3)
            }
            .scaleEffect(checkScale)
            .padding(.bottom, 16)

            Text("You're All Set")
                .font(.system(size: 24, weight: .heavy))
                .foregroundStyle(
                    LinearGradient(
                        colors: [DS.text, DS.accent3],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .padding(.bottom, 6)

            Text("NeuralClaw is configured and ready to go.\nHere's a summary of your setup:")
                .font(.system(size: 14))
                .foregroundColor(DS.textMuted)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.bottom, 24)

            // Summary grid
            summaryGrid
                .padding(.horizontal, 40)

            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2)) {
                checkScale = 1.0
            }
        }
        .onDisappear {
            checkScale = 0
        }
    }

    private var summaryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            SummaryCard(label: "Provider", value: state.provider.label)
            SummaryCard(label: "Model", value: state.selectedModel)
            SummaryCard(label: "Fallback", value: state.fallback.isEmpty ? "—" : state.fallback)
            SummaryCard(label: "Features", value: "\(state.features.filter(\.enabled).count) enabled")
            SummaryCard(
                label: "Channels",
                value: {
                    let enabled = state.channels.filter(\.enabled)
                    return enabled.isEmpty ? "None yet" : enabled.map(\.name).joined(separator: ", ")
                }()
            )
            SummaryCard(label: "Config Path", value: "~/.neuralclaw/config.toml", isSmall: true)
        }
    }
}

struct SummaryCard: View {
    let label: String
    let value: String
    var isSmall: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(DS.textMuted)
                .tracking(0.5)

            Text(value)
                .font(.system(size: isSmall ? 11 : 14, weight: .semibold))
                .foregroundColor(DS.text)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(DS.border, lineWidth: 1)
                )
        )
    }
}

// MARK: - Shared Step Helpers

func stepIcon(_ systemName: String) -> some View {
    ZStack {
        RoundedRectangle(cornerRadius: 14)
            .fill(
                LinearGradient(
                    colors: [DS.accent.opacity(0.15), DS.accent2.opacity(0.1)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            .frame(width: 48, height: 48)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(DS.accent.opacity(0.15), lineWidth: 1)
            )

        Image(systemName: systemName)
            .font(.system(size: 22))
            .foregroundColor(DS.accent)
    }
    .padding(.bottom, 16)
}

func stepTitle(_ title: String) -> some View {
    Text(title)
        .font(.system(size: 22, weight: .bold))
        .foregroundStyle(
            LinearGradient(
                colors: [DS.text, DS.accent],
                startPoint: .leading, endPoint: .trailing
            )
        )
        .padding(.bottom, 6)
}

func stepDesc(_ desc: String) -> some View {
    Text(desc)
        .font(.system(size: 14))
        .foregroundColor(DS.textMuted)
        .lineSpacing(3)
        .padding(.bottom, 20)
}
