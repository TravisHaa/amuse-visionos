//
//  GestureViewModel.swift
//  Music Kit
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
        // Initialize gesture packages
        self.gesturePackages = [
            URL(fileURLWithPath: "Music Kit/leftfist.gesturecomposer"),
            URL(fileURLWithPath: "Music Kit/rightthumbringfinger.gesturecomposer"),
            URL(fileURLWithPath: "Music Kit/leftthumbmiddlefinger.gesturecomposer"),
            URL(fileURLWithPath: "Music Kit/spidermanpause.gesturecomposer")
        ]
        
        let config = GestureDetectorConfiguration(packages: gesturePackages)
        self.detector = GestureDetector(configuration: config)
        
        
    }
    
    func start() async {
        // TEMPORARILY COMMENTED OUT - just for debugging detectedGestures
        // async let _ = virtualHands.startSession()
        // async let _ = virtualHands.startHandTracking()
        // async let _ = virtualHands.handleSessionEvents()
        
        // 🔍 DEBUG: Print type information about detectedGestures
        // 
        // DISCOVERED: detectedGestures is AsyncStream<GestureMatchType>
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
    // Note: gesture is GestureMatchType, which conforms to Gesture protocol
    // According to GestureKit README, use gesture.description to identify gestures
    private func handleSpecificGesture(_ gesture: GestureMatchType) {
        // Use description to identify which gesture was detected
        // gesture.description contains the gesture identifier from the gesture package
        let gestureDescription = gesture.description
        
        // Identify gesture by description and handle accordingly
        // According to GestureKit, gesture.description contains the gesture identifier
        // This may be the metadata description or title from the gesture package JSON
        switch gestureDescription {
        case "Opening the dashboard":
            // Left fist gesture - metadata description is "Opening the dashboard"
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
            
        case "Spider-Man":
            // Spider-Man gesture - title (metadata description is empty, so title is used)
            print("🕷️ Spider-Man gesture detected - perform pause action")
            // Pause or resume playback based on current state
            if let manager = musicManager {
                if manager.isPlaying() {
                    manager.pausePlayback()
                } else {
                    // Resume playback if paused
                    if let song = manager.currentlyPlayingSong {
                        manager.playSong(song)
                    }
                }
            }
            
        case "Ring thumb tip touch":
            // Ring thumb tip touch gesture - title (metadata description is empty, so title is used)
            print("👆 Ring thumb tip touch gesture detected")
            if let manager = musicManager {
                manager.skipToNextTrack()
            }
            
        default:
            // Unknown gesture - print description for debugging
            // This helps identify what description value is actually returned
            print("📱 Unknown gesture detected")
            print("   Description: '\(gestureDescription)'")
            print("   (Add this description value to the switch statement to handle this gesture)")
            // Handle unknown gestures
        }
    }
}
