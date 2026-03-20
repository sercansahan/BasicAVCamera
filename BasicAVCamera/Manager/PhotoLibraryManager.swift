//
//  PhotoLibraryManager.swift
//  SwiftUIDemo2
//
//  Created by Itsuki on 2024/05/18.
//

import Foundation
import Photos

class PhotoLibraryManager {
    
    enum PhotoLibraryError: Error {
        case notAuthorized
        case assetCollectionNotFound
        case saveFailed(Error)
    }
    
    private var assetCollection: PHAssetCollection?
    private var smartAlbumType: PHAssetCollectionSubtype = .smartAlbumUserLibrary

    init() async {
        let isAuthorized = await checkAuthorization()
        if (!isAuthorized) {
            return
        }
        loadAsset()
    }
    
    private func loadAsset() {
        let fetchOptions = PHFetchOptions()
        let collections = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: smartAlbumType, options: fetchOptions)
        self.assetCollection = collections.firstObject
    }

    private func checkAuthorization() async -> Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized, .limited:
            return true
        case .notDetermined, .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }
    
    func fetchAllPhotos() async throws -> [PHAsset] {
        let isAuthorized = await checkAuthorization()
        if (!isAuthorized) {
            throw PhotoLibraryError.notAuthorized
        }
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: false)
        ]
        
        let result = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        var assets: [PHAsset] = []
        result.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        
        return assets
    }
    
    func fetchPhotos(withIdentifiers identifiers: [String]) async throws -> [PHAsset] {
        let isAuthorized = await checkAuthorization()
        if (!isAuthorized) {
            throw PhotoLibraryError.notAuthorized
        }
        
        let result = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
        
        var assets: [PHAsset] = []
        result.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        
        return assets
    }
    
    func savePhoto(with imageData: Data) async throws {
        let isAuthorized = await checkAuthorization()
        if (!isAuthorized) {
            throw PhotoLibraryError.notAuthorized
        }
        
        if assetCollection == nil {
            loadAsset()
        }
        
        guard let assetCollection = self.assetCollection else {
            throw PhotoLibraryError.assetCollectionNotFound
        }
        
        do {
            try await PHPhotoLibrary.shared().performChanges {
                let creationRequest = PHAssetCreationRequest.forAsset()
                if let assetPlaceholder = creationRequest.placeholderForCreatedAsset {
                    creationRequest.addResource(with: .photo, data: imageData, options: nil)
                    if let albumChangeRequest = PHAssetCollectionChangeRequest(for: assetCollection), assetCollection.canPerform(.addContent) {
                        let fastEnumeration = NSArray(array: [assetPlaceholder])
                        albumChangeRequest.addAssets(fastEnumeration)
                    }
                }
            }
            print("Added image data to photo collection.")
        } catch {
            throw PhotoLibraryError.saveFailed(error)
        }
    }
    
    func saveVideo(from fileUrl: URL) async {
        let isAuthorized = await checkAuthorization()
        if (!isAuthorized) {
            return
        }
        
        if assetCollection == nil {
            loadAsset()
        }
        
        guard let assetCollection = self.assetCollection else {
            print("error saving video to photo")
            return
        }
        
        Task {
            do {
                try await PHPhotoLibrary.shared().performChanges {
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    if let assetPlaceholder = creationRequest.placeholderForCreatedAsset {
                        creationRequest.addResource(with: .video, fileURL: fileUrl, options: nil)
                        if let albumChangeRequest = PHAssetCollectionChangeRequest(for: assetCollection), assetCollection.canPerform(.addContent) {
                            let fastEnumeration = NSArray(array: [assetPlaceholder])
                            albumChangeRequest.addAssets(fastEnumeration)
                        }
                    }
                }
                print("Added video to photo collection.")
            } catch let error {
                print("Failed to add video to photo collection: \(error.localizedDescription)")
            }
        }
    }
}
