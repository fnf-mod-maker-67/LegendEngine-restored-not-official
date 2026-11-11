package substates;
import objects.Window;

class ErrorSubstate extends MusicBeatSubstate
{
	public var acceptCallback:Void->Void;
	public var backCallback:Void->Void;
	public var errorMsg:String;
	public var isFatal:Bool = false;

	public function new(error:String, accept:Void->Void = null, back:Void->Void = null, itFatal:Bool = false)
	{
		this.errorMsg = error;
		this.acceptCallback = accept;
		this.backCallback = back;
		this.isFatal = itFatal;
		super();
	}

	public var errorSine:Float = 0;
	public var errorText:FlxText;
	override function create()
	{
		var win = new Window("errorWin", 75, true, true);

		errorText = new FlxText(0, 0, FlxG.width - 300, errorMsg, 32);
		errorText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		if (!isFatal) {
			errorText.color = FlxColor.WHITE;
		}
		else {
			errorText.color = FlxColor.RED;
		}
		
		win.addItem("screenCenter", errorText);
		add(win);
		super.create();
	}

	override function update(elapsed:Float)
	{
		errorSine += 180 * elapsed;
		errorText.alpha = 1 - Math.sin((Math.PI * errorSine) / 180);
		if(controls.ACCEPT && acceptCallback != null)
			acceptCallback();
		else if(controls.ACCEPT && acceptCallback == null)
			close();
		else if(controls.BACK && backCallback != null)
			backCallback();
		else if(controls.BACK && backCallback == null)
			close();

		super.update(elapsed);
	}
}
