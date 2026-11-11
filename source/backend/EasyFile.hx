package backend;

import sys.io.File;
import sys.FileSystem;
import haxe.DynamicAccess;

/**
 * 파이썬 easyfile 라이브러리의 JSON 관련 함수만 포팅한 버전.
 * (allread/replacefile/listappend_file/listremove_file 등 텍스트 함수는 제외)
 *
 * readJson()이 Map<String, Dynamic>을 반환해서 Reflect.field() 없이
 * 파이썬 딕셔너리처럼 data['key'], data.exists('key'), data.keys() 로 접근 가능.
 * 중첩된 객체/배열도 재귀적으로 Map/Array로 변환됨.
 */
class EasyFile
{
	/**
	 * JSON 파일을 읽어서 Map(파이썬 딕셔너리 느낌)으로 반환한다.
	 * 파일이 없으면 null을 반환한다 (Python 원본은 raise였지만 Haxe에서는 null 처리).
	 *
	 * 사용 예:
	 *   var data = EasyFile.readJson('foo.json');
	 *   if (data != null && data.exists('name')) trace(data['name']);
	 *   for (key in data.keys()) trace(key + ' -> ' + data[key]);
	 */
	public static function readJson(filename:String):Map<String, Dynamic>
	{
		if (!FileSystem.exists(filename))
		{
			trace('EasyFile.readJson: 파일이 없습니다. No file found. ($filename)');
			return null;
		}

		var raw:String = File.getContent(filename).trim();
		if (raw == null || raw.length <= 0)
			return null;

		var parsed:Dynamic = tjson.TJSON.parse(raw);
		return cast toMap(parsed);
	}

	/**
	 * data(Map, 배열, 혹은 아무 구조체)를 JSON 문자열로 만들어 filename에 저장한다 (들여쓰기 4칸).
	 */
	public static function writeJson(filename:String, data:Dynamic):Void
	{
		File.saveContent(filename, haxe.Json.stringify(fromMap(data), null, '\t'));
	}

	// 파싱된 익명 객체/배열을 재귀적으로 Map/Array로 변환 (읽을 때)
	static function toMap(value:Dynamic):Dynamic
	{
		if (value == null)
			return null;

		if (Std.isOfType(value, Array))
		{
			var arr:Array<Dynamic> = cast value;
			return [for (v in arr) toMap(v)];
		}

		if (Reflect.isObject(value) && !(value is String))
		{
			var map = new Map<String, Dynamic>();
			for (field in Reflect.fields(value))
				map.set(field, toMap(Reflect.field(value, field)));
			return map;
		}

		return value; // 문자열/숫자/불 등 원시값
	}

	// Map/Array를 재귀적으로 익명 객체/배열로 되돌림 (쓸 때, Json.stringify가 이해하도록)
	static function fromMap(value:Dynamic):Dynamic
	{
		if (value == null)
			return null;

		if (Std.isOfType(value, Array))
		{
			var arr:Array<Dynamic> = cast value;
			return [for (v in arr) fromMap(v)];
		}

		if (Std.isOfType(value, haxe.ds.StringMap))
		{
			var map:Map<String, Dynamic> = cast value;
			var obj:DynamicAccess<Dynamic> = {};
			for (key in map.keys())
				obj[key] = fromMap(map.get(key));
			return obj;
		}

		return value;
	}
}
