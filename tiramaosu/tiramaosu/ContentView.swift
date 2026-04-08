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
        ZStack(alignment: .leading) {
            MinecraftTimerSign(
                time: formattedTime(secondsLeft)
            )
            .frame(width: 225, height: 236)
            .offset(x: 150, y: -75)
            .onTapGesture(count: 2) {
                isRunning = false
                isEditingTimer = true
            }
            .popover(isPresented: $isEditingTimer, arrowEdge: .bottom) {
                editPopup
            }

            Image(catImageName)
                .resizable()
                .scaledToFit()
                .frame(width: 330, height: 490)
                .contentShape(Rectangle())
                .onTapGesture {
                    isRunning.toggle()
                }

            Color.clear
                .frame(width: 300, height: 260)
                .contentShape(Rectangle())
                .onHover { isHovering in
                    isHoveringOverlay = isHovering
                }
        }
        .frame(width: 600, height: 520)
        .scaleEffect(0.30)
        .frame(width: 180, height: 156)
        .background(Color.clear)
        .contentShape(Rectangle())
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

    private var catImageName: String {
        if secondsLeft <= 10 {
            return "alert"
        }

        if slots[activeSlot].name == "Break" {
            return "sit"
        }

        return isHoveringOverlay ? "sleep-hover" : "sleep"
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
    let time: String

    var body: some View {
        ZStack {
            Image("sign")
                .resizable()
                .interpolation(.none)
                .scaledToFit()

            VStack(spacing: 3) {
                Text(time)
                    .font(.custom("Monaco", size: 55.5))
                    .fontWeight(.bold)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .foregroundStyle(.black.opacity(0.82))
            }
            .frame(width: 180)
            .position(x: 110, y: 55)
            .allowsHitTesting(false)
        }
        .contentShape(Rectangle())
        .help("Double-click the sign to edit the timer")
    }
}
