s.reboot;



ServerOptions.devices;
ServerOptions.outDevices;
ServerOptions.inDevices;
s.outDevice_("ASIO : FlexASIO");
s.inDevice_("ASIO : FlexASIO");

s.boot;
(//INIT//

p = ProxySpace.push(s, \def, TempoClock.new());
p.fadeTime = 2;
b = ();
b.put(\bell, Buffer.read(s,"D:/SUPERCOLLIDER/_SOUNDS/MUSIC_BOX.wav" ));
b.put(\voice, Buffer.read(s, "D:/SUPERCOLLIDER/_SOUNDS/VOICE.wav"));
b.put(\longvoice, Buffer.read(s, "D:/SUPERCOLLIDER/_SOUNDS/LONGVOICE.wav"));
b.put(\reverb, Bus.audio(s, 2));
b.put(\synthverb, Synth.new(\freeverb, [\in, b.reverb, addAction: 'addToTail']));
r = Bus.audio(s, 1);
~switch.play;
z = 0;
)


(//SYNTH//
SynthDef(\grains, { |out = 0, mul = 1, buf, attack = 0.5, decay = 5, rate = 1, density = 4|
    var pan, env, grain;
    env = EnvGen.ar( Env.perc(0, decay), doneAction:2) * mul;
	grain = GrainBuf.ar(2, Impulse.kr(density), 0.1, buf, rate,
            LFNoise2.kr(0.1).range(0, 1), 2);
	grain = FreeVerb.ar(grain, 8, 05, 0.1, 1);
    Out.ar(out, grain * env ! 2);
}).add;



SynthDef(\freeverb, {|out = 0, in, time = 0.6, mix = 0.5|
	var sig;
	sig = In.ar(in, 2);
	sig = FreeVerb2.ar(sig[0],sig[1], mix, time);
	Out.ar(out, sig);
}).add;

SynthDef(\bplayenv, {|out = 0, buf, rate = 1, loop = 0, mul = 1, decay = 2, attack = 0.1|
	var sample, env;
	env = Env.perc(attack, decay);
	sample = PlayBuf.ar(1, buf, rate * BufRateScale.kr(buf), loop: loop);
	sample = sample * EnvGen.ar(env, doneAction: 2);
	out.postln;
	Out.ar(out, sample * mul ! 2);
}).add;


SynthDef(\harmo, {
	|freq = 440, harmo = 0, amp = 1, out = 0|
	var osc;
	osc = 0;

	osc = osc * EnvGen.ar(Env.perc(0, 3), doneAction:2);
	Out.ar(out, osc);

}).add;


SynthDef(\sine, {|freq = 440, mul = 1, out = 0 | Out.ar(out, SinOsc.ar(freq, 0, EnvGen.ar(Env.perc, doneAction: 2) * mul) !2 )}).add;
)

(//Pattern
~filterfreq = 1000;

~reverbamount = 0;
~high = Pbind(\instrument, \bplayenv, \mul, 0.5,  \buf, b.bell, \rate, Pseq([Prand((Scale.major.ratios), 3)* Pseq([0.5, 0.25], 1) ],inf ), \dur, Prand([4, 1, 2, 1, 0.5, 0.1], inf));
~high[1] = \filter -> {arg sig; FreeVerb.ar(sig, ~reverbamount, 1, 0.2)};
~low = Pbind(\instrument, \bplayenv, \mul, 0.2, \buf,b.bell, \rate, Prand((0.5 * Scale.major.ratios), inf) * 0.5, \dur, Prand([4, 2, 1, 4, 0.5], inf), \attack, 1);
~low[2] = \filter -> {arg sig; LPF.ar(sig, 700)};
~low[3] = \filter -> {arg sig; (0.6* sig) + (0.4 * PitchShift.ar(sig, pitchRatio: 1.5 ))};
~longvoicelow = Pbind(\instrument, \bplayenv, \mul, 0.3,  \buf, b.longvoice,
	\rate, Prand((Scale.major.ratios ), inf) * Prand([[0.5, 1], [1.5, 1]], inf),
	\attack, 2, \decay, 7,
	\dur, Prand([4, 8], inf));


~longvoicelow[1] = \filter -> {arg sig; sig * 0.7 + (0.3 * PitchShift.ar(sig, pitchRatio: 0.5))};
~longvoicelow[2] = \filter -> {arg sig; sig + AllpassC.ar(sig, 1, 0.1, 3)};

~longvoicehigh = Pbind(\instrument, \bplayenv, \mul, 0.3,  \buf, b.longvoice,
	\rate, Prand((Scale.major.ratios ), inf) * Pseq([[1, 2], [1.7, 1], [1.5, 1]], inf),
	\attack, 0.5, \decay, 1,
	\dur, Prand([4, 8], inf));
~longvoicehigh[1] = \filter -> {arg sig; FreeVerb.ar(sig, ~reverbamount, 1, 0.2)};

~voicelayer.play;
~voicelaery.fadeTime = 10;
~voicelayer = nil;

~longvoice.play;
~longvoice = ~longvoicehigh;


~voicelayertemp = Pbind(\instrument, \bplayenv, \mul, 0.2,  \buf, b.longvoice,
	\rate, Prand((Scale.major.ratios ), inf) * Pseq([[2.5, 2], [1.7, 1], [1.5, 1]], inf),
	\attack, 0.5, \decay, 7,
	\dur, Prand([2, 4], inf));
~voicelayertemp[1] = \filter -> {arg sig; FreeVerb.ar(sig, ~reverbamount, 1, 0.2)};
~voicelayertemp.stop;

~switch = ~high;
//~switch.stop;
~switch.play;

~noisenew = {LinPan2.ar(BPF.ar(WhiteNoise.ar(LFNoise2.kr(0.1, 0.25, 0.3) * 0.1 ), ~filterfreq + LFNoise2.kr(3, 0.25, 0.3) + 100) * 0.5, LFNoise1.kr(0.2) )};
~noisenew.fadeTime = 1;
~noisenew.play;

)

~low.stop

~seq = Pbind(\instrument, \sine, \freq, Pseq((440 * Scale.major.ratios), 10), \dur, Pseq(0.5!10, 1), \mul, 0.2);
~seq.play;
~seq.stop


(//OSC//



OSCdef(\voiceevent1,
	{TempoClock.default.sched(0.5, {Synth(\grains, [\buf, b.voice, \decay, 5, \rate, 1.5, \mul, 0.6, \attack, 2, \density, 10])});
		"voiceevent1".postln;
	},
	'/voiceevent1');

OSCdef(\voiceevent2,
	{TempoClock.default.sched(0.5, {Synth(\grains, [\buf, b.voice, \decay, 5, \rate, 2.5, \mul, 0.4, \attack, 2, \density, 10])});
				"voiceevent2".postln;
	},
	'/voiceevent2');

OSCdef(\voiceevent3,
	{TempoClock.default.sched(0.5, {Synth(\grains, [\buf, b.voice, \decay, 5, \rate, 0.94, \mul, 0.7, \attack, 2, \density, 10])});
		"voiceevent3".postln;
	},
	'/voiceevent3');

OSCdef(\voicelayer,{|msg| var statut;
	statut = (msg[1] == 1);
		if(statut,{
		TempoClock.default.sched(1, {~voicelayer = ~voicelayertemp});
		"voicelayeron".postln;
		},{
		TempoClock.default.sched(1, {~voicelayer = nil});
		"voicelayeroff".postln;
	})
}, \voicelayer);

OSCdef(\switch,{|msg| var statut;
	statut = (msg[1] == 1);
		if(statut,{
			TempoClock.default.sched(1, {~switch = ~high});
		TempoClock.default.sched(1, {~longvoice = ~longvoicehigh});
		"switchhigh".postln;
		},{
			TempoClock.default.sched(1, {~switch = ~low});
		TempoClock.default.sched(1, {~longvoice = ~longvoicelow});
		"switchlow".postln;
	})
}, \switch );

OSCdef(\punct, {
	{TempoClock.default.sched(0.5,
		{Synth(\bplayenv, [\buf, b.voice, \mul, 0.1, \decay, 5, \rate, Scale.major.ratios.choose * 1.1, \out, b.reverb])});}
}, '\punct');

OSCdef(\filter, {|msg, time, recvPort|
	~filterfreq = (msg[1] *5) + 400;
	//((msg[1]*10) +100).postln;
	~reverbamount = (msg[1] / 200)
},'/filter');
)

