//
//  CameraView.swift
//  https://github.com/0Itsuki0/BasicAVCamera
//
//  Created by Itsuki on 2024/05/18.
//

import SwiftUI

struct CameraView: View {
    @StateObject var model: CameraModel

    var body: some View {
        GeometryReader { geometry in
            if let image = model.previewImage {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
                    .clipped()
                    .onAppear {
                        model.camera.isPreviewPaused = false
                    }
                    .onDisappear {
                        model.camera.isPreviewPaused = true
                    }
            }
        }
        .task {
            await model.camera.start()
        }
        .ignoresSafeArea(.all)
        .environmentObject(model)
    }
}

#Preview {
    CameraView(model: CameraModel())
}
