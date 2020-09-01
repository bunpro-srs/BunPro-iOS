//
//  Created by Andreas Braun on 30.06.20.
//  Copyright © 2020 Andreas Braun. All rights reserved.
//

import Foundation
import SwiftUI

struct LevelButton: View {
    var level: Level

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill()
                .layoutPriority(1)
                .frame(minWidth: 10, minHeight: 10)
                .foregroundColor(Color(.secondarySystemFill))

            VStack(alignment: .leading) {
                HStack {
                    VStack {
                        ZStack {
                            ProgressCircle(value: level.progress, maxValue: 1.0, lineWidth: 10)
                                .frame(width: 75, height: 75, alignment: .center)
                            Text(percentNumberFormatter().string(from: NSNumber(value: level.progress)) ?? "")
                                .font(.system(size: 19))
                        }
                        Text("\(level.completedGrammar)/\(level.totalGrammar)")
                            .font(.system(size: 14))
                    }

                    Spacer()
                    VStack {
                        Spacer()
                        Text(level.name)
                            .font(.title)
                            .foregroundColor(.primary)
                    }
                }
                .padding(8)
            }
        }
//        .frame(height: 100)
    }

    private func percentNumberFormatter() -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        return formatter
    }
}

struct ProgressCircle: View {
    enum Stroke {
        case line
        case dotted

        func strokeStyle(lineWidth: CGFloat) -> StrokeStyle {
            switch self {
            case .line:
                return StrokeStyle(
                    lineWidth: lineWidth,
                    lineCap: .round
                )

            case .dotted:
                return StrokeStyle(
                    lineWidth: lineWidth,
                    lineCap: .round,
                    dash: [12]
                )
            }
        }
    }

    private let value: Double
    private let maxValue: Double
    private let style: Stroke
    private let backgroundEnabled: Bool
    private let backgroundColor: Color
    private let foregroundColor: Color
    private let lineWidth: CGFloat

    init(
        value: Double,
        maxValue: Double,
        style: Stroke = .line,
        backgroundEnabled: Bool = true,
        backgroundColor: Color = Color(UIColor.systemBackground),
        foregroundColor: Color = Color.accentColor,
        lineWidth: CGFloat = 10
    ) {
        self.value = value
        self.maxValue = maxValue
        self.style = style
        self.backgroundEnabled = backgroundEnabled
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.lineWidth = lineWidth
    }

    var body: some View {
        ZStack {
            if self.backgroundEnabled {
                Circle()
                    .stroke(lineWidth: self.lineWidth)
                    .foregroundColor(self.backgroundColor)
            }

            Circle()
                .trim(from: 0, to: CGFloat(self.value / self.maxValue))
                .stroke(style: self.style.strokeStyle(lineWidth: self.lineWidth))
                .foregroundColor(self.foregroundColor)
                .rotationEffect(Angle(degrees: -90))
                .animation(.easeIn)
        }
        .padding(lineWidth / 2)
    }
}

struct LevelView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LevelButton(level: Level(name: "All", completedGrammar: 40, totalGrammar: 100))
                .padding()

            LevelButton(level: Level(name: "All", completedGrammar: 40, totalGrammar: 100))
                .preferredColorScheme(.dark)
                .padding()

            Group {
                LevelButton(level: Level(name: "All", completedGrammar: 40, totalGrammar: 100))
                    .environment(\.sizeCategory, .extraSmall)
                    .padding()
                LevelButton(level: Level(name: "All", completedGrammar: 40, totalGrammar: 100))
                    .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
                    .padding()
            }
        }
        .previewLayout(.sizeThatFits)
    }
}
