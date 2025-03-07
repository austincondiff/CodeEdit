//
//  FPSCounter.swift
//  CodeEdit
//
//  Created by Austin Condiff on 3/7/25.
//

import AppKit
import Charts
import CoreVideo
import SwiftUI

struct FPSMeasurement: Identifiable, Equatable {
    let id: Int
    let fps: Int

    static func == (lhs: FPSMeasurement, rhs: FPSMeasurement) -> Bool {
        lhs.id == rhs.id
    }
}

class FPSHistory: ObservableObject {
    @Published var history: [FPSMeasurement] = []
}

@available(macOS 14.0, *)
class FPSCounter: ObservableObject {
    @Published private(set) var fps = 0
    private(set) var fpsHistory = FPSHistory()

    private var displayLink: CADisplayLink?
    private(set) var maxHistoryCount: Int
    private(set) var nextId = 100

    private var frameCount = 0
    private var lastTimestamp: CFTimeInterval = 0
    private let updateInterval: CFTimeInterval = 0.2
    private var isTracking = false
    private weak var trackedWindow: NSWindow?

    private let maxPossibleWidth: CGFloat = 580
    private var absoluteMaxBars: Int
    private var currentMaxBars: Int

    init(maxHistoryCount: Int = 20) {
        // Calculate the maximum possible bars that could fit in 580px
        self.absoluteMaxBars = Int((maxPossibleWidth + 2)/(2 + 2)) // using barWidth=2, spacing=2
        self.currentMaxBars = absoluteMaxBars
        self.maxHistoryCount = absoluteMaxBars
    }

    func updateMaxHistoryCount(_ count: Int) {
        // Update currentMaxBars if the new count is larger
        currentMaxBars = max(absoluteMaxBars, count)
        while fpsHistory.history.count > currentMaxBars {
            fpsHistory.history.removeFirst()
        }
    }

    private func fillHistory() {
        for index in 0...maxHistoryCount {
            fpsHistory.history.append(
                FPSMeasurement(
                    id: index,
                    fps: 0
                )
            )
        }
    }

    func pause() {
        displayLink?.remove(from: .main, forMode: .common)
        fpsHistory.history.removeAll()
    }

    func resume() {
        displayLink?.add(to: .main, forMode: .common)
    }

    func startTracking(in window: NSWindow) {
        if isTracking {
            return
        }

        isTracking = true
        trackedWindow = window
        displayLink = window.displayLink(target: self, selector: #selector(displayLinkDidFire(_:)))
        displayLink?.add(to: .main, forMode: .common)
    }

    func stopTracking() {
        displayLink?.invalidate()
        displayLink = nil
        trackedWindow = nil
        isTracking = false
    }

    deinit {
        stopTracking()
    }

    @objc
    private func displayLinkDidFire(_ link: CADisplayLink) {
        if lastTimestamp == 0 {
            lastTimestamp = link.timestamp
            return
        }

        frameCount += 1

        let elapsed = link.timestamp - lastTimestamp
        if elapsed >= updateInterval {
            let currentFPS = Int(round(Double(frameCount) / elapsed))

            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                fps = currentFPS

                if self.fpsHistory.history.count >= self.currentMaxBars {
                    self.fpsHistory.history.removeFirst()
                }
                self.fpsHistory.history.append(FPSMeasurement(id: self.nextId, fps: self.fps))

                nextId += 1
            }

            frameCount = 0
            lastTimestamp = link.timestamp
        }
    }

    var maxFPS: Int {
        guard let screen = trackedWindow?.screen else { return 60 }
        return Int(round(1.0 / screen.maximumRefreshInterval))
    }
}

@available(macOS 14.0, *)
struct ChartView: View {
    let paused: Bool
    @ObservedObject var fps: FPSHistory
    let maxFPS: Int
    let barWidth: CGFloat
    let barSpacing: CGFloat
    var chartWidth: CGFloat

    var barCount: Int {
        max(Int((chartWidth + barSpacing) / (barWidth + barSpacing)), 1)
    }

    var visibleBars: [FPSMeasurement] {
        // Only show the most recent bars that fit in the current width
        if fps.history.isEmpty {
            return []
        }
        return Array(fps.history.suffix(barCount))
    }

    var body: some View {
        Group {
            if fps.history.isEmpty || paused {
                pausedView
            } else {
                HStack(spacing: 0) {
                    HStack(alignment: .bottom, spacing: barSpacing) {
                        ForEach(visibleBars) { measurement in
                            FPSBar(
                                fps: measurement.fps,
                                maxFPS: maxFPS,
                                width: barWidth
                            ).equatable()
                        }
                    }
                    Spacer(minLength: 0)
                }
                .frame(height: 24)
                .frame(maxWidth: .infinity)
                .contentShape(.interaction, .rect)
                .padding(.horizontal, 0)
            }
        }
        .animation(.easeOut(duration: 0.2), value: fps.history.isEmpty)
        .animation(.easeOut(duration: 0.2), value: paused)
    }

    @ViewBuilder var pausedView: some View {
        Rectangle()
            .cornerRadius(3)
            .foregroundStyle(.gray.gradient.quaternary)
            .overlay {
                if paused {
                    Text("Paused")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 24)
    }
}

@available(macOS 14.0, *)
struct FPSView: View {
    @StateObject private var counter = FPSCounter()
    @State private var isStressing = false
    @State private var heavyWorkItems: [Int] = []
    @State private var paused = false
    @State private var hasChart = true

    @ViewBuilder var texts: some View {
        VStack(alignment: .trailing, spacing: 0) {
            Text("\(counter.fps) FPS")
                .foregroundColor(.accentColor)
                .font(.system(size: 12, weight: .semibold))
                .offset(y: 2)
                .fixedSize()

            Text("\(counter.maxFPS)Hz")
                .foregroundColor(.gray)
                .font(.caption)
                .offset(y: -1)
        }
        .frame(width: 47, alignment: .trailing)
        .padding(.trailing, 4)
    }

    let barWidth: CGFloat = 2
    let barSpacing: CGFloat = 2
    @State private var chartWidth: CGFloat = 0

    var chart: some View {
        ChartView(
            paused: paused,
            fps: counter.fpsHistory,
            maxFPS: counter.maxFPS,
            barWidth: barWidth,
            barSpacing: barSpacing,
            chartWidth: chartWidth
        )
        .shakeEffect(isShaking: isStressing)
        .frame(minWidth: barWidth + barSpacing, alignment: .trailing)
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        updateBarCount(width: proxy.size.width)
                    }
                    .onChange(of: proxy.size.width) { width in
                        updateBarCount(width: width)
                    }
            }
        )
    }

    private func updateBarCount(width: CGFloat) {
        chartWidth = width
        // For n bars, we need n*barWidth + (n-1)*barSpacing to fit
        // Solving for n: n = (width + spacing)/(barWidth + spacing)
        let newBarCount = max(Int((width + barSpacing)/(barWidth + barSpacing)), 1)
        counter.updateMaxHistoryCount(newBarCount)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Rectangle()
                .fill(.clear)
                .frame(width: 47, alignment: .center)
                .overlay(alignment: .trailing) {
                    texts
                        .allowsHitTesting(false)
                }
            if hasChart {
                chart
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 20, alignment: .center)
        .offset(x: 2)
        .contentShape(Rectangle())
        .onTapGesture {
            togglePaused()
        }
        .animation(.easeOut(duration: 0.2), value: hasChart)
        .introspect(.window, on: .macOS(.v13, .v14, .v15)) { window in
            counter.startTracking(in: window)
        }
        .onAppear {
            paused = false
        }
        .onDisappear {
            counter.stopTracking()
        }
        .contextMenu {
            Button(!isStressing ? "Enable Stress Test" : "Disable Stress Test") {
                toggleStressTest()
            }

            Button(paused ? "Resume" : "Pause") {
                togglePaused()
            }

            Button(!hasChart ? "Enable Chart View" : "Disable Chart View") {
                hasChart.toggle()
            }
        }
    }

    private func togglePaused() {
        let nextPaused = !paused
        paused.toggle()

        if nextPaused {
            counter.pause()
        } else {
            counter.resume()
        }
    }

    private func toggleStressTest() {
        let nextIsStressing = !isStressing
        isStressing.toggle()

        if nextIsStressing {
            Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
                if !isStressing {
                    timer.invalidate()
                    return
                }

                for _ in 0...10000 {
                    heavyWorkItems.append(Int.random(in: 0...1000))
                    _ = sqrt(Double.random(in: 0...10000))
                }
                heavyWorkItems.removeAll()
            }
        }
    }
}

extension View {
    func shakeEffect(isShaking: Bool) -> some View {
        modifier(ShakeEffect(isShaking: isShaking))
    }
}

struct ShakeEffect: ViewModifier {
    let isShaking: Bool

    func body(content: Content) -> some View {
        content
            .offset(
                x: isShaking ? CGFloat(Int.random(in: -3...3)) : 0,
                y: isShaking ? CGFloat(Int.random(in: -1...1)) : 0
            )
            .animation(
                isShaking ?
                    .easeIn(duration: 0.09).repeatForever(autoreverses: true) :
                    .default,
                value: isShaking
            )
    }
}

@available(macOS 14.0, *)
struct FPSBar: View, Equatable {
    let fps: Int
    let maxFPS: Int
    let width: CGFloat

    private let maxHeight: CGFloat = 24

    private var heightPercentage: CGFloat {
        guard maxFPS > 0 else { return 0 }
        return CGFloat(fps) / CGFloat(maxFPS)
    }

    var percent: Double {
        Double(fps) / Double(maxFPS)
    }

    @ViewBuilder var shape: some View {
        let barFill: Color = percent > 0.75 ? .accentColor : percent > 0.5 ? .yellow : .red

        RoundedRectangle(cornerRadius: 1)
            .fill(barFill)
    }

    var body: some View {
        shape
            .frame(width: width, height: maxHeight * heightPercentage)
            .frame(maxHeight: maxHeight, alignment: .bottom)
    }
}
