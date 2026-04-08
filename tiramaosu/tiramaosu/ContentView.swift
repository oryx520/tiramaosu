//
//  ContentView.swift
//  tiramaosu
//
//  Created by vyx on 2026-04-07.
//

import SwiftUI
import Combine
import AVFoundation

struct TimerSlot: Identifiable {
    let id = UUID()
    var name: String
    var minutes: Int
    var seconds: Int

    var totalSeconds: Int {
        let safeMinutes = min(max(minutes, 0), 120)
        let safeSeconds = min(max(seconds, 0), 59)
        return max((safeMinutes * 60) + safeSeconds, 1)
    }
}

struct ContentView: View {
    @State private var slots = [
        TimerSlot(name: "Work", minutes: 15, seconds: 0),
        TimerSlot(name: "Break", minutes: 5, seconds: 0)
    ]
    @State private var activeSlot = 0
    @State private var secondsLeft = 15 * 60
    @State private var isRunning = false
    @State private var isEditingTimer = false
    @State private var isHoveringOverlay = false
    @State private var purrPlayer: AVAudioPlayer?

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
                .frame(width: catImageWidth, height: catImageHeight)
                .offset(x: catImageXOffset, y: catImageYOffset)
                .allowsHitTesting(false)

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
        .onChange(of: catImageName) { _, newValue in
            if newValue == "sit-hover" {
                playPurr()
            } else {
                stopPurr()
            }
        }
    }

    private var editPopup: some View {
        VStack(alignment: .leading, spacing: 14) {
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
                HStack(spacing: 7) {
                    Text(slot.name)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(width: 38, alignment: .leading)

                    TextField("", value: $slot.minutes, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.trailing)
                        .monospacedDigit()
                        .frame(width: 46)
                        .onSubmit {
                            clampTimerValues()
                        }

                    Text(":")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)

                    TextField("", value: $slot.seconds, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.trailing)
                        .monospacedDigit()
                        .frame(width: 46)
                        .onSubmit {
                            clampTimerValues()
                        }
                }
            }

            HStack {
                Button(isRunning ? "Pause" : "Start") {
                    clampTimerValues()
                    if !isRunning {
                        secondsLeft = slots[activeSlot].totalSeconds
                    }
                    isRunning.toggle()
                    isEditingTimer = false
                }

                Button("Reset") {
                    clampTimerValues()
                    resetTimer()
                    isEditingTimer = false
                }

                Spacer()

                Button("Done") {
                    clampTimerValues()
                    resetTimer()
                    isEditingTimer = false
                }
            }
        }
        .padding(14)
        .frame(width: 230)
    }

    private var catImageName: String {
        if secondsLeft <= 10 {
            return "alert"
        }

        if slots[activeSlot].name == "Break" {
            return isHoveringOverlay ? "sit-hover" : "sit"
        }

        return isHoveringOverlay ? "sleep-hover" : "sleep"
    }

    private var catImageWidth: CGFloat {
        switch catImageName {
        case "sit":
            return 330
        case "sit-hover":
            return 330
        case "alert":
            return 264
        case "sleep-hover":
            return 330
        default:
            return 330
        }
    }

    private var catImageHeight: CGFloat {
        switch catImageName {
        case "sit":
            return 490
        case "sit-hover":
            return 490
        case "alert":
            return 392
        case "sleep-hover":
            return 490
        default:
            return 490
        }
    }

    private var catImageXOffset: CGFloat {
        switch catImageName {
        case "sit":
            return 30
        case "sit-hover":
            return 30
        case "alert":
            return 0
        case "sleep-hover":
            return 0
        default:
            return 0
        }
    }

    private var catImageYOffset: CGFloat {
        switch catImageName {
        case "sit":
            return -35
        case "sit-hover":
            return -45
        case "alert":
            return -50
        case "sleep-hover":
            return 0
        default:
            return 0
        }
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

    private func clampTimerValues() {
        for index in slots.indices {
            slots[index].minutes = min(max(slots[index].minutes, 0), 120)
            slots[index].seconds = min(max(slots[index].seconds, 0), 59)

            if slots[index].minutes == 0 && slots[index].seconds == 0 {
                slots[index].seconds = 1
            }
        }
    }

    private func formattedTime(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func playPurr() {
        if purrPlayer?.isPlaying == true {
            return
        }

        guard let url = Bundle.main.url(forResource: "purr", withExtension: "mp3") else {
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = 0.5
            player.prepareToPlay()
            player.play()
            purrPlayer = player
        } catch {
            purrPlayer = nil
        }
    }

    private func stopPurr() {
        purrPlayer?.stop()
        purrPlayer = nil
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
