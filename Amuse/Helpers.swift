//
//  Helpers.swift
//  Amuse
//
//  Created by TRAVIS HA on 12/27/25.
//

import SwiftUI
import RealityKit
import MusicKit
import UIKit

/// A RealityKit component that holds a reference to the associated `Song`.
struct SongReferenceComponent: Component {
    let song: Song
}

/// Make the component codable if needed (optional).
extension SongReferenceComponent: Codable {}

/// Convert an Apple MusicKit Artwork to a CGImage.
func cgImageFromArtwork(artwork: Artwork, width: Int) async throws -> CGImage {
    // Provide a URL with the desired width x height
    guard let imageURL = artwork.url(width: width, height: width) else {
        throw NSError(domain: "ArtworkConversionError", code: -1,
                      userInfo: [NSLocalizedDescriptionKey: "Invalid artwork URL"])
    }
    
    let (data, _) = try await URLSession.shared.data(from: imageURL)
    guard let uiImage = UIImage(data: data) else {
        throw NSError(domain: "ArtworkConversionError", code: -1,
                      userInfo: [NSLocalizedDescriptionKey: "Unable to convert data into a UIImage"])
    }
    
    if let directCG = uiImage.cgImage {
        return directCG
    } else {
        let renderer = UIGraphicsImageRenderer(size: uiImage.size)
        let rendered = renderer.image { _ in uiImage.draw(at: .zero) }
        guard let renderedCG = rendered.cgImage else {
            throw NSError(domain: "ArtworkConversionError", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Unable to generate CGImage"])
        }
        return renderedCG
    }
}

/// Create a ModelEntity using a Song's artwork (unlit plane).
@MainActor
func createArtworkEntity(
    for song: Song,
    width: Float = 0.2,
    height: Float = 0.2
) async -> ModelEntity? {
    guard let artwork = song.artwork else { return nil }
    
    do {
        let cgImage = try await cgImageFromArtwork(artwork: artwork, width: 300)
        let texture = try await TextureResource(image: cgImage, options: .init(semantic: .color))
        
        var material = SimpleMaterial()
        let matTexture = MaterialParameters.Texture(texture)
        material.color = .init(texture: matTexture)
        
        let planeMesh = MeshResource.generatePlane(width: width, height: height)
        let entity = ModelEntity(mesh: planeMesh, materials: [material])
        return entity
    } catch {
        print("Error creating artwork entity: \(error)")
        return nil
    }
}

/// A SwiftUI view that displays artwork from MusicKit Artwork
struct ArtworkImage: View {
    let artwork: Artwork
    let width: CGFloat
    
    @State private var image: UIImage?
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: width, height: width)
                    .cornerRadius(8)
            } else {
                // Placeholder while loading
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: width, height: width)
                    .cornerRadius(8)
                    .overlay {
                        ProgressView()
                    }
            }
        }
        .task {
            await loadImage()
        }
    }
    
    // Load the artwork image asynchronously
    private func loadImage() async {
        guard let imageURL = artwork.url(width: Int(width), height: Int(width)) else {
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: imageURL)
            if let uiImage = UIImage(data: data) {
                await MainActor.run {
                    self.image = uiImage
                }
            }
        } catch {
            print("Error loading artwork image: \(error)")
        }
    }
}

/// A sample SwiftUI view for playback controls. Attach or modify as needed.
struct PlaybackControlsView: View {
    @EnvironmentObject var musicManager: MusicManager
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Playback Controls")
                .font(.headline)
            HStack {
                Button("Stop") {
                    musicManager.stopPlayback()
                }
                Button("Pause") {
                    musicManager.pausePlayback()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
    }
}
