//
//  PocketSynth.swift
//  PocketOperatorSwift
//
//  Created by Edwin Nwosu on 13/03/2024.
//

import Foundation
import AVFoundation
import AudioKit

class PocketSynth : Node
{
  
  var pocket_synth = AVAudioUnitMIDIInstrument()
  
  var connections: [AudioKit.Node] = []
  
  var avAudioNode: AVAudioNode {pocket_synth}
  

  
  
}
