package substates;

import backend.WeekData;
import backend.Song;
import backend.StageData;
import backend.Difficulty;
import backend.Paths;
import backend.ClientPrefs;
import backend.EnergySystem;


import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.graphics.FlxGraphic;

import objects.MenuItem;

import states.PlayState;
import states.LoadingState;
import states.FreeplayState;
import states.MainMenuState;

class StoryMenuSubState extends MusicBeatSubstate
{
	public static var weekCompleted:Map<String, Bool> = new Map<String, Bool>();

	private static var lastDifficultyName:String = '';
	var curDifficulty:Int = 1;

	private static var curWeek:Int = 0;

	var grpWeekText:FlxTypedGroup<MenuItem>;
	var grpLocks:FlxTypedGroup<FlxSprite>;

	var difficultySelectors:FlxSpriteGroup;
	var sprDifficulty:FlxSprite;
	var leftArrow:FlxSprite;
	var rightArrow:FlxSprite;

	var loadedWeeks:Array<WeekData> = [];
	var weekInitialX:Array<Float> = [];

	var movedBack:Bool = false;
	var selectedWeek:Bool = false;
	var stopspamming:Bool = false;

	override function create() {
		super.create();
		
		this.cameras = [FlxG.camera];
		
		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.0;
		add(bg);

		var bottomUIY:Float = 560;
		PlayState.isStoryMode = true;
		WeekData.reloadWeekFiles(true);

		if(curWeek >= WeekData.weeksList.length) curWeek = 0;

		var ui_tex = Paths.getSparrowAtlas('campaign_menu_UI_assets');

		grpWeekText = new FlxTypedGroup<MenuItem>();
		add(grpWeekText);

		grpLocks = new FlxTypedGroup<FlxSprite>();
		add(grpLocks);
		
		var num:Int = 0;
		var itemTargetY:Float = 200;
		var targetX:Float = FlxG.width / 4; // 왼쪽 구역의 중심점

		for (i in 0...WeekData.weeksList.length) {
			var weekFile:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			var isLocked:Bool = weekIsLocked(WeekData.weeksList[i]);

			loadedWeeks.push(weekFile);
			if (!isLocked || !weekFile.hiddenUntilUnlocked)
			{
				var weekThing:MenuItem = new MenuItem(0, 0, WeekData.weeksList[i]);
				weekThing.ID = num;

				// [교정] 아이템의 x(왼쪽 위 끝)를 기준으로 한 정확한 센터링 공식
				weekThing.x = targetX - (weekThing.frameWidth / 2) + weekThing.offset.x;
				
				var desiredY:Float = itemTargetY + (120 * num);
				weekThing.y = desiredY - (weekThing.frameHeight / 2) + weekThing.offset.y;
				
				grpWeekText.add(weekThing);
				
				if (isLocked)
				{
					var lock:FlxSprite = new FlxSprite();
					lock.frames = ui_tex;
					lock.animation.addByPrefix('lock', 'lock');
					lock.animation.play('lock');
					
					// 자물쇠 위치도 교정된 위크 기준 우측 도킹
					lock.x = weekThing.x + weekThing.frameWidth - weekThing.offset.x + 10;
					lock.y = weekThing.y + (weekThing.frameHeight / 2) - weekThing.offset.y - (lock.height / 2);
					
					lock.antialiasing = ClientPrefs.data.antialiasing;
					lock.ID = i;
					grpLocks.add(lock);
				}
				num++;
			}
		}
		

		difficultySelectors = new FlxSpriteGroup();
		add(difficultySelectors);

		leftArrow = new FlxSprite(850, bottomUIY);
		leftArrow.antialiasing = ClientPrefs.data.antialiasing;
		leftArrow.frames = ui_tex;
		leftArrow.animation.addByPrefix('idle', "arrow left");
		leftArrow.animation.addByPrefix('press', "arrow push left");
		leftArrow.animation.play('idle');
		difficultySelectors.add(leftArrow);

		Difficulty.resetList();
		if(lastDifficultyName == '')
		{
			lastDifficultyName = Difficulty.getDefault();
		}
		curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(lastDifficultyName)));
		
		sprDifficulty = new FlxSprite(0, leftArrow.y);
		sprDifficulty.antialiasing = ClientPrefs.data.antialiasing;
		difficultySelectors.add(sprDifficulty);

		rightArrow = new FlxSprite(leftArrow.x + 376, leftArrow.y);
		rightArrow.antialiasing = ClientPrefs.data.antialiasing;
		rightArrow.frames = ui_tex;
		rightArrow.animation.addByPrefix('idle', 'arrow right');
		rightArrow.animation.addByPrefix('press', "arrow push right", 24, false);
		rightArrow.animation.play('idle');
		difficultySelectors.add(rightArrow);
		
		difficultySelectors.screenCenter(X);

		changeWeek();
		changeDifficulty();
	}

		// 메인메뉴가 비쳐 보이도록 뒷배경을 반투명하게 설정
		

	override function update(elapsed:Float)
	{
		if(WeekData.weeksList.length < 1)
		{
			if (controls.BACK && !movedBack && !selectedWeek)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				movedBack = true;
				close();
			}
			super.update(elapsed);
			return;
		}

		if (!movedBack && !selectedWeek)
		{
			if (controls.UI_LEFT_P)
			{
				changeDifficulty(-1);
				leftArrow.animation.play('press');
			}

			if (controls.UI_RIGHT_P)
			{
				changeDifficulty(1);
				rightArrow.animation.play('press');
			}

			if(FlxG.mouse.wheel != 0)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
				changeWeek(-FlxG.mouse.wheel);
				changeDifficulty();
			}

			if (controls.UI_UP_P) {
				changeWeek(-1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			if (controls.UI_DOWN_P) {
				changeWeek(1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			
			if (controls.UI_RIGHT){
				rightArrow.animation.play('press');
			}
			else if (controls.UI_LEFT){
				leftArrow.animation.play('press');
			}
			else {
				rightArrow.animation.play('idle');
				leftArrow.animation.play('idle');
			}
			
			if (controls.ACCEPT)
				selectWeek();
			}
			if (controls.BACK && !movedBack && !selectedWeek)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				movedBack = true;
	
	// 커스텀 트랜지션을 건너뛰고 MainMenuState를 완전히 처음부터 새로 시작합니다.
				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
				MusicBeatState.switchState(new MainMenuState());
			}

		super.update(elapsed);
		// 왼쪽 구역의 중심점 X 좌표
		var targetX:Float = FlxG.width / 4; 

		for (num => item in grpWeekText.members)
		{
			var desiredY:Float = 200 + (120 * num) - (50 * curWeek);
			
			// [교정] 매 프레임 애니메이션 오프셋 변화를 반영하여 왼쪽 위 끝(x, y)을 정확히 강제 고정
			item.x = targetX - (item.frameWidth / 2) + item.offset.x;
			item.y = desiredY - (item.frameHeight / 2) + item.offset.y;
		}

		for (num => lock in grpLocks.members)
		{
			var parentItem = grpWeekText.members[lock.ID];
			if (parentItem != null)
			{
				lock.x = parentItem.x + parentItem.frameWidth - parentItem.offset.x + 10;
				lock.y = parentItem.y + (parentItem.frameHeight / 2) - parentItem.offset.y - (lock.height / 2);
			}
		}
	}

	function selectWeek()
	{
		if (!weekIsLocked(loadedWeeks[curWeek].fileName))
		{
			var songArray:Array<String> = [];
			var leWeek:Array<Dynamic> = loadedWeeks[curWeek].songs;
			for (i in 0...leWeek.length) {
				songArray.push(leWeek[i][0]);
			}

			try {
				var rawJson:String = Paths.getTextFromFile('data/energyStory.json');
    			if (rawJson != null && rawJson.length > 0)
    			{
        			var energyData:Dynamic = haxe.Json.parse(rawJson);
        			var diffName:String = Difficulty.getString(curDifficulty, false).toLowerCase();
        			var keyName:String = loadedWeeks[curWeek].fileName + '-' + diffName;
        
        			var value:Dynamic = Reflect.field(energyData, keyName);
        			if (value != null) {
            			var cost:Int = Std.parseInt(Std.string(value));
            
            			if (EnergySystem.canSpend(cost)) {
                			PlayState.pendingEnergyCost = cost; // start10sec.lua에서 첫 곡 진입 10초 후 소비, 이후 곡은 0으로 리셋됨
            			}
            			else {
                			openSubState(new substates.ErrorSubstate("통솔력이 부족해서 게임을 못 해요!",
                    			function() MusicBeatState.switchState(new states.MainMenuState()),
                    			function() MusicBeatState.switchState(new states.MainMenuState())));
                			return;
            			}
        			}
    			}
				PlayState.storyPlaylist = songArray;
				PlayState.isStoryMode = true;
				selectedWeek = true;
	
				var diffic = Difficulty.getFilePath(curDifficulty);
				if(diffic == null) diffic = '';
	
				PlayState.storyDifficulty = curDifficulty;
	
				Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + diffic, PlayState.storyPlaylist[0].toLowerCase());
				PlayState.campaignScore = 0;
				PlayState.campaignMisses = 0;
			}
			catch(e:Dynamic)
			{
				openSubState(new substates.ErrorSubstate("에러! : %e",
					function() MusicBeatState.switchState(new states.MainMenuState()),
					function() MusicBeatState.switchState(new states.MainMenuState())));
				return;
			}
			
			if (stopspamming == false)
			{
				FlxG.sound.play(Paths.sound('confirmMenu'));
				grpWeekText.members[curWeek].isFlashing = true;
				stopspamming = true;
			}

			var directory = StageData.forceNextDirectory;
			LoadingState.loadNextDirectory();
			StageData.forceNextDirectory = directory;

			@:privateAccess
			if(PlayState._lastLoadedModDirectory != Mods.currentModDirectory)
			{
				trace('CHANGED MOD DIRECTORY, RELOADING STUFF');
				Paths.freeGraphicsFromMemory();
			}
			LoadingState.prepareToSong();
			new FlxTimer().start(1, function(tmr:FlxTimer)
			{
				#if !SHOW_LOADING_SCREEN FlxG.sound.music.stop(); #end
				LoadingState.loadAndSwitchState(new PlayState(), true);
				FreeplayState.destroyFreeplayVocals();
			});
			
			#if (MODS_ALLOWED && DISCORD_ALLOWED)
			backend.DiscordClient.loadModRPC();
			#end
		}
		else FlxG.sound.play(Paths.sound('cancelMenu'));
	}

	function changeDifficulty(change:Int = 0):Void
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = Difficulty.list.length-1;
		if (curDifficulty >= Difficulty.list.length)
			curDifficulty = 0;

		WeekData.setDirectoryFromWeek(loadedWeeks[curWeek]);

		var diff:String = Difficulty.getString(curDifficulty, false);
		var newImage:FlxGraphic = Paths.image('menudifficulties/' + Paths.formatToSongPath(diff));

		if(sprDifficulty.graphic != newImage)
		{
			sprDifficulty.loadGraphic(newImage);
			sprDifficulty.x = leftArrow.x + 60;
			sprDifficulty.x += (308 - sprDifficulty.width) / 3;
			sprDifficulty.alpha = 1;
			sprDifficulty.y = leftArrow.y - sprDifficulty.height + 50;

			FlxTween.cancelTweensOf(sprDifficulty);
			FlxTween.tween(sprDifficulty, {y: sprDifficulty.y + 30, alpha: 1}, 0.07);
		}
		lastDifficultyName = diff;
	}

	function changeWeek(change:Int = 0):Void
	{
		curWeek += change;

		if (curWeek >= loadedWeeks.length)
			curWeek = 0;
		if (curWeek < 0)
			curWeek = loadedWeeks.length - 1;

		var leWeek:WeekData = loadedWeeks[curWeek];
		WeekData.setDirectoryFromWeek(leWeek);

		var unlocked:Bool = !weekIsLocked(leWeek.fileName);
		for (num => item in grpWeekText.members)
		{
			item.alpha = 0.6;
			if (num - curWeek == 0 && unlocked)
				item.alpha = 1;
		}

		PlayState.storyWeek = curWeek;

		Difficulty.loadFromWeek();
		difficultySelectors.visible = unlocked;

		if(Difficulty.list.contains(Difficulty.getDefault()))
			curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(Difficulty.getDefault())));
		else
			curDifficulty = 0;

		var newPos:Int = Difficulty.list.indexOf(lastDifficultyName);
		if(newPos > -1)
		{
			curDifficulty = newPos;
		}
		changeDifficulty(0);
	}

	function weekIsLocked(name:String):Bool {
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!weekCompleted.exists(leWeek.weekBefore) || !weekCompleted.get(leWeek.weekBefore)));
	}
}
