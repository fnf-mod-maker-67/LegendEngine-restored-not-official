package states.editors;

import backend.Paths;
import sys.FileSystem;
import flixel.graphics.FlxGraphic;

typedef Script = {
    var isLua:String;
    var name:String;
    var path:String;
    var detail:String;
}

class ScriptEditorState extends MusicBeatState {
    var fileList:Array<String>;
    var scriptList:Array<Script>;

    var curSelected:Int = 0;
    var bg:FlxSprite;
    var listBox:FlxSprite;
    var listSprite:FlxSpriteGroup;
    
    override function create() {
        reload();

        bg = new FlxSprite(0, 0);
        bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.GRAY);
        add(bg);

        listBox = new FlxSprite(50, 40);
        listBox.makeGraphic(400, 680, 0xFF87CEEB);
        add(listBox);

        listSprite = new FlxSpriteGroup(0,0);
        
        var i:Int = 0;
        for (rawItem in scriptList) {
            var items:FlxSpriteGroup = new FlxSpriteGroup(0,0);
            var icon:FlxSprite = new FlxSprite(0,0);
            var iconPath:FlxGraphic = Paths.image('scriptEditor/icon/'+rawItem.name);
            icon.loadGraphic(Paths.image('scriptEditor/placeholder'));
            if (Paths.fileExists("scriptEditor/icon/"+rawItem.name, IMAGE))
                icon.loadGraphic(iconPath);
            
            var luaHx:FlxSprite = new FlxSprite(0,icon.y + icon.height);
            if (rawItem.isLua == "lua") 
                luaHx.loadGraphic(Paths.image('scriptEditor/lua'));
            else if (rawItem.isLua == "hx")
                luaHx.loadGraphic(Paths.image('scriptEditor/hx'));
            else
                luaHx.loadGraphic(Paths.image('scriptEditor/other'));
            
            var txt:FlxText = new FlxText(icon.x + icon.width + 10, 0, 380, rawItem.name, 36);
            txt.setFormat(Paths.font("vcr.ttf"), 36, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
            txt.borderSize = 2;
            
            items.add(icon);
            items.add(luaHx);
            items.add(txt);
            items.y = listBox.y + i * (icon.height + 10);
            listSprite.add(items);
            i++;
        }
        add(listSprite);
        super.create();
    }

    function reload() {
        fileList = [];
        scriptList = [];
        fileList = FileSystem.readDirectory(Paths.getPath('scripts',null,null,true));
        for (i in fileList.copy()) {
            if (FileSystem.isDirectory(Paths.getPath('scripts',null,null,true) + '/' + i))
                fileList.remove(i);
        }
        
        for (i in fileList) {
            var isLua:String = "other";
            if (StringTools.endsWith(i, ".lua")) {
                isLua = "lua";
            }
            else if (StringTools.endsWith(i, ".hx")) {
                isLua = "hx";
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
