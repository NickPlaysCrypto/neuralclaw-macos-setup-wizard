import SwiftUI

// MARK: - Step 0: AI Usage Questionnaire

struct AIUsageStep: View {
    @EnvironmentObject var state: SetupState
    @State private var headerOpacity: Double = 0
    @State private var cardsOffset: CGFloat = 20

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 36)

            // Header
            VStack(spacing: 8) {
                Text("Which of these AI companies\ndo you use?")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [DS.text, DS.accent],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                Text("Select all that apply — this helps us configure NeuralClaw for you.")
                    .font(.system(size: 14))
                    .foregroundColor(DS.textMuted)
                    .multilineTextAlignment(.center)
            }
            .opacity(headerOpacity)
            .padding(.bottom, 28)

            // Service cards — 3 in a row
            HStack(spacing: 14) {
                ForEach(ConsumerAI.allCases) { service in
                    ConsumerAICard(
                        service: service,
                        isSelected: state.selectedServices.contains(service),
                        onToggle: { state.toggleService(service) }
                    )
                }
            }
            .offset(y: cardsOffset)
            .opacity(headerOpacity)
            .padding(.horizontal, 40)

            // File access warning
            HStack(spacing: 8) {
                Text("⚠️")
                    .font(.system(size: 14))

                Text("NeuralClaw will not have access to any of your device files unless you give it explicit access")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(red: 0.95, green: 0.75, blue: 0.30))
                    .fixedSize(horizontal: false, vertical: true)

                Text("⚠️")
                    .font(.system(size: 14))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(red: 0.95, green: 0.75, blue: 0.30).opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(red: 0.95, green: 0.75, blue: 0.30).opacity(0.2), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 40)
            .padding(.top, 16)
            .opacity(headerOpacity)

            // Biometric checkbox
            Button(action: {
                withAnimation(.easeInOut(duration: 0.15)) {
                    state.requireBiometric.toggle()
                }
            }) {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(state.requireBiometric ? DS.accent : Color.clear)
                            .frame(width: 18, height: 18)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(state.requireBiometric ? DS.accent : DS.border, lineWidth: 1.5)
                            )

                        if state.requireBiometric {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "touchid")
                            .font(.system(size: 13))
                            .foregroundColor(DS.accent)

                        Text("Require biometric fingerprint authentication for all file access permissions")
                            .font(.system(size: 12))
                            .foregroundColor(DS.textMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 40)
            .padding(.top, 10)
            .opacity(headerOpacity)

            Spacer()

            // Bottom actions
            VStack(spacing: 14) {
                // Continue button (only if services selected)
                if !state.selectedServices.isEmpty {
                    Button(action: state.chooseConsumerPath) {
                        HStack(spacing: 6) {
                            Text("Continue")
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .font(.system(size: 14, weight: .semibold))
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
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                // "I have an API key" link
                Button(action: state.chooseAPIKeyPath) {
                    HStack(spacing: 6) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 12))
                        Text("I have an API key")
                            .font(.system(size: 13, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundColor(DS.textMuted)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 20)
                    .background(
                        Capsule()
                            .stroke(DS.border, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 24)
            .animation(.easeInOut(duration: 0.25), value: state.selectedServices)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                headerOpacity = 1
                cardsOffset = 0
            }
        }
    }
}

struct ConsumerAICard: View {
    let service: ConsumerAI
    let isSelected: Bool
    let onToggle: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onToggle) {
            VStack(spacing: 12) {
                // Logo icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: service.gradientColors.map { $0.opacity(isSelected ? 0.25 : 0.12) },
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .overlay(
                            Circle()
                                .stroke(service.iconColor.opacity(isSelected ? 0.5 : 0.15), lineWidth: 1.5)
                        )

                    Image(systemName: service.icon)
                        .font(.system(size: 24))
                        .foregroundColor(service.iconColor)
                }

                // Product name
                Text(service.productName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(DS.text)

                // Company name
                Text(service.companyName)
                    .font(.system(size: 12))
                    .foregroundColor(DS.textMuted)

                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? service.iconColor : DS.textDim, lineWidth: 1.5)
                        .frame(width: 22, height: 22)

                    if isSelected {
                        Circle()
                            .fill(service.iconColor)
                            .frame(width: 22, height: 22)
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                            )
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
            }
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? service.iconColor.opacity(0.06)
                          : (isHovered ? DS.surfaceHover : Color.black.opacity(0.2)))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? service.iconColor.opacity(0.4) : DS.border, lineWidth: 1)
                    )
            )
            .shadow(color: isSelected ? service.iconColor.opacity(0.15) : .clear, radius: 10)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Intelligence Provider Step (Consumer Path)

struct OAuthInfoStep: View {
    @EnvironmentObject var state: SetupState
    @State private var localModelHovered = false
    @State private var apiKeyHovered = false
    @State private var directAPIKey = ""
    @State private var apiKeySaved = false
    @State private var showLearnInfo = false
    @State private var showDetection = false
    @State private var detectedProvider: String? = nil
    @State private var showManualPicker = false
    @State private var detectionProgress: Double = 0.0
    @State private var clickedNo = false
    @State private var detectionFailed = false

    // Volatile content: title and subtitle can be updated externally
    private var panelTitle: String {
        ContentRegistry.shared.getString(
            "wizard.providerPanel.title",
            default: "Select Your Intelligence Provider"
        )
    }

    private var panelSubtitle: String {
        ContentRegistry.shared.getString(
            "wizard.providerPanel.subtitle",
            default: "Choose one or more of these AI providers that will form the basis of your system's intelligence"
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            stepIcon("brain")
            stepTitle(panelTitle)
            stepDesc(panelSubtitle)

            // Provider list — scrollable volatile content frame
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(ConsumerAI.allCases) { service in
                        let isSelected = state.selectedServices.contains(service)
                        if isSelected {
                            OAuthServiceRow(service: service)
                        }
                    }

                    // Local models option
                    localModelRow

                    // Direct API key input
                    apiKeyRow

                    // If nothing is selected (shouldn't happen, but safety)
                    if state.selectedServices.isEmpty && directAPIKey.isEmpty {
                        Text("No services selected.")
                            .font(.system(size: 14))
                            .foregroundColor(DS.textMuted)
                            .padding(.top, 10)
                    }
                }
            }

            Spacer(minLength: 8)

            // Bottom hint link with info
            HStack(spacing: 8) {
                Button(action: state.goNext) {
                    HStack(spacing: 6) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 13))
                        Text("Learn how to get an API key")
                            .font(.system(size: 13, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundColor(DS.accent)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(DS.accent.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(DS.accent.opacity(0.12), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)

                Button(action: { showLearnInfo.toggle() }) {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(DS.textDim)
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showLearnInfo, arrowEdge: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("When do I need an API key?")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)

                        Text("If none of the providers you use offer Log In (OAuth) then you may be able to get an API key from them. Click to find out how.")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.8))
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(14)
                    .frame(width: 280)
                    .background(Color(red: 0.12, green: 0.13, blue: 0.18))
                }
            }
        }
        .padding(.horizontal, 40)
        .padding(.top, 32)
        .overlay {
            // API Provider Detection Overlay
            if showDetection {
                ZStack {
                    // Dim background
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()

                    // Detection card
                    VStack(spacing: 0) {
                        if let provider = detectedProvider {
                            // Provider detected — show success then auto-dismiss
                            VStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.green)

                                Text("Provider Identified")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(DS.text)

                                Text(provider)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(DS.accent)
                            }
                            .padding(28)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    showDetection = false
                                    apiKeySaved = false
                                    // TODO: Navigate to model selection for this provider
                                }
                            }
                        } else if showManualPicker {
                            // Manual provider selection
                            VStack(spacing: 14) {
                                Text("Select Your Provider")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(DS.text)

                                VStack(spacing: 8) {
                                    ForEach(ConsumerAI.allCases) { service in
                                        Button(action: {
                                            detectedProvider = "\(service.productName) by \(service.companyName)"
                                        }) {
                                            HStack(spacing: 10) {
                                                Image(systemName: service.icon)
                                                    .font(.system(size: 14))
                                                    .foregroundColor(service.iconColor)
                                                    .frame(width: 24)

                                                Text("\(service.productName) by \(service.companyName)")
                                                    .font(.system(size: 13, weight: .medium))
                                                    .foregroundColor(DS.text)

                                                Spacer()

                                                Image(systemName: "chevron.right")
                                                    .font(.system(size: 10, weight: .bold))
                                                    .foregroundColor(DS.textDim)
                                            }
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 10)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color.white.opacity(0.04))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .stroke(DS.border, lineWidth: 1)
                                                    )
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }

                                Button(action: {
                                    showManualPicker = false
                                    showDetection = false
                                    apiKeySaved = false
                                }) {
                                    Text("Cancel")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(DS.textMuted)
                                }
                                .buttonStyle(.plain)
                                .padding(.top, 4)
                            }
                            .padding(24)
                        } else if detectionFailed {
                            // Detection timed out — show error + manual option
                            VStack(spacing: 14) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(Color(red: 0.95, green: 0.65, blue: 0.20))

                                Text("Sorry, we could not match that API key to a provider. Please make sure you have the right key, and/or attempt to find the provider.")
                                    .font(.system(size: 13))
                                    .foregroundColor(DS.textMuted)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(2)

                                HStack(spacing: 10) {
                                    Button(action: {
                                        detectionFailed = false
                                        showManualPicker = true
                                    }) {
                                        Text("Select Provider")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(DS.accent)
                                            )
                                    }
                                    .buttonStyle(.plain)

                                    Button(action: {
                                        showDetection = false
                                        detectionFailed = false
                                        apiKeySaved = false
                                        detectionProgress = 0.0
                                    }) {
                                        Text("Dismiss")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(DS.textMuted)
                                            .padding(.horizontal, 16)
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
                            .padding(24)
                        } else {
                            // Detecting state — progress bar + question
                            VStack(spacing: 16) {
                                // 10-second progress bar
                                VStack(spacing: 6) {
                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color.white.opacity(0.08))
                                                .frame(height: 6)

                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(
                                                    LinearGradient(
                                                        colors: [DS.accent, Color(red: 0.55, green: 0.35, blue: 0.85)],
                                                        startPoint: .leading, endPoint: .trailing
                                                    )
                                                )
                                                .frame(width: geo.size.width * detectionProgress, height: 6)
                                        }
                                    }
                                    .frame(height: 6)
                                }

                                if clickedNo {
                                    // User clicked No — show scanning message
                                    Text("Please wait while we scan for possible providers")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(DS.text)
                                        .multilineTextAlignment(.center)

                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(DS.textMuted)
                                } else {
                                    // Initial state — asking the question
                                    Text("Attempting to determine API provider")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(DS.text)
                                        .multilineTextAlignment(.center)

                                    Divider()
                                        .background(DS.border)
                                        .padding(.horizontal, 8)

                                    Text("Do you know which AI provider this key is from?")
                                        .font(.system(size: 13))
                                        .foregroundColor(DS.textMuted)
                                        .multilineTextAlignment(.center)

                                    HStack(spacing: 12) {
                                        Button(action: {
                                            showManualPicker = true
                                        }) {
                                            Text("Yes")
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 24)
                                                .padding(.vertical, 8)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .fill(DS.accent)
                                                )
                                        }
                                        .buttonStyle(.plain)

                                        Button(action: {
                                            clickedNo = true
                                        }) {
                                            Text("No")
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundColor(DS.textMuted)
                                                .padding(.horizontal, 24)
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
                            .onAppear {
                                detectionProgress = 0.0
                                clickedNo = false
                                withAnimation(.linear(duration: 10)) {
                                    detectionProgress = 1.0
                                }
                            }
                        }
                    }
                    .frame(width: 320)
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
                .animation(.easeInOut(duration: 0.2), value: showDetection)
            }
        }
    }

    // MARK: - Local Model Row

    private var localModelRow: some View {
        let isSelected = state.wantsLocalModel

        return Button(action: { state.wantsLocalModel.toggle() }) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.55, green: 0.35, blue: 0.85).opacity(0.15),
                                    Color(red: 0.35, green: 0.75, blue: 0.85).opacity(0.15)
                                ],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)

                    Image(systemName: "desktopcomputer")
                        .font(.system(size: 18))
                        .foregroundColor(Color(red: 0.55, green: 0.35, blue: 0.85))
                }

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text("Local Models")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(DS.text)

                    Text("Run models on your own hardware via Ollama")
                        .font(.system(size: 12))
                        .foregroundColor(DS.textMuted)
                }

                Spacer()

                // Checkbox
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected ? DS.accent : Color.clear)
                        .frame(width: 22, height: 22)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(isSelected ? DS.accent : DS.border, lineWidth: 1.5)
                        )

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(localModelHovered ? DS.surfaceHover : Color.black.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? DS.accent.opacity(0.4) : DS.border, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { localModelHovered = $0 }
    }

    // MARK: - API Key Row

    private var apiKeyRow: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.85, green: 0.55, blue: 0.20).opacity(0.15),
                                    Color(red: 0.95, green: 0.75, blue: 0.30).opacity(0.15)
                                ],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)

                    Image(systemName: "key.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color(red: 0.85, green: 0.65, blue: 0.25))
                }

                // Label
                VStack(alignment: .leading, spacing: 2) {
                    Text("API Key")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(DS.text)
                    Text("Paste a key from any provider")
                        .font(.system(size: 12))
                        .foregroundColor(DS.textMuted)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            // Input field
            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 11))
                        .foregroundColor(DS.textDim)

                    SecureField("sk-...", text: $directAPIKey)
                        .font(.system(size: 13, design: .monospaced))
                        .textFieldStyle(.plain)
                        .foregroundColor(DS.text)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.25))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(DS.border, lineWidth: 1)
                        )
                )

                // Save button
                Button(action: {
                    guard !directAPIKey.isEmpty else { return }
                    state.directAPIKey = directAPIKey
                    apiKeySaved = true
                    showDetection = true
                    // Auto-detection timeout — 10 seconds
                    // TODO: Replace with real API provider detection logic.
                    // If real detection succeeds before timeout, set detectedProvider and it auto-closes.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                        // Only timeout if still detecting (no provider found, not manually picking)
                        if showDetection && detectedProvider == nil && !showManualPicker {
                            detectionFailed = true
                        }
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: apiKeySaved ? "checkmark.circle.fill" : "square.and.arrow.down")
                            .font(.system(size: 12))
                        Text(apiKeySaved ? "Saved" : "Save")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(apiKeySaved ? .green : (directAPIKey.isEmpty ? DS.textDim : DS.accent))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black.opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(apiKeySaved ? Color.green.opacity(0.3) : DS.border, lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
                .disabled(directAPIKey.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(apiKeyHovered ? DS.surfaceHover : Color.black.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(!directAPIKey.isEmpty ? DS.accent.opacity(0.4) : DS.border, lineWidth: 1)
                )
        )
        .onHover { apiKeyHovered = $0 }
    }
}

struct OAuthServiceRow: View {
    let service: ConsumerAI
    @State private var isHovered = false
    @State private var showPopover = false

    private var status: OAuthAvailability { service.oauthStatus }

    var body: some View {
        HStack(spacing: 14) {
            // Service icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: service.gradientColors.map { $0.opacity(0.15) },
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)

                Image(systemName: service.icon)
                    .font(.system(size: 18))
                    .foregroundColor(service.iconColor)
            }

            // Info — subtitle resolved from volatile conditionals
            VStack(alignment: .leading, spacing: 2) {
                Text("\(service.productName) by \(service.companyName)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DS.text)

                Text(service.oauthSubtitle)
                    .font(.system(size: 12))
                    .foregroundColor(DS.textMuted)
            }

            Spacer()

            // Right-side actions — varies by status
            oauthActions
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isHovered ? DS.surfaceHover : Color.black.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(DS.border, lineWidth: 1)
                )
        )
        .onHover { isHovered = $0 }
    }

    @ViewBuilder
    private var oauthActions: some View {
        switch status {
        case .available:
            Button(action: { /* TODO: trigger OAuth flow */ }) {
                HStack(spacing: 5) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 12))
                    Text("Log In")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [DS.accent3, Color(red: 0.18, green: 0.83, blue: 0.75)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                )
                .shadow(color: DS.accent3.opacity(0.3), radius: 6, y: 2)
            }
            .buttonStyle(.plain)

        case .comingSoon:
            HStack(spacing: 8) {
                Text("Coming Soon")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.5)
                    .foregroundColor(status.labelColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(status.bgColor.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(status.bgColor.opacity(0.15), lineWidth: 1)
                            )
                    )

                Button(action: {}) {
                    Text("Log In")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(DS.textMuted)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.04))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(DS.border, lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)
                .disabled(true)
                .opacity(0.5)
            }

        case .unavailable:
            HStack(spacing: 6) {
                Text("Unavailable")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.5)
                    .foregroundColor(DS.textMuted)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.04))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(DS.border, lineWidth: 1)
                            )
                    )

                Button(action: { showPopover.toggle() }) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 15))
                        .foregroundColor(DS.textDim)
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showPopover, arrowEdge: .bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.orange)
                            Text("Not Available")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        Text("This AI provider is not configurable this way, likely due to it being against their TOS (terms of service).")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(14)
                    .frame(width: 260)
                }
            }
        }
    }
}

// MARK: - API Key Guide Step (Consumer Path intermediary)

struct APIKeyGuideStep: View {
    @EnvironmentObject var state: SetupState
    @State private var showAPIInfo = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            stepIcon("key.viewfinder")

            // Title with info button
            HStack(alignment: .center, spacing: 8) {
                stepTitle("Get Your API Key")

                Button(action: { showAPIInfo.toggle() }) {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(DS.textDim)
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showAPIInfo, arrowEdge: .bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What is an API Key?")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)

                        Text("An Application-Program Interface (API) key is a long password-like object that allows you to send and receive data between two apps. It is what allows your AI agent to have a raw data stream between the agent and an AI provider company like Google/OpenAI etc...")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.8))
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(14)
                    .frame(width: 300)
                    .background(Color(red: 0.12, green: 0.13, blue: 0.18))
                }
            }

            stepDesc("Follow these steps to create an API key for your provider, then paste it below.")

            ScrollView {
                VStack(spacing: 14) {
                    ForEach(Array(state.selectedServices.sorted(by: { $0.rawValue < $1.rawValue })), id: \.self) { service in
                        APIKeyGuideCard(service: service)
                    }

                    // If they somehow have no services selected
                    if state.selectedServices.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "arrow.backward.circle")
                                .font(.system(size: 24))
                                .foregroundColor(DS.textDim)
                            Text("Go back and select at least one provider.")
                                .font(.system(size: 14))
                                .foregroundColor(DS.textMuted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 20)
                    }
                }
            }
            .frame(maxHeight: .infinity)

            // Footer hint
            HStack {
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 12))
                    Text("You can always add more providers later!")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(DS.textMuted)
                Spacer()
            }
            .padding(.top, 14)
            .padding(.bottom, 4)

            Spacer()
        }
        .padding(.horizontal, 40)
        .padding(.top, 32)
    }
}

struct APIKeyGuideCard: View {
    let service: ConsumerAI
    @EnvironmentObject var state: SetupState
    @State private var isExpanded = true
    @State private var showSavedCheck = false

    private var keyBinding: Binding<String> {
        Binding(
            get: { state.serviceAPIKeys[service] ?? "" },
            set: { state.serviceAPIKeys[service] = $0 }
        )
    }

    private var isSaved: Bool {
        state.savedServiceKeys.contains(service)
    }

    private var hasKey: Bool {
        !(state.serviceAPIKeys[service] ?? "").trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() } }) {
                HStack(spacing: 12) {
                    // Provider icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    colors: service.gradientColors.map { $0.opacity(0.2) },
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 36, height: 36)

                        Image(systemName: service.icon)
                            .font(.system(size: 16))
                            .foregroundColor(service.iconColor)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 8) {
                            Text("\(service.productName) API Key")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(DS.text)

                            if isSaved {
                                HStack(spacing: 3) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 10))
                                    Text("Saved")
                                        .font(.system(size: 10, weight: .bold))
                                        .tracking(0.3)
                                }
                                .foregroundColor(DS.accent3)
                                .transition(.opacity.combined(with: .scale(scale: 0.8)))
                            }
                        }

                        Text(service.apiKeyURL)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(DS.accent)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(DS.textMuted)
                }
            }
            .buttonStyle(.plain)
            .padding(14)

            // Steps + key input
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    // Instruction steps
                    stepsView

                    // Divider
                    Rectangle()
                        .fill(DS.border)
                        .frame(height: 1)
                        .padding(.vertical, 4)

                    // API key input + save button
                    keyInputRow
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(cardBackground)
        .animation(.easeInOut(duration: 0.2), value: isSaved)
    }

    private var stepsView: some View {
        ForEach(Array(service.apiKeySteps.enumerated()), id: \.offset) { idx, step in
            HStack(alignment: .top, spacing: 10) {
                ZStack {
                    Circle()
                        .fill(DS.accent.opacity(0.12))
                        .frame(width: 22, height: 22)
                    Text(String(idx + 1))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(DS.accent)
                }

                Text(step)
                    .font(.system(size: 13))
                    .foregroundColor(DS.text)
                    .lineSpacing(2)
            }
        }
    }

    private var keyInputRow: some View {
        HStack(spacing: 10) {
            // Text field
            HStack(spacing: 8) {
                Image(systemName: "key.fill")
                    .font(.system(size: 12))
                    .foregroundColor(isSaved ? DS.accent3 : DS.textDim)

                SecureField("Paste your \(service.productName) API key…", text: keyBinding)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(DS.text)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black.opacity(0.25))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(fieldBorderColor, lineWidth: 1)
                    )
            )

            // Save button
            saveButton
        }
    }

    private var fieldBorderColor: Color {
        if isSaved { return DS.accent3.opacity(0.4) }
        if hasKey { return DS.accent.opacity(0.3) }
        return DS.border.opacity(1)
    }

    private var saveButtonBG: Color {
        if isSaved { return DS.accent3.opacity(0.12) }
        if hasKey { return DS.accent.opacity(0.8) }
        return Color.white.opacity(0.06)
    }

    private var saveButton: some View {
        Button(action: {
            state.saveServiceKey(service)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showSavedCheck = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation { showSavedCheck = false }
            }
        }) {
            HStack(spacing: 5) {
                Image(systemName: isSaved ? "checkmark" : "square.and.arrow.down")
                    .font(.system(size: 11, weight: .semibold))
                Text(isSaved ? "Saved" : "Save")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(isSaved ? DS.accent3 : .white)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(saveButtonBG)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                isSaved ? DS.accent3.opacity(0.25) : Color.clear,
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(!hasKey)
        .opacity(hasKey || isSaved ? 1 : 0.4)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(Color.black.opacity(0.15))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSaved ? DS.accent3.opacity(0.25) : DS.border, lineWidth: 1)
            )
    }
}

// MARK: - API Provider Step (API Key Path)

struct APIProviderStep: View {
    @EnvironmentObject var state: SetupState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            stepIcon("key.fill")
            stepTitle("Choose Your API Provider")
            stepDesc("Select the provider whose API key you have. NeuralClaw will use this to power its reasoning engine.")

            // Provider grid — 3 columns for 5 providers (3+2)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                ForEach(AIProvider.allCases) { provider in
                    ProviderCard(
                        provider: provider,
                        isSelected: state.provider == provider,
                        onSelect: { state.selectProvider(provider) }
                    )
                }
            }

            Spacer()
        }
        .padding(.horizontal, 40)
        .padding(.top, 32)
    }
}

struct ProviderCard: View {
    let provider: AIProvider
    let isSelected: Bool
    let onSelect: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(provider.label)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(DS.text)

                        Text(provider.desc)
                            .font(.system(size: 11))
                            .foregroundColor(DS.textMuted)
                            .lineLimit(1)
                    }

                    Spacer()

                    Image(systemName: provider.icon)
                        .font(.system(size: 18))
                        .foregroundColor(provider.iconColor)
                }

                // Badge
                Text(provider.needsKey ? "API KEY" : "FREE")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.5)
                    .foregroundColor(provider.needsKey ? DS.accent : DS.accent3)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(provider.needsKey
                                  ? DS.accent.opacity(0.15) : DS.accent3.opacity(0.15))
                    )
                    .padding(.top, 4)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? DS.accent.opacity(0.06)
                          : (isHovered ? DS.surfaceHover : Color.black.opacity(0.2)))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? DS.accent : DS.border, lineWidth: 1)
                    )
            )
            .shadow(color: isSelected ? DS.accent.opacity(0.15) : .clear, radius: 8)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
