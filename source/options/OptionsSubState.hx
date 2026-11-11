package options;
import backend.MusicBeatSubstate;
import states.MainMenuState;
import backend.StageData;
import flixel.group.FlxSpriteGroup;

class OptionsSubState extends MusicBeatSubstate
{	
	var options:Array<String> = [
		'Controls',
		'Graphics',
		'Gameplay'
		#if TRANSLATIONS_ALLOWED , 'Language' #end
	];

	public static var instance:OptionsSubState;
	
	private static var curSelected:Int = 0;
	public static var onPlayState:Bool = false;
	
	private var grpOptions:FlxSpriteGroup;
	private var parentGrp:FlxSpriteGroup;
	public static var optionWindow:FlxSprite;
	public var optionCam:FlxCamera;
	var blockInput:Bool = true; // 입력 차단 플래그 추가
	
	function openSelectedSubstate(label:String) {
		var sub:MusicBeatSubstate = null;
		FlxTween.tween(grpOptions, {x: -900}, 1, {ease: FlxEase.quadOut});
		switch(label) {
			case 'Controls':
				sub = new options.ControlsSubState();
			case 'Graphics':
				sub = new options.GraphicsSettingsSubState();
			case 'Gameplay':
				sub = new options.GameplaySettingsSubState();
			case 'Language':
				sub = new options.LanguageSubState();
		}
		
		if (sub != null)
		{
			sub.cameras = [optionCam];
			openSubState(sub);
		}
	}

	var selectorLeft:Alphabet;
	var selectorRight:Alphabet;

	override function create() {
		instance = this;
		
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("옵션 메뉴", null);
		#end
			
		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.screenCenter();
		bg.alpha = 0.5;
		add(bg);

		parentGrp = new FlxSpriteGroup();
		add(parentGrp);
		
		optionWindow = new FlxSprite(0,0).loadGraphic(Paths.image('optionBG'));
		optionWindow.antialiasing = ClientPrefs.data.antialiasing;
		optionWindow.updateHitbox();
		parentGrp.add(optionWindow);
		
		grpOptions = new FlxSpriteGroup();
		parentGrp.add(grpOptions);

		
		
		var startY:Float = 150;    // 첫 번째 버튼이 시작될 창 내부의 Y 좌표
		var padding:Float = 50;     // 버튼과 버튼 사이의 순수 여백 (원하는 만큼 조절)

		for (num => option in options)
		{
    		var btn:FlxSprite = new FlxSprite(0, 0);
    		btn.loadGraphic(Paths.image('options/' + option.toLowerCase()));
			
    		btn.y = startY + (num * (btn.height + padding));
    
    		btn.ID = num;
			
    		grpOptions.add(btn);
		}

		selectorLeft = new Alphabet(0, 0, '>', true);
		selectorRight = new Alphabet(0, 0, '<', true);

		parentGrp.screenCenter();

		// parentGrp.screenCenter(); 바로 아래에 삽입
		var camX:Int = Std.int(parentGrp.x + 40);
		var camY:Int = Std.int(parentGrp.y + 120);
		var camW:Int = Std.int(optionWindow.width - 80);     // 잘라낼 내부 너비
		var camH:Int = Std.int(optionWindow.height - 140);   // 잘라낼 내부 높이

		optionCam = new FlxCamera(camX, camY, camW, camH);
		optionCam.bgColor = 0x00000000;                      // 윈도우 배경이 보이도록 투명화
		FlxG.cameras.add(optionCam, false);
		
		changeSelection();
		ClientPrefs.saveSettings();
		grpOptions.x = optionWindow.x + (optionWindow.width - grpOptions.width) / 2;

		blockInput = true;
    	new flixel.util.FlxTimer().start(0.1, function(tmr:flixel.util.FlxTimer) {
        	blockInput = false;
    	});
		
		super.create();
	}

	override function closeSubState()
	{
		super.closeSubState();
		grpOptions.x = optionWindow.x + (optionWindow.width - grpOptions.width) / 2;
		ClientPrefs.saveSettings();
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("설정 메뉴", null);
		#end
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		if (blockInput) return;
		
		if (controls.UI_UP_P)
			changeSelection(-1);
		if (controls.UI_DOWN_P)
			changeSelection(1);

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			if(onPlayState)
			{
				StageData.loadDirectory(PlayState.SONG);
				LoadingState.loadAndSwitchState(new PlayState());
				FlxG.sound.music.volume = 0;
			}
			else close();
		}
		else if (controls.ACCEPT) openSelectedSubstate(options[curSelected]);
	}
	
	function changeSelection(change:Int = 0)
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, options.length - 1);

		for (num => item in grpOptions.members)
		{
			item.alpha = 0.6;
			if (num == curSelected)
			{
				item.alpha = 1;
				selectorLeft.x = item.x - 63;
				selectorLeft.y = item.y;
				selectorRight.x = item.x + item.width + 15;
				selectorRight.y = item.y;
			}
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	override function destroy()
	{
		instance = null;
		ClientPrefs.loadPrefs();
		if (optionCam != null)
		{
    		FlxG.cameras.remove(optionCam, true);
		}
		FlxTransitionableState.skipNextTransIn = true;
		FlxTransitionableState.skipNextTransOut = true;
		MusicBeatState.switchState(new states.MainMenuState());
		super.destroy();
	}
}
