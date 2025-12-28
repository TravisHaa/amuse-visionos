//
//  ContentView.swift
//  Music Kit
//
//  Created by TRAVIS HA on 12/27/25.
//

import SwiftUI
import GestureKit
import RealityKit

/// This View now allows the user to enter an artist name,
/// then calls `musicManager.fetchSongsForArtist(artistName:)`.
struct ContentView: View {
    @EnvironmentObject var musicManager: MusicManager
    @Environment(AppModel.self) private var appModel
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    
    @StateObject private var gestureModel = GestureViewModel()
    
    @State private var artistName: String = "XG"
    
    var body: some View {
        VStack(spacing: 20) {
            Text("MusicKit Demo")
                .font(.title)
                .padding(.top, 40)
            
            // Show authorization status
            HStack {
                Image(systemName: musicManager.isAuthorized ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(musicManager.isAuthorized ? .green : .red)
                Text(musicManager.isAuthorized ? "Authorized" : "Not Authorized")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 10)
            
            // TextField to capture any artist name
            HStack {
                TextField("Enter artist name", text: $artistName)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
                
                Button("Fetch Artist Songs") {
                    // Print when search button is pressed
                    print("🔍 Search button pressed for artist: \(artistName)")
                    Task {
                        if musicManager.isAuthorized {
                            musicManager.customSongs.removeAll()
                            await musicManager.fetchSongsForArtist(artistName: artistName)
                        } else {
                            // Provide feedback when not authorized
                            print("⚠️ Cannot fetch songs: MusicKit not authorized")
                            // Try to request authorization again
                            musicManager.requestAuthorization()
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            
            // Button to show or hide the immersive space
            ToggleImmersiveSpaceButton()
                .padding(.bottom, 40)
            
            Text("Enter an artist above, fetch their songs, then open the immersive space.")
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            // Show error message if there's one
            if let error = musicManager.lastError {
                Text("Error: \(error.localizedDescription)")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 20)
            }
        }
        .task {
            // Set up gesture detection in ContentView
            // Pass the musicManager to the gesture model so gestures can control playback
            gestureModel.musicManager = musicManager
            // Pass AppModel and openImmersiveSpace action so gestures can toggle immersive space
            gestureModel.appModel = appModel
            // gestureModel.openImmersiveSpaceAction = {
            //     // Open immersive space action
            //     switch await openImmersiveSpace(id: appModel.immersiveSpaceID) {
            //     case .opened:
            //         // Space opened successfully
            //         break
            //     case .userCancelled, .error:
            //         // On error, mark as closed
            //         appModel.immersiveSpaceState = .closed
            //     @unknown default:
            //         appModel.immersiveSpaceState = .closed
            //     }
            // }
            await gestureModel.start()
        }
        .overlay(alignment: .topTrailing) {
            // Overlay to display detected gestures - positioned at top-right corner
            VStack(spacing: 12) {
                Text("Perform the 'Left Fist' gesture")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Display the detected gesture name if available
                if let detected = gestureModel.detectedGestureName {
                    Text(detected)
                        .font(.title3)
                        .bold()
                        .foregroundStyle(.green)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .animation(.easeInOut, value: detected)
                }
            }
            .padding()
        }
    }
}
