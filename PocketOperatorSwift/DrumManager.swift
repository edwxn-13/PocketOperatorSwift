//
//  DrumManager.swift
//  PocketOperatorSwift
//
//  Created by Edwin Nwosu on 18/03/2024.
//

import AudioKit
import AudioKitEX
import AudioKitUI
import AVFoundation
import Combine
import SwiftUI


struct Sample {
  var name: String
  var fileName: String
  var midiNote: Int
  var audioFile: AVAudioFile?
  
  init(_ drumPath: String, file: String, note: Int)
  {
    name = drumPath
    fileName = file
    midiNote = note
    
    do
    {
      var path = file
      if let fileURL = Bundle.main.url(forResource: path, withExtension: "wav")
      {
        try audioFile = AVAudioFile(forReading: fileURL)
      }
      else {
        Log("Could not find file")
      }
    } catch {
      Log("Could not load instrument")
    }
  }
}

class DrumManager : ObservableObject {
  
  let hats = AppleSampler()
  let clap = AppleSampler()
  let kick = AppleSampler()
  
  @Published var kick_sequence : [Bool] = Array(repeating: false, count: 16)
  @Published var hat_sequence : [Bool] = Array(repeating: false, count: 16)
  @Published var snare_sequence : [Bool] = Array(repeating: false, count: 16)

  var type : Int = 0
  
  func trap_pattern(_ step_number : Int , _ interval : Int)
  {
    hats.play(noteNumber: MIDINoteNumber(70))
    
    if(interval == 4)
    {
      clap.play(noteNumber: MIDINoteNumber(70))
    }
    
    if(interval == 12)
    {
      clap.play(noteNumber: MIDINoteNumber(70))
    }
    
    if(interval == 0)
    {
      kick.play(noteNumber: MIDINoteNumber(70))
    }
    
    if(interval == 3)
    {
      kick.play(noteNumber: MIDINoteNumber(70))
    }
    
    if(interval == 10)
    {
      kick.play(noteNumber: MIDINoteNumber(70))
    }
  }
  
  func simple_pattern(_ step_number : Int , _ interval : Int)
  {
    
    if(interval == 4)
    {
      clap.play(noteNumber: MIDINoteNumber(70))
    }
    
    if(interval == 12)
    {
      clap.play(noteNumber: MIDINoteNumber(70))
    }
    
    if(interval == 0)
    {
      kick.play(noteNumber: MIDINoteNumber(70))
    }
    
    if(interval == 4)
    {
      kick.play(noteNumber: MIDINoteNumber(70))
    }
    
    if(interval == 8)
    {
      kick.play(noteNumber: MIDINoteNumber(70))
    }
    
    if(interval == 12)
    {
      kick.play(noteNumber: MIDINoteNumber(70))
    }
    
    
  }
  
  
  func custom_pattern(_ step_number : Int , _ interval : Int)
  {
    if(hat_sequence[interval] == true)
    {
      hats.play(noteNumber: MIDINoteNumber(70))
    }
    
    if(snare_sequence[interval] == true)
    {
      clap.play(noteNumber: MIDINoteNumber(70))
    }
    
    if(kick_sequence[interval] == true)
    {
      kick.play(noteNumber: MIDINoteNumber(70))
    }

  }
  
  func drum_pattern(_ step_number : Int , _ interval : Int)
  {
    if(type == 0){trap_pattern(step_number, interval)}
    if(type == 1){simple_pattern(step_number, interval)}
    if(type == 2){simple_pattern(step_number, interval)}
    if(type == 3){custom_pattern(step_number, interval)}

    
  }
  init(drumOption : Int) {
    
    type = drumOption
    
    do
    {
      var path = "drumSamples/hat"
      if let fileURL = Bundle.main.url(forResource: path, withExtension: "wav")
      {
        try hats.loadWav("drumSamples/hat")
      }
      else {
        Log("Could not find file")
      }
    } catch {
      Log("Could not load instrument")
    }
    
    do
    {
      var path = "drumSamples/clap"
      if let fileURL = Bundle.main.url(forResource: path, withExtension: "wav")
      {
        try clap.loadWav("drumSamples/clap")
      }
      else {
        Log("Could not find file")
      }
    } catch {
      Log("Could not load instrument")
    }
    
    do
    {
      var path = "drumSamples/kick"
      if let fileURL = Bundle.main.url(forResource: path, withExtension: "wav")
      {
        try kick.loadWav("drumSamples/kick")
      }
      else {
        Log("Could not find file")
      }
    } catch {
      Log("Could not load instrument")
    }
    
    kick.amplitude = 8;
    hats.amplitude = 4;
    clap.amplitude = 6;
  }
  
  
  
}
