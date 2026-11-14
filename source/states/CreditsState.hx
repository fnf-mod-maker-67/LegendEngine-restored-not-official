package states;

import objects.AttachedSprite;
import flixel.graphics.FlxGraphic;

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
			["Funkin Crew", 		  	"fnf",   			"Made Original Friday Night Funkin'", 				"https://ninja-muffin24.itch.io/funkin", 		 "5165F6"],
			["Psych Engine Crew", 	"psych", 			"Made Psych Engine 1.0.4\nCloned for Legend Engine", 		"https://github.com/ShadowMario/FNF-PsychEngine", "5165F6"],
			["Mod devs"],
			["Tubenyan",            "tubenyan",         "Actually All of mod",       		"https://guns.lol/tubenyan",   		            "41c0ff"],
			["GreenGreen",          "green",            "Animator",       					"https://www.youtube.com/@Korean-Green-14",     "41c0ff"],
			["Barty",            	"barty",            "Animator",       					"",                                             "41c0ff"],
			["Dahee Song",          "songdah",          "Artist",       					"",     										"41c0ff"],
			["Used AI"],
			["Gemini",              "gemini",           'Made some code\nfor Tubenyan',    	"https://gemini.google.com/app",     			'4285F4'],
			["Claude+Base44",       "claude",           'Same with Gemini',                 "https://claude.ai",     						'4285F4'],
			["Discord"],
			["Mod Official Discord","discord", 			"Join to our talking!",				"https://discord.gg/tDCmRFtPjv", 							"5165F6"],
			[""]
		];
		
		for(i in defaultList)
			creditsStuff.push(i);
	
		for (i => credit in creditsStuff)
		{
			var isSelectable:Bool = !unselectableCheck(i);
			var scale:Int = isSelectable ? 45 : 57;
			var optionText:FlxText = new FlxText(0, 0, 0, credit[0], scale);
			
			optionText.setFormat(Paths.font("vcr.ttf"), scale, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			optionText.borderSize = isSelectable ? 2 : 3;
			optionText.antialiasing = true;
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
				icon.setGraphicSize(100, 0);
				icon.sprTracker = optionText;
	
				// using a FlxGroup is too much fuss!
				iconArray.push(icon);
				add(icon);
				Mods.currentModDirectory = '';

				if(curSelected == -1) curSelected = i;
			}
		}

		descText = new FlxText(FlxG.width / 2, 0, FlxG.width * 0.5, "");
		descText.setFormat(Paths.font("pixel-latin.ttf"), 25, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		descText.borderSize = 4;
		descText.scrollFactor.set();
		add(descText);
		
		bigIcon = new FlxSprite();
		bigIcon.antialiasing = true;
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
		    var targetY:Float = (FlxG.height / 2 - item.height / 2) + ((i - curSelected) * 100);
		    var targetX:Float = unselectableCheck(i) ? 50 : 100;
		    item.y = FlxMath.lerp(targetY, item.y, lerpVal);
		    item.x = FlxMath.lerp(targetX, item.x, lerpVal);
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
		
		var name:String = creditsStuff[curSelected][1];
		bigIcon.loadGraphic(Paths.image('credits/' + name) ?? Paths.image('credits/missing_icon'));
		bigIcon.setGraphicSize(250, 0);
		bigIcon.updateHitbox();
		bigIcon.x = FlxG.width * 0.75 - bigIcon.width / 2 + 40;
		bigIcon.y = FlxG.height * 0.3 - bigIcon.height / 2;
		
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
		    var targetY:Float = bigIcon.y + bigIcon.height + 40;
		    descText.y = targetY + 75;
		    if (moveTween != null) moveTween.cancel();
		    moveTween = FlxTween.tween(descText, {y: targetY}, 0.25, {ease: FlxEase.sineOut});
		}
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
