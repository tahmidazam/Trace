# ``Trace``

A document-based SwiftUI application for viewing and editing EEG data, aimed at making software for viewing brain imaging data more accessible.

## Overview

View EEG data conveniently on your phone, with the same powerful functions as desktop alternatives. Use a 2-dimensional scalp map visualisation and effortlessly scrub through samples, or plot potentials over time for a graphic solution. Import multi-stream data from CSV or from text, and save and share your EEG data with the new minimal, space-efficient Trace document type, `.trace`.

## Topics

### Articles

- <doc:Electrode-support>
- <doc:Document-lifecycle>
- <doc:Scalp-map-visualisation>

### Data structures

- ``TraceDocument``
- ``TraceDocumentContents``
- ``CompressedTraceDocumentContents``
- ``Stream``
- ``Electrode``

### Views

- ``DocumentView``
- ``ScalpMapView``
- ``ChartView``

### Subviews

- ``NewStreamView``
- ``DocumentPreferencesView``
- ``ImportFromTextView``
- ``StreamDetailView``
