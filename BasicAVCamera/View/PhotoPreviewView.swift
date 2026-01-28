//
//  PhotoPreviewView.swift
//  BasicAVCamera
//
//  Created by Itsuki on 2024/05/19.
//

import SwiftUI

struct PhotoPreviewView: View {
    @StateObject var model: CameraModel

    var body: some View {
        if let image = model.photoData?.image {
            GeometryReader { geometry in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
                    .clipped()
                    .background(Color.black)
            }
        } else {
            Spacer()
        }
    }
}
