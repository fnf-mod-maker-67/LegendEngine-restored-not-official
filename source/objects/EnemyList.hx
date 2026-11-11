package objects;

class EnemyList extends Window {
	var image:FlxSprite;
	var list:EnemyListGroup;
	public var closed:Bool = false;
	public function new(name:Array<String>) {
		super("enemyListWin", 20, true, false);
		list = new EnemyListGroup(name, 90);
		addItem("screenCenter", list);
	}
	override function update(elapsed:Float) {
		super.update(elapsed);
		if (FlxG.mouse.justPressed && FlxG.mouse.overlaps(this)) {
			close();
		}
	}
	public function close() {
    	closed = true;
    	destroyCam();
    	if (FlxG.state != null) FlxG.state.remove(this, true);
    	destroy();
	}
	public function beatHit():Void {
    	list.beatHit();
	}

}
