//
//  MediaStreamCompatibility.swift
//  ttaccessible
//

import Foundation

/// Checks whether a local media file can be streamed through the TeamTalk SDK as-is.
enum MediaStreamCompatibility {
    static let maxStreamingDimension = 1280

    /// ffprobe `codec_name` values treated as streamable without conversion.
    private static let streamableVideoCodecs: Set<String> = [
        "h264",
        "mjpeg",
        "jpeg",
        "mpeg1video",
        "mpeg4"
    ]

    /// Codecs that are never attempted (fast, explicit rejection when ffprobe is available).
    private static let blockedVideoCodecs: Set<String> = [
        "hevc",
        "h265",
        "hev1",
        "vp9",
        "av1",
        "av01"
    ]
    private static let ffprobeCandidates = [
        "/opt/homebrew/bin/ffprobe",
        "/usr/local/bin/ffprobe",
        "/usr/bin/ffprobe"
    ]

    /// Fast file-only check (ffprobe). Safe to call off the TeamTalk connection queue.
    static func preflightUnsupportedMessage(sourceURL: URL) -> String? {
        guard sourceURL.isFileURL else { return nil }
        guard let stream = probeVideoStreamWithFFprobe(sourceURL: sourceURL) else { return nil }
        return formattedMessage(for: reasonsFromVideoStream(stream))
    }

    /// SDK probe follow-up after preflight passes (no ffprobe — avoids blocking the connection queue twice).
    static func unsupportedMessageAfterSDKProbe(probe: MediaFileProbe) -> String? {
        var reasons: [String] = []
        if !probe.sdkSupported {
            reasons.append(L10n.text("mediaStream.error.reason.sdkUnsupported"))
        }
        if probe.hasVideo, probe.videoWidth > 0, probe.videoHeight > 0,
           max(probe.videoWidth, probe.videoHeight) > maxStreamingDimension {
            reasons.append(
                L10n.format(
                    "mediaStream.error.reason.videoResolution",
                    "\(probe.videoWidth)",
                    "\(probe.videoHeight)"
                )
            )
        }
        return formattedMessage(for: reasons)
    }

    private static func formattedMessage(for reasons: [String]) -> String? {
        guard !reasons.isEmpty else { return nil }
        if reasons.count == 1,
           reasons[0] == L10n.text("mediaStream.error.reason.sdkUnsupported") {
            return L10n.text("mediaStream.error.unsupportedFormat")
        }
        return L10n.format("mediaStream.error.unsupportedFormat.detail", reasons.joined(separator: " "))
    }

    private static func reasonsFromVideoStream(_ stream: FFprobeVideoStream) -> [String] {
        var reasons: [String] = []
        if let codec = stream.codec?.lowercased() {
            if blockedVideoCodecs.contains(codec) {
                let label = displayLabel(forVideoCodec: codec)
                reasons.append(L10n.format("mediaStream.error.reason.videoCodecBlocked", label))
            } else if !streamableVideoCodecs.contains(codec) {
                let label = displayLabel(forVideoCodec: codec)
                reasons.append(L10n.format("mediaStream.error.reason.videoCodec", label))
            }
        }
        if max(stream.width, stream.height) > maxStreamingDimension {
            reasons.append(
                L10n.format(
                    "mediaStream.error.reason.videoResolution",
                    "\(stream.width)",
                    "\(stream.height)"
                )
            )
        }
        if isTenBitPixelFormat(stream.pixelFormat) {
            reasons.append(L10n.text("mediaStream.error.reason.tenBitVideo"))
        }
        return reasons
    }

    private static func displayLabel(forVideoCodec codec: String) -> String {
        switch codec {
        case "mjpeg", "jpeg":
            return "MJPEG"
        case "mpeg1video":
            return "MPEG-1"
        case "mpeg4":
            return "MPEG-4"
        case "h264":
            return "H.264"
        default:
            return codec.uppercased()
        }
    }

    private static func isTenBitPixelFormat(_ pixelFormat: String?) -> Bool {
        guard let pixelFormat else { return false }
        let pix = pixelFormat.lowercased()
        return pix.contains("10le") || pix.contains("10be") || pix.contains("p010")
    }

    private struct FFprobeVideoStream {
        let codec: String?
        let pixelFormat: String?
        let width: Int
        let height: Int
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

        return FFprobeVideoStream(
            codec: videoStream["codec_name"] as? String,
            pixelFormat: videoStream["pix_fmt"] as? String,
            width: videoStream["width"] as? Int ?? 0,
            height: videoStream["height"] as? Int ?? 0
        )
    }

    private static func resolveFFprobePath() -> String? {
        for path in ffprobeCandidates where FileManager.default.isExecutableFile(atPath: path) {
            return path
        }
        return nil
    }
}
