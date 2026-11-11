package backend;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import backend.Paths;

class CustomFadeTransition extends MusicBeatSubstate {
	public static var finishCallback:Void->Void;
	var isTransIn:Bool = false;
	var transBlack:FlxSprite;
	var leftDoor:FlxSprite;
	var rightDoor:FlxSprite;
	
	var duration:Float;
	var transCamera:FlxCamera;

	public function new(duration:Float, isTransIn:Bool)
	{
		this.duration = duration;
		this.isTransIn = isTransIn;
		super();
	}

	override function create()
	{
		transCamera = new FlxCamera();
		transCamera.bgColor = FlxColor.TRANSPARENT;
		FlxG.cameras.add(transCamera, false);
		cameras = [transCamera];

		var fullWidth:Int = Std.int(FlxG.width / Math.max(transCamera.zoom, 0.001));
		var fullHeight:Int = Std.int(FlxG.height / Math.max(transCamera.zoom, 0.001));
		var width:Int = Std.int(fullWidth / 2) + 4;

		leftDoor = new FlxSprite();
		leftDoor.loadGraphic(Paths.image('fade/leftDoor'));
		leftDoor.setGraphicSize(width, fullHeight);
		leftDoor.updateHitbox();
		leftDoor.scrollFactor.set();
		leftDoor.y = (fullHeight / 2) - (leftDoor.height / 2);
		add(leftDoor);

		rightDoor = new FlxSprite();
		rightDoor.loadGraphic(Paths.image('fade/rightDoor'));
		rightDoor.setGraphicSize(width, fullHeight);
		rightDoor.updateHitbox();
		rightDoor.scrollFactor.set();
		rightDoor.y = (fullHeight / 2) - (rightDoor.height / 2);
		add(rightDoor);

		if (isTransIn) {
			// 문이 열리는 연출 (새 스테이트 진입)
			leftDoor.x = fullWidth / 2 - leftDoor.width;
			rightDoor.x = fullWidth / 2;
			FlxTween.tween(leftDoor, {x: -leftDoor.width}, duration, {ease: FlxEase.quadInOut});
			FlxTween.tween(rightDoor, {x: fullWidth}, duration, {ease: FlxEase.quadInOut, onComplete: function(_) close()});
		}
		else {
			// 문이 닫히는 연출 (기존 스테이트 퇴장)
			leftDoor.x = -leftDoor.width;
			rightDoor.x = fullWidth;
			FlxTween.tween(leftDoor, {x: fullWidth / 2 - leftDoor.width}, duration, {ease: FlxEase.quadInOut});
			FlxTween.tween(rightDoor, {x: fullWidth / 2}, duration, {
				ease: FlxEase.quadInOut, 
				onComplete: function(_) {
					// [수정 핵심] 의도적인 close() 생략
					// 문을 화면에 완전히 닫아둔 채로 스테이트만 즉시 교체하여 깜빡임을 완벽히 차단합니다.
					if(finishCallback != null) {
						finishCallback();
						finishCallback = null;
					}
				}
			});
		}
		super.create();
	}

	override function close():Void
	{
		super.close();

		if(finishCallback != null)
		{
			finishCallback();
			finishCallback = null;
		}
	}

	override function destroy()
	{
		if (transCamera != null) {
			FlxG.cameras.remove(transCamera);
		}
		super.destroy();
	}
}
