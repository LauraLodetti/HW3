(
MIDIClient.init;  // initialize a MIDI client object
MIDIIn.connectAll;
NetAddr("127.0.0.1",57120);
n = NetAddr("127.0.0.1",12000);
~bellParam = Array.newClear(37); // stores the parameters of all the bells
~index; // is the background of the bells. Linked to the effect being played
~bellTower = Buffer.read(s,"C:/Users/helac/Documents/Poli/CMLS/HW3-main/HW3/BellApplication/data/bellTower.wav");
~mountain = Buffer.read(s,"C:/Users/helac/Documents/Poli/CMLS/HW3-main/HW3/BellApplication/data/Mountain.wav");
)

// Bell (Risset's synthetized bell)
// from C2 130.8 Hz to C5 1046.5 Hz
(
SynthDef(\risset, {
	arg out= 0, reverbBus, delayBus, pan= 0, freq= 400, amp= 0.1, dur= 5 , t_trig= 1, direct= 1, reverb= 0, delay= 0;
	var amps= [1, 0.67, 1, 1.8, 2.67, 1.67, 1.46, 1.33, 1.33, 1, 1.33];
	var durs= [1, 0.9, 0.65, 0.55, 0.325, 0.35, 0.25, 0.2, 0.15, 0.1, 0.075];
	var frqs= [0.56, 0.56, 0.92, 0.92, 1.19, 1.7, 2, 2.74, 3, 3.76, 4.07];
	var dets= [0, 1, 0, 1.7, 0, 0, 2, 0, 8, 3, 0];    // Detune
	var src= Mix.fill(11, {
		arg i;
		var env = EnvGen.ar(Env.perc(0.005, dur*durs[i], amps[i], -4.5), t_trig);
		SinOsc.ar(freq*frqs[i]+dets[i], 0, amp*env);
	});
	Out.ar(out, Pan2.ar(src*direct , pan));
	Out.ar(reverbBus, src*reverb);
	Out.ar(delayBus, src*delay);
}).send(s);


SynthDef(\delay, {
	arg outBus=0, inBus;
	var input, delayedOutput, output;
	input = In.ar(inBus, 1);
	delayedOutput = AllpassL.ar(input,5,0.8,3,1);
	output = FreeVerb.ar(delayedOutput, mix: 0.5, room:0.6, damp: 0.5);
	Out.ar(outBus, Pan2.ar(output));
}).send(s);


SynthDef(\reverb, {
	arg outBus=0, inBus;
	var input = In.ar(inBus,1);
	16.do({input = AllpassC.ar(in:input, maxdelaytime:0.04, delaytime:{Rand(0.001,0.04)}.dup, decaytime:3)});
	Out.ar(outBus, Pan2.ar(input));
}).send(s);
)

(
b = Bus.audio(s,1);
c = Bus.audio(s,1);

g = Group.new;
x = Synth(\reverb, [\inBus, b], g);
y = Synth(\delay, [\inBus, c], g);
f = Synth.before(g, \risset, [\t_trig,0 ,\reverbBus, b, \delayBus, c]);
)
f.set(\freq, 880, \amp, 0.1, \dur, 1, \direct, 1, \reverb, 0.1, \delay, 1, \t_trig, 1); // used for testing

// a receiver that plays the bells selected from processing
(
OSCdef('OSCreceiver',
	{
		arg msg;
		var width, x, y;

		x = msg[1];
		y = msg[2];
		width = msg[3];
		//postln("x: " + x + "y: " + y + "width: " + width);
		if(~index == 0 , {                                            // bell tower: no particular effect
			f.set(\freq, width, \amp, y * 0.1, \dur, x, \direct, 1, \reverb, 0, \delay, 0, \t_trig, 1);
		});
		if(~index == 1 , {                                            // church: lots of reverb
			f.set(\freq, width, \amp, y * 0.1, \dur, x, \direct, 0, \reverb, 1, \delay, 0, \t_trig, 1);
		});
		if(~index == 2 , {                                            // auditorium: ??
			f.set(\freq, width, \amp, y * 0.1, \dur, x, \direct, 1, \reverb, 0, \delay, 0, \t_trig, 1);
		});
		if(~index == 3 , {                                            // mountains: delay
			f.set(\freq, width, \amp, y * 0.1, \dur, x, \direct, 1, \reverb, 0.1, \delay, 1, \t_trig, 1);
		});

	},
	"/myBellState");
)

(
OSCdef('OSCreceiver2',
	{
		arg msg;
		var width, x, y;

		for (0, 35, {
			arg i;
			~bellParam[i] = msg[i+1];
		});
		~index = msg[37];
		//postln("index: " + ~index);
	},
	"/bellState");
)

(
 SynthDef(\backgroundNoise,
	{
		arg bufnum = 0;    // Number of the buffer to play
		var sig;
		sig = PlayBuf.ar(2, bufnum, 1, loop:1, doneAction:0);
		Out.ar(0, 1.5*sig);
 }).add;
)

(
OSCdef('OSCreceiver3',
	{
		arg msg;
		var index = msg[1];
		if(index == 0 , {
			~bellTowerNoise = Synth(\backgroundNoise, [\bufnum, ~bellTower.bufnum]);
			NodeWatcher.register(~bellTowerNoise,true);
		});

		if(index == 1 && ~bellTowerNoise.isPlaying , {
		~bellTowerNoise.free;
		});

		if(index == 2 && ~mountainNoise.isPlaying , {
		~mountainNoise.free;
		});

		if(index == 3 , {
			~mountainNoise = Synth(\backgroundNoise, [\bufnum, ~mountain.bufnum]);
			NodeWatcher.register(~mountainNoise,true);
		});
	},
	"/indexChange");
)


(
var pads;
// create a new array with all slots filled with nils
pads = Array.newClear(84); // my pad uses midi numbers up to 83

~noteOnFunc = {arg val, num, chan, src;
	var node, bellParam;
	("note on num: " + ((num - 36) % 16)).postln;

	bellParam = (num - 36) % 16;
	node = pads.at(num);              // first assign to node the element of the array having as index the key number
	                                 // if the node is not Nil then release the node and put nil in the correspondent element
	if (node.notNil, {
		node.release;
		pads.put(num, nil);
	});

	// if the node is not Nil means that the correpondent synth is already playing
	// if the node is Nil then create an instance of risset synth with the correct arguments and using the tail method

	node = Synth.tail(nil, \risset, [\freq, ~bellParam[bellParam*3 + 2], \amp, ~bellParam[ (bellParam*3) + 1] * 0.1, \dur, ~bellParam[bellParam*3], \mix, ~reverbMix]);
	// assign the instance to the correspondent element of the array
	pads.put(num, node);
	n.sendMsg("/activeBell" , \bellNumber, bellParam);
};

// assign the function to the note on message
a = MIDIFunc.noteOn(func:~noteOnFunc);

// now we need to write the note off function
~noteOffFunc = {arg val, num, chan, src;
	var node, bellParam;
	node = pads.at(num);
	bellParam = (num - 36) % 16;

	if (node.notNil, {
		node.set(\gate,0);
	    node.release;
		pads.put(num, nil);
	});
	("note off num: " + num).postln;
	n.sendMsg("/turnOffBell" , \bellNumber, bellParam);
};

b = MIDIFunc.noteOff(func:~noteOffFunc);

~ccFunc = {arg val, ccnum;

	// use this to find the ccnumber of your controller and insert the correct number in the corresponding section
	//("ccnumber :" + ccnum).postln;

	// reverbMix control
	if (ccnum == 3, {
		~reverbMix = val.linlin(0, 127, 0, 1); // val ranges from 0 to 127 but reverb ranges from 0 to 1
	});
	if (ccnum == 9, {
		// other control
	});
};

c = MIDIFunc.cc(func:~ccFunc);

q = {a.free; b.free; c.free};
)

q.value(); // used to free the MIDIFuncs


// implement a routine to play the bell configuration set on processing
(
r = Routine({
	5.do{
		var bellNumber = 12.rand;
		f.set(\freq, ~bellParam[bellNumber*3 + 2], \amp, ~bellParam[ (bellNumber*3) + 1] * 0.1, \dur, ~bellParam[bellNumber*3], \t_trig, 1);
		// within a routine, wait will yield the number so that the clock  wait for this many beats. Outside a Routine, this trows an error.
		n.sendMsg("/activeBell" , \bellNumber, bellNumber);
		exprand(0.5,3).wait;
		n.sendMsg("/turnOffBell" , \bellNumber, bellNumber);
	}});
)
(
OSCdef('OSCreceiver3',
	{
		arg msg;
		r.reset;
		r.play();
	},
	"playBells");
)

r.stop;