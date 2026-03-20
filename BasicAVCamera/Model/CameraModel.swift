//
//  CameraModel.swift
//  https://github.com/0Itsuki0/BasicAVCamera
//
//  Created by Itsuki on 2024/05/18.
//

import AVFoundation
import SwiftUI

enum CameraMode {
    case video
    case photo
    
    mutating func toggle() {
        if self == .photo {
            self = .video
        } else {
            self = .photo
        }
    }
}

struct PhotoData: Equatable {
    static func == (lhs: PhotoData, rhs: PhotoData) -> Bool {
        lhs.imageData == rhs.imageData &&
        lhs.imageSize == rhs.imageSize
    }
    
    var imageData: Data
    var imageSize: (width: Int, height: Int)
    
    func resizePhotoData(maxDimension: CGFloat = 1200,
                         compression: CGFloat = 0.6) -> Data? {
        autoreleasepool {
            // Decode image from existing data (keeps orientation correct)
            guard let uiImage = UIImage(data: imageData) else {
                return nil
            }

            let originalSize = uiImage.size

            let scale = min(
                maxDimension / originalSize.width,
                maxDimension / originalSize.height,
                1 // never upscale
            )

            let newSize = CGSize(
                width: originalSize.width * scale,
                height: originalSize.height * scale
            )

            let renderer = UIGraphicsImageRenderer(size: newSize)
            let resizedImage = renderer.image { _ in
                uiImage.draw(in: CGRect(origin: .zero, size: newSize))
            }

            // Re-encode as JPEG @ desired compression
            return resizedImage.jpegData(compressionQuality: compression)
        }
    }
}

private let sharedCIContext = CIContext(options: [
    .useSoftwareRenderer: false,
    .cacheIntermediates: false
])

@MainActor
@Observable
class CameraModel {
    let cameraManager: CameraManager
    var photoLibraryManager: PhotoLibraryManager?
    
    var cameraMode: CameraMode = .photo
    
    private var previewTask: Task<Void, Never>?
    private var photoTask: Task<Void, Never>?
    private var movieTask: Task<Void, Never>?
    
    var previewImage: Image?
    
    private var _photoData: PhotoData?
    var photoData: PhotoData? {
        get { _photoData }
        set {
            _photoData = newValue
            if let photoData = newValue {
                onPhotoDataChange?(photoData)
                _photoData = nil
            }
        }
    }
    var onPhotoDataChange: ((PhotoData) -> Void)? = nil
    
    private var _movieFileUrl: URL?
    var movieFileUrl: URL? {
        get { _movieFileUrl }
        set {
            _movieFileUrl = newValue
            if let movieFileUrl = newValue {
                onMovieFileUrlChange?(movieFileUrl)
                _movieFileUrl = nil
            }
        }
    }
    var onMovieFileUrlChange: ((URL) -> Void)? = nil
    
    init(captureDevicePosition: CaptureDevicePosition, onPhotoDataChange: ((PhotoData?) -> Void)? = nil, onMovieFileUrlChange: ((URL?) -> Void)? = nil) {
        cameraManager = CameraManager(captureDevicePosition: captureDevicePosition)
        Task {
            self.photoLibraryManager = await PhotoLibraryManager()
        }
        
        previewTask = Task {
            await handleCameraPreviews()
        }
        
        photoTask = Task {
            await handleCameraPhotos()
        }
        
        movieTask = Task {
            await handleCameraMovie()
        }
        self.onPhotoDataChange = onPhotoDataChange
        self.onMovieFileUrlChange = onMovieFileUrlChange
    }
    
    deinit {
        MainActor.assumeIsolated {
            clearPhotoAndVideoData()
            stopCamera()
        }
    }
    
    func clearPhotoAndVideoData() {
        _photoData = nil
        _movieFileUrl = nil
    }
    
    func stopCamera() {
        previewTask?.cancel()
        photoTask?.cancel()
        movieTask?.cancel()
        
        previewImage = nil
        
        cameraManager.stop()
    }
    
    // MARK: Preview Camera Output
    func handleCameraPreviews() async {
        for await ciImage in cameraManager.previewStream {
            guard !Task.isCancelled else { break }
            
            await MainActor.run { [weak self] in
                guard let self else { return }
                autoreleasepool {
                    guard let cgImage = sharedCIContext.createCGImage(ciImage, from: ciImage.extent) else { return }
                    self.previewImage = Image(decorative: cgImage, scale: 1, orientation: .up)
                }
            }
        }
    }
    
    // MARK: Photo Taken
    func handleCameraPhotos() async {
        let unpackedPhotoStream = cameraManager.photoStream.compactMap { photo -> PhotoData? in
            autoreleasepool {
                guard let imageData = photo.fileDataRepresentation() else {
                    return nil
                }
                
                let photoDimensions = photo.resolvedSettings.photoDimensions
                let imageSize = (width: Int(photoDimensions.width), height: Int(photoDimensions.height))
                
                return PhotoData(imageData: imageData, imageSize: imageSize)
            }
        }
        
        for await photoData in unpackedPhotoStream {
            guard !Task.isCancelled else { break }
            await MainActor.run { [weak self] in
                autoreleasepool {
                    self?.photoData = photoData
                }
            }
        }
    }
    
    func savePhoto() async {
        guard let imageData = _photoData?.imageData else { return }
        do {
            try await photoLibraryManager?.savePhoto(with: imageData)
        } catch {
            print("Failed to save photo: \(error.localizedDescription)")
        }
    }
    
    // MARK: Video Recorded
    func handleCameraMovie() async {
        let fileUrlStream = cameraManager.movieFileStream
        
        for await url in fileUrlStream {
            guard !Task.isCancelled else { break }
            await MainActor.run { [weak self] in
                autoreleasepool {
                    self?.movieFileUrl = url
                }
            }
        }
    }
    
    func saveVideo() async {
        guard let videoFileUrl = _movieFileUrl else { return }
        await photoLibraryManager?.saveVideo(from: videoFileUrl)
    }
}
