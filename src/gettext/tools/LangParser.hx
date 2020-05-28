package gettext.tools;

import gettext.ext.StarlingBuilderFilesExplorer;
import sys.FileSystem;
import gettext.data.GetText;

class LangParser {
	public static function main() {
		var args = Sys.args();
		Sys.println(args);
		if(args.length != 3 && args.length != 4 && args.length != 5){
			Sys.println("Usage : source_folder po_folder json_folder [custom_explorer_class]");
			Sys.exit(1);
		}

		var cwd = args.pop();
		Sys.setCwd(cwd);
		var explorer = null;

		if(args.length == 4){
			Sys.println(args[3]);
			var clz = Type.resolveClass(args[3]);
			Sys.println("CLASS OK? " + (clz != null) + " " + clz);
			explorer = Type.createEmptyInstance(clz);
			
		}
		Sys.exit(1);
		var source = FileSystem.absolutePath(args[0]);
		var lang = FileSystem.absolutePath(args[1]);

		var assets = FileSystem.absolutePath(args[2]);

		var name = "sourceTexts";
		Sys.println("Building "+name+" file...");
		explorer = new StarlingBuilderFilesExplorer();
		try {

			var cdbs = #if castle findAll(assets, "cdb") #else null #end;
			var data = GetText.doParseGlobal({
				codePath: source,
				codeIgnore: null,
				cdbFiles: cdbs,
				cdbSpecialId: [],
				potFile: lang + "/"+name+".pot",
				customExplorer: explorer,
				customExplorerFiles: assets
			});
		}
		catch(e:String) {
			Sys.println("");
			Sys.println(e);
			Sys.println("Extraction failed: fatal error!");
			Sys.println("");
			Sys.exit(1);
		}
		Sys.println("Done.");
	}
#if castle
	static function findAll(path:String, ext:String, ?cur:Array<String>) {
		var ext = "."+ext;
		var all = cur==null ? [] : cur;
		Sys.println(path);
		for(e in sys.FileSystem.readDirectory(path)) {
			e = path+"/"+e;
			if( e.indexOf(ext)>=0 && e.lastIndexOf(ext)==e.length-ext.length )
				all.push(e);
			if( sys.FileSystem.isDirectory(e) && e.indexOf(".tmp")<0 )
				findAll(e, ext, all);
		}
		return all;
	}
#end
}