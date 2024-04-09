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

class MarkovManger
{
  public static func generate_stage_weight(selected : [Float], _ weight : Float) -> [Float]
  {
    var temp_array : [Float] = Array(repeating: 0, count: selected.count)
    var max : Float = 1;
    var tempMax : Float = 1
    for i in 0..<selected.count
    {
      tempMax = max
      let roll = calc_weight(index: i, weight: weight, size: selected.count, floor: max)
      max = max - roll
     
      if roll > tempMax
      {
        temp_array[i] = (max)
        break
      }
      
      if (i == selected.count-1)
      {
        temp_array[i] = (max)
        break
      }
      
      temp_array[i] = (roll)
    }
    
    return temp_array
  }
  
  public static func calc_weight(index : Int , weight : Float, size : Int, floor : Float) -> Float
  {
    var upper : Float = 0;
    if(weight > 0.5)
    {
      upper = weight
    }
    if(weight < 0.5)
    {
      upper = weight
    }
    
    let roll : Float = round(Float.random(in: 0..<weight) * 100)/100
    
    return roll
  }
}

class RhythmController
{
  var chord_number : Int = 0
  
  var rhythm_map : [division] = [division.Sixteenth, division.Eighth, division.Quarter, division.Dotted, division.Half]
  
  var transition_diagram : [[Float]] = [
    [0.3,0.2,0.2,0.2,0.1],
    [0.3,0.2,0.2,0.2,0.1],
    [0.2,0.2,0.2,0.2,0.2],
    [0.2,0.2,0.2,0.2,0.2],
    [0.2,0.2,0.2,0.2,0.2],
  ]
  public var r_progression : [Int] = [0 , 4 , 5, 2]
  
  
  func generate_transition_diagram(weight : Float)
  {
    for i in 0..<transition_diagram.count
    {
      transition_diagram[i] = MarkovManger.generate_stage_weight(selected: transition_diagram[i], weight)
    }
  }
  
  func generate_progression()
  {
    r_progression[0] = next_chord_markov(r_progression[3])
    
    for i in 0..<(r_progression.count - 1)
    {
      r_progression[i + 1] = next_chord_markov(r_progression[i])
    }
  }
  
  func next_chord_markov(_ chord : Int) -> Int
  {
    let selected = transition_diagram[chord]
    let roll = Float.random(in: 0..<1)
    var sum : Float = 0
    var result = 0
    
    for prob in selected
    {
      sum = sum + prob
      if roll < sum
      {
        return result
      }
      result = result + 1
    }
    
    return 0
  }
}



class MutationMelody
{
  
  var major_scale : KeyScale
  var trigger_note : Int = 0
  
  var rhythm_grid : [division] = [division.Sixteenth, division.Quarter, division.Dotted, division.Dotted]
  
  var rhythm_manager = RhythmController()
  var rhythm_index : Int = 0
  
  public var melody : [Int]
  public var former_melody : [Int]
  public var temp_melody : [Int]
  
  public var generations : [[Int]] = []
  
  public var rhythm : division = division.Sixteenth
  
  var generation = 0
  var chosen_melody = 0
  
  func next_rhythm()
  {
    rhythm_index = rhythm_index + 1
    if(rhythm_index > 3)
    {
      rhythm_index = 0
    }
  }
  
  func get_next_rhythm()
  {
    next_rhythm()
    rhythm = rhythm_grid[rhythm_index]
  }
  
  
  func gen_rhythm()
  {
    if(generation % 4 == 0)
    {
      rhythm_manager.generate_progression()
      for i in 0..<rhythm_grid.count {
        rhythm_grid[i] = rhythm_manager.rhythm_map[rhythm_manager.r_progression[i]]
      }
    }
  }
  
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
    display_melody()
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
  
  func display_melody()
  {
    print("melody :", melody)
    print("\n")
    for _ in 0..<400
    {
      print("\n")
    }
  }
}
