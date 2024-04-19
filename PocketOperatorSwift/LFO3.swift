//
//  LFO3.swift
//  PocketOperatorSwift
//
//  Created by Edwin Nwosu on 18/03/2024.
//

import Foundation
import SwiftUI

public enum Waveform2
{
  case Sine
  case Saw
  case Square
  case Random
}

public class LFO3 : ObservableObject
{
  @Published var angle : Float = 0;
  @Published var intensity : Float = 0;
 
  @Published var wave : Waveform2
  @Published var rate : division
  
  init()
  {
    wave = Waveform2.Sine
    rate = division.Half
  }
  
  func deg2rads(_ angle : Float) -> Float
  {
    angle * ((2 * 3.14)/180)
  }
  
  public func get_value() -> Float
  {
    
    var value : Float = 0;
    if(wave == Waveform2.Sine)
    {
      value = sin(deg2rads(angle))
    }
    if(wave == Waveform2.Saw)
    {
      value =  sin(angle)
    }
    if(wave == Waveform2.Square)
    {
      value = sin(deg2rads(angle)) + (0.33333 * sin (deg2rads(3 * angle))) + (0.2 * sin(deg2rads( 5 * angle))) + (0.124 * sin(deg2rads( 7 * angle)))
    }
    if(wave == Waveform2.Random)
    {
      value =  sin(angle)
    }
    
    value = (value + 1)/2
    
    return value * intensity
  }
  
  public func update()
  {
    if(rate == division.Sixteenth)
    {
      angle = angle + (45/8);
    }
    if(rate == division.Eighth)
    {
      angle = angle + (22.5/8);
    }
    if(rate == division.Quarter)
    {
      angle = angle + (11.25/8);
    }
    if(rate == division.Half)
    {
      angle = angle + (5.625/8);
    }
    print(get_value() , "\n")
  }
}


struct LFOManger : View {
  @EnvironmentObject var parent_class: LFO3
  
  public var label : String
  
  var body: some View
  {
    VStack
    {
      Text(label)
      HStack{
        Text("Intensity")
        Slider(value: $parent_class.intensity , in: 0...1, step: 0.01)
      }
    }
    HStack {
      Picker("Rate", selection: $parent_class.rate) {
        Text("Sixteenth").tag(division.Sixteenth)
        Text("Eight").tag(division.Eighth)
        Text("Quarter").tag(division.Dotted)
        Text("Half").tag(division.Half)
      }.pickerStyle(SegmentedPickerStyle())
    }
    HStack {
      Picker("Wave Type", selection: $parent_class.wave) {
        Text("Sin").tag(Waveform2.Sine)
        Text("Square").tag(Waveform2.Square)
        Text("Saw").tag(Waveform2.Saw)
        Text("Random").tag(Waveform2.Random)
      }.pickerStyle(SegmentedPickerStyle())
    }
  }
  
}
