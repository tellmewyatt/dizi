s.options.numWireBufs = 1024
s.reboot;
(~vocoderSamples = PathName("./vocoder-in-samples".resolveRelative)
	.entries.collect { | path |
		Buffer.readChannel(s, path.absolutePath, channels: [0]);
};)
s.record("./vocoder-samples".resolveRelative, 0, 1);
Buffer
~sample.path
(x = Routine {
	~vocoderSamples.do { | sample |
		var duration = sample.numFrames / sample.sampleRate;
		s.record(("vocoder-samples/" ++ PathName(sample.path).fileNameWithoutExtension ++ ".flac").resolveRelative,
			bus: 0,
			numChannels: 1
		);
		Synth(\vocoder, [\bufnum, sample]).waitForFree;
		s.stopRecording;
		0.1.wait;
	};
	"Done".postln;
}.play;)
x.stop;
(SynthDef(\vocoder, { | out = 0, bufnum |
	var sig = PlayBuf.ar(1, bufnum, BufRateScale.ir(bufnum), doneAction: 2);
	var filters = BPF.ar(sig, 200.collect { | i | (i + 1) * 100 }, 0.1, 1);
	var amps = filters.collect { | item | Amplitude.ar(item) };
	var outsig =  amps.collect ({ | amp, i | BPF.ar(Saw.ar(Rand(200, 1000), 1) + WhiteNoise.ar, (i + 1) * 100, 0.1, amp)}).sum * 10;
	Out.ar(out, outsig);
}).add;)
s.record("./one-star_vocoder.wav".resolveRelative, 0, 2);
)
()
x = Synth(\grainBuf, [\freq, 0.1, \grainDur, 1])
x.set(\freq, 0.5)
x.set(\grainDur, 0.5)
}
(SynthDef(\playBuf, { | bufnum, out  = 0 |
	Out.ar(out,
		PlayBuf.ar(
			2, bufnum,
			BufRateScale.ir(bufnum)));
}).add;)
Synth(\playBuf, [\bufnum, ~buffers.looking_vocoder, \out, 0])
~buffers.face_vocoder_2.pla
PathName("a").