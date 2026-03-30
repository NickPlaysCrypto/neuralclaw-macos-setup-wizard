import SwiftUI
import LocalAuthentication

// MARK: - API Config Step (model picker + install confirmation)

struct APIConfigStep: View {
    @EnvironmentObject var state: SetupState
    @State private var showInstallConfirm = false
    @State private var showBioAuth = false
    @State private var bioAuthFailed = false
    @State private var isInstalling = false
    @State private var installSuccess = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            stepIcon("cpu")
            stepTitle("Select a Model")
            stepDesc("Choose which AI model to power NeuralClaw. Larger models are more capable but slower and more expensive.")

            // Provider badge
            HStack(spacing: 8) {
                Image(systemName: state.provider.icon)
                    .font(.system(size: 13))
                    .foregroundColor(state.provider.iconColor)
                Text(state.provider.label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(DS.text)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(state.provider.iconColor.opacity(0.1))
                    .overlay(
                        Capsule()
                            .stroke(state.provider.iconColor.opacity(0.25), lineWidth: 1)
                    )
            )
            .padding(.bottom, 16)

            // Model list
            ScrollView {
                VStack(spacing: 6) {
                    ForEach(state.provider.models, id: \.self) { model in
                        let isSelected = state.selectedModel == model
                        Button(action: {
                            state.selectedModel = model
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 16))
                                    .foregroundColor(isSelected ? DS.accent : DS.textDim)

                                Text(model)
                                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular, design: .monospaced))
                                    .foregroundColor(isSelected ? DS.text : DS.textMuted)

                                Spacer()

                                if isSelected {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(DS.accent)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(isSelected ? DS.accent.opacity(0.06) : Color.black.opacity(0.15))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(isSelected ? DS.accent.opacity(0.3) : DS.border, lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxHeight: 260)

            Spacer()

            // Install button
            Button(action: {
                showInstallConfirm = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 14))
                    Text("Install with \(state.selectedModel)")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(DS.accentGradient)
                )
                .shadow(color: DS.accent.opacity(0.3), radius: 8, y: 4)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 40)
        .padding(.top, 32)
        .overlay {
            if showInstallConfirm {
                ZStack {
                    Color.black.opacity(0.6).ignoresSafeArea()

                    VStack(spacing: 16) {
                        if installSuccess {
                            // ✅ Success — Good Luck!
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [DS.accent3.opacity(0.2), Color(red: 0.18, green: 0.83, blue: 0.75).opacity(0.1)],
                                            startPoint: .topLeading, endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 56, height: 56)
                                    .overlay(
                                        Circle().stroke(DS.accent3.opacity(0.3), lineWidth: 2)
                                    )

                                Image(systemName: "checkmark")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(DS.accent3)
                            }

                            Text("You're All Set!")
                                .font(.system(size: 18, weight: .heavy))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [DS.text, DS.accent3],
                                        startPoint: .leading, endPoint: .trailing
                                    )
                                )

                            Text("You can use the agent to do anything\nfrom here! Good Luck!")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(DS.textMuted)
                                .multilineTextAlignment(.center)
                                .lineSpacing(3)

                            // Summary
                            HStack(spacing: 10) {
                                HStack(spacing: 4) {
                                    Image(systemName: state.provider.icon)
                                        .font(.system(size: 11))
                                        .foregroundColor(state.provider.iconColor)
                                    Text(state.provider.label)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(DS.textMuted)
                                }

                                Text("·")
                                    .foregroundColor(DS.textDim)

                                Text(state.selectedModel)
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .foregroundColor(DS.textMuted)
                            }

                            Button(action: {
                                NSApplication.shared.terminate(nil)
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 12))
                                    Text("Close Setup Wizard")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(DS.accentGradient)
                                )
                            }
                            .buttonStyle(.plain)

                        } else if isInstalling {
                            // Installing state
                            ProgressView()
                                .scaleEffect(1.2)
                                .tint(DS.accent)

                            Text("Installing NeuralClaw...")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(DS.text)

                        } else if bioAuthFailed {
                            // Biometric auth failed
                            Image(systemName: "touchid")
                                .font(.system(size: 28))
                                .foregroundColor(Color.red.opacity(0.8))

                            Text("Authentication failed. Please try again.")
                                .font(.system(size: 13))
                                .foregroundColor(DS.textMuted)
                                .multilineTextAlignment(.center)

                            HStack(spacing: 10) {
                                Button(action: { performBiometricAuth() }) {
                                    Text("Try Again")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(DS.accent)
                                        )
                                }
                                .buttonStyle(.plain)

                                Button(action: {
                                    showInstallConfirm = false
                                    bioAuthFailed = false
                                }) {
                                    Text("Cancel")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(DS.textMuted)
                                }
                                .buttonStyle(.plain)
                            }
                        } else {
                            // Confirmation prompt
                            Image(systemName: "arrow.down.doc.fill")
                                .font(.system(size: 28))
                                .foregroundColor(DS.accent)

                            Text("Install NeuralClaw with **\(state.selectedModel)** from **\(state.provider.label)**?")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(DS.text)
                                .multilineTextAlignment(.center)

                            HStack(spacing: 12) {
                                Button(action: {
                                    if state.requireBiometric {
                                        performBiometricAuth()
                                    } else {
                                        completeInstallation()
                                    }
                                }) {
                                    HStack(spacing: 6) {
                                        if state.requireBiometric {
                                            Image(systemName: "touchid")
                                                .font(.system(size: 13))
                                        }
                                        Text("Yes, Install")
                                            .font(.system(size: 13, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(DS.accent)
                                    )
                                }
                                .buttonStyle(.plain)

                                Button(action: {
                                    showInstallConfirm = false
                                }) {
                                    Text("Cancel")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(DS.textMuted)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.white.opacity(0.06))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(DS.border, lineWidth: 1)
                                                )
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(28)
                    .frame(width: 340)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(red: 0.10, green: 0.11, blue: 0.16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(DS.border, lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.5), radius: 20, y: 8)
                    )
                }
                .transition(.opacity)
            }
        }
    }

    private func performBiometricAuth() {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                   localizedReason: "Authenticate to install NeuralClaw") { success, _ in
                DispatchQueue.main.async {
                    if success {
                        completeInstallation()
                    } else {
                        bioAuthFailed = true
                    }
                }
            }
        } else {
            // No biometrics available — proceed without
            completeInstallation()
        }
    }

    private func completeInstallation() {
        isInstalling = true
        state.saveConfiguration()

        // Wait for config to be written, then launch NeuralClaw and show success
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isInstalling = false
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                installSuccess = true
            }

            // Launch the actual NeuralClaw app from /Applications
            state.launchNeuralClaw()

            // Auto-close the setup wizard after a brief moment
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                NSApplication.shared.terminate(nil)
            }
        }
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
