//
//  CameraModel.swift
//  https://github.com/0Itsuki0/BasicAVCamera
//
//  Created by Itsuki on 2024/05/18.
//

import AVFoundation
import Combine
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
        lhs.image == rhs.image &&
        lhs.imageData == rhs.imageData &&
        lhs.imageSize == rhs.imageSize
    }
    
    var image: Image
    var imageData: Data
    var imageSize: (width: Int, height: Int)
}

class CameraModel: ObservableObject {
    let camera = CameraManager()
    var photoLibraryManager: PhotoLibraryManager?
    
    @Published var cameraMode: CameraMode = .photo
    
    @Published var previewImage: Image?
    @Published var photoData: PhotoData? {
        didSet {
            onPhotoDataChange?(photoData)
        }
    }
    var onPhotoDataChange: ((PhotoData?) -> Void)? = nil
    @Published var movieFileUrl: URL? {
        didSet {
            onMovieFileUrlChange?(movieFileUrl)
        }
    }
    var onMovieFileUrlChange: ((URL?) -> Void)? = nil
    
    init(onPhotoDataChange: ((PhotoData?) -> Void)? = nil, onMovieFileUrlChange: ((URL?) -> Void)? = nil) {
        Task {
            self.photoLibraryManager = await PhotoLibraryManager()
        }
        
        Task {
            await handleCameraPreviews()
        }
        
        Task {
            await handleCameraPhotos()
        }
        
        Task {
            await handleCameraMovie()
        }
        self.onPhotoDataChange = onPhotoDataChange
        self.onMovieFileUrlChange = onMovieFileUrlChange
    }
    
    // MARK: Preview Camera Output
    func handleCameraPreviews() async {
        let imageStream = camera.previewStream
            .map { $0.image }

        for await image in imageStream {
            Task { @MainActor in
                previewImage = image
            }
        }
    }
    
    // MARK: Photo Taken
    func handleCameraPhotos() async {
        let unpackedPhotoStream = camera.photoStream.compactMap { photo -> PhotoData? in
            guard let imageData = photo.fileDataRepresentation(),
                  let cgImage = photo.cgImageRepresentation(),
                  let metadataOrientation = photo.metadata[String(kCGImagePropertyOrientation)] as? UInt32,
                  let cgImageOrientation = CGImagePropertyOrientation(rawValue: metadataOrientation) else {
                return nil
            }
            
            let imageOrientation = UIImage.Orientation(cgImageOrientation)
            let image = Image(uiImage: UIImage(cgImage: cgImage, scale: 1, orientation: imageOrientation))
            
            let photoDimensions = photo.resolvedSettings.photoDimensions
            let imageSize = (width: Int(photoDimensions.width), height: Int(photoDimensions.height))

            return PhotoData(image: image, imageData: imageData, imageSize: imageSize)
        }
        
        for await photoData in unpackedPhotoStream {
            Task { @MainActor in
                self.photoData = photoData
            }
        }
    }
    
    func savePhoto() async {
        guard let imageData = photoData?.imageData else { return }
        await photoLibraryManager?.savePhoto(with: imageData)
    }
    
    // MARK: Video Recorded
    func handleCameraMovie() async {
        let fileUrlStream = camera.movieFileStream
        
        for await url in fileUrlStream {
            Task { @MainActor in
                movieFileUrl = url
            }
        }
    }
    
    func saveVideo() async {
        guard let videoFileUrl = movieFileUrl else { return }
        await photoLibraryManager?.saveVideo(from: videoFileUrl)
    }
}

fileprivate extension CIImage {
    var image: Image? {
        let ciContext = CIContext()
        guard let cgImage = ciContext.createCGImage(self, from: self.extent) else { return nil }
        return Image(decorative: cgImage, scale: 1, orientation: .up)
    }
}

fileprivate extension UIImage.Orientation {
    init(_ cgImageOrientation: CGImagePropertyOrientation) {
        switch cgImageOrientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        }
    }
}
