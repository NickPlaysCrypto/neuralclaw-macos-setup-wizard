import SwiftUI

// MARK: - API Config Step (combines key + model + fallback)

struct APIConfigStep: View {
    @EnvironmentObject var state: SetupState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            stepIcon("gearshape.fill")
            stepTitle("Configure Your Connection")
            stepDesc("Enter your API key and select a model. Larger models are more capable but slower and more expensive.")

            // API Key field
            if state.provider.needsKey {
                VStack(alignment: .leading, spacing: 6) {
                    Text("API KEY")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(DS.textMuted)
                        .tracking(0.5)

                    HStack(spacing: 10) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 13))
                            .foregroundColor(DS.textDim)

                        SecureField(state.provider.keyPlaceholder, text: $state.apiKey)
                            .textFieldStyle(.plain)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundColor(DS.text)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.black.opacity(0.3))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(DS.border, lineWidth: 1)
                            )
                    )
                }
                .padding(.bottom, 20)
            }

            // Model picker
            VStack(alignment: .leading, spacing: 6) {
                Text("MODEL")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(DS.textMuted)
                    .tracking(0.5)

                HStack(spacing: 10) {
                    Image(systemName: "cpu")
                        .font(.system(size: 13))
                        .foregroundColor(DS.textDim)

                    Picker("", selection: $state.selectedModel) {
                        ForEach(state.provider.models, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .accentColor(DS.text)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.black.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(DS.border, lineWidth: 1)
                        )
                )
            }
            .padding(.bottom, 20)

            // Fallback provider
            VStack(alignment: .leading, spacing: 6) {
                Text("FALLBACK PROVIDER (IF PRIMARY FAILS)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(DS.textMuted)
                    .tracking(0.5)

                HStack(spacing: 10) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 13))
                        .foregroundColor(DS.textDim)

                    Picker("", selection: $state.fallback) {
                        Text("None").tag("")
                        ForEach(AIProvider.allCases.filter { $0 != state.provider }) { p in
                            Text(p.label).tag(p.rawValue)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .accentColor(DS.text)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.black.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(DS.border, lineWidth: 1)
                        )
                )
            }

            Spacer()
        }
        .padding(.horizontal, 40)
        .padding(.top, 32)
    }
}

// MARK: - Features Step

struct FeaturesStep: View {
    @EnvironmentObject var state: SetupState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            stepIcon("puzzlepiece.fill")
            stepTitle("Enable Features")
            stepDesc("Choose the cortex capabilities to activate. Disable unused features for faster boot and lower resource usage.")

            // Preset row
            HStack(spacing: 8) {
                ForEach(FeaturePreset.allCases, id: \.rawValue) { preset in
                    PresetButton(
                        label: preset.label,
                        isActive: state.preset == preset,
                        action: { state.applyPreset(preset) }
                    )
                }
            }
            .padding(.bottom, 14)

            // Feature grid
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                    ForEach($state.features) { $feature in
                        FeatureToggleRow(feature: $feature)
                    }
                }
            }
            .frame(maxHeight: 240)

            Spacer()
        }
        .padding(.horizontal, 40)
        .padding(.top, 32)
    }
}

struct PresetButton: View {
    let label: String
    let isActive: Bool
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isActive ? DS.accent : DS.textMuted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isActive ? DS.accent.opacity(0.08) : Color.black.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isActive ? DS.accent : (isHovered ? DS.accent.opacity(0.3) : DS.border), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

struct FeatureToggleRow: View {
    @Binding var feature: Feature

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: feature.icon)
                .font(.system(size: 15))
                .foregroundColor(feature.enabled ? DS.accent : DS.textDim)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 1) {
                Text(feature.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(DS.text)

                Text(feature.desc)
                    .font(.system(size: 10))
                    .foregroundColor(DS.textMuted)
                    .lineLimit(1)
            }

            Spacer()

            Toggle("", isOn: $feature.enabled)
                .toggleStyle(.switch)
                .scaleEffect(0.7)
                .frame(width: 36)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.clear)
        )
    }
}
