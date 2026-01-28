//
//  TopActionButton.swift
//  BasicAVCamera
//
//  Created by Sercan Şahan on 28.01.2026.
//

import SwiftUI

enum TopAction {
    case back
    case save
}

struct TopActionButton: View {
    let type: TopAction
    let action: () -> Void
    @State private var saved: Bool = false

    init(_ type: TopAction, action: @escaping () -> Void) {
        self.type = type
        self.action = action
    }

    var body: some View {
        Group {
            if #available(iOS 26.0, *) {
                modernButton
            } else {
                legacyButton
            }
        }
    }
}

@available(iOS 26.0, *)
private extension TopActionButton {
    var modernButton: some View {
        Button {
            handleTap()
        } label: {
            Image(systemName: modernIconName)
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 36, height: 36)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .accessibilityLabel(accessibilityLabel)
    }

    var modernIconName: String {
        switch type {
        case .back:
            return "chevron.backward"
        case .save:
            return saved ? "checkmark" : "square.and.arrow.down"
        }
    }
}


private extension TopActionButton {
    var legacyButton: some View {
        Button {
            handleTap()
        } label: {
            switch type {
            case .back:
                HStack(spacing: 6) {
                    Image(systemName: "chevron.backward")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 18))
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())

            case .save:
                HStack(spacing: 6) {
                    Image(systemName: saved ? "checkmark" : "square.and.arrow.down")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Save")
                        .font(.system(size: 18, weight: .semibold))
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
        .accessibilityLabel(accessibilityLabel)
    }
}


private extension TopActionButton {
    func handleTap() {
        action()
        guard type == .save else { return }
        saved = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            saved = false
        }
    }

    var accessibilityLabel: String {
        switch type {
        case .back:
            return "Back"
        case .save:
            return saved ? "Saved" : "Save"
        }
    }
}

