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

    var body: some View {
        ZStack {
            if let _ = model.photoData {
                VStack {
                    topButtonsView()
                    PhotoPreviewView(model: model)
                }
            } else if let _ = model.movieFileUrl {
                VStack {
                    topButtonsView()
                    VideoPreviewView(model: model)
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
                if model.photoData != nil {
                    model.photoData = nil
                } else if model.movieFileUrl != nil {
                    model.movieFileUrl = nil
                }
            }
            Spacer()
            TopActionButton(.save) {
                Task {
                    if model.photoData != nil {
                        await model.savePhoto()
                    } else if model.movieFileUrl != nil {
                        await model.saveVideo()
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
                    if let photoData {
                        let data = self.resizePhotoData(photoData)
                        print("Size: \((data?.count ?? 0) / 1024) KB")
                    }
                }
                model.camera.takePhoto()
            } else {
                isRecording.toggle()
                if isRecording {
                    model.camera.startRecordingVideo()
                } else {
                    model.camera.stopRecordingVideo()
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
            model.camera.switchCaptureDevice()
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
