//
//  MainView.swift
//  BasicAVCamera
//
//  Created by Sercan Şahan on 26.01.2026.
//

import SwiftUI

struct MainView: View {
    @StateObject var model: CameraModel = CameraModel()
    @State private var isRecording: Bool = false
    private let footerHeight: CGFloat = 110.0

    var body: some View {
        ZStack {
            if let _ = model.photoData {
                SaveImageView(model: model)
            } else if let _ = model.movieFileUrl {
                SaveVideoView(model: model)
            } else {
                CameraView(model: model)
                    .overlay(alignment: .bottom) {
                        buttonsView()
                            .frame(height: footerHeight)
                            .background(.gray.opacity(0.4))
                    }
            }
        }
    }
    
    private func buttonsView() -> some View {
        GeometryReader { geometry in
            let frameHeight = geometry.size.height
            HStack {

                Button {
                    model.cameraMode.toggle()
                } label: {
                    Image(systemName: model.cameraMode == .photo ? "video.fill" : "camera.fill")

                }
                
                Spacer()

                if model.cameraMode == .photo {
                    Button {
                        model.camera.takePhoto()
                        model.onPhotoDataChange = { photoData in
                            if let photoData {
                                let data = self.resizePhotoData(photoData)
                                print("Size: \((data?.count ?? 0) / 1024) KB")
                            }
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .strokeBorder(.white, lineWidth: 3)
                                .frame(width: frameHeight, height:  frameHeight)
                            Circle()
                                .fill(.white)
                                .frame(width:  frameHeight-10, height: frameHeight-10)

                        }
                    }
                } else {
                    Button {
                        if isRecording {
                            isRecording = false
                            model.camera.stopRecordingVideo()
                        } else {
                            isRecording = true
                            model.camera.startRecordingVideo()
                        }
                    } label: {
                        Image(systemName: "record.circle")
                            .symbolEffect(.pulse, isActive: isRecording)
                            .foregroundStyle(isRecording ? Color.red : Color.white)
                            .font(.system(size: 50))
                    }
                    
                }

                Spacer()

                Button {
                    model.camera.switchCaptureDevice()
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                }

            }
            .font(.system(size: 28, weight: .bold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, alignment: .center)
            
        }
        .padding(.vertical, 24)
        .padding(.bottom, 8)
        .padding(.horizontal, 32)
    }
    
    func resizePhotoData(_ photoData: PhotoData,
                         maxDimension: CGFloat = 1200,
                         compression: CGFloat = 0.6) -> Data? {

        // Decode image from existing data (keeps orientation correct)
        guard let uiImage = UIImage(data: photoData.imageData) else {
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

#Preview {
    MainView()
}
