import SwiftUI
import AudioKit
import Tonic
import SoundpipeAudioKit
import Controls

struct MorphingOscillatorData 
{
  var frequency: AUValue = 440
  var octaveFrequency: AUValue = 440
  var amplitude: AUValue = 0.2
  var carrier : AUValue = 1
  var modulator : AUValue = 1
}

class SynthClass: ObservableObject 
{
  public let engine = AudioEngine()
  @Published var octave = 1
  
  let filter : MoogLadder
  @Published public var env : AmplitudeEnvelope
  public let revarb: Reverb
  var notes = Array(repeating: 0, count: 11)
  
  @Published var cutoff = AUValue(20_000) 
  {
    didSet { filter.cutoffFrequency = AUValue(cutoff) }
  }
  
  var osc = [FMOscillator(carrierMultiplier: 1, modulatingMultiplier: 1), FMOscillator(carrierMultiplier: 2, modulatingMultiplier: 1), FMOscillator(carrierMultiplier: 1, modulatingMultiplier: 1)]
  
  init()
  {
    filter = MoogLadder(Mixer(osc[0],osc[1]), cutoffFrequency: 20_000)
    revarb = Reverb(filter)
    revarb.loadFactoryPreset(.largeHall)
    revarb.dryWetMix = 0;
    
    env = AmplitudeEnvelope(revarb, attackDuration: 0.1, decayDuration: 3.0, sustainLevel: 0.0, releaseDuration: 0.55)
    engine.output = env
    try? engine.start()
  }
  
  @Published public var data = MorphingOscillatorData()
  {
    didSet 
    {
      for i in 0...1 
      {
        osc[i].start()
        osc[i].$amplitude.ramp(to: data.amplitude, duration: 0)
      }
      osc[0].$baseFrequency.ramp(to: data.frequency, duration: 0.01)
      osc[1].$baseFrequency.ramp(to: data.frequency, duration: 0.01)
    }
  }
  
  func noteOn(pitch: Pitch, point: CGPoint)
  {
    noteOff(pitch: pitch);
    env.closeGate()
    
    data.frequency = AUValue(pitch.midiNoteNumber).midiNoteToFrequency()
    for num in 0 ... 10 
    {
      if notes[num] == 0 
      {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { self.env.openGate() }
        notes[num] = pitch.intValue
        break
      }
    }
  }
  
  func noteOff(pitch: Pitch)
  {
    for num in 0 ... 10 
    {
      if notes[num] == pitch.intValue { notes[num] = 0 }
      
      if Set(notes).count <= 1
      {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { self.env.closeGate() }
      }
    }
  }
}
