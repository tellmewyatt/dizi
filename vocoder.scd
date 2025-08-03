// The following code is used to record the vocal samples processed through a vocoder
s.options.numWireBufs = 1024
s.reboot;
s.waitForBoot {
	Routine {
		~vocoderSamples = PathName("./vocoder-in-samples".resolveRelative)
		.entries.collect { | path |
			Buffer.readChannel(s, path.absolutePath, channels: [0]);
		};
		SynthDef(\vocoder, { | out = 0, bufnum |
			var sig = PlayBuf.ar(1, bufnum, BufRateScale.ir(bufnum), doneAction: 2);
			var filters = BPF.ar(sig, 200.collect { | i | (i + 1) * 100 }, 0.1, 1);
			var amps = filters.collect { | item | Amplitude.ar(item) };
			var outsig =  amps.collect ({ | amp, i | BPF.ar(Saw.ar(Rand(200, 1000), 1) + WhiteNoise.ar, (i + 1) * 100, 0.1, amp)}).sum * 10;
			Out.ar(out, outsig);
		}).add;
		Routine {
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
		}.play;
	}
}