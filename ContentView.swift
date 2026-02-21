//
//  ContentView.swift
//  Oil & Gas Landman Calculator
//
//  A single-file SwiftUI iOS application using MVVM architecture
//  for fractional ownership calculations in oil and gas leasing.
//
//  Target: iOS 17+, Swift, SwiftUI
//

import SwiftUI

// MARK: - ViewModel (Calculation Engine)

@Observable
final class LandmanCalculatorViewModel {

    // MARK: String Inputs (bound to TextFields for real-time typing)

    var grossAcresInput: String = ""
    var mineralInterestInput: String = ""
    var royaltyRateInput: String = ""
    var bonusPerAcreInput: String = ""

    // MARK: Fraction & Decimal Parser

    /// Parses a string that may be a fraction (e.g. "3/16"), a decimal (e.g. "0.1875"),
    /// or a whole number (e.g. "640") into a precise Double value.
    /// Returns nil for invalid input such as empty strings, letters, or divide-by-zero.
    static func parseNumericInput(_ input: String) -> Double? {
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        // Check if the input contains a fraction slash
        if trimmed.contains("/") {
            let parts = trimmed.split(separator: "/")
            guard parts.count == 2,
                  let numerator = Double(parts[0].trimmingCharacters(in: .whitespaces)),
                  let denominator = Double(parts[1].trimmingCharacters(in: .whitespaces)),
                  denominator != 0
            else {
                return nil
            }
            return numerator / denominator
        }

        // Otherwise, parse as a standard decimal or integer
        return Double(trimmed)
    }

    // MARK: Parsed Values

    var grossAcres: Double? {
        Self.parseNumericInput(grossAcresInput)
    }

    var mineralInterest: Double? {
        Self.parseNumericInput(mineralInterestInput)
    }

    var royaltyRate: Double? {
        Self.parseNumericInput(royaltyRateInput)
    }

    var bonusPerAcre: Double? {
        Self.parseNumericInput(bonusPerAcreInput)
    }

    // MARK: Calculated Results

    /// Net Acres = Gross Acres * Mineral Interest
    var netAcres: Double? {
        guard let ga = grossAcres, let mi = mineralInterest else { return nil }
        return ga * mi
    }

    /// Total Bonus = Net Acres * Bonus per Acre
    var totalBonus: Double? {
        guard let na = netAcres, let bpa = bonusPerAcre else { return nil }
        return na * bpa
    }

    /// Net Revenue Interest (NRI) = Mineral Interest * Royalty Rate
    var netRevenueInterest: Double? {
        guard let mi = mineralInterest, let rr = royaltyRate else { return nil }
        return mi * rr
    }

    // MARK: Formatted Output Strings

    /// Formats Net Acres to 8 decimal places for oil & gas accounting fidelity.
    var formattedNetAcres: String {
        guard let value = netAcres else { return "-" }
        return String(format: "%.8f", value)
    }

    /// Formats Total Bonus as US Currency (e.g. "$1,234.56").
    var formattedTotalBonus: String {
        guard let value = totalBonus else { return "-" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US")
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    /// Formats NRI to 8 decimal places for oil & gas accounting fidelity.
    var formattedNRI: String {
        guard let value = netRevenueInterest else { return "-" }
        return String(format: "%.8f", value)
    }

    // MARK: Input Validity Indicators

    var isGrossAcresValid: Bool {
        grossAcresInput.isEmpty || grossAcres != nil
    }

    var isMineralInterestValid: Bool {
        mineralInterestInput.isEmpty || mineralInterest != nil
    }

    var isRoyaltyRateValid: Bool {
        royaltyRateInput.isEmpty || royaltyRate != nil
    }

    var isBonusPerAcreValid: Bool {
        bonusPerAcreInput.isEmpty || bonusPerAcre != nil
    }

    /// Returns true when all four fields have valid, non-empty input.
    var allInputsProvided: Bool {
        grossAcres != nil && mineralInterest != nil && royaltyRate != nil && bonusPerAcre != nil
    }

    // MARK: Reset

    func clearAll() {
        grossAcresInput = ""
        mineralInterestInput = ""
        royaltyRateInput = ""
        bonusPerAcreInput = ""
    }
}

// MARK: - View (User Interface)

struct ContentView: View {
    @State private var viewModel = LandmanCalculatorViewModel()

    var body: some View {
        NavigationStack {
            Form {
                inputSection
                resultsSection
                clearSection
            }
            .navigationTitle("Landman Calculator")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: Input Section

    private var inputSection: some View {
        Section {
            ValidatedInputRow(
                label: "Gross Acres",
                placeholder: "e.g. 640 or 320.5",
                text: $viewModel.grossAcresInput,
                isValid: viewModel.isGrossAcresValid
            )

            ValidatedInputRow(
                label: "Mineral Interest (MI)",
                placeholder: "e.g. 0.5 or 1/2",
                text: $viewModel.mineralInterestInput,
                isValid: viewModel.isMineralInterestValid
            )

            ValidatedInputRow(
                label: "Royalty Rate",
                placeholder: "e.g. 3/16 or 0.1875",
                text: $viewModel.royaltyRateInput,
                isValid: viewModel.isRoyaltyRateValid
            )

            ValidatedInputRow(
                label: "Bonus per Acre",
                placeholder: "e.g. 500 or 1250.00",
                text: $viewModel.bonusPerAcreInput,
                isValid: viewModel.isBonusPerAcreValid
            )
        } header: {
            Text("Ownership Inputs")
        } footer: {
            Text("Fractions (e.g. 3/16) and decimals (e.g. 0.1875) are both accepted.")
                .font(.caption2)
        }
    }

    // MARK: Results Section

    private var resultsSection: some View {
        Section {
            if viewModel.allInputsProvided {
                ResultRow(
                    label: "Net Acres",
                    value: viewModel.formattedNetAcres,
                    valueColor: .primary
                )

                ResultRow(
                    label: "Total Bonus",
                    value: viewModel.formattedTotalBonus,
                    valueColor: .green
                )

                ResultRow(
                    label: "Net Revenue Interest (NRI)",
                    value: viewModel.formattedNRI,
                    valueColor: .blue
                )
            } else {
                Text("Enter all four inputs above to see results.")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            }
        } header: {
            Text("Calculated Results")
        } footer: {
            if viewModel.allInputsProvided {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Net Acres = Gross Acres \u{00D7} MI")
                    Text("Total Bonus = Net Acres \u{00D7} Bonus/Acre")
                    Text("NRI = MI \u{00D7} Royalty Rate")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: Clear Section

    private var clearSection: some View {
        Section {
            Button(role: .destructive) {
                withAnimation {
                    viewModel.clearAll()
                }
            } label: {
                HStack {
                    Spacer()
                    Label("Clear All Fields", systemImage: "trash")
                        .font(.body.weight(.medium))
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Reusable Subviews

/// A labeled text field row with a validation indicator.
struct ValidatedInputRow: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    let isValid: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                TextField(placeholder, text: $text)
                    .keyboardType(.numbersAndPunctuation)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                if !text.isEmpty {
                    Image(systemName: isValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(isValid ? .green : .red)
                        .font(.body)
                        .accessibilityLabel(isValid ? "Valid input" : "Invalid input")
                }
            }
        }
        .padding(.vertical, 2)
    }
}

/// A labeled result row with a styled value display.
struct ResultRow: View {
    let label: String
    let value: String
    let valueColor: Color

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.system(.body, design: .monospaced).weight(.semibold))
                .foregroundStyle(valueColor)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
