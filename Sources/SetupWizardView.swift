import SwiftUI

// MARK: - Root Wizard View

struct SetupWizardView: View {
    @StateObject private var state = SetupState()

    var body: some View {
        ZStack {
            // Background
            DS.bg.ignoresSafeArea()
            backgroundMesh

            VStack(spacing: 0) {
                // Progress bar
                progressBar

                // Stepper dots
                stepperDots

                // Content area
                ZStack {
                    AIUsageStep()
                        .opacity(state.currentPage == .aiUsage ? 1 : 0)
                        .offset(x: pageOffset(for: .aiUsage))

                    OAuthInfoStep()
                        .opacity(state.currentPage == .oauthInfo ? 1 : 0)
                        .offset(x: pageOffset(for: .oauthInfo))

                    APIKeyGuideStep()
                        .opacity(state.currentPage == .apiKeyGuide ? 1 : 0)
                        .offset(x: pageOffset(for: .apiKeyGuide))

                    APIProviderStep()
                        .opacity(state.currentPage == .apiProvider ? 1 : 0)
                        .offset(x: pageOffset(for: .apiProvider))

                    APIConfigStep()
                        .opacity(state.currentPage == .apiConfig ? 1 : 0)
                        .offset(x: pageOffset(for: .apiConfig))

                    DoneStep()
                        .opacity(state.currentPage == .done ? 1 : 0)
                        .offset(x: pageOffset(for: .done))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()

                // Footer navigation (hidden on aiUsage, apiConfig, and done)
                if state.currentPage != .aiUsage && state.currentPage != .apiConfig && state.currentPage != .done {
                    footerNav
                }
            }
        }
        .environmentObject(state)
    }

    private func pageOffset(for page: WizardPage) -> CGFloat {
        let seq = state.pageSequence
        guard let pageIdx = seq.firstIndex(of: page),
              let currentIdx = seq.firstIndex(of: state.currentPage) else {
            // Page not in current sequence — push it off-screen
            return page == state.currentPage ? 0 : 40
        }
        if pageIdx == currentIdx { return 0 }
        return pageIdx < currentIdx ? -40 : 40
    }

    // MARK: - Background

    private var backgroundMesh: some View {
        ZStack {
            Circle()
                .fill(DS.accent.opacity(0.06))
                .frame(width: 400, height: 400)
                .blur(radius: 80)
                .offset(x: -200, y: -180)

            Circle()
                .fill(DS.accent2.opacity(0.05))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: 200, y: 180)

            Circle()
                .fill(DS.accent3.opacity(0.03))
                .frame(width: 200, height: 200)
                .blur(radius: 60)
                .offset(x: 50, y: 50)
        }
        .ignoresSafeArea()
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.white.opacity(0.04))
                Rectangle()
                    .fill(DS.accentGradient)
                    .frame(width: geo.size.width * state.progressFraction)
                    .animation(.spring(response: 0.5, dampingFraction: 0.85), value: state.currentPage)
            }
        }
        .frame(height: 3)
    }

    // MARK: - Stepper

    private var stepperDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<state.totalSteps, id: \.self) { i in
                RoundedRectangle(cornerRadius: 4)
                    .fill(dotColor(for: i))
                    .frame(width: i == state.currentStepIndex ? 24 : 8, height: 8)
                    .shadow(color: i == state.currentStepIndex ? DS.accent.opacity(0.4) : .clear, radius: 6)
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: state.currentPage)
                    .onTapGesture { state.goTo(i) }
            }
        }
        .padding(.top, 20)
    }

    private func dotColor(for step: Int) -> Color {
        if step == state.currentStepIndex { return DS.accent }
        if step < state.currentStepIndex { return DS.accent3 }
        return DS.textDim
    }

    // MARK: - Footer

    private var footerNav: some View {
        HStack {
            Text("Step \(state.currentStepIndex + 1) of \(state.totalSteps)")
                .font(.system(size: 12))
                .foregroundColor(DS.textDim)

            Spacer()

            HStack(spacing: 10) {
                // Back button
                Button(action: state.goBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 10, weight: .bold))
                        Text("Back")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(DS.textMuted)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(DS.border, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                // Next / Launch button
                Button(action: state.goNext) {
                    HStack(spacing: 6) {
                        Text(nextButtonLabel)
                        if !state.isLastPage {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .bold))
                        }
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(state.isLastPage
                                  ? AnyShapeStyle(DS.successGradient)
                                  : AnyShapeStyle(DS.accentGradient))
                    )
                    .shadow(color: DS.accent.opacity(0.3), radius: 8, y: 4)
                }
                .buttonStyle(.plain)
                .disabled(state.isSaving)
            }
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 16)
    }

    private var nextButtonLabel: String {
        if state.isLastPage {
            if state.isSaving { return "⏳ Saving..." }
            if state.saveComplete { return "✓ Saved!" }
            return "🚀 Launch NeuralClaw"
        }
        return "Continue"
    }
}
