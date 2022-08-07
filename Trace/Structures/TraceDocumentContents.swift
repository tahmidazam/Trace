//
//  TraceDocumentContents.swift
//  Trace
//
//  Created by Tahmid Azam on 07/08/2022.
//

import Foundation

/// The data structure for the contents of a trace document.
struct TraceDocumentContents: Identifiable, Codable {
    var id = UUID()
    
    // MARK: PROPERTIES
    /// The subject name..
    var subject: String?
    /// Information relating to the subject.
    var info: String?
    
    /// An array containing the streams of EEG data for each electrode in the trace.
    var streams: [Stream]
    /// The sample rate of the EEG data, measured in Hertz, Hz.
    var sampleRate: Double
    /// A dictionary containing each event type and their events as indexes.
    var events: [String: [Int]]?
    
    // MARK: COMPUTED PROPERTIES
    /// The number of samples.
    var sampleCount: Int? {
        if let first = streams.first {
            return first.samples.count
        } else {
            return nil
        }
    }
    /// The number of samples as text, formatted with a unit and alterations for plurals.
    var formattedSampleCount: String? {
        if let count = sampleCount {
            return "\(count) sample\(count == 1 ? "" : "s")"
        } else {
            return nil
        }
    }
    /// Duration of the recording in seconds, s.
    var duration: Double? {
        if let count = sampleCount {
            return Double(count) * Double(1 / sampleRate)
        } else {
            return nil
        }
        
    }
    
    var potentialRange: ClosedRange<Double>? {
        let allSamples = streams.map { stream in
            return stream.samples
        }.flatMap({ (element: [Double]) -> [Double] in
            return element
        })
        
        guard let min = allSamples.min() else { return nil }
        guard let max = allSamples.max() else { return nil }
        
        return min...max
    }
    
    var prefixes: [Electrode.Prefix] {
        Array(Set(streams.map(\.electrode.prefix))).sorted { elementA, elementB in
            return elementA.rawValue < elementB.rawValue
        }
    }
    
    // MARK: FUNCTIONS
    /// Converts a stream index to a time value, in seconds, s.
    /// - Parameter index: The index to convert.
    /// - Returns: The time value, in seconds, s.
    func time(at index: Int) -> Double {
        return Double(index) * (1 / sampleRate)
    }
    
    // MARK: STATIC FUNCTIONS
    /// Imports (multiple) streams from a `.csv` file.
    ///
    /// Each column from the `.csv` file corresponds to a singular stream. The header of each column (i.e., the first row), is used to identify the electrode involved in the stream. The rest of the rows are used to extract the samples for each stream.
    ///
    /// The import will fail in the following cases:
    ///  - The electrode symbol cannot be interpreted into an electrode instance.
    ///  - The number format for any one of the samples is incorrect (i.e., the `String` cannot be transformed into a `Double`).
    ///
    /// - Parameter csv: The raw text from the csv file.
    /// - Returns: Stream instances from the csv file.
    static func streams(from csv: String) -> [Stream]? {
        var streams: [Stream] = []
        
        var lines = csv.components(separatedBy: .newlines).filter { $0 != "" }
        
        let headerLine = lines.remove(at: 0)
        
        let electrodeSymbols = headerLine.components(separatedBy: ",").map { string in
            string.trimmingCharacters(in: .whitespacesAndNewlines )
        }
        
        for symbolIndex in electrodeSymbols.indices {
            guard let electrode = Electrode(from: electrodeSymbols[symbolIndex]) else { return nil }
            
            var streamDataPoints: [Double] = []
            
            for line in lines {
                let lineDataPoints = line.components(separatedBy: ",")
                
                let dataPoint = lineDataPoints[symbolIndex].filter { $0.isNumber || $0 == "." || $0 == "-"}
                
                guard let dataPoint = Double(dataPoint) else { return nil }
                
                streamDataPoints.append(dataPoint)
            }
            
            let stream = Stream(electrode: electrode, samples: streamDataPoints)
            
            streams.append(stream)
        }
        
        return streams
    }
    /// Converts a stream to a chart-parsable data structure.
    /// - Parameters:
    ///   - stream: The stream to map.
    ///   - sampleRate: The sample rate of the stream.
    /// - Returns: A chart-parsable stream.
    static func sampleDataPoints(from streams: [Stream], sampleRate: Double, spliced: Range<Int>? = nil) -> [TraceDocumentContents.SampleDataPoint] {
        var data: [TraceDocumentContents.SampleDataPoint] = []
        
        for stream in streams {
            if spliced != nil {
                for sampleIndex in spliced!.lowerBound..<min(stream.samples.count, spliced!.upperBound) {
                    let dataPoint = TraceDocumentContents.SampleDataPoint(
                        electrode: stream.electrode,
                        timestamp: (1 / sampleRate) * Double(sampleIndex),
                        potential: stream.samples[sampleIndex]
                    )
                    
                    data.append(dataPoint)
                }
            } else {
                for sampleIndex in 0..<stream.samples.count {
                    let dataPoint = TraceDocumentContents.SampleDataPoint(
                        electrode: stream.electrode,
                        timestamp: (1 / sampleRate) * Double(sampleIndex),
                        potential: stream.samples[sampleIndex]
                    )
                    
                    data.append(dataPoint)
                }
            }
        }
        
        return data
    }
    
    // MARK: STRUCTURES
    /// A data structure suitable for parsing by charts that represents a potential, along with its timestamp and associated electrode.
    struct SampleDataPoint: Hashable {
        static func == (lhs: TraceDocumentContents.SampleDataPoint, rhs: TraceDocumentContents.SampleDataPoint) -> Bool {
            lhs.electrode == rhs.electrode && lhs.timestamp == rhs.timestamp && lhs.potential == rhs.potential
        }
        
        /// The electrode associated with the data point.
        var electrode: Electrode
        /// The x-axis time value in seconds, s.
        var timestamp: Double
        /// The y-axis potential value in millivolts, mV.
        var potential: Double
    }
}
