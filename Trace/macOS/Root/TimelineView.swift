//
//  TimelineView.swift
//  Trace
//
//  Created by Tahmid Azam on 30/12/2022.
//

import SwiftUI

struct TimelineView: View {
    @Binding var doc: TraceDocument
    @ObservedObject var plottingState: PlottingState

    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(.quaternaryLabelColor)))
            
            if let sampleCount = doc.contents.sampleCount {
                for event in doc.contents.events.filter({ event in
                    plottingState.selectedEventTypes.contains(event.type)
                }) {
                    let timeProportion = CGFloat(event.sampleIndex + 1) / CGFloat(sampleCount)
                    
                    let x = size.width * timeProportion
                    
                    let linePath: Path = Path { path in
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size.height))
                    }
                    
                    context.stroke(linePath, with: .color(.red), lineWidth: plottingState.lineWidth)
                    
                    if plottingState.showEpochs {
                        let epochEnd = size.width * (CGFloat(doc.contents.epochLength + event.sampleIndex + 1) / CGFloat(sampleCount))
                        
                        let epochPath = Path { path in
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: epochEnd, y: 0))
                            path.addLine(to: CGPoint(x: epochEnd, y: size.height))
                            path.addLine(to: CGPoint(x: x, y: size.height))
                        }
                        
                        let eventEndPath = Path { path in
                            path.move(to: CGPoint(x: epochEnd, y: 0))
                            path.addLine(to: CGPoint(x: epochEnd, y: size.height))
                        }
                        
                        context.fill(epochPath, with: .color(.red.opacity(0.1)))
                        context.stroke(eventEndPath, with: .color(.red), style: StrokeStyle(lineWidth: plottingState.lineWidth, dash: [2]))
                    }
                }
                
                switch plottingState.visualisation {
                case .stackedPlot:
                    let frameWidth = size.width * (CGFloat(plottingState.windowSize) / CGFloat(sampleCount))
                    let xOffset = size.width * (CGFloat(plottingState.windowStartIndex) / CGFloat(sampleCount))
                    let trailingBound = xOffset + frameWidth
                    
                    let windowPath = Path { path in
                        path.move(to: CGPoint(x: xOffset, y: 0))
                        path.addLine(to: CGPoint(x: xOffset, y: size.height))
                        path.addLine(to: CGPoint(x: trailingBound, y: size.height))
                        path.addLine(to: CGPoint(x: trailingBound, y: 0))
                    }
                    
                    context.fill(windowPath, with: .color(.accentColor.opacity(0.5)))
                case .scalpMap:
                    let xOffset = size.width * (CGFloat(plottingState.sampleIndex) / CGFloat(sampleCount))
                    
                    let indicatorPath = Path { path in
                        path.move(to: CGPoint(x: xOffset, y: 0))
                        path.addLine(to: CGPoint(x: xOffset, y: size.height))
                    }
                    
                    context.stroke(indicatorPath, with: .color(.accentColor), lineWidth: 1.0)
                }
            }
        }
        .mask(Capsule())
        .frame(height: 10)
    }
}
