MIDIClient.init;  // initialize a MIDI client object
MIDIIn.connectAll;
NetAddr("127.0.0.1",57120);

(
// create a new and enabled OSCdef
// the first argument is the key at which to store this OSCDef in the global collection
// the second argument is a function that will respond to the incoming message; when evaluated it will have the arguments msg, time, addr and recvPort; we are going to use only the message argument which is an Array in the form of [OSC address, arg1, arg2,...]
// the third argument is the path of the OSC address (must begin with a / )

OSCdef('OSCreceiver',
	{
		arg msg;
		var width1 , x1, y1;

		// these are the x, y and width of the first bell. need to add all the others
		// for now I just post the values of the first bell to check that the comunication works
		// need to normalize the values and use them on the synth
		x1 = msg[1];
		y1 = msg[2];
		width1 = msg[3];
		postln("x: " + x1 + " - y: " + y1 + "width: " + width1);
	},
	"/bellState"); // the slash is necessary for it to be recognixed as an OSC path
)

// Bell (Risset's synthetized bell)
(
SynthDef(\risset, {
	arg out= 0, pan= 0, freq= 400, amp= 0.1, dur= 5, t_trig=1;
	var amps= [1, 0.67, 1, 1.8, 2.67, 1.67, 1.46, 1.33, 1.33, 1, 1.33];
	var durs= [1, 0.9, 0.65, 0.55, 0.325, 0.35, 0.25, 0.2, 0.15, 0.1, 0.075];

	var frqs= [0.56, 0.56, 0.92, 0.92, 1.19, 1.7, 2, 2.74, 3, 3.76, 4.07];
	var dets= [0, 1, 0, 1.7, 0, 0, 2, 0, 8, 3, 0];    // Detune
	var src= Mix.fill(11, {
		arg i;
		var env = EnvGen.ar(Env.perc(0.005, dur*durs[i], amps[i], -4.5), t_trig);
		SinOsc.ar(freq*frqs[i]+dets[i], 0, amp*env);
	});
	Out.ar(out, Pan2.ar(FreeVerb.ar(src, mix: 0.33, room: 0.5), pan));
}).add;
)


a= Synth(\risset, [\freq, 72.midicps, \dur, 10])
a.free

(
var pads;
// create a new array with all slots filled with nils
pads = Array.newClear(84); // my pad uses midi numbers up to 83

// For NoteOn:
// val: message value (velocity)
// num: messange number (note)
// chan : MIDIchannel, goes from 0 to 15
// src : unique identifier of the MIDI port

~noteOnFunc = {arg val, num, chan, src;
	var node;
	("note on num: " + num).postln;
	// first assign to node the element of the array having as index the key number
	node = pads.at(num);
	// if the node is not Nil then release the node and put nil in the correspondent element
	if (node.notNil, {
		node.release;
		pads.put(num, nil);
	});

	// if the node is not Nil means that the correpondent synth is already playing
	// if the node is Nil then create an instance of Rhodes synth with the correct arguments and using the tail method

	// the tail method create and return a Synth; the first argument is generally a Group, when is setted to nil the synth is added to the tail of the default_group of the default server
	//Synths on the server are a type of what are called nodes. There's another type of node: groups. Groups are simply collections of nodes, and can contain synths, other groups, or combinations of both.

	node = Synth.tail(nil, \risset, [\freq, num.midicps]); // here we should use the parameters received from OSCdef

	// assign the instance to the correspondent element of the array
	pads.put(num, node);
};

// assign the function to the note on message
a = MIDIFunc.noteOn(func:~noteOnFunc);

// now we need to write the note off function
~noteOffFunc = {arg val, num, chan, src;
	var node;
	node = pads.at(num);

	if (node.notNil, {
		node.set(\gate,0);
	    node.release;
		pads.put(num, nil);
	});
	("note off num: " + num).postln;

};

b = MIDIFunc.noteOff(func:~noteOffFunc);

q = {a.free; b.free};
)

q.value(); // used to free the MIDIFuncs