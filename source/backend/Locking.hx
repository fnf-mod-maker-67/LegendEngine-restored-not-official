package backend;

class Locking {
    public static var fpLocked:Bool = true;
    public static var charLocked:Bool = true;
    public static var missionLocked:Bool = true;

    public static function init() {
        if (FlxG.save.data.fpLocked != null) fpLocked = FlxG.save.data.fpLocked;
        else {fpLocked = true; FlxG.save.data.fpLocked = true;}
        if (FlxG.save.data.charLocked != null) charLocked = FlxG.save.data.charLocked;
        else {charLocked = true; FlxG.save.data.charLocked = true;}
        if (FlxG.save.data.missionLocked != null) missionLocked = FlxG.save.data.missionLocked;
        else {missionLocked = true; FlxG.save.data.missionLocked = true;}
    }
    
    public static function setLock(what:String, how:Bool) {         
        if (what.toLowerCase() == "freeplay") { fpLocked = how; FlxG.save.data.fpLocked = how; }
        else if (what.toLowerCase() == "charselect") { charLocked = how; FlxG.save.data.charLocked = how; }
        else if (what.toLowerCase() == "mission") { missionLocked = how; FlxG.save.data.missionLocked = how; }
        else return;
    }
    
    public static function isLocked(what:String):Bool {
        //1
        if (what.toLowerCase() == "freeplay") return fpLocked;
        else if (what.toLowerCase() == "charselect") return charLocked;
        else if (what.toLowerCase() == "mission") return missionLocked;
        else return false;
    }
}
