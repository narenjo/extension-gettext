package gettext;

import haxe.io.Bytes;
import gettext.data.GetText;

class Lang {
    static var _initDone = false;
    static var DEFAULT = "en";
    public static var CUR = "??";
    public static var t : GetText;

    public static function init(?lid:String, ?bytes:Bytes) {
        if( _initDone )
            return;

        _initDone = true;
        CUR = lid==null ? DEFAULT : lid;

		t = new GetText();
		t.readMo( bytes);//getBytesMethod("assets/i18n/"+CUR+".mo") );
    }

    public static function untranslated(str:Dynamic) : LocaleString {
        init();
        return t.untranslated(str);
    }
}