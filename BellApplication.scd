(
MIDIClient.init;                   // initialize a MIDI client object
MIDIIn.connectAll;                 // connect all MIDI objects
NetAddr("127.0.0.1",57120);        // usedto receive messages from processing
n = NetAddr("127.0.0.1",12000);    // used to send messages to processing
~bellParam = Array.newClear(37);   // stores the parameters of all the bells
~index;                            // indicates the background of the bells. Linked to the effect being played
~bellTower = Buffer.read(s, PathName.new("BellApplication/data/bellTower.wav").asAbsolutePath);
~mountain = Buffer.read(s, PathName.new("BellApplication/data/Mountain.wav").asAbsolutePath);
)

// Bell (Risset's synthetized bell)
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

	// we send this signal on 3 different buses to be able to select the desired effect with the desired background
	// we will be able to control the desired output by choosing how much of the orginal signal we send on each bus
	Out.ar(out, Pan2.ar(src*direct , pan));
	Out.ar(reverbBus, src*reverb);
	Out.ar(delayBus, src*delay);
}).send(s);

// a buffer used to play the background noises
 SynthDef(\backgroundNoise,
	{
		arg bufnum = 0;    // Number of the buffer to play
		var sig;
		sig = PlayBuf.ar(2, bufnum, 1, loop:1, doneAction:0); // we loop the signal
		Out.ar(0, 1.3*sig);
 }).add;

SynthDef(\delay, {
	arg outBus=0, inBus;
	var input, delayedOutput, output;
	input = In.ar(inBus, 1);
	delayedOutput = AllpassL.ar(input, maxdelaytime: 5, delaytime: 0.8, decaytime: 4);
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
// we create 2 buses for the effects
b = Bus.audio(s,1);
c = Bus.audio(s,1);

// we put the 2 effect Synths in the same group in order to put the risset synth before both of them
g = Group.new;
x = Synth(\reverb, [\inBus, b], g);
y = Synth(\delay, [\inBus, c], g);
f = Synth.before(g, \risset, [\t_trig,0 ,\reverbBus, b, \delayBus, c]);
)

//f.set(\freq, 880, \amp, 0.1, \dur, 1, \direct, 1, \reverb, 0.1, \delay, 1, \t_trig, 1); // used for testing

// implement a routine to play the bell configuration set on processing
(
r = Routine({
	7.do{
		var bellNumber = 12.rand; // number of the bell to be played

		f.set(\freq, ~bellParam[bellNumber*3 + 2], \amp, ~bellParam[ (bellNumber*3) + 1] * 0.1, \dur, ~bellParam[bellNumber*3], \t_trig, 1);
		n.sendMsg("/activeBell" , \bellNumber, bellNumber);  // turn on the bell
		exprand(0.5,3).wait;                                 // randomly play bell of duration going from 0.5 to 3s
		n.sendMsg("/turnOffBell" , \bellNumber, bellNumber); // turn off the bell
	}});
)

r.stop; // manually stop the routine


// a receiver that plays the bells selected from processing
(
OSCdef('OSCreceiver',
	{
		arg msg;
		var width, x, y;

		x = msg[1];
		y = msg[2];
		width = msg[3];

		if(~index == 0 , {                                            // bell tower: no particular effect
			f.set(\freq, width, \amp, y * 0.1, \dur, x, \direct, 1, \reverb, 0, \delay, 0, \t_trig, 1);
		});
		if(~index == 1 , {                                            // church: lots of reverb
			f.set(\freq, width, \amp, y * 0.1, \dur, x, \direct, 0, \reverb, 1, \delay, 0, \t_trig, 1);
		});
		if(~index == 2 , {                                            // auditorium: clean
			f.set(\freq, width, \amp, y * 0.1, \dur, x, \direct, 1, \reverb, 0, \delay, 0, \t_trig, 1);
		});
		if(~index == 3 , {                                            // mountains: delay
			f.set(\freq, width, \amp, y * 0.1, \dur, x, \direct, 1, \reverb, 0.1, \delay, 1, \t_trig, 1);
		});

	},
	"/myBellState");
)

// a receiver that constantly saves the parameters of all the bells from processing in order to be able to play them from the MIDI pad
(
OSCdef('OSCreceiver2',
	{
		arg msg;
		var width, x, y;

		for (0, 35, {                 // there are 3 parameters for each bell x, y and width
			arg i;
			~bellParam[i] = msg[i+1];
		});
		~index = msg[37];             // the last message is the index which indicates the background
	},
	"/bellState");
)

// a receiver that plays and stops the background noise when changing background
(
OSCdef('OSCreceiver3',
	{
		arg msg;
		var index = msg[1];
		if(index == 0 , {                                                              // bell tower background noise
			~bellTowerNoise = Synth(\backgroundNoise, [\bufnum, ~bellTower.bufnum]);
			NodeWatcher.register(~bellTowerNoise,true);
		});

		if(index == 1 && ~bellTowerNoise.isPlaying , {                                 // silence
		~bellTowerNoise.free;
		});

		if(index == 2 && ~mountainNoise.isPlaying , {                                  //  silence
		~mountainNoise.free;
		});

		if(index == 3 , {                                                              // mountains background noise
			~mountainNoise = Synth(\backgroundNoise, [\bufnum, ~mountain.bufnum]);
			NodeWatcher.register(~mountainNoise,true);
		});
	},
	"/indexChange");
)

// a reveiver that plays the routine when the play button is selected on processing
(
OSCdef('OSCreceiver4',
	{
		arg msg;
		r.reset;   // reset the routine
		r.play();  // play the routine
	},
	"playBells");
)


(
var pads;

pads = Array.newClear(84); // create a new array with all slots filled with nils. Our pad goes up to pad number 83

~noteOnFunc = {arg val, num, chan, src;
	var node, bellParam;

	bellParam = (num - 36) % 16;      // rescale the pad number from 0 to 15 so that it corresponds to the bells on processing
	//("note on num: " + num).postln; // use this to find out which number to substract from num using your pad and then divide by the number of pads you have

	node = pads.at(num);              // first assign to node the element of the array having as index the key number
	                                  // if the node is not Nil then release the node and put nil in the correspondent element
	if (node.notNil, {
		node.release;
		pads.put(num, nil);
	});

	// if the node is not Nil it means that the correpondent synth is already playing
	// if the node is Nil then create an instance of risset synth with the correct arguments and using the tail method

	if(~index == 0 , {                                                // bell tower: no particular effect
		    node = Synth.tail(nil, \risset, [\freq, ~bellParam[bellParam*3 + 2], \amp, ~bellParam[ (bellParam*3) + 1] * 0.1, \dur, ~bellParam[bellParam*3], \direct, 1, \reverb, 0, \delay, 0]);
		});
		if(~index == 1 , {                                            // church: lots of reverb
			node = Synth.tail(nil, \risset, [\freq, ~bellParam[bellParam*3 + 2], \amp, ~bellParam[ (bellParam*3) + 1] * 0.1, \dur, ~bellParam[bellParam*3], \direct, 0, \reverb, 1, \delay, 0]);
		});
		if(~index == 2 , {                                            // auditorium: ??
			node = Synth.tail(nil, \risset, [\freq, ~bellParam[bellParam*3 + 2], \amp, ~bellParam[ (bellParam*3) + 1] * 0.1, \dur, ~bellParam[bellParam*3], \direct, 1, \reverb, 0, \delay, 0]);
		});
		if(~index == 3 , {                                            // mountains: delay
			node = Synth.tail(nil, \risset, [\freq, ~bellParam[bellParam*3 + 2], \amp, ~bellParam[ (bellParam*3) + 1] * 0.1, \dur, ~bellParam[bellParam*3], \direct, 1, \reverb, 0.1, \delay, 1]);
		});

	// assign the instance to the correspondent element of the array
	pads.put(num, node);

	n.sendMsg("/activeBell" , \bellNumber, bellParam); // used to change color of the bell on processing
};

a = MIDIFunc.noteOn(func:~noteOnFunc);

~noteOffFunc = {arg val, num, chan, src;
	var node, bellParam;
	node = pads.at(num);
	bellParam = (num - 36) % 16;

	if (node.notNil, {
		node.set(\gate,0);
	    node.release;
		pads.put(num, nil);
	});
	n.sendMsg("/turnOffBell" , \bellNumber, bellParam); // used to change color of the bell on processing
};

b = MIDIFunc.noteOff(func:~noteOffFunc);

// this part could be used to map the effects on the pad control change controls but we decided it went against our original idea so we commented it

/*
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
*/

q = {a.free; b.free;};
)

q.value(); // used to free the MIDIFuncs
