package states;

import flixel.FlxG;

class StoryMenuState extends MusicBeatState
{
	// 다른 엔진 파일들이 참조하는 해금 데이터를 유지합니다.
	public static var weekCompleted:Map<String, Bool> = new Map<String, Bool>();

	override function create()
	{
		// 플레이가 끝나거나 게임오버 등으로 이 스테이트로 오게 되면 바로 메인 메뉴로 보냅니다.
		MusicBeatState.switchState(new MainMenuState());
		super.create();
	}
}
