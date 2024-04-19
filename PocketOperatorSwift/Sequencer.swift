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
  public var key_offset : Float = 0;
  public var fm1 : Float = 1;
  public var fm2 : Float = 1;
  public var fm3 : Float = 1;
  public var mode: Float = 1;
  public var drum_type : Int = 0;
  public var generation_weight : Float = 0.5
  
  public var speed_track : Bool = true;
  
  public var chord_rhythm : division = division.Dotted
  public var arp_rhythm : division = division.Eighth
  public var bass_rhythm : division = division.Dotted

  public var arp_style : Float = 0
  
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
  var total_speed : Float = 0.01
  var average_speed : Float = 0
  var frequency : Int = 0
  var last_recorded_speed : Float = 0
  var initial_bpm : Float = 0;
  var top_speed : Float = 0
  public var bpm_index : Float = 0;
  public var isTracking : Bool = true;
  
  private var weight : Float = 0
  
  public func calculate_average(_ new_speed : Float)
  {
    last_recorded_speed = new_speed
    frequency += 1
    total_speed += new_speed
    average_speed = total_speed / Float(frequency)
    
    if(last_recorded_speed > top_speed){top_speed = last_recorded_speed}
    if(top_speed != 0){weight = last_recorded_speed/top_speed}
    if(average_speed < 0){average_speed = 0.01}
    if(last_recorded_speed < 0){last_recorded_speed = 0.01}
    if(total_speed < 0){total_speed = 0.01}
  }
  
  public func get_weight() -> Float
  {
    if(weight < 0.2)
    {
      weight = 0.2
    }
    
    if(weight > 0.9)
    {
      weight = 0.9
    }
    return weight
  }
  
  init(initial_bpm: Float)
  {
    self.initial_bpm = initial_bpm
  }
  
  public func get_average_speed() -> Float
  {
    return average_speed
  }
  
  public func get_bpm(current : Float) -> Float
  {
    bpm_index = ((average_speed/top_speed))
    var bpm = current

    if(bpm_index > 1){bpm_index = 1}
    if(bpm_index < 0.1){bpm_index = 0.1}
    

    if(last_recorded_speed > average_speed)
    {
      bpm = bpm + (0.05 * initial_bpm)
    }
    
    if(last_recorded_speed < average_speed)
    {
      bpm = bpm - (0.05 * initial_bpm)
    }
    
    if(bpm < initial_bpm * 0.1)
    {
      bpm = initial_bpm * 0.1
    }
    
    if(bpm > initial_bpm * 1.1)
    {
      bpm = initial_bpm * 1.1
    }
    
    if(isTracking == false){  return current; }
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
  
  func generate_transition_diagram(weight : Float)
  {
    for i in 0..<transition_diagram.count
    {
      transition_diagram[i] = MarkovManger.generate_stage_weight(selected: transition_diagram[i], 1-weight)
    }
  }
  
  func generate_progression()
  {
    chord_progression[0] = next_chord_markov(chord_progression[3])
    
    for i in 0..<(chord_progression.count - 1)
    {
      chord_progression[i + 1] = next_chord_markov(chord_progression[i])
    }
    print_progression()
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
  
  func print_progression()
  {
    print("chords: " , chord_progression, " - ")
   
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
  
  public var drum_mangager = DrumManager(drumOption: 0)
  
  private var mixer = Mixer()
  
  private var thread: MyThread!
  private var major_scale : KeyScale = KeyScale(0, 4)
  
  public let x_size : Int = 8
  public let y_size : Int = 8
  
  private var beat_to_skip : Int = 2
  private var chordManager : ChordController
  private var melodyManager : MutationMelody
  
  private var speedUtility : SpeedUtility
  
  private var lastPlayed : Note = Note(position: 1, semitone: 60)
  
  @Published var amplitude : Float
  @State var volume: AmplitudeTap
  
  
  var lfo_array : [LFO3] = [LFO3(), LFO3()]
  
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
      harmony_synth.osc[0].modulationIndex = AUValue(sequencer_data.fm3)
      
    }
  }
  
  init() {
    
    chordManager = ChordController();
    melodyManager = MutationMelody(major_scale: major_scale);
    
    bass_synth.env.sustainLevel = 1;
    
    arp_synth.volume = 1;
    arp_synth.amplitude = 6;
    
    harmony_synth.data.amplitude = 0.1
    speedUtility = SpeedUtility(initial_bpm: 100);
    
    bass_synth.env.sustainLevel = 0;
    bass_synth.env.decayDuration = 0.4;
    
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
      try arp_synth.loadWav("basicSamples/pitchshiftedshot")
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
    } catch let err {}
    
    speedUtility = SpeedUtility(initial_bpm: Float(sequencer_data.bpm));
    
    while isPlaying
    {
      major_scale = KeyScale(Int(sequencer_data.key_offset), Int(sequencer_data.mode))
      melodyManager.next_gen()
      melodyManager.major_scale = major_scale
      
      drum_mangager.type = sequencer_data.drum_type
      
      melodyManager.gen_rhythm()
      melodyManager.child_melody()

      for x in 0..<x_size
      {
        generate_next_step(note_step)

        if(sequencer_data.speed_track)
        {
          sequencer_data.generation_weight = speedUtility.get_weight()
        }
        
        chordManager.generate_transition_diagram(weight: sequencer_data.generation_weight)
        melodyManager.rhythm_manager.generate_transition_diagram(weight: sequencer_data.generation_weight)
        
        for y in 0..<y_size
        {
          if (playing[note_step] == true)
          {
            let scale_note : Int = major_scale.getNoteNumber(position: (note_step/x_size), octave: 1)
            let temp_note : Note = major_scale.findIndividual(scale_note)
            lastPlayed = temp_note
          }
          note_step += x_size
        }
        
        note_step += 1
        step_behaviour(note_step)
        sequencer_data.bpm = Double(speedUtility.get_bpm(current: Float(sequencer_data.bpm)))

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
      speedUtility.isTracking = sequencer_data.speed_track
      speedUtility.calculate_average(Float(locationManager.getSpeed()))

      play_harmony(i, step_number);
      play_bassline(i, step_number);
      play_chord(i, step_number)
      play_arp(i);
      
      lfo_array[0].update()
      lfo_array[1].update()
      
      setLFO()

      drum_mangager.drum_pattern(step_number, i)
      filter?.cutoffFrequency = AUValue((calcFilterCutoff(cutoff: locationManager.getHeading())))
      
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
  
  
  public func setLFO()
  {
    //bass_synth.osc[0].$modulatingMultiplier.value = 0.001 + lfo_array[1].get_value() * 50;
    bass_synth.osc[0].modulationIndex = 0.001 + lfo_array[1].get_value() * 50;
    //bass_synth.osc[0].
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
  
  public func play_bassline( _ beat:Int , _ step : Int)
  {
    if(beat % sequencer_data.bass_rhythm.rawValue == 0)
    {
      bass_synth.noteOn(pitch: Pitch(intValue: lastPlayed.semitone - 12), point: CGPoint(x: 1, y: 1 ))
    }
  }
  
  public func play_chord( _ beat:Int , _ step : Int)
  {
    if(beat % sequencer_data.chord_rhythm.rawValue == 0)
    {
      arp_synth.play(noteNumber: MIDINoteNumber(lastPlayed.semitone - 12),velocity: 127, channel: 0)
      arp_synth.play(noteNumber: MIDINoteNumber(KeyScale.get_ambiguous_third(targetNote: lastPlayed).semitone - 12),velocity: 127, channel: 0)
      arp_synth.play(noteNumber: MIDINoteNumber(KeyScale.get_ambiguous_fifth(targetNote: lastPlayed).semitone - 12),velocity: 127, channel: 0)
    }
  }
  
  public func play_harmony( _ beat:Int , _ step : Int)
  {
    if(beat % melodyManager.rhythm.rawValue == 0)
    {
      harmony_synth.noteOn(pitch: Pitch(intValue:melodyManager.get_note(beat).semitone), point: CGPoint(x: 1, y: 1))
      //harmony_synth.noteOn(pitch: Pitch(intValue:melodyManager.get_note(beat).semitone), point: CGPoint(x: 1, y: 1))
      //harmony_synth.noteOn(pitch: Pitch(intValue:melodyManager.get_note(beat).semitone), point: CGPoint(x: 1, y: 1))
      //melodyManager.switch_rhythm()
      melodyManager.get_next_rhythm()
    }
  }
  
  public func play_arp( _ beat:Int)
  {
    
    if(beat % sequencer_data.arp_rhythm.rawValue == 0)
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
    let filterCutoff = interpolate * 19000
    
    return (20000 - filterCutoff)
  }
  
  public func bell_preset()
  {
    DispatchQueue.main.async { [self] in
      harmony_synth.env.attackDuration = 0.01
      harmony_synth.env.decayDuration = 0.07
      harmony_synth.env.sustainLevel = 0.01
      harmony_synth.env.releaseDuration = 0.7
      
      sequencer_data.fm1 = 7
      sequencer_data.fm2 = 3
      sequencer_data.fm3 = 1
      harmony_synth.cutoff = 19000
    }
  }
  
  
  public func guitar_preset()
  {
    DispatchQueue.main.async { [self] in
      harmony_synth.env.attackDuration = 0.01
      harmony_synth.env.decayDuration = 0.7
      harmony_synth.env.sustainLevel = 0.2
      harmony_synth.env.releaseDuration = 0.7
      
      sequencer_data.fm1 = 10
      sequencer_data.fm2 = 14
      sequencer_data.fm3 = 12
      
      harmony_synth.cutoff = 1300
    }
  }
  
  public func bright_lead_preset()
  {
    DispatchQueue.main.async { [self] in
      harmony_synth.env.attackDuration = 0.7
      harmony_synth.env.decayDuration = 0.3
      harmony_synth.env.sustainLevel = 0.1
      harmony_synth.env.releaseDuration = 0.2
      
      sequencer_data.fm1 = 3
      sequencer_data.fm2 = 2
      sequencer_data.fm3 = 17
      
      harmony_synth.cutoff = 1300
    }
  }
  
  public func sine_pluck_preset()
  {
    DispatchQueue.main.async { [self] in
      harmony_synth.env.attackDuration = 0.01
      harmony_synth.env.decayDuration = 0.1
      harmony_synth.env.sustainLevel = 0.1
      harmony_synth.env.releaseDuration = 0.05
      
      sequencer_data.fm1 = 8
      sequencer_data.fm2 = 0
      sequencer_data.fm3 = 0
      
      harmony_synth.cutoff = 20000
    }
  }
  
  public func onBPMChange()
  {
    speedUtility = SpeedUtility(initial_bpm: Float(sequencer_data.bpm))
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


struct HatsPad :Identifiable, View {
  @EnvironmentObject var parent_class: DrumManager
  @GestureState private var isPressed = false
  var id: Int
  @State var isActive = false
  
  var body: some View
  {
    RoundedRectangle(cornerRadius: 0.5 ).fill(parent_class.hat_sequence[id] ? Color.red.opacity(0.2) : Color.red).aspectRatio(contentMode: .fit).gesture(DragGesture(minimumDistance: 0).updating($isPressed) { (value, gestureState, transaction) in
      gestureState = true
    }).onChange(of: isPressed, perform: { (pressed) in
      if pressed {
        parent_class.hat_sequence[id].toggle()
      }})
  }
  
}


struct SnarePad :Identifiable, View {
  @EnvironmentObject var parent_class: DrumManager
  @GestureState private var isPressed = false
  var id: Int
  @State var isActive = false
  
  var body: some View
  {
    RoundedRectangle(cornerRadius: 0.5 ).fill(parent_class.snare_sequence[id] ? Color.red.opacity(0.2) : Color.red).aspectRatio(contentMode: .fit).gesture(DragGesture(minimumDistance: 0).updating($isPressed) { (value, gestureState, transaction) in
      gestureState = true
    }).onChange(of: isPressed, perform: { (pressed) in
      if pressed {
        parent_class.snare_sequence[id].toggle()
      }})
  }
  
}


struct KickPad :Identifiable, View {
  @EnvironmentObject var parent_class: DrumManager
  @GestureState private var isPressed = false
  var id: Int
  @State var isActive = false
  
  var body: some View
  {
    RoundedRectangle(cornerRadius: 0.5 ).fill(parent_class.kick_sequence[id] ? Color.red.opacity(0.2) : Color.red).aspectRatio(contentMode: .fit).gesture(DragGesture(minimumDistance: 0).updating($isPressed) { (value, gestureState, transaction) in
      gestureState = true
    }).onChange(of: isPressed, perform: { (pressed) in
      if pressed {
        parent_class.kick_sequence[id].toggle()
      }})
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
        TabView{
          VStack
          {
            ForEach(0..<parent_class.y_size) { x in
              HStack{
                ForEach(0..<parent_class.x_size) { y in
                  PocketSequencerPadView(id: y + (x * parent_class.x_size))
                }.environmentObject(parent_class)
              }
            }
            Text(isPlaying ? "stop" : "start").bold().foregroundColor(.blue).onTapGesture {
              isPlaying.toggle()
              if (isPlaying) {parent_class.start()}
              else{}
            }
            HStack{
              Text("BPM")
              Slider(value: $parent_class.sequencer_data.bpm, in: 20...280).onSubmit {
                parent_class.onBPMChange()
              }
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
          }.tabItem { Label("Sequencer", systemImage: "tray.and.arrow.up.fill") }
          
          VStack
          {
            Text("FM Lead Settings").padding(10).bold()

            HStack{
              Text("Oscillator")
              Slider(value: $parent_class.sequencer_data.fm1, in: 0...16, step: 1)
            }
            HStack{
              Text("Operator")
              Slider(value: $parent_class.sequencer_data.fm2, in: 0...24, step: 1)
            }
            HStack{
              Text("FM Amount")
              Slider(value: $parent_class.sequencer_data.fm3, in: 0...24, step: 1)
            }
            HStack{
              Text("Attack")
              Slider(value: $parent_class.harmony_synth.env.attackDuration, in: 0.01...1, step: 0.01)
            }
            HStack{
              Text("Decay")
              Slider(value: $parent_class.harmony_synth.env.decayDuration, in: 0.01...1, step: 0.01)
            }
            HStack{
              Text("Sustain")
              Slider(value: $parent_class.harmony_synth.env.sustainLevel, in: 0.01...1, step: 0.01)
            }
            HStack{
              Text("Release")
              Slider(value: $parent_class.harmony_synth.env.releaseDuration, in: 0.01...1, step: 0.01)
            }
            HStack{
              Text("Cutoff")
              Slider(value: $parent_class.harmony_synth.cutoff, in: 0.01...20000, step: 0.01)
            }.padding(10)
            
            Text("Presets")
            
            HStack
            {
              ZStack{
                RoundedRectangle(cornerRadius: 0.5 ).fill(Color.red)
                  .onTapGesture(perform: {
                    parent_class.bell_preset()
                  })
                Text("FM Bell")
              }
              ZStack{
                RoundedRectangle(cornerRadius: 0.5 ).fill(Color.red)
                  .onTapGesture(perform: {
                    parent_class.guitar_preset()
                  })
                Text("Guitar")
              }
              ZStack{
                RoundedRectangle(cornerRadius: 0.5 ).fill(Color.red)
                  .onTapGesture(perform: {
                    parent_class.sine_pluck_preset()
                  })
                Text("Sine Pluck")
              }
              ZStack{
                RoundedRectangle(cornerRadius: 0.5).fill(Color.red)
                  .onTapGesture(perform: {
                    parent_class.bright_lead_preset()
                  })
                Text("Bright Lead")
              }
            }

          }.tabItem { Label("FM Settings", systemImage: "tray.and.arrow.up.fill") }
          
          ScrollView{
            VStack
            {
              Text("Session Settings").padding(10).bold()
              Text("Chord Rhythm")
              HStack {
                Picker("Chord Rhythm", selection: $parent_class.sequencer_data.chord_rhythm) {
                  Text("Sixteenth").tag(division.Sixteenth)
                  Text("Eigth").tag(division.Eighth)
                  Text("Quarter").tag(division.Quarter)
                  Text("Dotted").tag(division.Dotted)
                  Text("Half").tag(division.Half)
                }.pickerStyle(SegmentedPickerStyle()).padding(10)
              }
              HStack {
                Text("Arppegio Style")
                Picker("Arppegio Style", selection: $parent_class.sequencer_data.arp_style) {
                  Text("7ths").tag(0)
                  Text("Standard").tag(1)
                }.pickerStyle(SegmentedPickerStyle())
              }.padding(10)
              Text("Arppegio Rhythm")
              HStack {
                Picker("Arppegio Rhythm", selection: $parent_class.sequencer_data.arp_rhythm) {
                  Text("Sixteenth").tag(division.Sixteenth)
                  Text("Eigth").tag(division.Eighth)
                  Text("Quarter").tag(division.Quarter)
                  Text("Dotted").tag(division.Dotted)
                  Text("Half").tag(division.Half)
                }.pickerStyle(SegmentedPickerStyle())
              }.padding(10)
              
              Text("Bass Rhythm")
              HStack {
                Picker("Bass Rhythm", selection: $parent_class.sequencer_data.bass_rhythm) {
                  Text("Sixteenth").tag(division.Sixteenth)
                  Text("Eigth").tag(division.Eighth)
                  Text("Quarter").tag(division.Quarter)
                  Text("Dotted").tag(division.Dotted)
                  Text("Half").tag(division.Half)
                  Text("HalfDot").tag(division.HalfDotted)

                }.pickerStyle(SegmentedPickerStyle())
              }.padding(10)
              
              LFOManger(label: "Lead Amp LFO").environmentObject(parent_class.lfo_array[0]).padding(10)
              LFOManger(label: "Bass FM LFO").environmentObject(parent_class.lfo_array[1]).padding(10)
            }
          }.tabItem { Label("Session", systemImage: "tray.and.arrow.up.fill") }
          
          VStack
          {
            Text("Advnaced Settings").padding(10).bold()

            HStack{
              Text("KeyOffset")
              Slider(value: $parent_class.sequencer_data.key_offset, in: -12...12, step: 1)
            }
            HStack{
              Text("Mode")
              Slider(value: $parent_class.sequencer_data.mode, in: 1...7, step: 1)
            }
            HStack {
              Text("Drum Style")
              Picker("Drums", selection: $parent_class.sequencer_data.drum_type) {
                Text("Trap").tag(0)
                Text("Slow").tag(1)
                Text("Custom").tag(3)
                Text("None").tag(4)
              }.pickerStyle(SegmentedPickerStyle())
            }
            
            HStack {
              Text("Speed Tracking")
              Picker("Speed", selection: $parent_class.sequencer_data.speed_track) {
                Text("On").tag(true)
                Text("Off").tag(false)
              }.pickerStyle(SegmentedPickerStyle())
            }
            
            HStack{
              Text("Generation Weight")
              Slider(value: $parent_class.sequencer_data.generation_weight, in: 0.2...0.8, step: 0.01)
            }
          }.padding(10).onDisappear(){}.tabItem { Label("Adv", systemImage: "tray.and.arrow.down.fill") }
          
          VStack // Drum Sequencer Screen
          {
            Text("Drum Sequencer").padding(10).bold()

            HStack{
              Text("H.")
              ForEach(0..<16)
              {i in
                HatsPad(id: i)
              }.environmentObject(parent_class.drum_mangager)
            }
            HStack{
              Text("S.")
              ForEach(0..<16)
              {i in
                SnarePad(id: i)
              }.environmentObject(parent_class.drum_mangager)
            }
            HStack{
              Text("K.")
              ForEach(0..<16)
              {i in
                KickPad(id: i)
              }.environmentObject(parent_class.drum_mangager)
            }
          }.tabItem { Label("dSequencer", systemImage: "tray.and.arrow.down.fill") }
        }
      }
    }
  }
}
