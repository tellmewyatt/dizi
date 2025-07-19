s.options.memSize_(8192 * 20);
s.reboot;
~createBuses = {
	~longIn = ~longIn ? Bus.audio;
	~mediumIn = ~mediumIn ? Bus.audio;
	~shortIn = ~shortIn ? Bus.audio;
	~beatBoxIn = ~beatBoxIn ? Bus.audio;
	~shortCombIn = ~shortCombIn ? Bus.audio;
	~longCombIn = ~longCombIn ? Bus.audio;
	~buffers = ~buffers ? ();
	~buffers.waterPour = ~buffers.waterPour ? Buffer.read(s, "./water-pour.wav".resolveRelative);
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
	SynthDef(\comb, { | out = 0, in, freq = 60, decayTime=10 |
		var input = In.ar(in);
		var sig = Splay.ar(CombC.ar(input, 0.2, 10.collect { | i | 1/(freq * i +1) }, decayTime));
		Out.ar(out, sig * amp);
	}).add;
	SynthDef(\water, { | out=0, pitchRatio=1.0, amp=0.2, bufnum, freqModRate=1, gate=1 |
		var env = EnvGen.kr(Env.asr, gate, doneAction: 2);
		var sig = Splay.ar(PlayBuf.ar(1, bufnum, BufRateScale.ir(bufnum) * Rand(0.2, 2 ! 10), 1, loop: 1));
		sig = LPF.ar(sig, Line.ar(15000, 1000, 5)) * amp;
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
	Synth(\tom, [\in, ~beatBoxIn, \pan, 1, \freq, 500, \amp, 0.5], addAction: \addToTail)
};
~seq = [
	{ ~input.set(\out, ~longIn); },
	{ ~input.set(\out, ~longCombIn); },
	{ ~input.set(\out, ~shortCombIn); },
	{ ~input.set(\out, ~mediumIn); },
	{ ~input.set(\out, ~beatBoxIn); },
	{ ~waterDry = Synth(\water, [\bufnum, ~buffers.waterPour, \amp, 0.5, \out, 0]); },
	{ ~waterDrum = Synth(\water, [\bufnum, ~buffers.waterPour, \amp, 0.1, \out, ~beatBoxIn]); },
	{ ~waterComb = Synth(\water, [\bufmum, ~buffers.waterPour, \amp, 0.1, \out, ~shortCombIn]); },
	{ ~input.set(\out, ~shortIn) },
	{ ~input.set(\out, 0) }
];
~createGui = {


}