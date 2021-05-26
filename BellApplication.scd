(
MIDIClient.init;  // initialize a MIDI client object
MIDIIn.connectAll;
NetAddr("127.0.0.1",57120);
n = NetAddr("127.0.0.1",12000);
~bellParam = Array.newClear(37); // stores the parameters of all the bells
~reverbMix = 0;
)

// Bell (Risset's synthetized bell)
// from C2 130.8 Hz to C5 1046.5 Hz
(
SynthDef(\risset, {
	arg out= 0, pan= 0, freq= 400, amp= 0.1, dur= 5, mix= 0.33 , t_trig=1;
	var amps= [1, 0.67, 1, 1.8, 2.67, 1.67, 1.46, 1.33, 1.33, 1, 1.33];
	var durs= [1, 0.9, 0.65, 0.55, 0.325, 0.35, 0.25, 0.2, 0.15, 0.1, 0.075];

	var frqs= [0.56, 0.56, 0.92, 0.92, 1.19, 1.7, 2, 2.74, 3, 3.76, 4.07];
	var dets= [0, 1, 0, 1.7, 0, 0, 2, 0, 8, 3, 0];    // Detune
	var src= Mix.fill(11, {
		arg i;
		var env = EnvGen.ar(Env.perc(0.005, dur*durs[i], amps[i], -4.5), t_trig);
		SinOsc.ar(freq*frqs[i]+dets[i], 0, amp*env);
	});
	Out.ar(out, Pan2.ar(FreeVerb.ar(src, mix: mix, room: 0.8), pan));
}).add;
)

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
		f = Synth(\risset, [\freq, width, \amp, y * 0.1, \dur, x, \mix, ~reverbMix])
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

		//postln("x1: " + ~bellParam[1] + "width: " + ~bellParam[2]);
	},
	"/bellState");
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
	10.do{
		var bellNumber = 12.rand;
		f = Synth(\risset, [\freq, ~bellParam[bellNumber*3 + 2], \amp, ~bellParam[ (bellNumber*3) + 1] * 0.1, \dur, ~bellParam[bellNumber*3]]);
		// within a routine, wait will yield the number so that the clock  wait for this many beats. Outside a Routine, this trows an error.
		//~bellParam[bellNumber*3].wait; // the durations are too long => boring
		n.sendMsg("/activeBell" , \bellNumber, bellNumber);
		1.wait;
		n.sendMsg("/turnOffBell" , \bellNumber, bellNumber);
	}});
)
r.play();
r.reset;
r.stop;