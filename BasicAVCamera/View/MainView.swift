//
//  MainView.swift
//  BasicAVCamera
//
//  Created by Sercan Şahan on 26.01.2026.
//

import SwiftUI

struct MainView: View {
    @State var model: CameraModel = CameraModel(captureDevicePosition: .back)
    @State private var isRecording: Bool = false
    @State private var capturedPhotoData: PhotoData?
    @State private var capturedVideoUrl: URL?

    var body: some View {
        ZStack {
            if let photoData = capturedPhotoData {
                VStack {
                    topButtonsView()
                    PhotoPreviewView(photoData: photoData)
                }
            } else if let videoFileUrl = capturedVideoUrl {
                VStack {
                    topButtonsView()
                    VideoPreviewView(videoFileUrl: videoFileUrl)
                }
            } else {
                CameraView(model: model)
                    .overlay(alignment: .bottom) {
                        bottomButtonsView()
                            .frame(height: 110.0)
                    }
            }
        }
    }
    
    private func topButtonsView() -> some View {
        HStack {
            TopActionButton(.back) {
                if capturedPhotoData != nil {
                    capturedPhotoData = nil
                } else if capturedVideoUrl != nil {
                    capturedVideoUrl = nil
                }
            }
            Spacer()
            TopActionButton(.save) {
                Task {
                    if capturedPhotoData != nil {
                        await model.savePhoto()
                        capturedPhotoData = nil
                    } else if capturedVideoUrl != nil {
                        await model.saveVideo()
                        capturedVideoUrl = nil
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }
    
    private func bottomButtonsView() -> some View {
        HStack {
            changeModeButton()
            Spacer()
            captureButton()
            Spacer()
            changeDeviceButton()
        }
        .padding(.all, 32)
    }
    
    private func changeModeButton() -> some View {
        Button {
            model.cameraMode.toggle()
        } label: {
            Image(systemName: model.cameraMode == .photo ? "video.fill" : "camera.fill")
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 36, height: 36)
        }
        .modifier(NativeButtonStyle())
    }
    
    private func captureButton() -> some View {
        Button {
            if model.cameraMode == .photo {
                model.onPhotoDataChange = { photoData in
                    capturedPhotoData = photoData
                    let data = self.resizePhotoData(photoData)
                    print("Size: \((data?.count ?? 0) / 1024) KB")
                }
                model.cameraManager.takePhoto()
            } else {
                isRecording.toggle()
                if isRecording {
                    model.onMovieFileUrlChange = { url in
                        capturedVideoUrl = url
                    }
                    model.cameraManager.startRecordingVideo()
                } else {
                    model.cameraManager.stopRecordingVideo()
                }
            }
        } label: {
            ZStack {
                Circle()
                    .strokeBorder(.white, lineWidth: 3)
                    .frame(width: 72, height:  72)
                Circle()
                    .fill(model.cameraMode == .photo ? .white : (isRecording ? .red : .white))
                    .frame(width: 62, height: 62)
            }
        }
    }
    
    private func changeDeviceButton() -> some View {
        Button {
            model.cameraManager.switchCaptureDevice()
        } label: {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 36, height: 36)
        }
        .modifier(NativeButtonStyle())
    }
    
    private func resizePhotoData(_ photoData: PhotoData,
                                 maxDimension: CGFloat = 1200,
                                 compression: CGFloat = 0.6) -> Data? {
        guard let uiImage = UIImage(data: photoData.imageData) else { return nil }
        let originalSize = uiImage.size
        let scale = min(maxDimension / originalSize.width, maxDimension / originalSize.height, 1)
        let newSize = CGSize(width: originalSize.width * scale, height: originalSize.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resizedImage = renderer.image { _ in uiImage.draw(in: CGRect(origin: .zero, size: newSize)) }
        return resizedImage.jpegData(compressionQuality: compression)
    }
}

private struct NativeButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
        } else {
            content
                .buttonStyle(.plain)
                .foregroundStyle(.primary)
        }
    }
}
