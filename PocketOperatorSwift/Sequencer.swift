//
//  Sequencer.swift
//  PocketOperatorSwift
//
//  Created by Edwin Nwosu on 27/02/2024.
//

import Foundation
import AudioKit
import AudioKitEX
import AudioKitUI
import AVFoundation
import SoundpipeAudioKit
import SwiftUI
import Controls
import Darwin
import Tonic
import BackgroundTasks

struct PocketSequencerData
{
  public var drum_vol: Float = 1;
  public var pad_vol: Float = 0.8;
  public var melody_vol: Float = 0.3;
  public var lead_vol: Float = 0.6;
  public var step_len: Double = 0.8;
  public var bpm : Double = 100;
  public var master_vol : Float = 0.8;
  public var key_offset : Int = 0;
  public var fm1 : Float = 1;
  public var fm2 : Float = 1;

  init(drum_vol: Float, pad_vol: Float, melody_vol: Float, lead_vol: Float, step_len: Double, bpm: Double, master_vol: Float) {
    self.drum_vol = drum_vol
    self.pad_vol = pad_vol
    self.melody_vol = melody_vol
    self.lead_vol = lead_vol
    self.step_len = step_len
    self.bpm = bpm
    self.master_vol = master_vol
  }
}

class SpeedUtility
{
  var total_speed : Float = 0
  
  var average_speed : Float = 0
  
  var frequency : Int = 0
    
  var last_recorded_speed : Float = 0

  public func calculate_average(_ new_speed : Float)
  {
    last_recorded_speed = new_speed
    frequency += 1
    total_speed += new_speed
    average_speed = total_speed / Float(frequency)
    
    if(average_speed < 0.005)
    {
      frequency = 0;
    }
  }
  
  public func get_average_speed() -> Float
  {
    return average_speed
  }
  
  public func get_bpm(_ initial_bpm : Float) -> Float
  {
    var bpm_index = ((average_speed/10.0) * 100)
    var bpm = initial_bpm + (bpm_index)
    
    if bpm > 150
    {
      return 150
    }
    return bpm
  }
}

class ChordController
{
  var chord_number : Int = 0
  
  var transition_diagram : [[Float]] = [
    [0.2, 0.2, 0, 0.2, 0.2, 0.2, 0],
    [0.1, 0.1, 0.2, 0.1, 0.3, 0.15, 0.15],
    [0.2, 0.3, 0, 0.3, 0.1, 0, 0.1],
    [0.1, 0.2, 0.2, 0.1, 0.3, 0, 0.1],
    [0.4, 0.1, 0, 0.2, 0, 0.2, 0.1],
    [0.2, 0.1, 0.1, 0, 0.2, 0.3, 0.1],
    [0.5, 0.3, 0, 0, 0.1, 0.1, 0]
  ]
  public var chord_progression : [Int] = [0 , 4 , 5, 2]
  
  func generate_progression()
  {
    chord_progression[0] = next_chord(chord_progression[3])
    
    for i in 0..<(chord_progression.count - 1) 
    {
      chord_progression[i + 1] = next_chord_markov(chord_progression[i])
    }
  }
  
  
  
  func old_generate_progression()
  {
    chord_progression[0] = next_chord(chord_progression[3])
    
    for i in 0..<(chord_progression.count - 1)
    {
      chord_progression[i + 1] = next_chord(chord_progression[i])
    }
  }
  
  func next_chord_markov(_ chord : Int) -> Int
  {
    var selected = transition_diagram[chord]
    var roll = Float.random(in: 0..<1)
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
  func next_chord(_ chord : Int) -> Int
  {
    var the_next_chord : Int = 0
    var randomizer = Int.random(in: 0..<4)

    switch chord {
      
    case 0:
      if(randomizer == 0){the_next_chord = 1}
      
      else if(randomizer == 1){the_next_chord = 5}
      
      else if(randomizer == 2){the_next_chord = 3}

      else{the_next_chord = 4}
      
      break;
      
    case 1:
      if(randomizer == 0){the_next_chord = 2}
      
      else if(randomizer == 1){the_next_chord = 5}
      
      else if(randomizer == 2){the_next_chord = 4}

      else{the_next_chord = 0}
      
      break;
      
    case 2:
      if(randomizer == 0){the_next_chord = 1}
      
      else if(randomizer == 1){the_next_chord = 3}
      
      else if(randomizer == 2){the_next_chord = 5}

      else{the_next_chord = 0}
      
      break;
      
    case 3:
      if(randomizer == 0){the_next_chord = 0}
      
      else if(randomizer == 1){the_next_chord = 4}
      
      else if(randomizer == 2){the_next_chord = 1}

      else{the_next_chord = 5}
      break;

    case 4:
      if(randomizer == 0){the_next_chord = 0}
      
      else if(randomizer == 1){the_next_chord = 1}
      
      else if(randomizer == 2){the_next_chord = 6}

      else{the_next_chord = 0}
      break;

    case 5:
      if(randomizer == 0){the_next_chord = 1}
      
      else if(randomizer == 1){the_next_chord = 2}
      
      else if(randomizer == 2){the_next_chord = 5}

      else{the_next_chord = 0}
      break;
      
    case 6:
      if(randomizer == 0){the_next_chord = 0}
      
      else if(randomizer == 1){the_next_chord = 2}
      
      else if(randomizer == 2){the_next_chord = 5}

      else{the_next_chord = 0}
      break;

    default:
      the_next_chord = 0
    }
    
    return the_next_chord
  }
  
}


class PocketSequencer: ObservableObject, HasAudioEngine
{
  
  var engine: AudioEngine = AudioEngine()
  
  @Published var playing : [Bool] = Array(repeating: false, count: 256)
  
  private var locationManager : UserLocationService = UserLocationService()
  private var filter: MoogLadder?
  let reverb: Reverb

  private var isPlaying: Bool!
  
  public var arp_synth = AppleSampler()
  
  public var bass_synth = SynthClass()
  public var harmony_synth = SynthClass()
  public var drone_synth = SynthClass()
  
  private var drum_mangager = DrumManager()
  
  private var mixer = Mixer()
  private var thread: MyThread!
  private var major_scale : KeyScale = KeyScale(0)
  
  public let x_size : Int = 8
  public let y_size : Int = 8
  
  private var beat_to_skip : Int = 2
  private var chordManager : ChordController
  private var melodyManager : MutationMelody

  private var speedUtility : SpeedUtility
  
  private var lastPlayed : Note = Note(position: 1, semitone: 60)
  
  @Published var amplitude : Float
  @State var volume: AmplitudeTap

  
  @Published public var sequencer_data =
  PocketSequencerData(drum_vol: 1, pad_vol: 1, melody_vol: 0.4, lead_vol: 0.3, step_len: 0, bpm: 155, master_vol: 0)
  {
    didSet
    {
      drum_mangager.clap.volume = sequencer_data.drum_vol
      drum_mangager.kick.volume = sequencer_data.drum_vol
      drum_mangager.hats.volume = sequencer_data.drum_vol
      
      harmony_synth.engine.mainMixerNode?.volume = sequencer_data.melody_vol
      bass_synth.engine.mainMixerNode?.volume = sequencer_data.lead_vol

      arp_synth.volume = sequencer_data.pad_vol

      //harmony_synth.engine.mainMixerNode?.volume = sequencer_data.pad_vol
      harmony_synth.osc[0].$carrierMultiplier.value = AUValue(sequencer_data.fm1)
      harmony_synth.osc[0].$modulatingMultiplier.value = AUValue(sequencer_data.fm2)
      
    }
  }

  init() {
    speedUtility = SpeedUtility();
    chordManager = ChordController();
    melodyManager = MutationMelody(major_scale: major_scale);
    
    drone_synth.env.attackDuration = 3;
    drone_synth.env.sustainLevel = 0.5;
    drone_synth.env.decayDuration = 8;
    drone_synth.env.releaseDuration = 1;
    drone_synth.data.amplitude = 0.1
    
    drone_synth.osc[0].$carrierMultiplier.value = 2
    drone_synth.osc[0].$modulatingMultiplier.value = 2;
    drone_synth.osc[0].modulationIndex = 2;
    drone_synth.revarb.dryWetMix = 60;
    
    drone_synth.osc[1].$carrierMultiplier.value = 2
    drone_synth.osc[1].$modulatingMultiplier.value = 2;
    drone_synth.osc[1].modulationIndex = 2;

    bass_synth.env.sustainLevel = 1;

    arp_synth.volume = 1;
    arp_synth.amplitude = 6;
  
    harmony_synth.data.amplitude = 0.1
    
    mixer = Mixer(arp_synth, drum_mangager.kick, drum_mangager.hats, drum_mangager.clap)
    mixer.volume = 0.9

    reverb = Reverb(mixer)
    filter = MoogLadder(reverb)
    reverb.loadFactoryPreset(.smallRoom)
    reverb.dryWetMix = 10;
    
    engine.output = filter
    
    filter?.cutoffFrequency = 20000;

    locationManager.UpdateLocation()
    
    amplitude = 5;

    volume = AmplitudeTap(mixer)
    volume.start()

    do
    {
      var path = "basicSamples/5shot3"
      if let fileURL = Bundle.main.url(forResource: path, withExtension: "wav")
      {
        try arp_synth.loadWav("basicSamples/pitchshiftedshot")
      }
      else {
        Log("Could not find file")
      }
    } catch {
      Log("Could not load instrument")
    }

    isPlaying = false;
    thread = MyThread(self)
  }
  
  public func start_sequencer()
  {
    isPlaying = true;
    var note_step:Int = 0
    var step:Int = 0
    
    do
    {
      try engine.start()
    }
    
    catch let err
    {
      
    }
    
    for i in 0..<1000
    {
      melodyManager.child_melody()
    }
    while isPlaying
    {
      //drone_synth.noteOn(pitch: Pitch( intValue: 48 + sequencer_data.key_offset), point: CGPoint(x: 1, y: 1))
      melodyManager.next_gen()
      for x in 0..<x_size
      {
        generate_next_step(note_step)
        speedUtility.calculate_average(Float(locationManager.getSpeed()))
        //sequencer_data.bpm = Double(speedUtility.get_bpm(Float(sequencer_data.bpm)))
        for y in 0..<y_size
        {
          filter?.cutoffFrequency = AUValue((calcFilterCutoff(cutoff: locationManager.getHeading())))
          bass_synth.filter.cutoffFrequency = AUValue((calcFilterCutoff(cutoff: locationManager.getHeading())))
          drone_synth.filter.cutoffFrequency = AUValue((calcFilterCutoff(cutoff: locationManager.getHeading())))
          harmony_synth.filter.cutoffFrequency = AUValue((calcFilterCutoff(cutoff: locationManager.getHeading())))

          if (playing[note_step] == true)
          {
            let scale_note : Int = major_scale.getNoteNumber(position: (note_step/x_size), octave: 1)
            let temp_note : Note = major_scale.findIndividual(scale_note)
            
            lastPlayed = temp_note
            arp_synth.play(noteNumber: MIDINoteNumber(temp_note.semitone - 12),velocity: 127, channel: 0)
            arp_synth.play(noteNumber: MIDINoteNumber(KeyScale.get_ambiguous_third(targetNote: temp_note).semitone - 12),velocity: 127, channel: 0)
            arp_synth.play(noteNumber: MIDINoteNumber(KeyScale.get_fifth(note: temp_note).semitone - 12),velocity: 127, channel: 0)

            bass_synth.noteOn(pitch: Pitch(intValue: temp_note.semitone - 12), point: CGPoint(x: 1, y: 1 ))
          }

          else
          {
            let scale_note2 : Int = major_scale.getNoteNumber(position: (note_step/x_size), octave: 1)
            let temp_note2 : Note = major_scale.findIndividual(scale_note2)
            bass_synth.noteOff(pitch: Pitch(intValue: temp_note2.semitone))
          }
          note_step += x_size
        }

        note_step += 1
        step_behaviour(note_step)

        if note_step > (x_size * y_size)
        {
          note_step = x
        }
      }
      
      chordManager.generate_progression()
      
    }
  }
  
  public func getAmplitude(target: Int) -> Float
  {
    DispatchQueue.main.async { [self] in
      
      switch target
      {
      case 1:
        amplitude = volume.amplitude.magnitude
      default:
        amplitude = volume.amplitude.magnitude
      }
    }
    return amplitude + (0.3 * amplitude)
  }
  
  private func step_behaviour(_ step_number : Int)
  {
    for i in 0 ..< 16
    {
      reset_harmony();
      play_harmony(i, step_number);
      play_arp(i);

      drum_mangager.drum_pattern(step_number, i)
      //thread.sequencer_sleep((60/sequencer_data.bpm)/2)
      if(i == 15)
      {
        thread.sequencer_sleep((60/sequencer_data.bpm)/7)
      }
      else
      {
        thread.sequencer_sleep((60/sequencer_data.bpm)/2)
      }
    }
  }
  
  private func generate_next_step(_ step_number : Int)
  {
    var step = step_number

    for i in 0 ..< y_size
    {
      playing[step] = false

      if(step / x_size == chordManager.chord_progression[step % 4])
      {
        playing[step] = true;
      }
      step += x_size
      if(step > x_size * y_size){step = step % x_size}
    }
  }
  
  private func get_interval(_ init_value : Int, _ interval : Int) -> Int
  {
    var final = init_value + interval

    if(final > 7)
    {
      final -= 8
    }
    return final
  }
  
  private func generate_next_harmony(_ step_number : Int)
  {
    var step = step_number
    
    if(Int.random(in: 0..<3) == 0)
    {
      return
    }

    for i in 0 ..< y_size
    {

      if(step / 16 == get_interval(chordManager.chord_progression[step % 4] , 2))
      {
        playing[step] = true;
      }
      step += 16

      if(step > x_size * y_size){step = step % x_size}
    }
  }
  
  private func clear_step(step_number : Int)
  {
    var step = step_number

    for i in 0 ..< y_size
    {
      playing[step] = false
      step += x_size
    }
    if(step > x_size * y_size){step = step % x_size}
  }

  private func play_note(note_number : Int)
  {
    arp_synth.play(noteNumber: MIDINoteNumber(note_number),velocity: 127, channel: 0)
  }

  private func decide_skip() -> Int
  {
    let randomInt = Int.random(in: 1..<3)
    return randomInt
  }

  public func stop_sequencer_thread()
  {
    thread.exit()
  }

  public func play_bassline()
  {
    //play chord root
  }

  public func play_harmony( _ beat:Int , _ step : Int)
  {
    if(beat % melodyManager.rhythm.rawValue == 0)
    {
      harmony_synth.noteOn(pitch: Pitch(intValue:melodyManager.get_rendered_note2(beat).semitone), point: CGPoint(x: 1, y: 1))
      //harmony_synth.noteOn(pitch: Pitch(intValue:melodyManager.get_note(beat).semitone), point: CGPoint(x: 1, y: 1))
      //harmony_synth.noteOn(pitch: Pitch(intValue:melodyManager.get_note(beat).semitone), point: CGPoint(x: 1, y: 1))
      //melodyManager.switch_rhythm()
    }
  }
  
  public func play_arp( _ beat:Int)
  {
    var division : Int
    division = beat
    if(beat > 4)
    {
      division = beat/2
    }
    //either play note passed in or next note in fractal
      switch (division % 4){
      case 0:
        arp_synth.play(noteNumber: MIDINoteNumber(KeyScale.get_ambiguous_third(targetNote: lastPlayed).semitone),velocity: 127, channel: 0)
        break;
        
      case 1:
        arp_synth.play(noteNumber: MIDINoteNumber(KeyScale.get_ambiguous_seventh(targetNote: lastPlayed).semitone),velocity: 127, channel: 0)
        break;
        
      case 2:
        arp_synth.play(noteNumber: MIDINoteNumber(lastPlayed.semitone + 12),velocity: 127, channel: 0)
        break;

      case 3:
        arp_synth.play(noteNumber: MIDINoteNumber(KeyScale.get_ambiguous_seventh(targetNote: lastPlayed).semitone),velocity: 127, channel: 0)
        break;

      default:
        break;
      }
  }
  
  public func reset_harmony()
  {
    harmony_synth.noteOff(pitch: Pitch(intValue: KeyScale.get_ambiguous_seventh(targetNote: lastPlayed).semitone))
    harmony_synth.noteOff(pitch: Pitch(intValue: KeyScale.get_ambiguous_seventh(targetNote: lastPlayed).semitone))
    harmony_synth.noteOff(pitch: Pitch(intValue:lastPlayed.semitone + 12))
    harmony_synth.noteOff(pitch: Pitch(intValue:lastPlayed.semitone + 12))
  }
  
  func start()
  {
    thread.start()
  }
  
  func calcFilterCutoff(cutoff : Double) -> Double
  {
    var interpolate = sin((cutoff/2) * (3.14159265359 / 180));
    
    if(interpolate < 0)
    {
      interpolate += (2 * interpolate)
    }
    var filterCutoff = interpolate * 19000
    
    return (20000 - filterCutoff)
  }
  class MyThread: Thread {
    
    public var parent_class: PocketSequencer
    
    init(_ parent_class: PocketSequencer) {
      self.parent_class = parent_class
    }

    let waiter = DispatchGroup()
    override func main() {
      parent_class.start_sequencer();
    }
    
    public func exit()
    {
      parent_class.isPlaying = false;
      Thread.exit()
    }
    
    public func sequencer_sleep (_ milliseconds : Double)
    {
      Thread.sleep(forTimeInterval: milliseconds)
    }
  }
}


struct PocketSequencerPadView :Identifiable, View {
  @EnvironmentObject var parent_class: PocketSequencer
  @GestureState private var isPressed = false
  var id: Int
  @State var isActive = false
  
  var body: some View
  {
    RoundedRectangle(cornerRadius: 0.5 ).fill(parent_class.playing[id] ? Color.red.opacity(0.2) : Color.red).aspectRatio(contentMode: .fit).gesture(DragGesture(minimumDistance: 0).updating($isPressed) { (value, gestureState, transaction) in
      gestureState = true
    })
  }
  
}


struct PocketSequencerView : View {
  
  @StateObject var parent_class = PocketSequencer()
  @State var isPlaying = false
  let range = -2 * CGFloat.pi ... 0
  let centre_x = UIScreen.main.bounds.width / 2
  let centre_y = 0
  let r: CGFloat = 100
  
  var body: some View {
    
    ZStack{
      VStack{
        ForEach(0..<40)
        {i in
          var angle =  5 * CGFloat.pi/40 * CGFloat(parent_class.getAmplitude(target: 22))
          let offset = CGPoint(x: CGFloat(centre_x) + (r * cos(angle * CGFloat(i))), y: CGFloat(centre_y) + (r * sin(angle * CGFloat(i))))
          
          HStack
          {
            Circle().fill(Color(red: Double(parent_class.getAmplitude(target: 22)), green: 0.8 - Double(parent_class.getAmplitude(target: 22)), blue: 1 - Double(parent_class.getAmplitude(target: 22)), opacity: 1)).frame(width: 50 * CGFloat(parent_class.getAmplitude(target: 22) * 3), height: 50 * CGFloat(parent_class.getAmplitude(target: 22) * 4)).onTapGesture
            {
              
            }.position(offset)
            
          }
        }
      }
      
      
      VStack{
        
        ForEach(0..<parent_class.y_size) { x in
          HStack{
            ForEach(0..<parent_class.x_size) { y in
              PocketSequencerPadView(id: y + (x * parent_class.x_size))
            }.environmentObject(parent_class)
          }
          
        }
        
        
        Text(isPlaying ? "stop" : "start").bold().foregroundColor(.blue).onTapGesture {
          isPlaying.toggle()
          if isPlaying
          {
            parent_class.start()
          }
          else
          {
            
          }
        }
        
        VStack
        {
          
          HStack{
            Text("BPM")
            Slider(value: $parent_class.sequencer_data.bpm, in: 120...250)
          }
          HStack{
            Text("Drum Volume")
            Slider(value: $parent_class.sequencer_data.drum_vol, in: 0...1, step: 0.01)
          }
          HStack{
            Text("Pad Volume")
            Slider(value: $parent_class.sequencer_data.pad_vol, in: 0...1, step: 0.01)
          }
          HStack{
            Text("Lead Volume")
            Slider(value: $parent_class.sequencer_data.melody_vol, in: 0...1, step: 0.01)
          }
          HStack{
            Text("Bass Volume")
            Slider(value: $parent_class.sequencer_data.lead_vol, in: 0...1, step: 0.01)
          }
          HStack{
            Text("FM")
            Slider(value: $parent_class.sequencer_data.fm1, in: 0...16, step: 1)
          }
          HStack{
            Text("Modulator")
            Slider(value: $parent_class.sequencer_data.fm2, in: 0...24, step: 1)
          }

          //Slider(value: $parent_class.harmony_synth.env.attackDuration, in: 0...1, step: 0.01)
          //Slider(value: $parent_class.harmony_synth.env.decayDuration, in: 0...1, step: 0.01)
          //Slider(value: $parent_class.harmony_synth.env.sustainLevel, in: 0...1, step: 0.01)
          //Slider(value: $parent_class.harmony_synth.env.releaseDuration, in: 0...1, step: 0.01)
          //Slider(value: $parent_class.sequencer_data.fm1, in: 0...16, step: 1)
          //Slider(value: $parent_class.sequencer_data.fm2, in: 0...32, step: 1)

        }.padding(10).onDisappear()
        {
          parent_class.stop_sequencer_thread()
        }
      }
    }
  }
}
