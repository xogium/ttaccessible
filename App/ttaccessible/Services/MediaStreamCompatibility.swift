//
//  MediaStreamCompatibility.swift
//  ttaccessible
//

import Foundation

/// Checks whether a local media file can be streamed through the TeamTalk SDK as-is.
enum MediaStreamCompatibility {
    private static let ffprobeCandidates = [
        "/opt/homebrew/bin/ffprobe",
        "/usr/local/bin/ffprobe",
        "/usr/bin/ffprobe"
    ]

    /// Fast file-only check (ffprobe). Safe to call off the TeamTalk connection queue.
    /// Codec and resolution are left to the SDK; only known-bad pixel formats are rejected here.
    static func preflightUnsupportedMessage(sourceURL: URL) -> String? {
        guard sourceURL.isFileURL else { return nil }
        guard let stream = probeVideoStreamWithFFprobe(sourceURL: sourceURL) else { return nil }
        guard isTenBitPixelFormat(stream.pixelFormat) else { return nil }
        return L10n.format(
            "mediaStream.error.unsupportedFormat.detail",
            L10n.text("mediaStream.error.reason.tenBitVideo")
        )
    }

    /// SDK probe follow-up after preflight passes (no ffprobe — avoids blocking the connection queue twice).
    static func unsupportedMessageAfterSDKProbe(probe: MediaFileProbe) -> String? {
        guard !probe.sdkSupported else { return nil }
        return L10n.text("mediaStream.error.unsupportedFormat")
    }

    private static func isTenBitPixelFormat(_ pixelFormat: String?) -> Bool {
        guard let pixelFormat else { return false }
        let pix = pixelFormat.lowercased()
        return pix.contains("10le") || pix.contains("10be") || pix.contains("p010")
    }

    private struct FFprobeVideoStream {
        let pixelFormat: String?
    }

    private static func probeVideoStreamWithFFprobe(sourceURL: URL) -> FFprobeVideoStream? {
        guard let ffprobe = resolveFFprobePath() else { return nil }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: ffprobe)
        process.arguments = [
            "-v", "quiet",
            "-print_format", "json",
            "-show_streams",
            "-select_streams", "v:0",
            sourceURL.path
        ]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
        } catch {
            return nil
        }
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { return nil }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let streams = json["streams"] as? [[String: Any]],
              let videoStream = streams.first else {
            return nil
        }

        return FFprobeVideoStream(pixelFormat: videoStream["pix_fmt"] as? String)
    }

    private static func resolveFFprobePath() -> String? {
        for path in ffprobeCandidates where FileManager.default.isExecutableFile(atPath: path) {
            return path
        }
        return nil
    }
}
