package objects;
import backend.EasyJson;
class EnemyListCharacter extends FlxSprite {
	var charName:String;

	// 캐릭터를 넣을 상자 크기 (가로 80, 세로 60)
	static inline var BOX_W:Float = 80;
	static inline var BOX_H:Float = 60;
	public function new(characterName:String) {
		super();
		charName = characterName;
		var charJson = new EasyJson(Paths.getPath('characters/$charName.json', TEXT));
		// EasyFile.readJson은 중첩 객체/배열을 실제 Map<String,Dynamic>으로 변환함.
		// DynamicAccess는 Reflect.field 기반이라 Map 인스턴스에는 안 먹혀서(항상 null) fps 버그의 원인이었음.
		var animations:Array<Map<String, Dynamic>> = charJson.get('animations');
		var idleAnim:Map<String, Dynamic> = Lambda.find(animations, a -> a['anim'] == 'idle');
		if (idleAnim == null && animations.length > 0) idleAnim = animations[0];
		this.frames = Paths.getSparrowAtlas(charJson.get('image'));
		this.animation.addByPrefix("idle", "idle", idleAnim['fps'], false); // loop 끄기
		this.animation.play("idle");

		// --- 여기가 크기 맞추는 부분 ---
		// 캐릭터마다 원본 그림 크기(frameWidth, frameHeight)가 다 다름.
		// "가로를 80에 맞추려면 몇 배?" 랑 "세로를 60에 맞추려면 몇 배?"를 각각 구함.
		var scaleForWidth:Float = BOX_W / this.frameWidth;
		var scaleForHeight:Float = BOX_H / this.frameHeight;
		// 둘 중 더 작은 배수를 골라야 상자 밖으로 안 삐져나옴 (비율 유지됨)
		var finalScale:Float = Math.min(scaleForWidth, scaleForHeight);
		// 가로세로에 "같은 배수"를 곱해야 안 찌부러짐 (따로따로 하면 찌부됨)
		this.scale.set(finalScale, finalScale);
		this.updateHitbox();
	}
	public function beatHit():Void {
    	this.animation.play("idle", true); // force restart
	}
}
