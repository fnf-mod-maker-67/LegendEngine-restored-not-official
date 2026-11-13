package backend;

import flixel.util.FlxSave;

/**
 * 가마토토 챌린지 시스템.
 * 지역마다 곡 1개, 난이도 3개. 지역 x 난이도 각각 쿨타임이 따로 돈다.
 * 쿨타임은 곡을 "시작"할 때 걸리고, 현재 시각(Clock.now) 기준 절대 시각으로 저장한다.
 * 클리어 보상 / 클릭 보상은 각 곡 Lua의 onEndSong 등에서 모드측이 직접 처리한다.
 */
class Gamatoto
{
	// 언락된 지역 이름 목록. 기본값은 첫 지역만 (GamatotoState.create()에서 비어있으면 채움)
	public static var unlockedNames:Array<String> = [];

	// "지역|난이도번호" -> 쿨타임이 끝나는 시각(유닉스 초)
	public static var cooldownEnd:Map<String, Float> = new Map();

	// 지금 가마토토 챌린지 곡을 플레이 중인가 (곡이 끝나면 GamatotoState로 복귀)
	public static var inChallenge:Bool = false;

	static var sv:FlxSave;

	// 게임 켤 때 / GamatotoState 진입 시 호출
	public static function init():Void
	{
		load();
	}

	static function key(region:String, diff:Int):String
	{
		return region + '|' + diff;
	}

	public static function isUnlocked(name:String):Bool
	{
		return unlockedNames.indexOf(name) != -1;
	}

	// Lua에서 unlockGamatoto(name) 함수로 호출됨
	public static function unlock(name:String):Void
	{
		if (!isUnlocked(name))
		{
			unlockedNames.push(name);
			save();
		}
	}

	// 곡을 시작할 때 호출: seconds 만큼 쿨타임 시작
	public static function startCooldown(region:String, diff:Int, seconds:Float):Void
	{
		cooldownEnd.set(key(region, diff), Clock.now() + seconds);
		save();
	}

	// 남은 쿨타임(초). 0이면 도전 가능
	public static function getCooldownLeft(region:String, diff:Int):Float
	{
		var end:Null<Float> = cooldownEnd.get(key(region, diff));
		if (end == null) return 0;
		var left:Float = end - Clock.now();
		return left > 0 ? left : 0;
	}

	public static function canChallenge(region:String, diff:Int):Bool
	{
		return getCooldownLeft(region, diff) <= 0;
	}

	static function bindSave():Void
	{
		if (sv == null)
		{
			sv = new FlxSave();
			sv.bind('clock');
		}
	}

	static function save():Void
	{
		bindSave();
		sv.data.gamatotoUnlocked = unlockedNames.join(',');

		var parts:Array<String> = [];
		for (k in cooldownEnd.keys())
			parts.push(k + '=' + cooldownEnd.get(k));
		sv.data.gamatotoCooldowns = parts.join(';');

		sv.flush();
	}

	static function load():Void
	{
		bindSave();

		if (sv.data.gamatotoUnlocked != null && sv.data.gamatotoUnlocked != '')
			unlockedNames = sv.data.gamatotoUnlocked.split(',');

		cooldownEnd = new Map();
		if (sv.data.gamatotoCooldowns != null && sv.data.gamatotoCooldowns != '')
		{
			for (p in cast(sv.data.gamatotoCooldowns, String).split(';'))
			{
				var kv:Array<String> = p.split('=');
				if (kv.length == 2)
					cooldownEnd.set(kv[0], Std.parseFloat(kv[1]));
			}
		}
	}
}
