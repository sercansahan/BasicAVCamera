//
//  SaveImageView.swift
//  BasicAVCamera
//
//  Created by Itsuki on 2024/05/19.
//

import SwiftUI

struct SaveImageView: View {
    @StateObject var model: CameraModel
    
    @State private var saved = false
    
    private let headerHeight: CGFloat = 90.0

    var body: some View {
        GeometryReader { geometry in
            if let image = model.photoData?.image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
                    .clipped()
                    .padding(.top, headerHeight)
                    .overlay(alignment: .top) {
                        buttonsView()
                            .frame(height: headerHeight)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .background(.gray.opacity(0.4))
                    }
                    .padding(.bottom, 16)
                    .background(Color.black)
            }
        }
    }
    
    private func buttonsView() -> some View {
        HStack {
            Button {
                model.photoData = nil
            } label: {
                Image(systemName: "chevron.left")
            }
            
            Spacer()

            Button {
                Task {
                    await model.savePhoto()
                    withAnimation {
                        self.saved = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                            self.saved = false
                        })
                    }
                }
            } label: {
                Image(systemName: saved ? "checkmark" : "square.and.arrow.down")
            }
        }
        .font(.system(size: 24, weight: .bold))
        .foregroundColor(.white)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, 32)
    }
}
