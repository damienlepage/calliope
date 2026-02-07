//
//  AudioOutputDeviceLookup.swift
//  Calliope
//
//  Created on [Date]
//

import AudioToolbox
import CoreAudio

struct AudioOutputDevice: Equatable, Identifiable {
    let id: AudioDeviceID
    let name: String
}

enum AudioOutputDeviceLookup {
    static func defaultOutputDevice() -> AudioOutputDevice? {
        guard let deviceID = defaultOutputDeviceID() else { return nil }
        guard let name = deviceName(for: deviceID) else { return nil }
        return AudioOutputDevice(id: deviceID, name: name)
    }

    private static func defaultOutputDeviceID() -> AudioDeviceID? {
        var deviceID = AudioDeviceID(0)
        var dataSize = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &dataSize,
            &deviceID
        )
        guard status == noErr, deviceID != 0 else { return nil }
        return deviceID
    }

    private static func deviceName(for deviceID: AudioDeviceID) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var dataSize = UInt32(MemoryLayout<CFString>.size)
        var name: CFString = "" as CFString
        let status = withUnsafeMutablePointer(to: &name) { pointer in
            AudioObjectGetPropertyData(
                deviceID,
                &address,
                0,
                nil,
                &dataSize,
                pointer
            )
        }
        guard status == noErr else { return nil }
        return name as String
    }
}
