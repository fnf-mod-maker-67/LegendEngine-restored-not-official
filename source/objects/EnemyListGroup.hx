package objects;

class EnemyListGroup extends FlxSpriteGroup {
	public function new(characterNames:Array<String>, spacing:Float = 90) {
		super();

		for (i in 0...characterNames.length) {
			var enemy = new EnemyListCharacter(characterNames[i]);
			enemy.x = i * spacing;
			add(enemy);
		}
	}
	public function beatHit():Void {
    	for (enemy in members) if (enemy != null) cast(enemy, EnemyListCharacter).beatHit();
	}


}
