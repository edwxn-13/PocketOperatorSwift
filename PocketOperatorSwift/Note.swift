//
//  Note.swift
//  PocketOperatorSwift
//
//  Created by Edwin Nwosu on 01/03/2024.
//

import Foundation

class Note
{
  public var position: Int;
  public var semitone: Int;
  
  init(position: Int, semitone: Int) 
  {
    self.position = position
    self.semitone = semitone
  }
}

class NoteQueue
{
  private var pointer: Int
  private var note_queue : [Note] = Array()

  public init()
  {
    pointer = 0
  }

  public func add( _ new_note : Note)
  {
    note_queue.append(new_note)
  }

  public func pop_queue() -> Note
  {
    var value : Note = note_queue[pointer]
    pointer += 1
    return value
  }

  public func size() -> Int
  {
    return note_queue.count
  }

  public func isEmpty() -> Bool
  {
    if note_queue.count == 0 {return true}
    if note_queue.count == pointer {return true}
    return false
  }

};
