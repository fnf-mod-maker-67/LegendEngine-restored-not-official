package backend;
import backend.Language;
#if DISCORD_ALLOWED
import backend.Discord;
#end

class GameManager
{
	public static var curState:String = "";
	public static var prevState:String = "";
	static var stateList:Array<String> = ["AchievementsMenuState","CharacterSelectState","CreditsState","FreeplayState",
								   "GamatotoState",        "LoadingState",        "MainMenuState","PlayState","TitleState"];
	static var discordMap:Map<String, Array<String>> = [
	"AchievementsMenuState" => ["dc_mission", "In Mission Menu"],
	"CharacterSelectState" 	=> ["dc_charselect", "Selecting Character"],
	"CreditsState" 			=> ["dc_credits", "Seeing Credits"],
	"FreeplayState" 		=> ["dc_freeplay", "In Freeplay Menu"],
	"GamatotoState" 		=> ["dc_gamatoto", "Challenging in Gamatoto"],
	"LoadingState" 			=> ["dc_loading", "Loading.."],
	"MainMenuState" 		=> ["dc_mainmenu", "In Main Menu"],
	"TitleState" 			=> ["dc_title", "Start of FNF BC : LB"]
];
	public static function enterState(name:String)
	{
		prevState = curState;
		curState = name;
		#if DISCORD_ALLOWED
			var discord = discordMap.get(name);
			if (discord != null)
				DiscordClient.changePresence(Language.getPhrase(discord[0], discord[1]), null);
		#end		
	}
}
