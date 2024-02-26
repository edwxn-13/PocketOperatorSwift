//
//  ContentView.swift
//  PocketOperatorSwift
//
//  Created by Edwin Nwosu on 26/02/2024.
//

import SwiftUI
import AudioKit
import SoundpipeAudioKit
import AudioKitEX

struct ContentView: View {

  var editSequencer = false
  
  
    var body: some View {
      ZStack{
        VStack {
          PocketSequencerView()
        }
        .padding().onAppear()
      }
    }
}

#Preview {
    ContentView()
}
