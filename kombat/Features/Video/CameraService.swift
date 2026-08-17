//
//  CameraService.swift
//  kombat
//

@preconcurrency import AVFoundation
import SwiftUI

/// Owns the AVFoundation capture pipeline: permissions, session lifecycle, and movie recording.
@MainActor
final class CameraService: NSObject, ObservableObject {
    enum Status {
        case idle
        case requestingPermission
        case denied
        case ready
        case failed(String)
    }

    @Published private(set) var status: Status = .idle
    @Published private(set) var isRecording = false
    @Published private(set) var recordingSeconds = 0
    @Published var lastRecording: RecordedScan?

    struct RecordedScan: Identifiable {
        let id = UUID()
        let url: URL
        let durationSeconds: Int
    }

    nonisolated(unsafe) let session = AVCaptureSession()

    private nonisolated let sessionQueue = DispatchQueue(label: "kombat.camera.session")
    private nonisolated(unsafe) let movieOutput = AVCaptureMovieFileOutput()
    private var recordingTimer: Timer?

    func start() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureAndRun()
        case .notDetermined:
            status = .requestingPermission
            AVCaptureDevice.requestAccess(for: .video) { granted in
                Task { @MainActor in
                    if granted {
                        self.configureAndRun()
                    } else {
                        self.status = .denied
                    }
                }
            }
        default:
            status = .denied
        }
    }

    func stop() {
        stopRecording()
        sessionQueue.async { [session] in
            if session.isRunning {
                session.stopRunning()
            }
        }
    }

    func toggleRecording() {
        isRecording ? stopRecording() : startRecording()
    }

    private func configureAndRun() {
        sessionQueue.async { [self] in
            var configured = false
            if session.inputs.isEmpty {
                session.beginConfiguration()
                session.sessionPreset = .high
                if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                   let input = try? AVCaptureDeviceInput(device: device),
                   session.canAddInput(input),
                   session.canAddOutput(movieOutput) {
                    session.addInput(input)
                    session.addOutput(movieOutput)
                    configured = true
                }
                session.commitConfiguration()
            } else {
                configured = true
            }

            guard configured else {
                Task { @MainActor in
                    self.status = .failed("No camera available on this device.")
                }
                return
            }

            if !session.isRunning {
                session.startRunning()
            }
            Task { @MainActor in
                self.status = .ready
            }
        }
    }

    private func startRecording() {
        guard case .ready = status, !movieOutput.isRecording else { return }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("scan-\(UUID().uuidString)")
            .appendingPathExtension("mov")
        isRecording = true
        recordingSeconds = 0
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                self.recordingSeconds += 1
            }
        }
        sessionQueue.async { [movieOutput] in
            movieOutput.startRecording(to: url, recordingDelegate: self)
        }
    }

    private func stopRecording() {
        guard isRecording else { return }
        recordingTimer?.invalidate()
        recordingTimer = nil
        sessionQueue.async { [movieOutput] in
            if movieOutput.isRecording {
                movieOutput.stopRecording()
            }
        }
    }
}

extension CameraService: AVCaptureFileOutputRecordingDelegate {
    nonisolated func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        let duration = Int(output.recordedDuration.seconds.rounded())
        Task { @MainActor in
            self.isRecording = false
            self.recordingTimer?.invalidate()
            self.recordingTimer = nil
            if error == nil {
                self.lastRecording = RecordedScan(url: outputFileURL, durationSeconds: max(duration, 1))
            }
        }
    }
}
