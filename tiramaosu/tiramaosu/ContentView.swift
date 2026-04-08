//
//  ContentView.swift
//  tiramaosu
//
//  Created by vyx on 2026-04-07.
//

import SwiftUI
import Combine

struct TimerSlot: Identifiable {
    let id = UUID()
    var name: String
    var minutes: Int

    var totalSeconds: Int {
        max(minutes, 1) * 60
    }
}

struct ContentView: View {
    @State private var slots = [
        TimerSlot(name: "Work", minutes: 15),
        TimerSlot(name: "Break", minutes: 5)
    ]
    @State private var activeSlot = 0
    @State private var secondsLeft = 15 * 60
    @State private var isRunning = false
    @State private var isEditingTimer = false
    @State private var isHoveringOverlay = false

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(alignment: .center, spacing: -8) {
            Image(isHoveringOverlay ? "sleep-hover" : "sleep")
                .resizable()
                .scaledToFit()
                .frame(width: 235, height: 205)

            MinecraftTimerSign(
                title: slots[activeSlot].name,
                time: formattedTime(secondsLeft),
                isRunning: isRunning
            )
            .frame(width: 270, height: 205)
            .onTapGesture(count: 2) {
                isRunning = false
                isEditingTimer = true
            }
            .popover(isPresented: $isEditingTimer, arrowEdge: .bottom) {
                editPopup
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(width: 520, height: 260)
        .background(Color.clear)
        .contentShape(Rectangle())
        .onHover { isHovering in
            isHoveringOverlay = isHovering
        }
        .onReceive(ticker) { _ in
            tick()
        }
    }

    private var editPopup: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Edit Timer")
                .font(.headline)

            Picker("Timer", selection: $activeSlot) {
                ForEach(slots.indices, id: \.self) { index in
                    Text(slots[index].name).tag(index)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: activeSlot) { _, newSlot in
                isRunning = false
                secondsLeft = slots[newSlot].totalSeconds
            }

            ForEach($slots) { $slot in
                HStack {
                    Text(slot.name)
                        .frame(width: 52, alignment: .leading)

                    Stepper("\(slot.minutes) min", value: $slot.minutes, in: 1...120)
                }
            }

            HStack {
                Button(isRunning ? "Pause" : "Start") {
                    isRunning.toggle()
                    isEditingTimer = false
                }

                Button("Reset") {
                    resetTimer()
                    isEditingTimer = false
                }

                Button("Apply") {
                    resetTimer()
                    isEditingTimer = false
                }
            }
        }
        .padding(18)
        .frame(width: 260)
    }

    private func tick() {
        guard isRunning, !isEditingTimer else {
            return
        }

        if secondsLeft > 1 {
            secondsLeft -= 1
        } else {
            activeSlot = (activeSlot + 1) % slots.count
            secondsLeft = slots[activeSlot].totalSeconds
        }
    }

    private func resetTimer() {
        isRunning = false
        secondsLeft = slots[activeSlot].totalSeconds
    }

    private func formattedTime(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    ContentView()
}

struct MinecraftTimerSign: View {
    let title: String
    let time: String
    let isRunning: Bool

    var body: some View {
        ZStack(alignment: .top) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.43, green: 0.31, blue: 0.16),
                            Color(red: 0.30, green: 0.22, blue: 0.12)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 32, height: 134)
                .offset(y: 62)
                .pixelBlocks([
                    PixelBlock(x: 0.10, y: 0.18, w: 0.45, h: 0.15, color: Color.black.opacity(0.16)),
                    PixelBlock(x: 0.52, y: 0.48, w: 0.38, h: 0.14, color: Color.black.opacity(0.22)),
                    PixelBlock(x: 0.08, y: 0.74, w: 0.50, h: 0.13, color: Color.black.opacity(0.24))
                ])

            SignBoard()
                .frame(width: 245, height: 118)

            VStack(spacing: 4) {
                Text(title.uppercased())
                    .font(.system(size: 16, weight: .black, design: .monospaced))
                    .foregroundStyle(.black.opacity(0.70))

                Text(time)
                    .font(.system(size: 38, weight: .heavy, design: .monospaced))
                    .monospacedDigit()
                    .foregroundStyle(.black.opacity(0.82))

                Text(isRunning ? "RUNNING" : "PAUSED")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundStyle(.black.opacity(0.56))
            }
            .padding(.top, 20)
            .frame(width: 220)
            .allowsHitTesting(false)
        }
        .contentShape(Rectangle())
        .help("Double-click the sign to edit the timer")
    }
}

struct SignBoard: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color(red: 0.67, green: 0.53, blue: 0.29))

            VStack(spacing: 16) {
                Rectangle()
                    .fill(Color(red: 0.48, green: 0.38, blue: 0.20).opacity(0.75))
                    .frame(height: 14)

                Rectangle()
                    .fill(Color(red: 0.48, green: 0.38, blue: 0.20).opacity(0.75))
                    .frame(height: 14)
            }

            PixelBlockLayer(blocks: [
                PixelBlock(x: 0.00, y: 0.02, w: 0.10, h: 0.16, color: Color.black.opacity(0.12)),
                PixelBlock(x: 0.15, y: 0.00, w: 0.10, h: 0.20, color: Color.white.opacity(0.07)),
                PixelBlock(x: 0.38, y: 0.00, w: 0.24, h: 0.10, color: Color.white.opacity(0.10)),
                PixelBlock(x: 0.68, y: 0.10, w: 0.12, h: 0.16, color: Color.black.opacity(0.10)),
                PixelBlock(x: 0.00, y: 0.42, w: 0.14, h: 0.11, color: Color.white.opacity(0.08)),
                PixelBlock(x: 0.28, y: 0.46, w: 0.08, h: 0.16, color: Color.black.opacity(0.12)),
                PixelBlock(x: 0.54, y: 0.52, w: 0.08, h: 0.14, color: Color.white.opacity(0.06)),
                PixelBlock(x: 0.83, y: 0.42, w: 0.08, h: 0.16, color: Color.black.opacity(0.15)),
                PixelBlock(x: 0.10, y: 0.76, w: 0.09, h: 0.16, color: Color.black.opacity(0.10)),
                PixelBlock(x: 0.50, y: 0.78, w: 0.15, h: 0.14, color: Color.white.opacity(0.08)),
                PixelBlock(x: 0.86, y: 0.82, w: 0.14, h: 0.12, color: Color.black.opacity(0.08))
            ])
        }
        .clipShape(Rectangle())
        .overlay(
            Rectangle()
                .stroke(Color.black.opacity(0.18), lineWidth: 2)
        )
    }
}

struct PixelBlock: Identifiable {
    let id = UUID()
    var x: Double
    var y: Double
    var w: Double
    var h: Double
    var color: Color
}

struct PixelBlockLayer: View {
    let blocks: [PixelBlock]

    var body: some View {
        GeometryReader { geometry in
            ForEach(blocks) { block in
                Rectangle()
                    .fill(block.color)
                    .frame(
                        width: geometry.size.width * block.w,
                        height: geometry.size.height * block.h
                    )
                    .position(
                        x: geometry.size.width * (block.x + block.w / 2),
                        y: geometry.size.height * (block.y + block.h / 2)
                    )
            }
        }
    }
}

private extension View {
    func pixelBlocks(_ blocks: [PixelBlock]) -> some View {
        overlay(PixelBlockLayer(blocks: blocks))
    }
}
