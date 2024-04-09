//
//  KeyScale.swift
//  PocketOperatorSwift
//
//  Created by Edwin Nwosu on 01/03/2024.
//

import Foundation


class KeyScale
{
  public static func get_ninth(note: Note) -> Note
  {
    return Note(position: 1, semitone: note.semitone + 14)
  }
  
  public static func get_seventh(note: Note) -> Note
  {
    return Note(position: 1, semitone: note.semitone + 11)
  }
  
  public static func get_mSeventh(note: Note) -> Note
  {
    return Note(position: 1, semitone: note.semitone + 10)
  }
  
  public static func get_fifth(note: Note) -> Note
  {
    return Note(position: 1, semitone: note.semitone + 7)
  }
  
  
  public static func get_mFifth(note: Note) -> Note
  {
    return Note(position: 1, semitone: note.semitone + 6)
  }
  
  
  public static func get_third(note: Note) -> Note
  {
    return Note(position: 1, semitone: note.semitone + 4)
  }
  
  public static func get_mThird(note: Note) -> Note
  {
    return Note(position: 1, semitone: note.semitone + 3)
  }
  
  
  public static func get_ambiguous_seventh(targetNote: Note) -> Note
  {
    if(targetNote.position == 1 || targetNote.position == 4 )
    {
      return get_seventh(note: targetNote)
    }
    
    else if(targetNote.position == 7)
    {
      return Note(position: 7, semitone: (targetNote.semitone + 12))
    }
    
    else
    {
      return get_mSeventh(note: targetNote)
    }
  }
  
  public static func get_ambiguous_third(targetNote: Note) -> Note
  {
    if(targetNote.position == 1 || targetNote.position == 4 || targetNote.position == 5 )
    {
      return get_third(note: targetNote)
    }
    
    else
    {
      return get_mThird(note: targetNote)
    }
    
  }
  
  public static func get_ambiguous_fifth(targetNote: Note) -> Note
  {
    if(targetNote.position == 7)
    {
      return get_mFifth(note: targetNote)
    }
    
    else
    {
      return get_fifth(note: targetNote)
    }
    
  }
  
  
  public var offset = 0
  
  private var key_scale : [Note] = Array()
  
  public func getNoteNumber(position : Int, octave: Int) -> Int
  {
    var ordinance = position + 1
    var octave_range = octave
    
    if(position > 7)
    {
      ordinance = 1
      octave_range = octave + 1
    }
    var temp_semitone : Int = key_scale[ordinance - 1].semitone
    temp_semitone += (octave_range * 12)
    return temp_semitone;
  }
  
  public func get_root(octave : Int) -> Note
  {
    var index = 0
    
    for i in 0..<octave
    {
      index = (i * 7)
    }
    
    return key_scale[index]
  }
  
  
  public func get_scale_note(index : Int) -> Note
  {
    return key_scale[index]
  }
  
  public func get_size() -> Int
  {
    return key_scale.count
  }
  
  public init(_ offset:Int, _ type:Int)
  {
    
    self.offset = offset
    var temp_scale : [Note]
    
    temp_scale = [
      Note(position: 1, semitone: 36 + offset),
      Note(position: 2, semitone: 38 + offset),
      Note(position: 3, semitone: 40 + offset),
      Note(position: 4, semitone: 41 + offset),
      Note(position: 5, semitone: 43 + offset),
      Note(position: 6, semitone: 45 + offset),
      Note(position: 7, semitone: 47 + offset)]
    
    if(type == 1)
    {
      temp_scale = [
        Note(position: 1, semitone: 36 + offset),
        Note(position: 2, semitone: 38 + offset),
        Note(position: 3, semitone: 40 + offset),
        Note(position: 4, semitone: 41 + offset),
        Note(position: 5, semitone: 43 + offset),
        Note(position: 6, semitone: 45 + offset),
        Note(position: 7, semitone: 47 + offset)]
    }
    
    if(type == 2)
    {
      temp_scale = [
        Note(position: 2, semitone: 36 + offset),
        Note(position: 3, semitone: 38 + offset),
        Note(position: 4, semitone: 39 + offset),
        Note(position: 5, semitone: 41 + offset),
        Note(position: 6, semitone: 43 + offset),
        Note(position: 7, semitone: 45 + offset),
        Note(position: 1, semitone: 46 + offset)]
    }
    
    if(type == 3)
    {
      temp_scale = [
        Note(position: 3, semitone: 36 + offset),
        Note(position: 4, semitone: 37 + offset),
        Note(position: 5, semitone: 39 + offset),
        Note(position: 6, semitone: 41 + offset),
        Note(position: 7, semitone: 43 + offset),
        Note(position: 1, semitone: 44 + offset),
        Note(position: 2, semitone: 46 + offset)]
    }
    
    if(type == 4)
    {
      temp_scale = [
        Note(position: 4, semitone: 36 + offset),
        Note(position: 5, semitone: 38 + offset),
        Note(position: 6, semitone: 40 + offset),
        Note(position: 7, semitone: 42 + offset),
        Note(position: 1, semitone: 43 + offset),
        Note(position: 2, semitone: 45 + offset),
        Note(position: 3, semitone: 47 + offset)]
    }
    
    if(type == 5)
    {
      temp_scale = [
        Note(position: 5, semitone: 36 + offset),
        Note(position: 6, semitone: 38 + offset),
        Note(position: 7, semitone: 40 + offset),
        Note(position: 1, semitone: 41 + offset),
        Note(position: 2, semitone: 43 + offset),
        Note(position: 3, semitone: 45 + offset),
        Note(position: 4, semitone: 46 + offset)]
    }
    if(type == 6)
    {
      temp_scale = [
        Note(position: 6, semitone: 36 + offset),
        Note(position: 7, semitone: 38 + offset),
        Note(position: 1, semitone: 39 + offset),
        Note(position: 2, semitone: 41 + offset),
        Note(position: 3, semitone: 43 + offset),
        Note(position: 4, semitone: 44 + offset),
        Note(position: 5, semitone: 46 + offset)]
    }
    if(type == 7)
    {
      temp_scale = [
        Note(position: 7, semitone: 36 + offset),
        Note(position: 1, semitone: 37 + offset),
        Note(position: 2, semitone: 39 + offset),
        Note(position: 3, semitone: 41 + offset),
        Note(position: 4, semitone: 42 + offset),
        Note(position: 5, semitone: 44 + offset),
        Note(position: 6, semitone: 46 + offset)]
    }
    
    for octave in 0..<9
    {
      for i in 0..<temp_scale.count
      {
        var holder : Int = temp_scale[i].semitone
        key_scale.append(Note(position: (i+1), semitone: holder))
        temp_scale[i].semitone += (12)
      }
    }
  }
  
  /*public oldinit(_ offset:Int)
  {
    
    self.offset = offset
    let temp_scale : [Note] = [
      Note(position: 1, semitone: 36 + offset),
      Note(position: 2, semitone: 38 + offset),
      Note(position: 3, semitone: 40 + offset),
      Note(position: 4, semitone: 41 + offset),
      Note(position: 5, semitone: 43 + offset),
      Note(position: 6, semitone: 45 + offset),
      Note(position: 7, semitone: 47 + offset)]
    
    for octave in 0..<9
    {
      for i in 0..<temp_scale.count
      {
        var holder : Int = temp_scale[i].semitone
        key_scale.append(Note(position: (i+1), semitone: holder))
        temp_scale[i].semitone += (12)
      }
    }
  }*/
  
  public func find(_ midi_number:Int, _ interval:Int) -> Note
  {
    return key_scale[binaryNoteSearch(0, key_scale.count, midi_number + interval)]
  }

  public func findIndividual(_ midi_number:Int) -> Note
  {
    return key_scale[binaryNoteSearch(0, key_scale.count, midi_number)]
  }
  
  public func findBasedOnPosition(_ position : Int, _ octave : Int) -> Note
  {
    var midi_number : Int = 0
    switch position {
    case 1:
      midi_number = (36 + offset)
    case 2:
      midi_number = (38 + offset)
    case 3:
      midi_number = (40 + offset)
    case 4:
      midi_number = (41 + offset)
    case 5:
      midi_number = (43 + offset)
    case 6:
      midi_number = (45 + offset)
    case 7:
      midi_number = (47 + offset)
    default:
      midi_number = (38 + offset)
    }
    
    for i in 0..<octave
    {
      midi_number = midi_number + 12;
    }
    
    return key_scale[binaryNoteSearch(0, key_scale.count, midi_number)]
  }
  
  
  public func binaryNoteSearch( _ lower:Int , _ upper:Int, _ value:Int) -> Int
  {
    
    var high : Int = upper
    var low : Int = lower
    var middle : Int

    
    while (high >= low)
    {
      middle = (high + low) / 2
      
      if(key_scale[middle].semitone < value)
      {
        low = middle + 1
      }
      
      else if(key_scale[middle].semitone > value)
      {
        high = middle - 1
      }
      
      else
      {
        return middle
      }
    }
    
    return -1
  }
  
  
}
