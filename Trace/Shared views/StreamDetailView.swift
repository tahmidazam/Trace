//
//  StreamDetailView.swift
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
struct StreamDetailView: View {
    @Binding var doc: TraceDocument
    
    @State var stream: Stream
    
    var body: some View {
        if let potentialRange = doc.contents.potentialRange {
            Chart(stream.sampleDataPoints(at: doc.contents.sampleRate), id: \.self) { point in
                LineMark(
                    x: .value("time/s", point.timestamp),
                    y: .value("potential/mV", point.potential)
                )
                .lineStyle(StrokeStyle(lineWidth: 0.5))
            }
            .chartYScale(domain: potentialRange)
            .padding()
        }
    }
}
#else

struct StreamDetailView: View {
    @Binding var doc: TraceDocument
    @Binding var streamIds: Set<Stream.ID>
    @Binding var tab: DocumentView.Tab
    
    var window: Range<Int> = 0..<100
    
    var body: some View {
        Chart(TraceDocumentContents.sampleDataPoints(from: doc.contents.streams.filter({ stream in
            streamIds.contains(stream.id)
        }), sampleRate: doc.contents.sampleRate, spliced: window)) { point in
            LineMark(
                x: .value("time/s", point.timestamp),
                y: .value("potential/mV", point.potential)
            )
            .foregroundStyle(by: .value("Electrode", point.electrode.symbol))
        }
        .chartYAxis(content: {
            AxisMarks(position: .leading)
        })
        .padding()
    }
}

#endif
