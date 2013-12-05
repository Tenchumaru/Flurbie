var nl = "\r\n";

if(!Array.prototype.filter) {
	Array.prototype.filter = function (fn) {
		var i, n = this.length, rv = [];
		for(i = 0; i < n; ++i) {
			var el = this[i];
			if(fn(el))
				rv.push(el);
		}
		return rv;
	}
}

if(!String.prototype.trim) {
	String.prototype.trim = function (ch) {
		var begin = new RegExp('^' + (ch ? ch : "[\\s]+"));
		var end = new RegExp((ch ? ch : "[\\s]+") + '$');
		return this.replace(begin, "").replace(end, "");
	}
}

function ParseArguments() {
	var args = WScript.Arguments, l = args.length;
	if(l < 2 || l > 3) {
		WScript.Echo("usage:", WScript.FullScriptPath, "input.sv input_tb.txt [output.sv]");
		WScript.Quit(2);
	}
	return { input: args(0), input_tb: args(1), output: l > 2 && args(2) };
}

var fso = WScript.CreateObject("Scripting.FileSystemObject");

function ReadAllText(fileName) {
	var fin = fso.OpenTextFile(fileName, 1, false, 0);
	var text = fin.ReadAll();
	if(fileName || WScript.Arguments.length > 0)
		fin.Close();
	return text;
}

function Main() {
	var args, fout, print, fin, line, name, names, parts, value, values, i, j, n, l, format, not_clock_or_reset;

	args = ParseArguments();
	fout = args.output ? fso.CreateTextFile(args.output) : WScript.StdOut;
	print = function () {
		var i, n, ar = [];
		for(i = 0, n = arguments.length; i < n; ++i)
			ar.push(arguments[i]);
		fout.WriteLine(ar.join(' '));
	};
	fin = fso.OpenTextFile(args.input, 1, false, 0);
	line = fin.ReadLine();
	name = line.split(' ')[1].split('('/*)*/)[0];
	print("module test_" + name + "(input logic clock, reset_n, start_n);");
	print();
	not_clock_or_reset = function (el) {
		return el.indexOf("input") < 0 && el.indexOf("output") < 0 && el.indexOf("clock") < 0 && el.indexOf("reset") < 0;
	}
	while(line = fin.ReadLine(), line.indexOf(/*(*/')') < 0) {
		parts = line.trim().split(' ').filter(not_clock_or_reset).join(' ');
		print(parts.trim(',') + ';');
	}
	fin.Close();
	print();
	print(name, "the_" + name + "(.*);");
	print();
	print("typedef enum logic[1:0] {Idle, Running, Finishing} state_t;");
	print();
	print("state_t state, next_state;");
	print("logic in_last_state;");
	print("logic[7:0] counter, increment;");
	print();
	print("// next state logic");
	print("always_comb begin : next_state_logic");
	print("\tcase(state)");
	print("\t\tIdle: next_state= start_n ? Idle : Running;");
	print("\t\tRunning: next_state= Finishing;");
	print("\t\tFinishing: next_state= start_n ? Idle : Finishing;");
	print("\t\tdefault: next_state= Idle;");
	print("\tendcase");
	print("\tincrement= state == Running || next_state == Running;");
	print("end : next_state_logic");
	print();
	print("// state register");
	print("always_ff@(posedge clock, negedge reset_n) begin : state_register");
	print("\tif(!reset_n) begin");
	print("\t\tstate <= Idle;");
	print("\t\tcounter <= 0;");
	print("\tend else begin");
	print("\t\tstate <= next_state;");
	print("\t\tcounter <= counter + increment;");
	print("\tend");
	print("end : state_register");
	print();
	print("// output logic");
	fin = fso.OpenTextFile(args.input_tb, 1, false, 0);
	line = fin.ReadLine();
	names = line.split(':')[0].replace("reset_n", "").trim().replace(/ +/g, ", ");
	print("always_comb begin : output_logic");
	print("\tif(state == Running)");
	for(j = 0; !fin.AtEndOfStream; ++j) {
		line = fin.ReadLine();
		parts = line.split(':')[0].split(/ +/);
		values = [];
		for(i = 1, n = parts.length; i < n; ++i) {
			value = parts[i].replace(/[Xx]/g, "z");
			l = value.length;
			format = l > 1 ? (l * 4) + "'h" : l + "'b";
			values.push(format + value);
		}
		values = values.join(", ");
		if(j == 0) {
			print("\t\t{" + names + "}= {" + values + "};");
			print("\telse case(counter)");
			print("\t\tdefault: {" + names + "}= {" + values + "};");
		} else
			print("\t\t" + (j < 10 ? ' ' : "") + j + ": {" + names + "}= {" + values + "};");
	}
	print("\tendcase");
	print("end : output_logic");
	print();
	print("endmodule");
	fin.Close();
	fout.Close();
}

Main();
