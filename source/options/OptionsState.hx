package options;

import flixel.system.FlxSound;

class OptionsState extends MusicBeatState
{
	// 진짜 순수하게 데이터만 공유하는 전역 변수들
	public static var onPlayState:Bool = false;
	public static var curSelected:Int = 0;
	public static var menuMusic:FlxSound;
	public static var sharedModData:Map<String, Dynamic> = new Map();

	// 인스턴스로 작동하지 않도록 즉시 파괴 처리만 유지
	override function create()
	{
		destroy();
		super.create();
	}
}
