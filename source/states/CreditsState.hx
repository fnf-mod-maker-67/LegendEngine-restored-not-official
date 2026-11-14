package states;

import objects.AttachedSprite;

class CreditsState extends MusicBeatState
{
	var curSelected:Int = -1;

	private var grpOptions:FlxTypedGroup<FlxText>;
	private var iconArray:Array<AttachedSprite> = [];
	private var creditsStuff:Array<Array<String>> = [];

	var bg:FlxSprite;
	var descText:FlxText;
	var bigIcon:FlxSprite;
	
	var offsetThing:Float = -75;

	override function create()
	{
		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("크레딧 보는 중", null);
		#end

		persistentUpdate = true;
		bg = new FlxSprite().loadGraphic(Paths.image('Credits'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);
		bg.screenCenter();
		
		grpOptions = new FlxTypedGroup<FlxText>();
		add(grpOptions);

		#if MODS_ALLOWED
		for (mod in Mods.parseList().enabled) pushModCreditsToList(mod);
		#end

		var defaultList:Array<Array<String>> = [ //Name - Icon name - Description - Link - BG Color
			["Original game"],
			["FNF Crew", 		  "fnf",   "", "https://ninja-muffin24.itch.io/funkin", 		 "5165F6"],
			["Psych Engine Crew", "psych", "", "https://github.com/ShadowMario/FNF-PsychEngine", "5165F6"],
			["Mod dev"], // 새로운 카테고리 이름
			["Tubenyan",            "tubenyan",         "ALL OF MOD",       				"https://guns.lol/tubenyan",   		            "41c0ff"],
			["GreenGreen",          "green",            "Animator",       					"https://www.youtube.com/@Korean-Green-14",     "41c0ff"],
			["Barty",            	"barty",            "Animator",       					"",                                             "41c0ff"],
			["Dahee Song",          "songdah",          "Artist",       					"",     										"41c0ff"],
			["Used AI"],
			["Gemini",              "gemini",           'Made some code for Tubenyan',    	"https://gemini.google.com/app",     			'4285F4'],
			["Claude",              "claude",           'Same with Gemini',                 "https://claude.ai",     						'4285F4'],
			["Our DISCORD"],
			["Join In Legend Begins Team!!", "discord", "", 								"https://discord.gg/tDCmRFtPjv", 				"5165F6"],
			[""]
		];
		
		for(i in defaultList)
			creditsStuff.push(i);
	
		for (i => credit in creditsStuff)
		{
			var isSelectable:Bool = !unselectableCheck(i);
			var optionText:FlxText = new FlxText(0, 0, 0, credit[0], isSelectable ? 40 : 48);
	
	// 폰트, 크기, 색상, 정렬 방식, 테두리 스타일 설정
			optionText.setFormat(Paths.font("vcr.ttf"), isSelectable ? 40 : 48, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			optionText.borderSize = 2;
			grpOptions.add(optionText);

			if(isSelectable)
			{
    			if(credit[5] != null)
        			Mods.currentModDirectory = credit[5];

    			var str:String = 'credits/missing_icon';
    			if(credit[1] != null && credit[1].length > 0)
    			{
        			str = 'credits/' + credit[1]; 
    			}

    			var icon:AttachedSprite = new AttachedSprite(str);
				if(str.endsWith('-pixel')) icon.antialiasing = false;
				icon.xAdd = optionText.width + 10;
				icon.yAdd = (optionText.height - icon.height) / 2;
				icon.sprTracker = optionText;
	
				// using a FlxGroup is too much fuss!
				iconArray.push(icon);
				add(icon);
				Mods.currentModDirectory = '';

				if(curSelected == -1) curSelected = i;
			}
		}

		descText = new FlxText(FlxG.width / 2, FlxG.height * 0.5, FlxG.width / 2, "", 36);
		descText.setFormat(Paths.font("pixel-latin.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		descText.borderSize = 4;
		descText.scrollFactor.set();
		add(descText);
		
		bigIcon = new FlxSprite();
		bigIcon.antialiasing = ClientPrefs.data.antialiasing;
		add(bigIcon);
		
		changeSelection();
		super.create();
	}

	var quitting:Bool = false;
	var holdTime:Float = 0;
	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * elapsed;
		}

		if(!quitting)
		{
			if(creditsStuff.length > 1)
			{
				var shiftMult:Int = 1;
				if(FlxG.keys.pressed.SHIFT) shiftMult = 3;

				var upP = controls.UI_UP_P;
				var downP = controls.UI_DOWN_P;

				if (upP)
				{
					changeSelection(-shiftMult);
					holdTime = 0;
				}
				if (downP)
				{
					changeSelection(shiftMult);
					holdTime = 0;
				}

				if(controls.UI_DOWN || controls.UI_UP)
				{
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

					if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
					{
						changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
					}
				}
			}
			var link = creditsStuff[curSelected][3];
			if(controls.ACCEPT && link != null && link.length > 4)
    			CoolUtil.browserLoad(link);
			
			if (controls.BACK)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new MainMenuState());
				quitting = true;
			}
		}
		var lerpVal:Float = Math.exp(-elapsed * 12);
		for (i => item in grpOptions.members)
		{
    		var targetY:Float = (FlxG.height / 2 - item.height / 2) + ((i - curSelected) * 150);
    		item.y = FlxMath.lerp(targetY, item.y, lerpVal);
    		item.x = FlxMath.lerp(50, item.x, lerpVal);
		}		
		super.update(elapsed);
	}

	var moveTween:FlxTween = null;
	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		do
		{
			curSelected = FlxMath.wrap(curSelected + change, 0, creditsStuff.length - 1);
		}
		while(unselectableCheck(curSelected));
		var imagePath = Paths.image("credits/" + creditsStuff[curSelected][1]);
		bigIcon.loadGraphic(imagePath);
		for (num => item in grpOptions.members)
		{
			if(!unselectableCheck(num)) {
				item.alpha = (num == curSelected) ? 1.0 : 0.6;
			} else {
				item.alpha = 1.0;
			}
		}

		descText.text = creditsStuff[curSelected][2];
		descText.visible = descText.text.trim().length > 0;
		if (descText.visible)
		{
			descText.y = FlxG.height * 0.5 - 75;
    		if (moveTween != null) moveTween.cancel();
    		moveTween = FlxTween.tween(descText, {y : descText.y + 75}, 0.25, {ease: FlxEase.sineOut});
		}
		bigIcon.setGraphicSize(300, 300 * bigIcon.height / bigIcon.width);
		bigIcon.updateHitbox();
		bigIcon.x = FlxG.width * 0.75 - bigIcon.width / 2;
		bigIcon.y = FlxG.height * 0.25 - bigIcon.height / 2;
	}

	#if MODS_ALLOWED
	function pushModCreditsToList(folder:String)
	{
		var creditsFile:String = Paths.mods(folder + '/data/credits.txt');
		
		#if TRANSLATIONS_ALLOWED
		//trace('/data/credits-${ClientPrefs.data.language}.txt');
		var translatedCredits:String = Paths.mods(folder + '/data/credits-${ClientPrefs.data.language}.txt');
		#end

		if (#if TRANSLATIONS_ALLOWED (FileSystem.exists(translatedCredits) && (creditsFile = translatedCredits) == translatedCredits) || #end FileSystem.exists(creditsFile))
		{
			var firstarray:Array<String> = File.getContent(creditsFile).split('\n');
			for(i in firstarray)
			{
				var arr:Array<String> = i.replace('\\n', '\n').split("::");
				if(arr.length >= 5) arr.push(folder);
				creditsStuff.push(arr);
			}
			creditsStuff.push(['']);
		}
	}
	#end

	private function unselectableCheck(num:Int):Bool {
		return creditsStuff[num].length <= 1;
	}
}
