// AudioService.swift
// QuietLater
//
// Wraps macOS CoreAudio public APIs to read and write the default system
// output volume and mute state.
//
// TECHNICAL NOTE — App Store Compliance:
// All APIs used here (AudioObjectGetPropertyData / AudioObjectSetPropertyData,
// kAudioHardwarePropertyDefaultOutputDevice, kAudioDevicePropertyVolumeScalar,
// kAudioDevicePropertyMute) are documented public CoreAudio APIs.
// They require no special entitlements and work fully inside the App Sandbox.
// No private APIs, AppleScript, shell commands, or accessibility hacks are used.
//
// DEVICE VOLUME CHANNELS:
// Some audio devices expose a virtual master channel (element = 0).
// Others require per-channel writes (channels 1 = left, 2 = right).
// AudioService tries the master channel first, then falls back to per-channel.

import CoreAudio
import Foundation

final class AudioService {

    // MARK: - Read

    /// Returns the current volume state of the default output device.
    /// Returns nil if no suitable device is found.
    func currentState() -> VolumeState? {
        guard let deviceID = defaultOutputDeviceID else { return nil }
        let volume = readVolumeScalar(deviceID: deviceID) ?? 0.5
        let muted  = readMute(deviceID: deviceID) ?? false
        return VolumeState(volume: volume, isMuted: muted)
    }

    // MARK: - Write

    /// Sets the output volume scalar (0.0 – 1.0). Does not change mute state.
    @discardableResult
    func setVolume(_ volume: Float) -> Bool {
        guard let deviceID = defaultOutputDeviceID else { return false }
        return writeVolumeScalar(max(0, min(1, volume)), deviceID: deviceID)
    }

    /// Sets the mute state. Does not change the volume scalar.
    @discardableResult
    func setMuted(_ muted: Bool) -> Bool {
        guard let deviceID = defaultOutputDeviceID else { return false }
        return writeMute(muted, deviceID: deviceID)
    }

    /// Applies a previously captured VolumeState.
    func applyState(_ state: VolumeState) {
        setVolume(state.volume)
        setMuted(state.isMuted)
    }

    // MARK: - Default Device

    private var defaultOutputDeviceID: AudioDeviceID? {
        var deviceID = AudioDeviceID(kAudioObjectUnknown)
        var size     = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address  = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope:    kAudioObjectPropertyScopeGlobal,
            mElement:  kAudioObjectPropertyElementMain
        )
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address, 0, nil, &size, &deviceID
        )
        guard status == noErr, deviceID != kAudioObjectUnknown else { return nil }
        return deviceID
    }

    // MARK: - Volume Scalar

    private func readVolumeScalar(deviceID: AudioDeviceID) -> Float? {
        // Try the virtual master channel (element 0) first.
        if let v = readFloat(deviceID: deviceID,
                             selector: kAudioDevicePropertyVolumeScalar,
                             scope: kAudioObjectPropertyScopeOutput,
                             element: kAudioObjectPropertyElementMain) {
            return v
        }
        // Fall back to channel 1 (left) as a proxy for overall volume.
        return readFloat(deviceID: deviceID,
                         selector: kAudioDevicePropertyVolumeScalar,
                         scope: kAudioObjectPropertyScopeOutput,
                         element: 1)
    }

    private func writeVolumeScalar(_ volume: Float, deviceID: AudioDeviceID) -> Bool {
        var vol    = Float32(volume)
        let size   = UInt32(MemoryLayout<Float32>.size)

        // Try master element first.
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope:    kAudioObjectPropertyScopeOutput,
            mElement:  kAudioObjectPropertyElementMain
        )
        if AudioObjectHasProperty(deviceID, &address) {
            let status = AudioObjectSetPropertyData(deviceID, &address, 0, nil, size, &vol)
            if status == noErr { return true }
        }

        // Fall back to per-channel (covers most built-in Mac audio devices).
        var succeeded = false
        for channel: UInt32 in [1, 2] {
            address.mElement = channel
            if AudioObjectHasProperty(deviceID, &address) {
                let status = AudioObjectSetPropertyData(deviceID, &address, 0, nil, size, &vol)
                if status == noErr { succeeded = true }
            }
        }
        return succeeded
    }

    // MARK: - Mute

    private func readMute(deviceID: AudioDeviceID) -> Bool? {
        guard let raw = readUInt32(deviceID: deviceID,
                                   selector: kAudioDevicePropertyMute,
                                   scope: kAudioObjectPropertyScopeOutput,
                                   element: kAudioObjectPropertyElementMain) else { return nil }
        return raw != 0
    }

    private func writeMute(_ muted: Bool, deviceID: AudioDeviceID) -> Bool {
        var value  = UInt32(muted ? 1 : 0)
        let size   = UInt32(MemoryLayout<UInt32>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope:    kAudioObjectPropertyScopeOutput,
            mElement:  kAudioObjectPropertyElementMain
        )
        guard AudioObjectHasProperty(deviceID, &address) else { return false }
        return AudioObjectSetPropertyData(deviceID, &address, 0, nil, size, &value) == noErr
    }

    // MARK: - Generic Property Helpers

    private func readFloat(deviceID: AudioDeviceID,
                           selector: AudioObjectPropertySelector,
                           scope: AudioObjectPropertyScope,
                           element: AudioObjectPropertyElement) -> Float? {
        var value: Float32 = 0
        var size = UInt32(MemoryLayout<Float32>.size)
        var address = AudioObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: element)
        guard AudioObjectHasProperty(deviceID, &address) else { return nil }
        let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &value)
        return status == noErr ? value : nil
    }

    private func readUInt32(deviceID: AudioDeviceID,
                            selector: AudioObjectPropertySelector,
                            scope: AudioObjectPropertyScope,
                            element: AudioObjectPropertyElement) -> UInt32? {
        var value: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        var address = AudioObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: element)
        guard AudioObjectHasProperty(deviceID, &address) else { return nil }
        let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &value)
        return status == noErr ? value : nil
    }
}
