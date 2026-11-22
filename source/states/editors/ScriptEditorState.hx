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

    var isTyping:Bool = false;
    
    var curSelected:Int = 0;
    var bg:FlxSprite;
    var listBox:FlxSprite;
    var listSprite:FlxSpriteGroup;

    var selectSprite:FlxSprite;

    var listCam:FlxCamera;
    
    override function create() {
        super.create();
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
            
            var luaHx:FlxSprite = new FlxSprite(0,0);
            if (rawItem.isLua == "lua") 
                luaHx.loadGraphic(Paths.image('scriptEditor/lua'));
            else if (rawItem.isLua == "hx")
                luaHx.loadGraphic(Paths.image('scriptEditor/hx'));
            else
                luaHx.loadGraphic(Paths.image('scriptEditor/other'));
            luaHx.y = icon.y + icon.height - luaHx.height;
            
            var txt:FlxText = new FlxText(icon.x + icon.width, 0, 380, rawItem.name, 36);
            txt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
            txt.borderSize = 2;
            
            items.add(icon);
            items.add(luaHx);
            items.add(txt);
            items.y = i * (icon.height + 10);
            listSprite.add(items);
            i++;
        }
        selectSprite = new FlxSprite(0,0);
        add(selectSprite);
        add(listSprite);

        listCam = new FlxCamera(listBox.x, listBox.y, Std.int(listBox.width), Std.int(listBox.height));
        listCam.bgColor = 0x00000000;
        FlxG.cameras.add(listCam, false);
        listSprite.cameras = [listCam];
        selectSprite.cameras = [listCam];  
        
        changeSelect(0);        
    }
    override function update(elapsed:Float) {
        if (!isTyping) {
            selectSprite.visible = true;
            if (controls.UI_DOWN_P) changeSelect(1);
            if (controls.UI_UP_P) changeSelect(-1);
            if (controls.BACK) MusicBeatState.switchState(new MasterEditorMenu());
        }
        super.update(elapsed);
    }

    function changeSelect(howmuch:Int) {
        curSelected += howmuch;
        if (scriptList.length <= curSelected) curSelected = 0;
        if (curSelected < 0) curSelected = scriptList.length - 1;
        
        var item:FlxSpriteGroup = cast listSprite.members[curSelected];
        var width:Int = Std.int(item.width);
        var height:Int = Std.int(item.height);
        selectSprite.makeGraphic(width, height, FlxColor.WHITE);
        selectSprite.alpha = 0.5;
        selectSprite.x = item.x;
        selectSprite.y = item.y;

        listCam.scroll.y = curSelected * item.height + 10;
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
