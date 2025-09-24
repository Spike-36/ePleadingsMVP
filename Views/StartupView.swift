//
//  StartupView.swift
//  ePleadingsMVP
//
//  Created by Peter Milligan on 24/09/2025.
//

//
//  StartupView.swift
//  ePleadingsMVP
//
//  A startup screen like Word: open an existing case or create a new one.
//

import SwiftUI

struct StartupView: View {
    @ObservedObject var caseManager = CaseManager.shared
    @State private var newCaseName: String = ""
    @State private var errorMessage: String?

    var body: some View {
        HStack {
            // LEFT: Existing cases
            VStack(alignment: .leading, spacing: 12) {
                Text("Recent Cases")
                    .font(.headline)

                if caseManager.cases.isEmpty {
                    Text("No cases yet")
                        .foregroundColor(.secondary)
                } else {
                    List(caseManager.cases) { caseInfo in
                        Button {
                            caseManager.openCase(caseInfo)
                        } label: {
                            HStack {
                                Image(systemName: "folder")
                                Text(caseInfo.displayName)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .frame(minWidth: 200, maxHeight: .infinity)
                }

                Spacer()
            }
            .padding()
            .frame(minWidth: 250)

            Divider()

            // RIGHT: Create new case
            VStack(alignment: .leading, spacing: 16) {
                Text("Create New Case")
                    .font(.headline)

                TextField("Enter case name", text: $newCaseName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 250)

                Button("Create") {
                    createCase()
                }
                .keyboardShortcut(.defaultAction)

                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                Spacer()
            }
            .padding()
            .frame(minWidth: 300)

        }
        .frame(minWidth: 600, minHeight: 400)
    }

    private func createCase() {
        guard !newCaseName.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Case name cannot be empty."
            return
        }

        do {
            try caseManager.createCase(named: newCaseName)
            if let created = caseManager.cases.first(where: { $0.displayName == newCaseName }) {
                caseManager.openCase(created)
            }
            newCaseName = ""
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
