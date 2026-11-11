package states;

import flixel.FlxObject;
import flixel.util.FlxSort;
import objects.Bar;

#if ACHIEVEMENTS_ALLOWED
class AchievementsMenuState extends MusicBeatState
{
	public var curSelected:Int = 0;

	public var options:Array<Dynamic> = [];
	public var grpOptions:FlxSpriteGroup;
	public var nameText:FlxText;
	public var descText:FlxText;
	public var progressTxt:FlxText;
	public var progressBar:Bar;

	var camFollow:FlxObject;

	var MAX_PER_ROW:Int = 4;

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In the Nyanko Mission", null);
		#end

		// prepare achievement list
		for (achievement => data in Achievements.achievements)
		{
			var unlocked:Bool = Achievements.isUnlocked(achievement);
			if(data.hidden != true || unlocked)
				options.push(makeAchievement(achievement, data, unlocked, data.mod));
		}

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

		var menuBG:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuBGBlue'));
		menuBG.antialiasing = ClientPrefs.data.antialiasing;
		menuBG.setGraphicSize(FlxG.width,FlxG.height);
		menuBG.updateHitbox();
		menuBG.screenCenter();
		menuBG.scrollFactor.set();
		add(menuBG);

		grpOptions = new FlxSpriteGroup();
		grpOptions.scrollFactor.x = 0;

		options.sort(sortByID);
		for (option in options)
		{
			var optionGrp:FlxSpriteGroup = new FlxSpriteGroup();
			var hasAntialias:Bool = ClientPrefs.data.antialiasing;
			var graphic = null;
			if(option.unlocked)
			{
				#if MODS_ALLOWED Mods.currentModDirectory = option.mod; #end
				var image:String = 'achievements/' + option.name;
				if(Paths.fileExists('images/$image-pixel.png', IMAGE))
				{
					graphic = Paths.image('$image-pixel');
					hasAntialias = false;
				}
				else graphic = Paths.image(image);

				if(graphic == null) graphic = Paths.image('unknownMod');
			}
			else graphic = Paths.image('achievements/lockedachievement');

			var spr:FlxSprite = new FlxSprite(440, grpOptions.members.length * 180).loadGraphic(graphic);
			spr.scrollFactor.x = 0;
			spr.screenCenter(X);
			spr.x = spr.x - 180;
			spr.ID = options.indexOf(option);
			spr.antialiasing = hasAntialias;
			var name:FlxText = new FlxText(spr.x + spr.width + 20, spr.y + 50);
			var desc:FlxText = new FlxText(spr.x + spr.width + 20, spr.y + 70);
			name.text = option.displayName;
			desc.text = option.description;
			name.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE);
			desc.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE);
			optionGrp.add(spr);
			optionGrp.add(name);
			optionGrp.add(desc);
			
			grpOptions.add(optionGrp);
		}
		#if MODS_ALLOWED Mods.loadTopMod(); #end

		var box:FlxSprite = new FlxSprite(0, 0).makeGraphic(1, 1, FlxColor.BLACK);
		box.scale.set(grpOptions.width + 60, grpOptions.height + 60);
		box.updateHitbox();
		box.alpha = 0.6;
		box.scrollFactor.set();
		box.screenCenter(X);
		add(box);
		add(grpOptions);

		progressBar = new Bar(0, -200);
		progressBar.screenCenter(X);
		progressBar.scrollFactor.set();
		progressBar.enabled = false;
		
		progressTxt = new FlxText();

		add(progressBar);
		add(progressTxt);
		
		_changeSelection();
		super.create();
		
		FlxG.camera.follow(camFollow, null, 0.15);
		FlxG.camera.scroll.y = -FlxG.height;
	}

	function makeAchievement(achievement:String, data:Achievement, unlocked:Bool, mod:String = null)
	{
		return {
			name: achievement,
			displayName: unlocked ? Language.getPhrase('achievement_$achievement', data.name) : '???',
			description: Language.getPhrase('description_$achievement', data.description),
			curProgress: data.maxScore > 0 ? Achievements.getScore(achievement) : 0,
			maxProgress: data.maxScore > 0 ? data.maxScore : 0,
			decProgress: data.maxScore > 0 ? data.maxDecimals : 0,
			unlocked: unlocked,
			ID: data.ID,
			mod: mod
		};
	}

	public static function sortByID(Obj1:Dynamic, Obj2:Dynamic):Int
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.ID, Obj2.ID);

	var goingBack:Bool = false;
	override function update(elapsed:Float) {
    	if(!goingBack && options.length > 1)
    	{
        	var add:Int = 0;
        	if (controls.UI_UP_P) add = -1;
        	else if (controls.UI_DOWN_P) add = 1;

        	if(add != 0)
        	{
            	curSelected = FlxMath.wrap(curSelected + add, 0, options.length - 1);
            	_changeSelection();
        	}

        	if(controls.RESET && (options[curSelected].unlocked || options[curSelected].curProgress > 0))
        	{
            	openSubState(new ResetAchievementSubstate());
        	}
    	}

    	if (controls.BACK) {
        	FlxG.sound.play(Paths.sound('cancelMenu'));
        	MusicBeatState.switchState(new MainMenuState());
        	goingBack = true;
    	}
    	super.update(elapsed);
	}

	public var barTween:FlxTween = null;
	function _changeSelection()
	{
    	FlxG.sound.play(Paths.sound('scrollMenu'));
    	var hasProgress = options[curSelected].maxProgress > 0;
    	progressTxt.visible = progressBar.visible = hasProgress;

    	if(barTween != null) barTween.cancel();

    	if(hasProgress)
    	{
        	var val1:Float = options[curSelected].curProgress;
        	var val2:Float = options[curSelected].maxProgress;
	        progressTxt.text = CoolUtil.floorDecimal(val1, options[curSelected].decProgress) + ' / ' + CoolUtil.floorDecimal(val2, options[curSelected].decProgress);

        	barTween = FlxTween.tween(progressBar, {percent: (val1 / val2) * 100}, 0.5, {ease: FlxEase.quadOut,
            	onComplete: function(twn:FlxTween) progressBar.updateBar(),
            	onUpdate: function(twn:FlxTween) progressBar.updateBar()
        	});
    	}
    	else progressBar.percent = 0;

    	var optionGrp:FlxSpriteGroup = cast grpOptions.members[curSelected];
		var spr:FlxSprite = cast optionGrp.members[0];
		camFollow.setPosition(0, spr.getGraphicMidpoint().y);

    	for(i in 0...grpOptions.members.length)
        	grpOptions.members[i].alpha = (i == curSelected) ? 1 : 0.6;
	}
}

class ResetAchievementSubstate extends MusicBeatSubstate
{
	var onYes:Bool = false;
	var yesText:Alphabet;
	var noText:Alphabet;

	public function new()
	{
		super();

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);
		FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});

		var text:Alphabet = new Alphabet(0, 180, Language.getPhrase('reset_achievement', 'Reset Achievement:'), true);
		text.screenCenter(X);
		text.scrollFactor.set();
		add(text);
		
		var state:AchievementsMenuState = cast FlxG.state;
		var text:FlxText = new FlxText(50, text.y + 90, FlxG.width - 100, state.options[state.curSelected].displayName, 40);
		text.setFormat(Paths.font("vcr.ttf"), 40, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		text.scrollFactor.set();
		text.borderSize = 2;
		add(text);
		
		yesText = new Alphabet(0, text.y + 120, Language.getPhrase('Yes'), true);
		yesText.screenCenter(X);
		yesText.x -= 200;
		yesText.scrollFactor.set();
		for(letter in yesText.letters) letter.color = FlxColor.RED;
		add(yesText);
		noText = new Alphabet(0, text.y + 120, Language.getPhrase('No'), true);
		noText.screenCenter(X);
		noText.x += 200;
		noText.scrollFactor.set();
		add(noText);
		updateOptions();
	}

	override function update(elapsed:Float)
	{
		if(controls.BACK)
		{
			close();
			FlxG.sound.play(Paths.sound('cancelMenu'));
			return;
		}

		super.update(elapsed);

		if(controls.UI_UP_P || controls.UI_DOWN_P) {
			onYes = !onYes;
			updateOptions();
		}

		if(controls.ACCEPT)
		{
			if(onYes)
			{
				var state:AchievementsMenuState = cast FlxG.state;
				var option:Dynamic = state.options[state.curSelected];

				Achievements.variables.remove(option.name);
				Achievements.achievementsUnlocked.remove(option.name);
				option.unlocked = false;
				option.curProgress = 0;
				option.name = '???';
				if(option.maxProgress > 0) state.progressTxt.text = '0 / ' + option.maxProgress;
				
				var optionGrp:FlxSpriteGroup = cast state.grpOptions.members[state.curSelected];
				var spr:FlxSprite = cast optionGrp.members[0];
				spr.loadGraphic(Paths.image('achievements/lockedachievement'));
				spr.antialiasing = ClientPrefs.data.antialiasing;

				if(state.progressBar.visible)
				{
					if(state.barTween != null) state.barTween.cancel();
					state.barTween = FlxTween.tween(state.progressBar, {percent: 0}, 0.5, {ease: FlxEase.quadOut,
						onComplete: function(twn:FlxTween) state.progressBar.updateBar(),
						onUpdate: function(twn:FlxTween) state.progressBar.updateBar()
					});
				}
				Achievements.save();
				FlxG.save.flush();

				FlxG.sound.play(Paths.sound('cancelMenu'));
			}
			close();
			return;
		}
	}

	function updateOptions() {
		var scales:Array<Float> = [0.75, 1];
		var alphas:Array<Float> = [0.6, 1.25];
		var confirmInt:Int = onYes ? 1 : 0;

		yesText.alpha = alphas[confirmInt];
		yesText.scale.set(scales[confirmInt], scales[confirmInt]);
		noText.alpha = alphas[1 - confirmInt];
		noText.scale.set(scales[1 - confirmInt], scales[1 - confirmInt]);
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}
}
#end
