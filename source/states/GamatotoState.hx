package states;

import backend.Gamatoto;
import backend.Clock;
import backend.Song;
import backend.Language;
import backend.Conductor;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import objects.Window;
import openfl.utils.AssetType;
import flixel.text.FlxText.FlxTextBorderStyle;

/**
 * 가마토토 챌린지 화면.
 * 지역(좌우)을 고르고 난이도(상하)를 골라 엔터로 챌린지 곡을 시작한다.
 * 곡 이름 규칙: data/<지역폴더>/<지역폴더>-<난이도>.json (예: plains/plains-easy)
 * 쿨타임은 지역 x 난이도 각각, 곡을 시작할 때 걸린다.
 * 가마토토 관련 이미지는 전부 images/gamatoto/ 안에 위치 (없으면 자동으로 대체 그래픽 사용).
 * 언락: Gamatoto.unlockedNames에 이름 저장됨. Lua에서 unlockGamatoto(name) 함수로 풀어줌.
 */
class GamatotoState extends MusicBeatState
{
	// 화면에 보이는 지역 이름 / 차트 폴더명 (같은 순서)
	var adventureNames:Array<String> = ["평화 초원", "쿵후 왕국", "사바의 사막"];
	var chartFolders:Array<String> = ["plains", "kh_kingdom", "savadesert"];

	// 난이도: 차트 접미사 / 번역 키 / 기본 표시 텍스트 / 쿨타임(초)
	var diffIds:Array<String> = ["easy", "normal", "hard"];
	var diffDefaults:Array<String> = ["Easy", "Normal", "Hard"];
	var cooldowns:Array<Float> = [3600, 3600 * 3, 3600 * 6]; // 1h, 3h, 6h (난이도별로 바꿔도 됨)

	// 배경 이미지 없을 때 쓸 진한 초록색 (안 쨍하게)
	static inline var FALLBACK_BG_COLOR:FlxColor = 0xFF234433;

	var curAdIndex:Int = 0;
	var curDiff:Int = 0;

	var catSprite:FlxSprite;
	var curWindow:Window;
	var windowTexts:Array<FlxText> = [];
	var windowTitle:FlxText; // 창 위쪽에 모험 이름 표시 (창 이미지는 통일해서 씀)

	// idle: 창 닫힌 상태, carousel: 지역/난이도 선택중
	var uiState:String = "idle";


	override function create()
	{
		cropOverlay = false; // 가마토토 화면은 오버레이로 안 자름

		// 예전에 플레이한 곡의 bpmChangeMap이 static이라 그대로 남아있어서
		// 메인메뉴 곡 시간이랑 안 맞는 엉뚱한 stepCrochet이 나옴 -> 여기서 초기화
		Conductor.bpm = 120;

		Gamatoto.init();

		// 첫 실행이면 첫 모험만 언락
		if (Gamatoto.unlockedNames.length == 0)
			Gamatoto.unlock(adventureNames[0]);

		FlxG.mouse.visible = true;

		var bg:FlxSprite = new FlxSprite();
		if (Paths.fileExists('images/gamatoto/bg.png', IMAGE))
		{
			bg.loadGraphic(Paths.image('gamatoto/bg'));
			bg.setGraphicSize(FlxG.width, FlxG.height);
			bg.updateHitbox();
		}
		else
		{
			bg.makeGraphic(FlxG.width, FlxG.height, FALLBACK_BG_COLOR);
		}
		bg.scrollFactor.set();
		add(bg);

		catSprite = new FlxSprite();
		if (Paths.fileExists('images/gamatoto/cat.png', IMAGE))
		{
			catSprite.frames = Paths.getSparrowAtlas('gamatoto/cat');
			catSprite.animation.addByPrefix('idle', 'idle', 12, false);
			catSprite.animation.play('idle');
			catSprite.antialiasing = ClientPrefs.data.antialiasing;
		}
		else
		{
			catSprite.makeGraphic(150, 150, FlxColor.BLACK);
		}
		catSprite.screenCenter();
		add(catSprite);

		super.create();
	}

	// FlxG.mouse.overlaps(obj)는 카메라 쪼가리에서 널참조 나길래
	// FlxPointer 안 타는 좌표 직접비교로 완전히 회피
	function mouseOverlaps(obj:FlxSprite):Bool
	{
		if (obj == null) return false;
		return FlxG.mouse.x >= obj.x && FlxG.mouse.x <= obj.x + obj.width
			&& FlxG.mouse.y >= obj.y && FlxG.mouse.y <= obj.y + obj.height;
	}

	override function beatHit()
	{
		super.beatHit();
		catSprite.animation.play('idle', true);
	}

	function openWindow()
	{
		uiState = "carousel";
		openAdventureWindow();
	}

	// 창 이미지는 gamatoto/window 하나로 통일. 이름은 위쪽에 텍스트로 표시
	function openAdventureWindow()
	{
		closeWindow(false);

		var name:String = adventureNames[curAdIndex];
		var locked:Bool = !Gamatoto.isUnlocked(name);

		curWindow = new Window('gamatoto/window', 0, true, true);
		add(curWindow);

		windowTitle = new FlxText(0, 20, 300, name, 28);
		windowTitle.setFormat(Paths.font("vcr.ttf"), 28, FlxColor.WHITE, CENTER);
		windowTitle.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 2, 1);
		curWindow.addItemAt(0, 10, windowTitle);
		windowTitle.antialiasing = ClientPrefs.data.antialiasing;

		if (locked)
		{
			var lockedText:FlxText = new FlxText(0, 100, 300, "아직 잠겨있음", 24);
			lockedText.antialiasing = ClientPrefs.data.antialiasing;
			lockedText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.GRAY, CENTER);
			lockedText.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 2, 1);
			curWindow.addItemAt(0, 100, lockedText);
			windowTexts.push(lockedText);
		}
		else
		{
			for (i in 0...diffIds.length)
			{
				var t:FlxText = new FlxText(0, 0, 260, "", 24);
				t.antialiasing = ClientPrefs.data.antialiasing;
				t.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER);
				t.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 2, 1);
				curWindow.addItemAt(20, 60 + i * 50, t);
				windowTexts.push(t);
			}
			refreshDiffTexts();
		}
	}

	// 난이도 이름(번역) + 쿨타임 중이면 남은 시간 표시
	function refreshDiffTexts()
	{
		var region:String = chartFolders[curAdIndex];
		for (i in 0...windowTexts.length)
		{
			if (i >= diffIds.length) break;
			var label:String = Language.getPhrase('gamatoto_' + diffIds[i], diffDefaults[i]);
			var left:Float = Gamatoto.getCooldownLeft(region, i);
			if (left > 0)
				label += "  (" + formatTime(left) + ")";
			windowTexts[i].text = label;
			windowTexts[i].alpha = (i == curDiff) ? 1 : 0.6;
			if (left > 0) windowTexts[i].color = FlxColor.GRAY;
			else windowTexts[i].color = FlxColor.WHITE;
		}
	}

	function formatTime(sec:Float):String
	{
		var total:Int = Std.int(Math.ceil(sec));
		var h:Int = Std.int(total / 3600);
		var m:Int = Std.int((total % 3600) / 60);
		var sc:Int = total % 60;
		if (h > 0) return h + "h " + m + "m";
		if (m > 0) return m + "m " + sc + "s";
		return sc + "s";
	}

	function closeWindow(fullClose:Bool = true)
	{
		if (curWindow != null)
		{
			remove(curWindow);
			curWindow.destroy();
			curWindow = null;
		}
		windowTitle = null;
		windowTexts = [];
		if (fullClose) uiState = "idle";
	}

	function startSelectedAdventure()
	{
		var name:String = adventureNames[curAdIndex];
		if (!Gamatoto.isUnlocked(name)) return; // 잠긴 지역은 시작 불가

		var folder:String = chartFolders[curAdIndex];
		if (!Gamatoto.canChallenge(folder, curDiff))
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			return; // 쿨타임 중
		}

		var chartName:String = folder + "-" + diffIds[curDiff]; // 예: plains-easy
		try
		{
			Song.loadFromJson(chartName, folder);
		}
		catch (e:haxe.Exception)
		{
			trace('가마토토 차트 로드 실패: ' + chartName + ' / ' + e.message);
			FlxG.sound.play(Paths.sound('cancelMenu'));
			openSubState(new substates.ErrorSubstate(
				Language.getPhrase("gamatoto_no_chart", "차트가 없어요!\n") + chartName));
			return;
		}

		FlxG.sound.play(Paths.sound('confirmMenu'));
		Gamatoto.startCooldown(folder, curDiff, cooldowns[curDiff]); // 곡 시작할 때 쿨타임 시작
		Gamatoto.inChallenge = true;

		PlayState.isStoryMode = false;
		PlayState.storyDifficulty = curDiff;

		LoadingState.prepareToSong();
		LoadingState.loadAndSwitchState(new PlayState());
		FlxG.sound.music.stop();
	}

	override function update(elapsed:Float)
	{
		// 메인메뉴 음악(freakyMenu)이 계속 흐르는 중이라 그거 기준으로 Conductor 갱신
		// (PlayState 밖에서는 Conductor.songPosition이 자동으로 안 흐름)
		if (FlxG.sound.music != null && FlxG.sound.music.playing)
			Conductor.songPosition = FlxG.sound.music.time;

		super.update(elapsed);

		switch (uiState)
		{
			case "idle":
				var clickedEntry:Bool = FlxG.mouse.justPressed
					&& (mouseOverlaps(catSprite));
				if (controls.ACCEPT || clickedEntry)
				{
					FlxG.sound.play(Paths.sound('confirmMenu'));
					openWindow();
				}
				else if (controls.BACK)
				{
					FlxG.sound.play(Paths.sound('cancelMenu'));
					MusicBeatState.switchState(new MainMenuState());
				}

			case "carousel":
				var unlocked:Bool = Gamatoto.isUnlocked(adventureNames[curAdIndex]);

				if (controls.UI_LEFT_P || controls.UI_RIGHT_P)
				{
					curAdIndex = FlxMath.wrap(curAdIndex + (controls.UI_LEFT_P ? -1 : 1), 0, adventureNames.length - 1);
					FlxG.sound.play(Paths.sound('scrollMenu'));
					openAdventureWindow();
				}
				else if (controls.UI_UP_P || controls.UI_DOWN_P)
				{
					if (unlocked)
					{
						curDiff = FlxMath.wrap(curDiff + (controls.UI_UP_P ? -1 : 1), 0, diffIds.length - 1);
						FlxG.sound.play(Paths.sound('scrollMenu'));
						refreshDiffTexts();
					}
				}
				else if (controls.ACCEPT)
				{
					startSelectedAdventure();
				}
				else if (controls.BACK)
				{
					FlxG.sound.play(Paths.sound('cancelMenu'));
					closeWindow();
				}
				else if (FlxG.mouse.justPressed && unlocked)
				{
					for (i in 0...windowTexts.length)
					{
						if (mouseOverlaps(windowTexts[i]))
						{
							curDiff = i;
							startSelectedAdventure();
							break;
						}
					}
				}

				// 쿨타임 남은 시간 실시간 갱신
				if (unlocked && curWindow != null) refreshDiffTexts();
		}
	}
}
