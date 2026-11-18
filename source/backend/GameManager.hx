class GameManager
{
	public static var curState:String = "";
	public static var prevState:String = "";

	public static function enterState(name:String)
	{
		prevState = curState;
		curState = name;
	}
}
