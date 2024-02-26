//
//  LFO3.swift
//  PocketOperatorSwift
//
//  Created by Edwin Nwosu on 18/03/2024.
//

import Foundation


public class LFO3 : ObservableObject
{
  
  @Published var angle : Float = 0;
  @Published var intensity : Float = 0;
  public enum Waveform
  {
    case Sine
    case Saw
    case Square
    case Random
  }
  
  public enum Rate
  {
    case Eighth
    case Quarter
    case Half
    case Whole
  }
  
  var wave : Waveform
  var rate : Rate
  
  init()
  {
    wave = Waveform.Sine
    rate = Rate.Half
  }
  
  func deg2rads(_ angle : Float) -> Float
  {
    angle * ((2 * 3.14)/180)
  }
  
  public func get_value() -> Float
  {
    if(wave == Waveform.Sine)
    {
      return sin(deg2rads(angle))
    }

    if(wave == Waveform.Saw)
    {
      return sin(angle)
    }

    if(wave == Waveform.Square)
    {
      return sin(deg2rads(angle)) + (0.33333 * sin (deg2rads(3 * angle))) + (0.2 * sin(deg2rads( 5 * angle))) + (0.124 * sin(deg2rads( 7 * angle)))
    }

    if(wave == Waveform.Random)
    {
      return sin(angle)
    }

    return sin(angle)

  }
  
  public func update()
  {
    if(rate == Rate.Eighth)
    {
      angle = angle + 2.8125;
    }
    
    if(rate == Rate.Quarter)
    {
      angle = angle + 5.625;
    }
    
    if(rate == Rate.Half)
    {
      angle = angle + 11.25;
    }
    
    if(rate == Rate.Half)
    {
      angle = angle + 22.5;
    }
  }
}
