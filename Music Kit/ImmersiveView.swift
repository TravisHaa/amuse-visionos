//
//  ImmersiveView.swift
//  Music Kit
//
//  Created by TRAVIS HA on 12/27/25.
//

import SwiftUI
import RealityKit
import MusicKit
import GestureKit

/// Adjust this to define how many songs appear in one row / chunk
let CHUNK_SIZE = 9

struct ImmersiveView: View {
    @EnvironmentObject var musicManager: MusicManager
    @Environment(AppModel.self) private var appModel
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @StateObject private var gestureModel = GestureViewModel()
    
    var body: some View {
        RealityView { content, attachments in
            // Create a ModelEntity to serve as a parent anchor
            let nameEntity = ModelEntity(
                mesh: .generateText(
                    "",
                    extrusionDepth: 0.001,
                    font: .systemFont(ofSize: 12),
                    containerFrame: .zero,
                    alignment: .center,
                    lineBreakMode: .byCharWrapping
                ),
                materials: [UnlitMaterial(color: .black)]
            )
            nameEntity.position = [0.1, 1.5, -1]
            nameEntity.name = "name"
            content.add(nameEntity)
            
            // Add attachments to that entity
            let attachmentData: [(name: String, position: SIMD3<Float>)] = [
                (name: "Artwork", position: [0, 0, 0]),
                (name: "Titles",  position: [0, 0, 0.1])
            ]
            
            for data in attachmentData {
                if let attachment = attachments.entity(for: data.name) {
                    attachment.name = data.name
                    attachment.components.set(InputTargetComponent())
                    attachment.generateCollisionShapes(recursive: true)
                    attachment.position = data.position
                    nameEntity.addChild(attachment)
                }
            }
        } attachments: {
            // Attachment for listing songs (simple list)
            Attachment(id: "Songs") {
                List(musicManager.customSongs, id: \.id) { song in
                    HStack {
                        Text(song.title)
                        Spacer()
                        Button(action: {
                            // Print when play button is pressed
                            print("🎵 Play button pressed for song: \(song.title) by \(song.artistName)")
                            musicManager.playSong(song)
                        }) {
                            Image(systemName: "play.circle")
                                .font(.system(size: 36))
                        }
                    }
                }
            }
            
            // Attachment for Artwork
            Attachment(id: "Artwork") {
                let chunkedSongs = musicManager.customSongs.chunked(into: CHUNK_SIZE)
                
                ScrollView {
                    VStack {
                        ForEach(chunkedSongs, id: \.self) { songChunk in
                            HStack {
                                ForEach(songChunk, id: \.id) { song in
                                    if let artwork = song.artwork {
                                        ArtworkImage(artwork, width: 350)
                                            .hoverEffect(LiftHoverEffect())
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            
            // Attachment for Titles / custom UI
            Attachment(id: "Titles") {
                VStack {
                    TitlesView()
                    HStack {
                        // A separate "Stop Playback" UI
                        StopView {
                            musicManager.stopPlayback()
                        }
                    }
                    .frame(width: 350)
                }
            }
        }
        .task {
            // Pass the musicManager to the gesture model so gestures can control playback
            gestureModel.musicManager = musicManager
            // Pass AppModel and openImmersiveSpace action so gestures can toggle immersive space
            gestureModel.appModel = appModel
            gestureModel.openImmersiveSpaceAction = {
                // Open immersive space action
                switch await openImmersiveSpace(id: appModel.immersiveSpaceID) {
                case .opened:
                    // Space opened successfully
                    break
                case .userCancelled, .error:
                    // On error, mark as closed
                    appModel.immersiveSpaceState = .closed
                @unknown default:
                    appModel.immersiveSpaceState = .closed
                }
            }
            await gestureModel.start()
        }
        .overlay {
            // Overlay to display detected gestures
            VStack(spacing: 20) {
                Text("Perform the 'Left Fist' gesture")
                    .font(.title2)
                
                // Display the detected gesture name if available
                if let detected = gestureModel.detectedGestureName {
                    Text(detected)
                        .font(.largeTitle)
                        .bold()
                        .foregroundStyle(.green)
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .animation(.easeInOut, value: detected)
                }
            }
            .padding()
        }
    }
}

/// Format a time interval into mm:ss if needed
func formatTimeInterval(_ timeInterval: TimeInterval) -> String {
    let seconds = Int(timeInterval) % 60
    let minutes = (Int(timeInterval) / 60) % 60
    return String(format: "%02d:%02d", minutes, seconds)
}

struct TitlesView: View {
    @EnvironmentObject var musicManager: MusicManager
    
    var body: some View {
        let chunkedSongs = musicManager.customSongs.chunked(into: CHUNK_SIZE)
        
        ScrollView {
            VStack {
                ForEach(chunkedSongs, id: \.self) { songChunk in
                    HStack {
                        ForEach(songChunk, id: \.id) { song in
                            VStack {
                                Button(action: {
                                    // Print when play button is pressed (title button)
                                    print("🎵 Play button pressed for song: \(song.title) by \(song.artistName)")
                                    musicManager.playSong(song)
                                }) {
                                    VStack {
                                        Text(song.title)
                                    }
                                    .padding(30)
                                    .frame(width: 350)
                                }
                                .buttonStyle(StyledButton())
                                .frame(width: 350)
                            }
                        }
                        .frame(height: 400)
                    }
                }
            }
        }
    }
}

/// Custom button style for the titles
struct StyledButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(.thinMaterial)
            .hoverEffect(.highlight)
            .foregroundColor(.white)
            .clipShape(.capsule)
            .hoverEffect { effect, isActive, _ in
                effect.scaleEffect(isActive ? 1.0 : 0.8)
            }
    }
}

/// A custom "Stop" button that animates a text label into view on hover.
struct StopView: View {
    var action: () -> Void
    @Namespace var hoverNamespace
    
    var hoverGroup: HoverEffectGroup {
        HoverEffectGroup(hoverNamespace)
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 2) {
                StopButtonView {
                    action()
                }
                .hoverEffect(in: hoverGroup) { effect, isActive, _ in
                    effect.scaleEffect(isActive ? 1.05 : 1.0)
                }
                
                StopTextView()
                    .hoverEffect(in: hoverGroup) { effect, isActive, _ in
                        effect.opacity(isActive ? 1 : 0)
                    }
            }
        }
        .frame(width: 350)
        .buttonStyle(StopButtonStyle(hoverGroup: hoverGroup))
    }
}

struct StopButtonView: View {
    var action: () -> Void
    
    var body: some View {
        Button(action: {
            action()
        }) {
            Image(systemName: "stop.circle")
                .resizable()
                .scaledToFit()
                .frame(width: 42, height: 42)
                .padding(6)
                .foregroundColor(.white)
                .background(Color.clear)
        }
    }
}

/// Animates the capsule shape when hovered
struct StopButtonStyle: ButtonStyle {
    var hoverGroup: HoverEffectGroup?
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(.thinMaterial)
            .hoverEffect(.highlight)
            .hoverEffect { effect, isActive, proxy in
                effect.animation(.default.delay(isActive ? 0.2 : 0.1)) {
                    $0.clipShape(.capsule.size(
                        width: isActive ? proxy.size.width : proxy.size.width - 121,
                        height: proxy.size.height,
                        anchor: .leading
                    ))
                }
            }
    }
}

struct StopTextView: View {
    var body: some View {
        Text("Stop Playing")
            .font(.subheadline)
            .foregroundStyle(.white)
            .padding(.trailing, 24)
            .padding(.leading, 12)
    }
}
