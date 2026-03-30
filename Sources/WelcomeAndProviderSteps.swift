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

// MARK: - OAuth Info Step (Consumer Path)

struct OAuthInfoStep: View {
    @EnvironmentObject var state: SetupState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            stepIcon("link")
            stepTitle("Connect Your Accounts")
            stepDesc("Here's how NeuralClaw can connect with the services you use. Log in to authorize NeuralClaw to work on your behalf.")

            VStack(spacing: 10) {
                ForEach(ConsumerAI.allCases) { service in
                    let isSelected = state.selectedServices.contains(service)
                    if isSelected {
                        OAuthServiceRow(service: service)
                    }
                }

                // If nothing is selected (shouldn't happen, but safety)
                if state.selectedServices.isEmpty {
                    Text("No services selected.")
                        .font(.system(size: 14))
                        .foregroundColor(DS.textMuted)
                        .padding(.top, 10)
                }
            }

            Spacer()

            // Bottom hint link
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
        }
        .padding(.horizontal, 40)
        .padding(.top, 32)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            stepIcon("key.viewfinder")
            stepTitle("Get Your API Key")
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
