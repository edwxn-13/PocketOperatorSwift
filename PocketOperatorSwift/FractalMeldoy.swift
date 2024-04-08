//
//  FractalMeldoy.swift
//  PocketOperatorSwift
//
//  Created by Edwin Nwosu on 18/03/2024.
//

import Foundation


enum division : Int
{
  case Sixteenth = 1
  case Eighth = 2
  case Dotted = 3
  case Quarter = 4
  case Half = 8
  case HalfDotted = 6

}


class MutationMelody
{
  
  var major_scale : KeyScale
  var trigger_note : Int = 0

  public var melody : [Int]
  public var former_melody : [Int]
  public var temp_melody : [Int]
  
  public var generations : [[Int]] = []
  
  public var rhythm : division = division.Sixteenth
  
  var generation = 0
  var chosen_melody = 0
  
  init(major_scale: KeyScale)
  {
    melody = Array(repeating: 7, count: 16)
    former_melody = Array(repeating: 7, count: 16)
    temp_melody = Array(repeating: 7, count: 16)
    generations.append(melody)
    self.major_scale = major_scale
  }

  func update_scale(_ major_scale: KeyScale)
  {
    self.major_scale = major_scale
  }
  
  func child_note(_ parent : Int , _ s_parent : Int) -> Int
  {
    var child = ((3 * parent) + (2 * s_parent)) / 5
    return child
  }
  
  public func child_melody()
  {
    
    if(generation > 5)
    {
      if(Int.random(in: 0..<15) < 10)
      {
        return
      }
    }
    temp_melody = melody
    mutate(index: Int.random(in: 0..<4))
    
    for i in 0..<melody.count
    {
      melody[i] = child_note(melody[i], former_melody[i])
    }
    generation = generation + 1
    former_melody = temp_melody
    generations.append(melody)
  }
  
  
  func mutate(index : Int)
  {
    for i in 0..<index
    {
      var randomizer = Int.random(in: 0..<32)
      
      if(randomizer > 15)
      {
        var octave = melody[randomizer - 16] + 7
        
        if(octave > major_scale.get_size())
        {
          melody[randomizer - 16] = octave/2
        }
        else{ melody[randomizer - 16] = octave }
      }
      
      else
      {
        var note = melody[randomizer] + Int.random(in: 0..<14)
        
        melody[randomizer] = note
        
        if(note > major_scale.get_size())
        {
          melody[randomizer] = note / 2
        }
        else { melody[randomizer] = note }
        
      }
    }
  }
  
  func get_note(_ step : Int) -> Note
  {
    return major_scale.get_scale_note(index: melody[step]);
  }
  
  func get_rendered_note(_ step : Int) -> Note
  {
    return major_scale.get_scale_note(index: generations[next_melody_random()][step]);
  }
  
  func get_rendered_note2(_ step : Int) -> Note
  {
    return major_scale.get_scale_note(index: generations[chosen_melody][step]);
  }
  
  public func next_melody_random() -> Int
  {
    switch Int.random(in: 0..<3)
    {
    case 0:
      chosen_melody = chosen_melody + 1
      return chosen_melody
    default:
      return chosen_melody
    }
  }
  
  public func next_gen()
  {
    chosen_melody = chosen_melody + 1
  }
  
  func switch_rhythm()
  {
    switch Int.random(in: 0..<7) {
    case 0:
      rhythm = division.Sixteenth
    case 1:
      rhythm = division.Eighth
    case 2:
      rhythm = division.Half
    case 3:
      rhythm = division.Dotted
    default:
      return
    }
  }
}
