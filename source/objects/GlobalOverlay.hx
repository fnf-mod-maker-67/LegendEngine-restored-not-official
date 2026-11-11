package objects;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;

/**
 * 화면 위/아래에 오버레이 이미지를 덮어씌우는 전용 카메라.
 * 카메라를 자르는 대신, 맨 위에 그려지는 막대(스프라이트)로 덮어씌우는 방식이라
 * 배경/버튼 등 다른 요소들의 위치·크기에는 전혀 영향을 주지 않음.
 * MusicBeatState.initPsychCamera()에서 cropOverlay가 true인 스테이트에 자동으로 추가됨.
 */
class GlobalOverlay extends FlxCamera
{
	public static inline var BAR_SIZE:Float = 100;

	public function new()
	{
		super();
		bgColor.alpha = 0;

		var topBar = makeBar('overlay/topOverlay', 0);
		var bottomBar = makeBar('overlay/downOverlay', FlxG.height - BAR_SIZE);

		FlxG.state.add(topBar);
		FlxG.state.add(bottomBar);
	}

	function makeBar(imageKey:String, yPos:Float):FlxSprite
	{
		var bar = new FlxSprite(0, yPos);
		var graphic = Paths.image(imageKey);
		if (graphic != null)
		{
			bar.loadGraphic(graphic);
			bar.setGraphicSize(FlxG.width, Std.int(BAR_SIZE));
			bar.updateHitbox();
		}
		else
		{
			// 에셋이 없을 때를 위한 안전한 폴백 (makeGraphic, BitmapData 직접 생성 안 함)
			bar.makeGraphic(FlxG.width, Std.int(BAR_SIZE), FlxColor.BLACK);
		}
		bar.scrollFactor.set();
		bar.cameras = [this];
		return bar;
	}
}
