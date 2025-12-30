//
//  GestureViewModel.swift
//  Amuse
//
//  Created by TRAVIS HA on 12/27/25.
//

import Foundation
import GestureKit
import RealityKit
import SwiftUI


@MainActor
class GestureViewModel: ObservableObject {
    let detector: GestureDetector
    
    // Published property to track the currently detected gesture name
    // This is used to display gesture detection feedback in the UI
    @Published var detectedGestureName: String?
    
    // Reference to the shared MusicManager instance
    // This allows gestures to control music playback
    // Using a regular var (not weak) since there's no retain cycle:
    // - ImmersiveView owns gestureModel (via @StateObject)
    // - Environment owns musicManager (via @EnvironmentObject)
    var musicManager: MusicManager?
    
    // Closure to open the immersive space (passed from the view)
    // This allows gestures to trigger opening the immersive space
    var openImmersiveSpaceAction: (() async -> Void)?
    
    // Reference to AppModel to check immersive space state
    var appModel: AppModel?
    
    // Store the gesture package URLs to identify specific gestures
    private let gesturePackages: [URL]
    
    // Map of gesture titles (from JSON metadata) to their package filenames
    // These titles come from the "title" field in each gesture package's main.json
    private let gestureTitleMap: [String: String] = [
        "Spider-Man": "spidermanpause.gesturecomposer",
        "Ring thumb tip touch": "rightthumbringfinger.gesturecomposer",
        "Left fist": "opendashboard.gesturecomposer",
        "Left middle click": "leftmiddleclick.gesturecomposer"
    ]
    
    // Specify which gesture title  to detect
    // Set this to one of the titles from gestureTitleMap above
    // Example: "Spider-Man", "Ring thumb tip touch", "Left fist", "Left middle click"
    // Set to nil to detect all gestures
    var targetGestureTitle: String? = nil
    
    init(musicManager: MusicManager? = nil) {
        // Store reference to the shared MusicManager
        self.musicManager = musicManager
        
        // Initialize gesture packages using Bundle.main.url(forResource:withExtension:)
        // This correctly loads .gesturecomposer folders from the app bundle,
        // ensuring they work in built apps, simulator, and on device
        let gestureNames = ["leftfist", "rightthumbringfinger", "leftthumbmiddlefinger", "spidermanpause"]
        var loadedPackages: [URL] = []
        
        // Load each gesture package and log success/failure for debugging
        for name in gestureNames {
            if let url = Bundle.main.url(forResource: name, withExtension: "gesturecomposer") {
                // Verify the URL actually points to an existing file/folder
                let fileManager = FileManager.default
                var isDirectory: ObjCBool = false
                let exists = fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)
                
                if exists {
                    print("✅ Loaded gesture package: \(name)")
                    print("   URL: \(url.path)")
                    print("   Is directory: \(isDirectory.boolValue)")
                    loadedPackages.append(url)
                } else {
                    print("❌ Gesture package URL returned but file doesn't exist: \(name)")
                    print("   URL: \(url.path)")
                    print("   This suggests a bundle configuration issue.")
                }
            } else {
                print("❌ Could not find gesture package in bundle: \(name).gesturecomposer")
                print("   Make sure the .gesturecomposer folder is added to the app target in Xcode:")
                print("   - Select the folder in Xcode")
                print("   - Open File Inspector (right sidebar)")
                print("   - Under 'Target Membership', check your app's target")
                print("   - Also verify it's in the 'Copy Bundle Resources' build phase")
            }
        }
        
        self.gesturePackages = loadedPackages
        
        // Only create detector if we have at least one valid package
        guard !gesturePackages.isEmpty else {
            fatalError("No gesture packages could be loaded. Please ensure .gesturecomposer folders are added to the app target in Xcode.")
        }
        
        let config = GestureDetectorConfiguration(packages: gesturePackages)
        self.detector = GestureDetector(configuration: config)
        
        
    }
    
    func start() async {
        //detectedGestures is AsyncStream<GestureMatchType>
        // - Type: AsyncStream<GestureMatchType> (from GestureKit)
        // - Element Type: GestureMatchType (conforms to 'Gesture' protocol)
        // - Usage: for await gesture in detector.detectedGestures
        // - Each gesture element (GestureMatchType) has:
        //   • gesture.description (String) - required
        //   • gesture.title (String?) - optional, from gesture package JSON metadata
        //   • gesture.package (URL?) - optional, path to the .gesturecomposer file
        //
        // NOTE: In simulator, the sequence will be empty, but type info will still print
        Task {
            // Print type information about the sequence itself
            let sequenceType = type(of: detector.detectedGestures)
            print("═══════════════════════════════════════")
            print("📊 detectedGestures TYPE INFORMATION:")
            print("═══════════════════════════════════════")
            print("   ✅ Type: \(sequenceType)")
            print("   ✅ Element Type: GestureMatchType")
            print("   ✅ Sequence Type: AsyncStream<GestureMatchType>")
            print("═══════════════════════════════════════\n")
            
            // Iterate through detected gestures (will be empty in simulator)
            // Each element is of type GestureMatchType (from AsyncStream<GestureMatchType>)
            print("🔍 Waiting for gestures (GestureMatchType)...")
            print("   (Note: Will be empty in simulator - requires physical device)")
            print("───────────────────────────────────\n")
            
            for await gesture in detector.detectedGestures {
                // gesture is of type GestureMatchType
                print("✅ GESTURE DETECTED (GestureMatchType):")
                print("   Description: \(gesture.description)")
                
                // Print the actual type of the gesture element
                let gestureElementType = type(of: gesture)
                print("   Element Type: \(gestureElementType)")
                print("   Element Type (String): \(String(describing: gestureElementType))")
                
                // Check protocol conformance
                print("   Conforms to Gesture protocol: \(gesture is any Gesture)")
                
                print("running gesture through handleSpecificGesture...")
                handleSpecificGesture(gesture)
            }
            print("───────────────────────────────────\n")
            print("⚠️ Gesture detection loop ended (no gestures detected in simulator)")
        }
    }
    
    // Handle the specific gesture that was detected
    // GestureMatchType is an enum with cases: full(url: URL, name: String), 
    // partial(url: URL, name: String, stage: Int), reset(url: URL, name: String)
    // According to GestureKit README, use gesture.description to identify gestures
    private func handleSpecificGesture(_ gesture: GestureMatchType) {
        // Extract info for debugging
        let gestureName: String
        let gestureURL: URL
        
        switch gesture {
        case .full(let url, let name):
            gestureName = name
            gestureURL = url
            print("   Match Type: full")
        case .partial(let url, let name, let stage):
            gestureName = name
            gestureURL = url
            print("   Match Type: partial (stage: \(stage))")
            // Only handle full matches, ignore partial
            return
        case .reset(let url, let name):
            gestureName = name
            gestureURL = url
            print("   Match Type: reset")
            // Ignore reset events
            return
        }
        
        print("   Gesture Name: \(gestureName)")
        print("   Gesture URL: \(gestureURL.lastPathComponent)")
        
        // Use gesture.description to identify gestures (as per GestureKit README)
        // The description property provides a human-readable string representation
        let gestureDescription = gesture.description
        print("   Description: '\(gestureDescription)'")
        
        // Update the detected gesture name for UI display
        // Use the description if available, otherwise fall back to the gesture name
        detectedGestureName = gestureDescription.isEmpty ? gestureName : gestureDescription
        
        // Identify gesture by description (as demonstrated in GestureKit README)
        // The description format may vary, so we check multiple possible formats
        switch gestureDescription {
        case "Opening the dashboard":
            // Left fist gesture - metadata description
            print("✊ Left fist gesture detected - open immersive space")
            // Open the immersive space (same as the button does)
            Task { @MainActor in
                guard let appModel = appModel else {
                    print("⚠️ AppModel not available")
                    return
                }
                
                switch appModel.immersiveSpaceState {
                case .closed:
                    // Open the immersive space
                    appModel.immersiveSpaceState = .inTransition
                    await openImmersiveSpaceAction?()
                    
                case .open:
                    //TODO: Space is already open, do nothing (should change to close it)
                    print("📱 Immersive space is already open")
                    
                case .inTransition:
                    // Already transitioning, do nothing
                    print("📱 Immersive space is already transitioning")
                    break
                }
            }
            
        case "Use your left thumb tip to click your left middle finger tip￼":
            // Left middle click gesture - metadata description
            print("🖱️ Left middle click gesture detected")
            if let manager = musicManager {
                manager.skipToPreviousTrack()
            }
            
        case "Peace Sign":
            print("Peace Sign gesture detected - perform pause action")
            // Pause or resume playback based on current state
            if let manager = musicManager {
                let isCurrentlyPlaying = manager.isPlaying()
                print("   📊 Current playback status: \(manager.getPlaybackStatus())")
                print("   📊 Is playing: \(isCurrentlyPlaying)")
                print("   📊 Currently playing song: \(manager.currentlyPlayingSong?.title ?? "none")")
                
                if isCurrentlyPlaying {
                    print("   ⏸️ Pausing playback...")
                    manager.pausePlayback()
                    // Verify pause was successful
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
                        print("   ✅ After pause - status: \(manager.getPlaybackStatus())")
                    }
                } else {
                    // Resume playback if paused
                    print("   ▶️ Resuming playback...")
                    if let song = manager.currentlyPlayingSong {
                        manager.playSong(song)
                    } else {
                        print("   ⚠️ No song to resume")
                    }
                }
            } else {
                print("   ⚠️ MusicManager is nil - cannot control playback")
            }
            
        case "Ring thumb tip touch":
            // Ring thumb tip touch gesture - title (metadata description is empty)
            print("👆 Ring thumb tip touch gesture detected")
            if let manager = musicManager {
                manager.skipToNextTrack()
            }
            
        default:
            // Unknown gesture - print info for debugging
            // This helps identify what description value is actually returned
            print("📱 Unknown gesture detected")
            print("   Description: '\(gestureDescription)'")
            print("   Name: '\(gestureName)'")
            print("   URL: \(gestureURL.lastPathComponent)")
            print("   (Add this description value to the switch statement to handle this gesture)")
            // Handle unknown gestures
        }
    }
}
