/*
Facing the Current
by Wyatt Cannon
August 2025
for SuperCollider V 3.13.0

To run this patch:
1. Open in SuperCollider IDE.
2. Select All (Ctrl + A)
3. Execute (Ctrl + Enter)
4. Press Space Bar / Use a foot pedal to follow the cues.


*/

// See bottom for main function
// Increase memory size so we can use more combs
s.options.memSize_(8192 * 20);
// Function Definitions
~createBuses = {
	~longIn = ~longIn ? Bus.audio;
	~mediumIn = ~mediumIn ? Bus.audio;
	~shortIn = ~shortIn ? Bus.audio;
	~beatBoxIn = ~beatBoxIn ? Bus.audio;
	~shortCombIn = ~shortCombIn ? Bus.audio;
	~longCombIn = ~longCombIn ? Bus.audio;
	~emptyIn = ~emptyIn ? Bus.audio;
	~buffers = ~buffers ? ();
	~buffers.waterPour = ~buffers.waterPour ? Buffer.read(s, "audio/water-pour.wav".resolveRelative);
	~buffers.narration1 = ~buffers.narration1 ? Buffer.read(s, "audio/narrations/facing_the_current.flac".resolveRelative);
	~buffers.narration2 = ~buffers.narration2 ? Buffer.read(s, "audio/narrations/one_star.flac".resolveRelative);
	~buffers.narration3 = ~buffers.narration3 ? Buffer.read(s, "audio/narrations/looking.flac".resolveRelative);
	~buffers.vocoderBuffers = ~buffers.vocoderBuffers ? PathName("audio/vocoder-samples".resolveRelative)
	.entries.collect { | path |
		Buffer.readChannel(s, path.absolutePath, channels: [0]);
	};
	"Created Buses and Loaded Buffers".postln;
};
~createSynthDefs = {
	SynthDef(\grainify, { | in, out, decayTime = 4, amp= 0, pan = 0 |
		var input = In.ar(in, 1);
		var grainFunc = { | input, decayTime | CombC.ar(input, 4, LFNoise2.ar(0.1).range(0.1, 0.2), decayTime) };
		var sig = 2.collect { grainFunc.(input, decayTime) };
		sig  = sig+ Mix.ar(PitchShift.ar(sig, 0.2, [0.1, 0.2, 0.5]));
		Out.ar(out, Pan2.ar(sig, pan, amp))
	}).add;
	SynthDef(\input, { | in, out |
		var sig = In.ar(2);
		Out.ar(out, sig);
	}).add;
	SynthDef(\beatBox, { | in, out = 0, detectThreshold = 0.1 |
		var input = In.ar(2);
		var amp = Amplitude.ar(input, 0.01, 0.5);
		var trig = Gate.ar(1, amp - detectThreshold);
		var sig = SinOsc.ar(440, 0, 0.1);
		sig = EnvGen.ar(Env.triangle, trig) * sig;
		Out.ar(out, sig)
	}).add;
	SynthDef(\tom, { | out = 0, in, pan, freq = 100, freqSpread = 15000, decayTime = 0.4, gate=1, amp=1 |
		var input = In.ar(in);
		var env = EnvGen.kr(Env.asr(0.0, 1, 0.1), gate, doneAction: 2);
		var sig = Ringz.ar(input, freq + (LFNoise2.ar(0.1 ! 70).range(0, 1) * freqSpread), decayTime).mean * env;
		//sig = sig + input;
		sig = Pan2.ar(sig, pan, amp);
		Out.ar(out, sig);

	}).add;
	SynthDef(\tomFlat, { | out = 0, in, pan, freq = 100, freqSpread = 15000, decayTime = 0.4, gate=1, amp=1 |
		var input = In.ar(in);
		var env = EnvGen.kr(Env.asr(0.0, 1, 0.1), gate, doneAction: 2);
		var sig = Ringz.ar(input, freq + (Rand(0, 1 ! 70) * freqSpread), decayTime).mean * env;
		//sig = sig + input;
		sig = Pan2.ar(sig, pan, amp);
		Out.ar(out, sig);

	}).add;
	SynthDef(\comb, { | out = 0, in, freq = 60, decayTime=10, amp = 0 |
		var input = In.ar(in);
		var sig = Splay.ar(CombC.ar(input, 0.2, 10.collect { | i | 1/(freq * i +1) }, decayTime));
		Out.ar(out, sig * amp);
	}).add;
	SynthDef(\water, { | out=0, pitchRatio=1.0, amp=0.2, bufnum, freqModRate=1, gate=1, cutoff = 2000 |
		var env = EnvGen.kr(Env.asr, gate, doneAction: 2);
		var sig = Splay.ar(PlayBuf.ar(1, bufnum, BufRateScale.ir(bufnum) * Rand(0.2, 2 ! 10), 1, loop: 1));
		sig = LPF.ar(sig, Line.ar(15000, cutoff, 5)) * amp;
		sig = sig * env;
		Out.ar(out, sig);
	}).add;
	SynthDef(\grainBuf, { | out = 0, freq = 2, grainDur = 2, gate=1 |
		var env = EnvGen.kr(Env.asr(0.01, 1, 0.01), gate);
		var trigger = Impulse.kr(freq);
		var bufnum = TChoose.kr(trigger, ~buffers.vocoderBuffers);
		var bufrate = BufRateScale.ir(bufnum);
		var pos = TRand.kr(0, 1, trigger);
		var sig = Pan2.ar(
			GrainBuf.ar(
				1,
				trigger ,
				grainDur.min(BufDur.kr(bufnum)),
				bufnum,
				bufrate, pos),
			TRand.kr(-1, 1, trigger) // Pan
		);
		Out.ar(out, sig * env);
	}).add;
};
~createEffects = {
	~input = Synth(\input, [\out, ~emptyIn], addAction: \addToHead);
	~longGrainify = Synth(\grainify, [
		\in, ~longIn,
		\out, 0,
		\decayTime, 100,
		\amp, 0.5,
		\pan, -0.5], addAction: \addToTail);
	~mediumGrainify = Synth(\grainify, [
		\in, ~mediumIn,
		\out, 0,
		\decayTime, 4,
		\amp, 0.5,
		\pan, 0.5], addAction: \addToTail);
	~shortGrainify = Synth(\grainify, [
		\in, ~shortIn,
		\out, 0,
		\decayTime, 0.1,
		\amp, 0.5,
		\pan, 0.5], addAction: \addToTail);
	~longComb = Synth(\comb, [
		\in, ~longCombIn,
		\out, 0,
		\freq, (67 - 36).midicps,
		\amp, 0.5], addAction: \addToTail);
	~shortComb = Synth(\comb, [
		\in, ~shortCombIn,
		\out, 0,
		\freq, (67 - 36).midicps,
		\decayTime, 1,
		\amp, 0.5], addAction: \addToTail);
	Synth(\tom, [\in, ~beatBoxIn, \pan, -1, \amp, 0.5], addAction: \addToTail);
	Synth(\tom, [\in, ~beatBoxIn, \pan, 1, \freq, 500, \amp, 0.5], addAction: \addToTail);
	"Created Effects".postln;
};
// This is the sequence we will use throughout the piece.
// It does something and returns a description
~createSeq = {
	~seq = [
		{
			~buffers.narration1.play;
			~input.set(\out, ~longIn);
			"1. Intro narration and swishing sounds."
		},
		{
			~input.set(\out, ~mediumIn);
			"2. Uncanny melody"
		},
		{
			var freq = 0.1;
			~input.set(\out, ~beatBoxIn);
			~vocoderGrains = Pmono(\grainBuf,
				\freq, Pseg([0.1, 2, 2, 0.1, 0.1], [40, 5, 20, 10], \exp)
			).play;
			"3. Unpitched Grains"
		},
		{
			~vocoderGrains.stop;
			~buffers.narration2.play;
			~input.set(\out, ~longCombIn);
			"4. Soaring Melody over G Drone"
		},
		{
			~waterDry = Synth(\water, [\bufnum, ~buffers.waterPour, \amp, 0.5, \out, 0]);
			"5. Add Water"

		},
		{
			~waterDrum = Synth(\water, [\bufnum, ~buffers.waterPour, \amp, 0.2, \out, ~beatBoxIn]);
			"6. Add Water Filtered Through Drums"
		},
		{
			~waterComb = Synth(\water, [\bufmum, ~buffers.waterPour, \amp, 0.2, \out, ~shortCombIn]);
			"7. Add Water Through Comb Filter"
		},
		{
			~waterDry.release;
			~waterDrum.release;
			~waterComb.release;
			~input.set(\out, ~longCombIn);
			"8. Octave Doubling and Water Sounds End"
		},
		{
			~input.set(\out, ~emptyIn);
			"9. Everything Ends"
		},
		{
			~buffers.narration3.play;
			"10. Final Narration"
		}

	];
};
// This is used to create the gui
~createGui = {
	var indexString = StaticText().font_(Font("Sans Serif", 60)).string_("Beginning of piece (silence).");
	~currentIndex = -1;
	w = Window.new("Dizi Effects", Rect(500,500, 500, 500)).layout_(
		VLayout(
			StaticText().font_(Font("Sans Serif", 60)).string_("Press [SpaceBar] to go to next cue"),
			StaticText().font_(Font("Sans Serif", 60)).string_("Current patch: "),
			indexString
		)
	);
	w.view.keyDownAction = { | doc, char, mod, unicode  |
		unicode.postln;
		if(unicode == 32, {
			~currentIndex = ~currentIndex + 1;
			indexString.string = ~seq[~currentIndex].();
		});
		if(unicode == 27, {
			w.close;
			~currentIndex = -1;
			indexString = "Beginning of piece (silence).";
			~input.set(\out, 0);
		})
	};
	w.front;
};
// THe main function
s.waitForBoot {
	~createGui.();
	r {
		~createBuses.();
		~createSynthDefs.();
		s.sync;
		~createEffects.();
		~createSeq.();
	}.play;
}
