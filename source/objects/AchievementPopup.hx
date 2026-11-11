package objects;

#if ACHIEVEMENTS_ALLOWED
import openfl.events.Event;
import flash.display.Bitmap;
import openfl.Lib;

class AchievementPopup extends openfl.display.Sprite {
	public var onFinish:Void->Void = null;
	var lastScale:Float = 1;
	var bitmap:Bitmap;
	var imgWidth:Float = 0;
	var imgHeight:Float = 0;

	public function new(achieve:String, onFinish:Void->Void)
	{
		super();

		// 커스텀 이미지 로드 (파일명: mission_clear.png)
		var graphic = Paths.image('mission_clear', false);
		if(graphic == null) graphic = Paths.image('unknownMod', false);

		bitmap = new Bitmap(graphic.bitmap);
		bitmap.smoothing = ClientPrefs.data.antialiasing;
		addChild(bitmap);

		imgWidth = graphic.bitmap.width;
		imgHeight = graphic.bitmap.height;

		// 이벤트 리스너 등록
		FlxG.stage.addEventListener(Event.RESIZE, onResize);
		addEventListener(Event.ENTER_FRAME, update);

		FlxG.game.addChild(this);

		// 해상도 비율 및 위치 계산
		lastScale = (FlxG.stage.stageHeight / FlxG.height);
		
		// X축: 화면 가로 중앙 정렬
		this.x = ((FlxG.width - imgWidth) / 2) * lastScale;
		
		// Y축: 화면 상단 바깥쪽 영역에서 대기
		this.y = -imgHeight * lastScale;
		
		this.scaleX = lastScale;
		this.scaleY = lastScale;
		
		// 화면 상단 끝에서 머무를 Y 좌표 위치 (여백 10px)
		intendedY = 10; 
	}

	var lerpTime:Float = 0;
	var countedTime:Float = 0;
	var timePassed:Float = -1;
	public var intendedY:Float = 0;

	function update(e:Event)
	{
		if(timePassed < 0) 
		{
			timePassed = Lib.getTimer();
			return;
		}

		var time = Lib.getTimer();
		var elapsed:Float = (time - timePassed) / 1000;
		timePassed = time;

		if(elapsed >= 0.5) return;

		countedTime += elapsed;
		if(countedTime < 3)
		{
			lerpTime = Math.min(1, lerpTime + elapsed);
			// 이미지 높이에 맞춰 위에서 아래로 내려오는 애니메이션
			y = ((FlxEase.elasticOut(lerpTime) * (intendedY + imgHeight)) - imgHeight) * lastScale;
		}
		else
		{
			// 화면 위로 다시 올라가며 퇴장
			y -= FlxG.height * 2 * elapsed * lastScale;
			if(y <= -imgHeight * lastScale)
				destroy();
		}
	}

	private function onResize(e:Event)
	{
		var mult = (FlxG.stage.stageHeight / FlxG.height);
		scaleX = mult;
		scaleY = mult;

		// 해상도가 변경되어도 가로 중앙 유지
		x = ((FlxG.width - imgWidth) / 2) * mult;
		y = (mult / lastScale) * y;
		lastScale = mult;
	}

	public function destroy()
	{
		Achievements._popups.remove(this);

		if (FlxG.game.contains(this))
		{
			FlxG.game.removeChild(this);
		}
		FlxG.stage.removeEventListener(Event.RESIZE, onResize);
		removeEventListener(Event.ENTER_FRAME, update);
		
		if (bitmap != null) {
			removeChild(bitmap);
			bitmap = null;
		}
	}
}
#end
