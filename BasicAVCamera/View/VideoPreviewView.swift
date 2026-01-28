//
//  VideoPreviewView.swift
//  BasicAVCamera
//
//  Created by Itsuki on 2024/05/19.
//

import SwiftUI
import AVKit

struct VideoPreviewView: View {
    @StateObject var model: CameraModel

    var body: some View {
        if let url = model.movieFileUrl {
            VideoPlayer(player: AVPlayer(url: url))
                .background(Color.black)
                .onAppear {
                    print(url)
                }
                .onDisappear {
                    Task {
                        try? FileManager().removeItem(at: url)
                    }
                }
        } else {
            Spacer()
        }
    }
}
