//
//  ContentView.swift
//  Music Kit
//
//  Created by TRAVIS HA on 12/27/25.
//

import SwiftUI
import GestureKit

/// This View now allows the user to enter an artist name,
/// then calls `musicManager.fetchSongsForArtist(artistName:)`.
struct ContentView: View {
    @EnvironmentObject var musicManager: MusicManager
    
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
                .disabled(artistName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 20)
            
            // Button to show or hide the immersive space
            ToggleImmersiveSpaceButton()
                .padding(.bottom, 40)
            
            // Display which album cover was pressed
            if let selectedSong = musicManager.lastSelectedSong {
                VStack(spacing: 8) {
                    Text("🎨 Album Cover Selected:")
                        .font(.headline)
                    Text(selectedSong.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("by \(selectedSong.artistName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(.regularMaterial)
                .cornerRadius(12)
                .padding(.horizontal, 20)
            }
            
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
    }
}
