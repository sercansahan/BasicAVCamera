//
//  CameraView.swift
//  https://github.com/0Itsuki0/BasicAVCamera
//
//  Created by Itsuki on 2024/05/18.
//

import SwiftUI

struct CameraView: View {
    @Bindable var model: CameraModel

    var body: some View {
        GeometryReader { geometry in
            if let image = model.previewImage {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
                    .clipped()
                    .onAppear {
                        model.cameraManager.isPreviewPaused = false
                    }
                    .onDisappear {
                        model.cameraManager.isPreviewPaused = true
                    }
            }
        }
        .onAppear {
            Task {
                await model.cameraManager.start()
            }
        }
        .onDisappear {
            model.cameraManager.stop()
        }
        .ignoresSafeArea(.all)
        .environment(model)
    }
}
