package states;

import flixel.FlxSubState;
import flixel.effects.FlxFlicker;
import lime.app.Application;

class FlashingState extends MusicBeatState
{
	public static var leftState:Bool = false;
	private static var step:Int = 0;

	var isYes:Bool = true;
	var texts:FlxTypedSpriteGroup<FlxText>;
	var bg:FlxSprite;
	var warnText:FlxText;

	// 질문 목록
	var questions:Array<String> = [
		"Hey, watch out!\n\nThis Mod contains some flashing lights!\nDo you wish to disable them?",
		"Are you korean? If it's right, press ENTER. else, press Esc.\n너 한국인이야? 맞으면 엔터, 아니면 Esc를 눌러줘!" // 두 번째 질문 내용
	];

	override function create()
	{
		super.create();
		step = 0;

		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(bg);

		texts = new FlxTypedSpriteGroup<FlxText>();
		texts.alpha = 0.0;
		add(texts);

		warnText = new FlxText(0, 0, FlxG.width, questions[0]);
		warnText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		warnText.screenCenter(Y);
		texts.add(warnText);

		final keys = ["Yes", "No"];
		for (i in 0...keys.length) {
			final button = new FlxText(0, 0, FlxG.width, keys[i]);
			button.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
			button.y = (warnText.y + warnText.height) + 24;
			button.x += (128 * i) - 80;
			texts.add(button);
		}

		FlxTween.tween(texts, {alpha: 1.0}, 0.5, {
			onComplete: (_) -> updateItems()
		});
	}

	override function update(elapsed:Float) {
		if(leftState) {
			super.update(elapsed);
			return;
		}
		var back:Bool = controls.BACK;
		if (controls.UI_LEFT_P || controls.UI_RIGHT_P) {
			FlxG.sound.play(Paths.sound("scrollMenu"), 0.7);
			isYes = !isYes;
			updateItems();
		}
		if (controls.ACCEPT || back) {
			// step 0: 플래시 설정
			if (step == 0) {
				if (!back) {
					ClientPrefs.data.flashing = !isYes;
					ClientPrefs.saveSettings();
				}
				step++;
				isYes = true;
				warnText.text = questions[step];
				warnText.screenCenter(Y);
				FlxG.sound.play(Paths.sound(back ? 'cancelMenu' : 'confirmMenu'));
				updateItems();
				return;
			}
			
			// step 1: 언어 설정 (ACCEPT 선택 시 isYes 기준, Esc(back) 누를 시 en-US 처리)
			if (step == 1) {
				if (!back) {
					ClientPrefs.data.language = isYes ? "ko-KR" : "en-US";
				} else {
					ClientPrefs.data.language = "en-US";
				}
				ClientPrefs.saveSettings();

				leftState = true;
				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
				FlxG.sound.play(Paths.sound(back ? 'cancelMenu' : 'confirmMenu'));
				
				final button = texts.members[isYes ? 1 : 2];
				FlxFlicker.flicker(button, 1, 0.1, false, true, function(flk:FlxFlicker) {
					new FlxTimer().start(0.5, function (tmr:FlxTimer) {
						FlxTween.tween(texts, {alpha: 0}, 0.2, {
							onComplete: (_) -> MusicBeatState.switchState(new TitleState())
						});
					});
				});
			}
		}
		super.update(elapsed);
	}

	function updateItems() {
		texts.members[1].alpha = isYes ? 1.0 : 0.6;
		texts.members[2].alpha = isYes ? 0.6 : 1.0;
	}
}
