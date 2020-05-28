package gettext.data;

import gettext.data.GetText.POData;

interface IExplorer {
    public function explore(folder:String, data:POData, strMap:Map<String,Bool>, ?codeIgnore: EReg):Void;
}