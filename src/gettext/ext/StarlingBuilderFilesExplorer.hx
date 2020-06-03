package gettext.ext;

import gettext.data.GetText;
import gettext.data.GetText.POData;
import gettext.data.IExplorer;

class StarlingBuilderFilesExplorer implements IExplorer{
	var strMap:Map<String,Bool>;
	var data:POData;
	public function new(){}
    public function explore(folder:String, data:POData, strMap:Map<String,Bool>, ?codeIgnore: EReg){
		var stack = [folder];
		this.strMap = strMap;
		this.data = data;
		//Sys.println(folder);
        while( stack.length > 0 ){
			var folder = stack.shift();
			for( f in sys.FileSystem.readDirectory(folder) ) {
				var path = folder+"/"+f;
				if( codeIgnore != null && codeIgnore.match(path) ){
					trace("Ignore: "+path);
					continue;
				}

				// Parse sub folders
				if( sys.FileSystem.isDirectory(path) ) {
					stack.push(path);
					continue;
				}

				// Ignore non starling builder
				if( f.substr(f.length - 5) != ".json" )
                    continue;
                
				var json = haxe.Json.parse(sys.io.File.getContent(path));
				load(path, json.layout);
            }
        }
	}
	function load(f:String, obj:Dynamic){
		if(obj.cls == "starling.text.TextField" || obj.cls == "starling.display.Button"){
			// if(obj.params != null){
			// 	Sys.println("NAME ======== " + obj.params.name);
			// 	Sys.println("TEXT ======== " + obj.params.text);
			// }
			if(obj.customParams != null && obj.customParams.localizeKey != null){
				//Sys.println("LOC KEY ======== " + obj.customParams.localizeKey);
				processString(f, obj.customParams.localizeKey);
			}
		}
		
		if(obj.children != null){
			//Sys.println("HAS CHiDLREN");
			for(child in cast(obj.children, Array<Dynamic>)){
				//Sys.println("LOAD CHILD");
				load(f, child);
			}
		}
	}
	function processString(f:String, str:String){
		var cleanedStr = str;
		var n = 0;
		// Translator comment
		var comment : String = null;
		if( cleanedStr.indexOf(GetText.CONTEXT)>=0 ) {
			var parts = cleanedStr.split(GetText.CONTEXT);
			if( parts.length!=2 ) {
				GetText.error(f,n,"Malformed translator comment");
				return;
			}
			if( parts[0].length != StringTools.rtrim(parts[0]).length ||
				parts[1].length != StringTools.trim(parts[1]).length ) {
					GetText.error(f,n,"Any SPACE character around \""+GetText.CONTEXT+"\" will lead to translation overlaps");
					return;
				}
			comment = StringTools.trim(parts[1]);
			cleanedStr = cleanedStr.substr(0,cleanedStr.indexOf(GetText.CONTEXT));
		}
		cleanedStr = StringTools.replace(cleanedStr, "\n", "\\n");
		cleanedStr = StringTools.rtrim(cleanedStr);

		// New entry found
		if( !strMap.exists(cleanedStr) ) {
			strMap.set(cleanedStr, true);
			data.push({
				id			: cleanedStr,
				str			: "",
				cRef		: f+":"+n,
				cExtracted	: comment,
			});
		}else{
			var previous = Lambda.find(data,function(e) return e.id==cleanedStr && e.cExtracted==comment);
			if( previous != null && previous.cExtracted == comment ){
				previous.cRef += " "+f+":"+n;
			}else{
				// if( previous != null && previous.cExtracted != null && previous.cExtracted.length > 0 ){
				// 	previous.id += " "+CONTEXT+" "+previous.cExtracted;
				// }
				// if( comment != null && comment.length > 0 ){
				// 	cleanedStr += " || " + comment;
				// }
				data.push({
					id			: cleanedStr,
					str			: "",
					cRef		: f+":"+n,
					cExtracted	: comment,
				});
			}
		}
	}
}