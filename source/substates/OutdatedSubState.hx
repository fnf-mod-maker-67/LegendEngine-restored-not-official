package substates;

import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

import states.MainMenuState;
import states.TitleState;

class OutdatedSubState extends MusicBeatSubstate
{
	// 최신 버전 (온라인 release.txt 첫 줄). 응답이 오기 전에는 현재 버전과 같게 둔다.
	public static var updateVersion:String = states.MainMenuState.psychEngineVersion;
	public static var checked:Bool = false;      // 온라인 응답이 도착했는가
	public static var checkStarted:Bool = false; // 요청을 이미 보냈는가
	var leftState:Bool = false;

	var bg:FlxSprite;
	var warnText:FlxText;

	override function create()
	{
		super.create();

		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.scrollFactor.set();
		bg.alpha = 0.0;
		add(bg);

		warnText = new FlxText(0, 0, FlxG.width,
			Language.getPhrase('outdated_title', 'A new version is out!') + '\n(' + Language.getPhrase('outdated_now', 'Current') + ': ${MainMenuState.psychEngineVersion}  >  ' + Language.getPhrase('outdated_latest', 'Latest') + ': ${updateVersion})\n\n'
			+ Language.getPhrase('outdated_enter', 'Enter: Open download page') + '\n'
			+ Language.getPhrase('outdated_esc', 'Esc: Continue anyway'),
			32);
		warnText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		warnText.scrollFactor.set();
		warnText.screenCenter(Y);
		warnText.alpha = 0.0;
		add(warnText);

		FlxTween.tween(bg, { alpha: 0.8 }, 0.6, { ease: FlxEase.sineIn });
		FlxTween.tween(warnText, { alpha: 1.0 }, 0.6, { ease: FlxEase.sineIn });
	}

	override function update(elapsed:Float)
	{
		if(!leftState) {
			if (controls.ACCEPT) {
				leftState = true;
				CoolUtil.browserLoad("https://github.com/fnf-mod-maker-67/fnf-battle-cats-legend-begins");
			}
			else if(controls.BACK) {
				leftState = true;
			}
			if(leftState)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				FlxTween.tween(bg, { alpha: 0.0 }, 0.9, { ease: FlxEase.sineOut });
				FlxTween.tween(warnText, {alpha: 0}, 1, {
					ease: FlxEase.sineOut,
					onComplete: function (twn:FlxTween) {
						FlxG.state.persistentUpdate = true;
						close();
					}
				});
			}
		}
		super.update(elapsed);
	}
}
