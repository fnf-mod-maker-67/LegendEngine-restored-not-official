package objects;

import haxe.Json;
import openfl.utils.Assets;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.FlxG;

using StringTools;

enum Alignment
{
	LEFT;
	CENTERED;
	RIGHT;
}

class Alphabet extends FlxSpriteGroup
{
	public var text(default, set):String;

	public var bold:Bool = false;
	public var letters:Array<Dynamic> = []; // 외부 호환성을 위해 빈 배열 유지

	public var isMenuItem:Bool = false;
	public var targetY:Int = 0;
	public var changeX:Bool = true;
	public var changeY:Bool = true;

	public var alignment(default, set):Alignment = LEFT;
	public var scaleX(default, set):Float = 1;
	public var scaleY(default, set):Float = 1;
	public var rows:Int = 0;

	public var distancePerItem:FlxPoint = new FlxPoint(20, 120);
	public var startPosition:FlxPoint = new FlxPoint(0, 0);

	private var nativeText:FlxText = null;

	public function new(x:Float, y:Float, text:String = "", ?bold:Bool = true)
	{
		super(x, y);

		this.startPosition.x = x;
		this.startPosition.y = y;
		this.bold = bold;
		this.text = text;
	}

	// 외부에서 호출되는 그룹 전체 크기 제어 함수 구현
	public function setScale(newX:Float, newY:Null<Float> = null)
	{
		if(newY == null) newY = newX;
		scaleX = newX;
		scaleY = newY;
		scale.set(newX, newY);
	}

	// [컴파일 에러 해결] CreditsState 등에서 호출되는 정렬 함수 구현
	public function snapToPosition()
	{
		if (isMenuItem)
		{
			if(changeX)
				x = (targetY * distancePerItem.x) + startPosition.x;
			if(changeY)
				y = (targetY * 1.3 * distancePerItem.y) + startPosition.y;
		}
	}

	public function setAlignmentFromString(align:String)
	{
		switch(align.toLowerCase().trim())
		{
			case 'right':
				alignment = RIGHT;
			case 'center' | 'centered':
				alignment = CENTERED;
			default:
				alignment = LEFT;
		}
	}

	private function set_alignment(align:Alignment)
	{
		alignment = align;
		updateAlignment();
		return align;
	}

	private function updateAlignment()
	{
		if (nativeText == null) return;

		switch(alignment)
		{
			case CENTERED:
				nativeText.x = -nativeText.width / 2;
			case RIGHT:
				nativeText.x = -nativeText.width;
			default:
				nativeText.x = 0;
		}
	}

	private function set_text(newText:String)
	{
		newText = newText.replace('\\n', '\n');
		text = newText;
		
		if (nativeText != null) {
			remove(nativeText);
			nativeText.destroy();
			nativeText = null;
		}

		if (text.length == 0) return newText;

		nativeText = new FlxText(0, 0, 0, text);
		
		// shared/fonts/font.ttf 경로의 통합 폰트를 자동으로 적용합니다.
		var fontName:String = Paths.font("font.ttf");
		var fontSize:Int = bold ? 56 : 36;
		
		nativeText.setFormat(fontName, fontSize, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		nativeText.borderSize = bold ? 5 : 3;
		
		try {
			nativeText.antialiasing = ClientPrefs.data.antialiasing;
		} catch(e:Dynamic) {
			nativeText.antialiasing = true;
		}
		
		add(nativeText);
		updateAlignment();

		rows = text.split('\n').length;

		return newText;
	}

	private function set_scaleX(value:Float)
	{
		scaleX = value;
		scale.x = value;
		return value;
	}

	private function set_scaleY(value:Float)
	{
		scaleY = value;
		scale.y = value;
		return value;
	}

	override function update(elapsed:Float)
	{
		if (isMenuItem)
		{
			var lerpVal:Float = Math.exp(-elapsed * 9.6);
			if(changeX)
				x = FlxMath.lerp((targetY * distancePerItem.x) + startPosition.x, x, lerpVal);
			if(changeY)
				y = FlxMath.lerp((targetY * 1.3 * distancePerItem.y) + startPosition.y, y, lerpVal);
		}
		super.update(elapsed);
	}
}

// [컴파일 에러 해결] Language.hx 등 외부 파일들의 참조 파괴를 막기 위한 상속 구조 및 static 함수 더미 유지
class AlphaCharacter extends flixel.FlxSprite
{
	public static var allLetters:Map<String, Dynamic> = new Map<String, Dynamic>();
	
	public static function loadAlphabetData(request:String = 'alphabet')
	{
		// FlxText 시스템을 사용하므로 내부 데이터를 로드할 필요가 없어 더미로 비워둡니다.
	}

	public static function isTypeAlphabet(c:String):Bool
	{
		return true;
	}
}
