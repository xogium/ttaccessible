//
//  AudioRoutingSnapshot.swift
//  ttaccessible
//

import Foundation

/// Captures the audio routing state that matters for live TeamTalk sessions.
/// Used to ignore benign CoreAudio device-list churn (e.g. Continuity devices)
/// while still reacting to real route changes (AirPods, unplugged hardware, defaults).
struct AudioRoutingSnapshot: Equatable {
    var resolvedInputUID: String?
    var defaultInputUID: String?
    var defaultOutputUID: String?
    var preferredOutputPersistentID: String?
    var outputPersistentIDInCatalog: Bool
    var activeInputSampleRate: Double
}
