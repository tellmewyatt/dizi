s.options.memSize_(8192 * 20);
s.reboot;
(
~createBuses = {
	~longIn = ~longIn ? Bus.audio;
	~mediumIn = ~mediumIn ? Bus.audio;
	~shortIn = ~shortIn ? Bus.audio;
	~beatBoxIn = ~beatBoxIn ? Bus.audio;
	~shortCombIn = ~shortCombIn ? Bus.audio;
	~longCombIn = ~longCombIn ? Bus.audio;
	~emptyIn = ~emptyIn ? Bus.audio;
	~buffers = ~buffers ? ();
	~buffers.waterPour = ~buffers.waterPour ? Buffer.read(s, "./water-pour.wav".resolveRelative);
	~buffers.narration1 = ~buffers.narration1 ? Buffer.read(s, "./facing-the-current.wav".resolveRelative);
	~buffers.narration2 = ~buffers.narration2 ? Buffer.read(s, "./one-star.wav".resolveRelative);
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
};
~createEffects = {
	~input = Synth(\input, [\out, 0], addAction: \addToHead);
	~longGrainify = Synth(\grainify, [
		\in, ~longIn,
		\out, 0,
		\decayTime, 200,
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
~createSeq = {
	~seq = [
		{
			~buffers.narration1.play;
			~input.set(\out, ~longIn);
			"1. Start on high quiet s. Wait for narration to finish.
2. ss-> sh -> w.
3. Long tones on ss, sh, w, h, f.
Gradually add flute notes."
		},
		{
			~input.set(\out, ~mediumIn);
			"Melody. Switch to next cue before long tones end"
		},
		{
			~input.set(\out, ~beatBoxIn);
			"Nonpitched, erratic consonants or instrument sounds."
		},
		{
			~buffers.narration2.play;
			~input.set(\out, ~longCombIn);
			"1. Sigh some through your instrument, onobtrusively while the narration plays.
2. Play beautiful soaring melody over G drone.
3. Then cue next (water sounds) while econtinuing melody."
		},
		{
			~waterDry = Synth(\water, [\bufnum, ~buffers.waterPour, \amp, 0.5, \out, 0]);
			"Continue melody. After a few seconds cue next (more water sounds)."

		},
		{
			~waterDrum = Synth(\water, [\bufnum, ~buffers.waterPour, \amp, 0.2, \out, ~beatBoxIn]);
			"Continue melody. After a few seconds cue next (more water sounds)."
		},
		{
			~waterComb = Synth(\water, [\bufmum, ~buffers.waterPour, \amp, 0.2, \out, ~shortCombIn]);
			"Continue melody. After a few seconds cue next (octave doubling effect)."
		},
		{
			~input.set(\out, ~shortIn);
			"Continue melody. Cue next to release water sounds."
		},
		{
			~waterDry.release;
			~waterDrum.release;
			~waterComb.release;
			~input.set(\out, ~longCombIn);
			"Continue melody. When you have landed on final, cue next while holding note."
		},
		{
			~input.set(\out, ~emptyIn);
			"Continue holding this note longer than when the drone fades out. Then cue final narration."
		},
		{
			~buffers.narration3.play;
			"Wait for the narration to finish.
Play simple melodic fragments around final note.
Repeat final note, gradually slower and softer.
END."
		}

	];
	};
~createGui = {
	var indexString = StaticText().font_(Font("Sans Serif", 20)).string_("Beginning of piece (silence).");
	~currentIndex = -1;
	w = Window.new("Dizi Effects", Rect(500,500, 500, 500)).layout_(
		VLayout(
			StaticText().font_(Font("Sans Serif", 20)).string_("Press [SpaceBar] to go to next cue"),
			StaticText().font_(Font("Sans Serif", 20)).string_("Current patch: "),
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
			~currentIndex = -1
			indexString = "Beginning of piece (silence).";
			~input.set(\out, 0);
		})
	};
	w.front;
}
)
(
~createBuses.();
~createSynthDefs.();
~createEffects.();
~createSeq.();
~createGui.();
)