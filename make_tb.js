var nl = "\r\n";

String.prototype.trim = function () {
	return this.replace(/^[\s]+/, "").replace(/[\s]+$/, "");
}

var fso = WScript.CreateObject("Scripting.FileSystemObject");

function ReadAllText(fileName) {
	var fin = fileName ? fso.OpenTextFile(fileName, 1, false, 0) : WScript.Arguments.length > 0 ? fso.OpenTextFile(WScript.Arguments(0), 1, false, 0) : WScript.StdIn;
	var text = fin.ReadAll();
	if(fileName || WScript.Arguments.length > 0)
		fin.Close();
	return text;
}

function GetFormat(type, name) {
	return name.slice(-9) === "registers" ? 's' : type === "logic" || name === "flags" ? 'b' : 'x';
}

function ParseModportParameters(text) {
	var rv = { inputs: [], outputs: [] };
	var parts = text.split(',');
	for(var i = 0, currentTarget, n = parts.length; i < n; ++i) {
		var subparts = parts[i].trim().split(/[\s]+/, 2);
		var name = subparts[subparts.length - 1];
		if(subparts[0] == "input") {
			currentTarget = rv.inputs;
		} else if(subparts[0] == "output") {
			currentTarget = rv.outputs;
		}
		currentTarget.push(name);
	}
	return rv;
}

function ParseModports(text) {
	var rv = {};
	var parts = text.split("modport");
	for(var i = 1, n = parts.length; i < n; ++i) {
		var part = parts[i];
		var subparts = part.split('('/*)*/);
		var modportName = subparts[0].trim();
		var modportParameters = ParseModportParameters(subparts[1].split(/*(*/')')[0]);
		rv[modportName] = modportParameters;
	}
	return rv;
}

function ParseInterfaces(text) {
	var rv = {};
	var parts = text.split("interface");
	for(var i = 1, n = parts.length; i < n; i += 2) {
		var part = parts[i];
		var interfaceName = part.split('('/*)*/)[0].trim();
		var modports = ParseModports(part);
		rv[interfaceName] = modports;
	}
	rv.nr = parseInt(text.split(';')[0].split('=')[1]);
	return rv;
}

function ParseModuleParameters(text) {
	var i = text.indexOf(' '), j = text.indexOf('('), k = text.indexOf(");");
	var moduleName = text.substring(i + 1, j);
	var moduleParameters = text.substring(j + 1, k).split(',');
	var inputs = [], outputs = [], interfaces = [], registers = [];
	for(var i = 0, currentType, currentTarget, n = moduleParameters.length; i < n; ++i) {
		var parts = moduleParameters[i].trim().split(/[\s]+/, 3);
		if(parts[0] === "input") {
			currentType = parts[1];
			currentTarget = inputs;
		} else if(parts[0] === "output") {
			currentType = parts[1];
			currentTarget = outputs;
		} else if(parts.length == 2) {
			var subparts = parts[0].split('.');
			interfaces.push({ name: parts[1], interfaceName: subparts[0], modportName: subparts[1] });
			continue;
		}
		var name = parts[parts.length - 1];
		currentTarget.push({ type: currentType, name: name });
		if(name.slice(-9) === "registers") {
			registers.push(name);
		}
	}
	return { name: moduleName, inputs: inputs, outputs: outputs, interfaces: interfaces, registers: registers };
}

function HasOutputputInterface(moduleParameters, interfaces) {
	for(var i = 0, a = moduleParameters.interfaces, n = a.length; i < n; ++i) {
		var modport = interfaces[a[i].interfaceName][a[i].modportName];
		if(modport.outputs.length > 0)
			return true;
	}
	return false;
}

function Main() {
	var text = ReadAllText("registers.sv");
	var interfaces = ParseInterfaces(text);
	var fout = WScript.Arguments.length > 1 ? fso.CreateTextFile(WScript.Arguments(1)) : WScript.StdOut;
	var print = function () {
		var ar = [];
		for(var i = 0, n = arguments.length; i < n; ++i)
			ar.push(arguments[i]);
		fout.WriteLine(ar.join(' '));
	};
	text = ReadAllText();
	var moduleParameters = ParseModuleParameters(text);
	print('`include "../../registers.sv"');
	print('`include "../../' + moduleParameters.name + '.sv"');
	print();
	print("module " + moduleParameters.name + "_tb();");
	print();
	print("parameter enforce_dont_cares= 1;");
	print();
	print("// inputs");
	for(var i = 0, a = moduleParameters.inputs, n = a.length; i < n; ++i) {
		print(a[i].type, a[i].name + ';');
	}
	print();
	print("// outputs");
	for(var i = 0, a = moduleParameters.outputs, n = a.length; i < n; ++i) {
		print(a[i].type, a[i].name + ',', "expected_" + a[i].name + ';');
	}
	print();
	print("// interfaces");
	for(var i = 0, a = moduleParameters.interfaces, n = a.length; i < n; ++i) {
		print(a[i].interfaceName, a[i].name + "(),", "expected_" + a[i].name + "();");
	}
	print();
	print(moduleParameters.name, "DUT("/*)*/);
	var actualParameters = [];
	for(var i = 0, a = moduleParameters.inputs, n = a.length; i < n; ++i) {
		actualParameters.push(a[i].name);
	}
	for(var i = 0, a = moduleParameters.outputs, n = a.length; i < n; ++i) {
		actualParameters.push(a[i].name);
	}
	for(var i = 0, a = moduleParameters.interfaces, n = a.length; i < n; ++i) {
		actualParameters.push(a[i].name + "(" + a[i].name + "." + a[i].modportName + ")");
	}
	print("\t." + actualParameters.join("," + nl + "\t."));
	print(/*(*/");");
	print();
	print('logic test_setup_clock;');
	print();
	print('always begin');
	print('\ttest_setup_clock= 1; #25; test_setup_clock= 0; #50; test_setup_clock= 1; #25;');
	print('end');
	print();
	print('always begin');
	print('\tclock= 1; #50; clock= 0; #50;');
	print('end');
	print();
	print('int fin, err, test_vector_index, errors, i;');
	print('string s, sin, sout;');
	print();
	print('initial begin');
	print('\tfin= $fopen("../../' + moduleParameters.name + '_tb.txt", "r");');
	print('\terr= $fgets(s, fin);');
	print('\t$display(s);');
	print('\ttest_vector_index= 0;');
	print('\terrors= 0;');
	print('end');
	print();
	print('always@(posedge test_setup_clock) begin');
	print('\terr = $fgets(s, fin);');
	var fscanfFormats = [], fscanfArguments = [], errorFormats = [], errorArguments = [], summaries = [];
	for(var i = 0, a = moduleParameters.inputs, n = a.length; i < n; ++i) {
		var name = a[i].name;
		if(name !== "clock") {
			var format = GetFormat(a[i].type, name);
			fscanfFormats.push(format);
			summaries.push(name);
			var b = name.slice(-9) === "registers" ? "sin" : name;
			fscanfArguments.push(b);
			errorFormats.push(name + "=%" + format);
			errorArguments.push(b);
		}
	}
	for(var i = 0, a = moduleParameters.interfaces, n = a.length; i < n; ++i) {
		var modport = interfaces[a[i].interfaceName][a[i].modportName];
		for(var j = 0, b = modport.inputs, m = b.length; j < m; ++j) {
			var format = GetFormat("", b[j]);
			fscanfFormats.push(format);
			var name = a[i].name + "." + b[j];
			fscanfArguments.push(name);
			summaries.push(name);
			errorFormats.push(name + "=%" + format);
			errorArguments.push(name);
		}
	}
	fscanfFormats.push("s");
	fscanfArguments.push("s");
	summaries.push(" : ");
	for(var i = 0, a = moduleParameters.outputs, n = a.length; i < n; ++i) {
		var name = a[i].name;
		fscanfFormats.push(GetFormat(a[i].type, name));
		summaries.push("expected_" + name);
		var b = name.slice(-9) === "registers" ? "sout" : "expected_" + name;
		fscanfArguments.push(b);
	}
	for(var i = 0, a = moduleParameters.interfaces, n = a.length; i < n; ++i) {
		var name = a[i].name;
		var modport = interfaces[a[i].interfaceName][a[i].modportName];
		for(var j = 0, b = modport.outputs, m = b.length; j < m; ++j) {
			fscanfFormats.push(GetFormat("", b[j]));
			fscanfArguments.push("expected_" + name + "." + b[j]);
			summaries.push("expected_" + name + "." + b[j]);
		}
	}
	var s = '\terr= $sscanf(s, "%' + fscanfFormats.join(" %") + '", ' + fscanfArguments.join(", ") + ");";
	print(s);
	print('\tif(err < ' + fscanfFormats.length + ') begin');
	print('\t\t$display("%d tests completed with %d errors", test_vector_index, errors);');
	print('\t\t$stop;');
	print('\tend');
	var s = '\t$display("line %2d: (%1d) %' + fscanfFormats.join(" %") + '", test_vector_index + 2, err, ' + fscanfArguments.join(", ") + ");";
	print(s);
	for(var i = 0, n = moduleParameters.registers.length; i < n; ++i) {
		var name = moduleParameters.registers[i];
		var s = name.substr(0, 6) === "output" ? "sout" : "sin";
		if(s === "sout")
			name = "expected_" + name;
		print('\t' + name + '[0]= 0;');
		for(var a = "", b = "", j = 1; j < interfaces.nr; ++j) {
			a += ",%x";
			b += ", " + name + "[" + j + "]";
		}
		a = a.substr(1);
		print('\terr= $sscanf(' + s + ', "' + a + '"' + b + ');');
		print('\tfor(i= err + 1; i < NR; ++i)');
		print('\t\t' + name + '[i]= ' + name + '[err];');
	}
	print('end');
	print();
	print('always@(negedge test_setup_clock) begin');
	var emitted_if = false;
	var emit_prolog = function () {
		var s = emitted_if ? "\t\t\t|| " : "\tif("/*)*/;
		emitted_if = true;
		return s;
	};
	for(var i = 0, a = moduleParameters.outputs, n = a.length; i < n; ++i) {
		var name = a[i].name;
		var relop = name.slice(-9) === "registers" ? "=" : "==";
		print(emit_prolog() + name + " !" + relop + " expected_" + name + " && (enforce_dont_cares || expected_" + name + " !" + relop + " 'X)");
	}
	for(var i = 0, a = moduleParameters.interfaces, n = a.length; i < n; ++i) {
		var modport = interfaces[a[i].interfaceName][a[i].modportName];
		for(var j = 0, b = modport.outputs, m = b.length; j < m; ++j) {
			print(emit_prolog() + a[i].name + "." + b[j] + " !== expected_" + a[i].name + "." + b[j] + " && (enforce_dont_cares || expected_" + a[i].name + "." + b[j] + " !== 'X)");
		}
	}
	print(/*(*/"\t\t\t) begin");
	print('\t\t$display("Error: inputs: ' + errorFormats.join(", ") + '", ' + errorArguments.join(", ") + ');');
	print('\t\terrors += 1;');
	for(var i = 0, a = moduleParameters.outputs, n = a.length; i < n; ++i) {
		var name = a[i].name;
		var relop = name.slice(-9) === "registers" ? "=" : "==";
		print("\t\tif(" + name + " !" + relop + " expected_" + name + " && (enforce_dont_cares || expected_" + name + " !" + relop + " 'X))");
		var format = GetFormat(a[i].type, name);
		if(relop === '==')
			print('\t\t\t$display("output: ' + name + '=%' + format + ' (%' + format + ' expected)", ' + name + ', expected_' + name + ');');
		else {
			for(var m = "", b = "", s = "", j = 1; j < interfaces.nr; ++j) {
				m += ",%x";
				b += ", " + name + "[" + j + "]";
				s += ", expected_" + name + "[" + j + "]";
			}
			m = m.substr(1);
			print('\t\t\t$display("output: ' + name + '=' + m + ' (' + m + ' expected)"' + b + s + ');');
		} 
	}
	for(var i = 0, a = moduleParameters.interfaces, n = a.length; i < n; ++i) {
		var modport = interfaces[a[i].interfaceName][a[i].modportName];
		for(var j = 0, b = modport.outputs, m = b.length; j < m; ++j) {
			var name = a[i].name + "." + b[j];
			print("\t\tif(" + name + " !== expected_" + name + " && (enforce_dont_cares || expected_" + name + " !== 'X))");
			print('\t\t\t$display("output: ' + name + '=%x (%x expected)", ' + name + ', expected_' + name + ');');
		}
	}
	print("\tend else");
	print('\t\t$display("okay");');
	print("\ttest_vector_index += 1;");
	print("end");
	print();
	print("endmodule");
	print();
	print("//", summaries.join(' '));
}

Main();
