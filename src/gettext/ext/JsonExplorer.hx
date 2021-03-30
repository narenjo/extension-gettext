package gettext.ext;

import sys.FileSystem;
import haxe.display.Protocol.HaxeNotificationMethod;
import gettext.data.GetText;
import gettext.data.GetText.POData;
import gettext.data.IExplorer;

class JsonExplorer implements IExplorer {
	var strMap:Map<String, Bool>;
	var data:POData;

	public function new() {}

	public function explore(folder:String, data:POData, strMap:Map<String, Bool>, ?codeIgnore:EReg) {
		var stack = [folder];
		this.strMap = strMap;
		this.data = data;
		// Sys.println(folder);
		while (stack.length > 0) {
			var folder = stack.shift();
			if (sys.FileSystem.isDirectory(folder)) {
				for (f in sys.FileSystem.readDirectory(folder)) {
					var path = folder + "/" + f;
					var relPath = StringTools.replace(path, Sys.getCwd(), "");
					if (codeIgnore != null && codeIgnore.match(path)) {
						trace("Ignore: " + path);
						continue;
					}

					// Parse sub folders
					if (sys.FileSystem.isDirectory(path)) {
						stack.push(path);
						continue;
					}

					// Ignore non json builder
					if (f.substr(f.length - 5) != ".json")
						continue;

					try {
						var json = haxe.Json.parse(sys.io.File.getContent(path));
						load(relPath, json);
					} catch (e:Dynamic) {
						Sys.println("=============");
						Sys.println("Error in " + path);
						Sys.println(e);
						Sys.println("skipping...");
						Sys.println("=============");
					}
				}
			} else if (FileSystem.exists(folder)) {
				var path = folder;
				var relPath = StringTools.replace(path, Sys.getCwd(), "");
				try {
					var json = haxe.Json.parse(sys.io.File.getContent(path));
					load(relPath, json);
				} catch (e:Dynamic) {
					Sys.println("=============");
					Sys.println("Error in " + path);
					Sys.println(e);
					Sys.println("skipping...");
					Sys.println("=============");
				}
			}
		}
	}

	function load(f:String, json:Dynamic) {
		if (Std.is(json, Array)) {
			var arr:Array<Dynamic> = cast json;
			for (obj in arr) {
				load(f, obj);
			}
		} else {
			for (field in Reflect.fields(json)) {
				var val:Dynamic = Reflect.field(json, field);
				if (field == "text" || field == "label") {
					processText(f, val);
				} else if (Std.is(val, Array)) {
					load(f, val);
				}
			}
		}
	}

	function processText(f:String, text:Dynamic) {
		if (Std.is(text, Array)) {
			var t:Array<String> = cast text;
			for (txt in t) {
				processString(f, txt);
			}
		} else if (Std.is(text, String)) {
			processString(f, text);
		}
	}

	function processString(f:String, str:String) {
		var cleanedStr = str;
		var n = 0;
		// Translator comment
		var comment:String = null;
		if (cleanedStr.indexOf(GetText.CONTEXT) >= 0) {
			var parts = cleanedStr.split(GetText.CONTEXT);
			if (parts.length != 2) {
				GetText.error(f, n, "Malformed translator comment");
				return;
			}
			if (parts[0].length != StringTools.rtrim(parts[0]).length || parts[1].length != StringTools.trim(parts[1]).length) {
				GetText.error(f, n, "Any SPACE character around \"" + GetText.CONTEXT + "\" will lead to translation overlaps");
				return;
			}
			comment = StringTools.trim(parts[1]);
			cleanedStr = cleanedStr.substr(0, cleanedStr.indexOf(GetText.CONTEXT));
		}
		cleanedStr = StringTools.replace(cleanedStr, "\n", "\\n");
		cleanedStr = StringTools.rtrim(cleanedStr);

		// New entry found
		if (!strMap.exists(cleanedStr)) {
			strMap.set(cleanedStr, true);
			data.push({
				id: cleanedStr,
				str: "",
				cRef: f + ":" + n,
				cExtracted: comment,
			});
		} else {
			var previous = Lambda.find(data, function(e) return e.id == cleanedStr && e.cExtracted == comment);
			if (previous != null && previous.cExtracted == comment) {
				previous.cRef += " " + f + ":" + n;
			} else {
				// if( previous != null && previous.cExtracted != null && previous.cExtracted.length > 0 ){
				// 	previous.id += " "+CONTEXT+" "+previous.cExtracted;
				// }
				// if( comment != null && comment.length > 0 ){
				// 	cleanedStr += " || " + comment;
				// }
				data.push({
					id: cleanedStr,
					str: "",
					cRef: f + ":" + n,
					cExtracted: comment,
				});
			}
		}
		// Sys.println(cleanedStr);
	}
}
