//
//  ChartView.swift
//  Trace
//
//  Created by Tahmid Azam on 29/07/2022.
//
//  Copyright (C) 2022 Tahmid Azam
//
//  This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with this program. If not, see https://www.gnu.org/licenses/.

import SwiftUI
import Charts

#if os(iOS)
struct ChartView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var doc: TraceDocument
    
    @State var selectedStreams: [Stream] = []
    
    @State var windowSize: Int = 100
    @State var windowStart: Int = 0
    
    var window: ClosedRange<Int> {
        windowStart...(windowStart + windowSize)
    }
    var timeWindow: Range<Double> {
        doc.contents.time(at: window.lowerBound)..<doc.contents.time(at: window.upperBound)
    }
    
    var points: [TraceDocumentContents.SampleDataPoint] {
        TraceDocumentContents.sampleDataPoints(from: selectedStreams, sampleRate: doc.contents.sampleRate, spliced: window)
    }
    
    @GestureState var magnifyBy: CGFloat = 1.0
    @GestureState var dragAmount = CGSize.zero
    
    var magnification: some Gesture {
        MagnificationGesture()
            .updating($magnifyBy) { currentState, gestureState, transaction in
                withAnimation {
                    gestureState = currentState
                }
            }
    }
    var drag: some Gesture {
        DragGesture().updating($dragAmount) { value, state, transaction in
            state = value.translation
        }
    }
    var xValues: [Double] {
        stride(from: timeWindow.lowerBound, to: timeWindow.upperBound, by: (timeWindow.upperBound - timeWindow.lowerBound) / 5).map { $0 }
    }
    var body: some View {
        NavigationStack {
            ZStack {
                if let potentialRange = doc.contents.potentialRange {
                    chart
                        .chartYScale(domain: potentialRange)
                        .chartXScale(domain: ClosedRange(uncheckedBounds: (lower: timeWindow.lowerBound, upper: timeWindow.upperBound)))
                        .chartXAxis {
                            AxisMarks(values: xValues)
                        }
                        .chartYAxis(content: {
                            AxisMarks(position: .leading)
                        })
                        .chartLegend(position: .leading)
                        .scaleEffect(magnifyBy)
                        .offset(dragAmount)
                        .simultaneousGesture(drag)
                        .simultaneousGesture(magnification)
                        .animation(.easeInOut, value: magnifyBy)
                        .animation(.easeInOut, value: dragAmount)
                        .padding()
                }
            }
            .task {
                selectedStreams = doc.contents.streams
                print(xValues)
            }
            .navigationTitle("Plotting \(selectedStreams.count) of \(doc.contents.streams.count)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                closeButton
                
                ToolbarItem(placement: .navigationBarLeading) {
                    streamSelector
                }
                
                ToolbarItemGroup(placement: .bottomBar) {
                    stepBackwardButton
                    
                    Spacer()
                    
                    VStack {
                        if let duration = doc.contents.duration {
                            Text("\(timeWindow.lowerBound.format()) s to \(min(timeWindow.upperBound, duration).format()) s of \(duration.format()) s")
                                .font(.headline)
                        }
                        
                        
                        if let sampleCount = doc.contents.sampleCount {
                            Text("Sample \(window.lowerBound + 1) to \(min(window.upperBound, sampleCount)) of \(sampleCount)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    stepForwardButton
                }
            }
        }
    }
    
    var chart: some View {
        Chart(points, id: \.self) { point in
            LineMark(
                x: .value("time/s", point.timestamp),
                y: .value("potential/mV", point.potential)
            )
            .foregroundStyle(by: .value("Electrode", point.electrode.symbol))
        }
    }
    var closeButton: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button {
                presentationMode.wrappedValue.dismiss()
            } label: {
                Text("Close")
            }
        }
    }
    var stepBackwardButton: some View {
        Button(action: {
            windowStart -= windowSize
        }) {
            Image(systemName: "backward.frame.fill")
        }.disabled(windowStart - windowSize < 0)
    }
    var stepForwardButton: some View {
        Button(action: {
            windowStart += windowSize
        }) {
            Image(systemName: "forward.frame.fill")
        }
        .disabled(windowStart + windowSize > doc.contents.sampleCount ?? 0)
    }
    var windowSizingButtons: some View {
        Section {
            Button {
                windowSize += 100
            } label: {
                Label("Increase window size", systemImage: "plus")
            }
            .disabled(windowSize + 100 > 1000)
            
            Button {
                windowSize -= 100
            } label: {
                Label("Decrease window size", systemImage: "minus")
            }
            .disabled(windowSize - 100 < 100)
        }
    }
    var generalSelectionButtons: some View {
        Section {
            Button("Select all") { selectedStreams = doc.contents.streams }
            Button("Deselect all") { selectedStreams = [] }
        }
    }
    var streamSelector: some View {
        Menu {
            windowSizingButtons
            
            Section {
                Menu {
                    generalSelectionButtons
                    
                    ForEach(doc.contents.prefixes, id: \.self) { pre in
                        Section {
                            let streams = doc.contents.streams.filter { stream in
                                return stream.electrode.prefix == pre
                            }.sorted(by: { a, b in
                                a.electrode.suffix < b.electrode.suffix
                            })
                                                                                                                                 
                            ForEach(streams) { stream in
                                Button {
                                    if selectedStreams.contains(stream) {
                                        selectedStreams.removeAll(where: { $0.id == stream.id })
                                    } else {
                                        selectedStreams.append(stream)
                                    }
                                } label: {
                                    Label {
                                        Text(stream.electrode.symbol)
                                    } icon: {
                                        if selectedStreams.contains(stream) {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        }
                    }
                } label: {
                    Label("Selected streams", systemImage: "list.bullet")
                }
            }
        } label: {
            Label("View options", systemImage: "ellipsis.circle")
        }

    }
}

struct ChartView_Previews: PreviewProvider {
    static var previews: some View {
        ChartView(doc: .constant(TraceDocument()))
    }
}
#endif
