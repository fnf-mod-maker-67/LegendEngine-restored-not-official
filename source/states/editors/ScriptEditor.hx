import backend.Paths;

typedef Script = {
    var isLua:Bool;
    var name:String;
    var path:String;
    var detail:String;
}

class ScriptEditor extends MusicBeatState {
    var fileList:Array<String>;
    var scriptList:Array<Script>;
    
    function create() {
        scriptList = [];
        fileList = FileSystem.readDirectory(Paths.getPath('scripts',null,null,true));
        for (i in fileList.copy()) {
            if (FileSystem.isDirectory(Paths.getPath('scripts',null,null,true) + '/' + i))
                fileList.remove(i);
        }
        
        for (i in fileList) {
            var isLua:Bool = false;
            
            if (StringTools.endsWith(i, ".lua")) {
                isLua = true;
            }

            var splited:Array<String> = i.split('.'); 
            var name:String = splited[0];
            var path:String = "scripts/" + i;
            var detail:String = Paths.getTextFromFile(path);
            var script:Script = {isLua:isLua, name:name, path:path, detail:detail};
            scriptList.push(script);
        }
    }
    
}
