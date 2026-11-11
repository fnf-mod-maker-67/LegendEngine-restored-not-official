package backend;

/**
 * EasyFile을 감싼 간편 JSON 도구.
 * 파일 하나를 물고 있으면서 get/write로 값을 다루는 느낌.
 *
 * 사용 예:
 *   var j = new EasyJson("data/foo.json");
 *   var value = j.get("키");
 *   var first = value[0]; // value가 배열이면 그대로 인덱싱 가능
 *
 *   j.write(["다른키" => 123]); // 기존 내용 유지, 넘긴 키들만 추가/덮어쓰기
 */
class EasyJson
{
	var filename:String;
	var data:Map<String, Dynamic>;

	public function new(filename:String)
	{
		this.filename = filename;
		this.data = EasyFile.readJson(filename);
		if (this.data == null)
			this.data = new Map<String, Dynamic>();
	}

	/** 키로 값 가져오기. 없으면 null. */
	public function get(key:String):Dynamic
	{
		return data.get(key);
	}

	/** 키 존재 여부 */
	public function exists(key:String):Bool
	{
		return data.exists(key);
	}

	/** 메모리상의 데이터만 바로 수정 (파일 저장은 write()나 save() 호출해야 함) */
	public function set(key:String, value:Dynamic):Void
	{
		data.set(key, value);
	}

	/**
	 * newData의 키들만 기존 내용에 병합(추가/덮어쓰기)해서 파일에 저장.
	 * 파일 전체가 새로 바뀌는 게 아니라 넘긴 키들만 반영됨.
	 */
	public function write(newData:Map<String, Dynamic>):Void
	{
		for (key in newData.keys())
			data.set(key, newData.get(key));

		save();
	}

	/** 현재 메모리 상태 그대로 파일에 저장 */
	public function save():Void
	{
		EasyFile.writeJson(filename, data);
	}
}
