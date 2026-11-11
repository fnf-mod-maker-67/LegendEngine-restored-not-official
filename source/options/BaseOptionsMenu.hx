package options;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadInputID;

import objects.CheckboxThingie;
import options.Option;
import backend.InputFormatter;
import backend.Language;
import backend.ClientPrefs;

class BaseOptionsMenu extends MusicBeatSubstate
{
	private var curOption:Option = null;
	private var curSelected:Int = 0;
	private var optionsArray:Array<Option>;

	private var grpOptions:FlxTypedGroup<FlxText>;
	private var checkboxGroup:FlxTypedGroup<CheckboxThingie>;
	private var grpTexts:FlxTypedGroup<FlxText>;

	private var descBox:FlxSprite;
	private var descText:FlxText;

	public var title:String;
	public var rpcTitle:String;

	private static inline var OPTION_X:Float = 170;
	private static inline var START_Y:Float = 50;
	private static inline var TEXT_SPACING:Float = 80;
	
	// 체크박스 오프셋 및 위치 기준
	private static inline var CHECKBOX_OFFSET_X:Float = -42;
	private static inline var CHECKBOX_SIZE:Float = 108 * 0.6; // 64.8
	private static inline var VALUE_OFFSET_X:Float = 0;

	public function new()
	{
		super();

		if(title == null) title = 'Options';
		if(rpcTitle == null) rpcTitle = 'Options Menu';
		
		#if DISCORD_ALLOWED
		DiscordClient.changePresence(rpcTitle, null);
		#end

		var targetCam = OptionsSubState.instance != null ? OptionsSubState.instance.optionCam : null;

		grpOptions = new FlxTypedGroup<FlxText>();
		if(targetCam != null) grpOptions.cameras = [targetCam];
		add(grpOptions);

		grpTexts = new FlxTypedGroup<FlxText>();
		if(targetCam != null) grpTexts.cameras = [targetCam];
		add(grpTexts);

		checkboxGroup = new FlxTypedGroup<CheckboxThingie>();
		if(targetCam != null) checkboxGroup.cameras = [targetCam];
		add(checkboxGroup);

		descBox = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		descBox.alpha = 0.6;
		if(targetCam != null) descBox.cameras = [targetCam];

		descText = new FlxText(40, 560, 720, "", 20);
		descText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		descText.scrollFactor.set();
		descText.borderSize = 2.0;
		if(targetCam != null) descText.cameras = [targetCam];

		var maxTextWidth:Float = (targetCam != null ? targetCam.width : FlxG.width) - OPTION_X - 20;

		for (i in 0...optionsArray.length)
		{
			var optionText:FlxText = new FlxText(OPTION_X, START_Y + (i * TEXT_SPACING), maxTextWidth, optionsArray[i].name, 30);
			optionText.setFormat(Paths.font("vcr.ttf"), 30, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			optionText.wordWrap = true;
			optionText.autoSize = false;
			// 텍스트가 2줄 이상이면 글자 크기를 줄여서 한 줄에 맞춤
			if(optionText.textField.numLines > 1)
			{
				var shrinkSize:Int = 30;
				while(optionText.textField.numLines > 1 && shrinkSize > 16)
				{
					shrinkSize -= 2;
					optionText.setFormat(Paths.font("vcr.ttf"), shrinkSize, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				}
			}
			optionText.borderSize = 2;
			optionText.scrollFactor.set();
			optionText.ID = i;
			grpOptions.add(optionText);

			if(optionsArray[i].type == BOOL)
			{
				var checkbox:CheckboxThingie = new CheckboxThingie(0, 0, Std.string(optionsArray[i].getValue()) == 'true');
				checkbox.scale.set(0.6, 0.6);
				checkbox.updateHitbox();
				
				checkbox.sprTracker = optionText;
				checkbox.offsetX = CHECKBOX_OFFSET_X;
				checkbox.offsetY = (CHECKBOX_SIZE - optionText.height) / 2;
				checkbox.copyAlpha = true;
				checkbox.ID = i;
				checkboxGroup.add(checkbox);
			}
			else
			{
				var valueText:FlxText = new FlxText(0, 0, 0, '' + optionsArray[i].getValue(), 24);
				valueText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				valueText.borderSize = 2;
				valueText.scrollFactor.set();
				valueText.ID = i;
				
				grpTexts.add(valueText);
				optionsArray[i].child = valueText;
			}
			
			updateTextFrom(optionsArray[i]);
		}

		changeSelection();
		reloadCheckboxes();
	}

	public function addOption(option:Option) {
		if(optionsArray == null || optionsArray.length < 1) optionsArray = [];
		optionsArray.push(option);
		return option;
	}

	var nextAccept:Int = 5;
	var holdTime:Float = 0;
	var holdValue:Float = 0;

	var bindingKey:Bool = false;
	var holdingEsc:Float = 0;
	var bindingBlack:FlxSprite;
	var bindingText:FlxText;
	var bindingText2:FlxText;
	
	override function update(elapsed:Float)
	{
		var lerpVal:Float = FlxMath.bound(elapsed * 9.6, 0, 1);

		var scrollOffset:Float = 0;
		if (curSelected > 3) {
			scrollOffset = (curSelected - 3) * TEXT_SPACING;
		}

		for (i in 0...grpOptions.members.length)
		{
			var item = grpOptions.members[i];
			var targetYPos:Float = START_Y + (i * TEXT_SPACING) - scrollOffset;
			item.y = FlxMath.lerp(item.y, targetYPos, lerpVal);
			item.x = OPTION_X;
		}

// FlxText(값 텍스트) 위치 매 프레임 업데이트
		for (text in grpTexts)
		{
			if (text.ID >= 0 && text.ID < grpOptions.members.length)
			{
				var option = optionsArray[text.ID];
				var optionText = grpOptions.members[text.ID];
				
				if (option != null && optionText != null && option.type != KEYBIND)
				{
					// 여백을 20에서 60으로 늘려 더 왼쪽으로 배치
					text.x = optionText.x - text.width - 60;
					text.y = optionText.y + (optionText.height - text.height) / 2;
				}
			}
		}

		for (checkbox in checkboxGroup)
		{
			checkbox.offset.set(0, 0);
			checkbox.updateHitbox();
		}

		super.update(elapsed);

		if(bindingKey)
		{
			bindingKeyUpdate(elapsed);
			return;
		}

		if (controls.UI_UP_P) changeSelection(-1);
		if (controls.UI_DOWN_P) changeSelection(1);

		if (controls.BACK) {
			close();
			FlxG.sound.play(Paths.sound('cancelMenu'));
		}

		if(nextAccept <= 0)
		{
			switch(curOption.type)
			{
				case BOOL:
					if(controls.ACCEPT)
					{
						FlxG.sound.play(Paths.sound('scrollMenu'));
						curOption.setValue((curOption.getValue() == true) ? false : true);
						curOption.change();
						reloadCheckboxes();
					}

				case KEYBIND:
					if(controls.ACCEPT)
					{
						var targetCam = OptionsSubState.instance != null ? OptionsSubState.instance.optionCam : null;
						bindingBlack = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
						bindingBlack.scale.set(FlxG.width, FlxG.height);
						bindingBlack.updateHitbox();
						bindingBlack.alpha = 0;
						if(targetCam != null) bindingBlack.cameras = [targetCam];
						FlxTween.tween(bindingBlack, {alpha: 0.6}, 0.35, {ease: FlxEase.linear});
						add(bindingBlack);
	
						bindingText = new FlxText(0, 160, FlxG.width, Language.getPhrase('controls_rebinding', 'Rebinding {1}', [curOption.name]));
						bindingText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
						if(targetCam != null) bindingText.cameras = [targetCam];
						add(bindingText);
						
						bindingText2 = new FlxText(0, 280, FlxG.width, Language.getPhrase('controls_rebinding2', 'Hold ESC to Cancel\nHold Backspace to Delete'));
						bindingText2.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
						if(targetCam != null) bindingText2.cameras = [targetCam];
						add(bindingText2);
	
						bindingKey = true;
						holdingEsc = 0;
						ClientPrefs.toggleVolumeKeys(false);
						FlxG.sound.play(Paths.sound('scrollMenu'));
					}

				default:
					if(controls.UI_LEFT || controls.UI_RIGHT)
					{
						var pressed = (controls.UI_LEFT_P || controls.UI_RIGHT_P);
						if(holdTime > 0.5 || pressed)
						{
							if(pressed)
							{
								var add:Dynamic = null;
								if(curOption.type != STRING)
									add = controls.UI_LEFT ? -curOption.changeValue : curOption.changeValue;
		
								switch(curOption.type)
								{
									case INT, FLOAT, PERCENT:
										holdValue = curOption.getValue() + add;
										if(holdValue < curOption.minValue) holdValue = curOption.minValue;
										else if (holdValue > curOption.maxValue) holdValue = curOption.maxValue;
		
										if(curOption.type == INT)
										{
											holdValue = Math.round(holdValue);
											curOption.setValue(holdValue);
										}
										else
										{
											holdValue = FlxMath.roundDecimal(holdValue, curOption.decimals);
											curOption.setValue(holdValue);
										}
		
									case STRING:
										var num:Int = curOption.curOption;
										if(controls.UI_LEFT_P) --num;
										else num++;
		
										if(num < 0)
											num = curOption.options.length - 1;
										else if(num >= curOption.options.length)
											num = 0;
		
										curOption.curOption = num;
										curOption.setValue(curOption.options[num]);

									default:
								}
								updateTextFrom(curOption);
								curOption.change();
								FlxG.sound.play(Paths.sound('scrollMenu'));
							}
							else if(curOption.type != STRING)
							{
								holdValue += curOption.scrollSpeed * elapsed * (controls.UI_LEFT ? -1 : 1);
								if(holdValue < curOption.minValue) holdValue = curOption.minValue;
								else if (holdValue > curOption.maxValue) holdValue = curOption.maxValue;
		
								switch(curOption.type)
								{
									case INT:
										curOption.setValue(Math.round(holdValue));
									
									case PERCENT:
										curOption.setValue(FlxMath.roundDecimal(holdValue, curOption.decimals));

									default:
								}
								updateTextFrom(curOption);
								curOption.change();
							}
						}
		
						if(curOption.type != STRING)
							holdTime += elapsed;
					}
					else if(controls.UI_LEFT_R || controls.UI_RIGHT_R)
					{
						if(holdTime > 0.5) FlxG.sound.play(Paths.sound('scrollMenu'));
						holdTime = 0;
					}
			}

			if(controls.RESET)
			{
				var leOption:Option = optionsArray[curSelected];
				if(leOption.type != KEYBIND)
				{
					leOption.setValue(leOption.defaultValue);
					if(leOption.type != BOOL)
					{
						if(leOption.type == STRING) leOption.curOption = leOption.options.indexOf(leOption.getValue());
						updateTextFrom(leOption);
					}
				}
				else
				{
					leOption.setValue(!Controls.instance.controllerMode ? leOption.defaultKeys.keyboard : leOption.defaultKeys.gamepad);
					updateBind(leOption);
				}
				leOption.change();
				FlxG.sound.play(Paths.sound('cancelMenu'));
				reloadCheckboxes();
			}
		}

		if(nextAccept > 0) {
			nextAccept -= 1;
		}
	}

	function bindingKeyUpdate(elapsed:Float)
	{
		if(FlxG.keys.pressed.ESCAPE || FlxG.gamepads.anyPressed(B))
		{
			holdingEsc += elapsed;
			if(holdingEsc > 0.5)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				closeBinding();
			}
		}
		else if (FlxG.keys.pressed.BACKSPACE || FlxG.gamepads.anyPressed(BACK))
		{
			holdingEsc += elapsed;
			if(holdingEsc > 0.5)
			{
				if (!controls.controllerMode) curOption.keys.keyboard = NONE;
				else curOption.keys.gamepad = NONE;
				updateBind(!controls.controllerMode ? InputFormatter.getKeyName(NONE) : InputFormatter.getGamepadName(NONE));
				FlxG.sound.play(Paths.sound('cancelMenu'));
				closeBinding();
			}
		}
		else
		{
			holdingEsc = 0;
			var changed:Bool = false;
			if(!controls.controllerMode)
			{
				if(FlxG.keys.justPressed.ANY || FlxG.keys.justReleased.ANY)
				{
					var keyPressed:FlxKey = cast (FlxG.keys.firstJustPressed(), FlxKey);
					var keyReleased:FlxKey = cast (FlxG.keys.firstJustReleased(), FlxKey);

					if(keyPressed != NONE && keyPressed != ESCAPE && keyPressed != BACKSPACE)
					{
						changed = true;
						curOption.keys.keyboard = keyPressed;
					}
					else if(keyReleased != NONE && (keyReleased == ESCAPE || keyReleased == BACKSPACE))
					{
						changed = true;
						curOption.keys.keyboard = keyReleased;
					}
				}
			}
			else if(FlxG.gamepads.anyJustPressed(ANY) || FlxG.gamepads.anyJustPressed(LEFT_TRIGGER) || FlxG.gamepads.anyJustPressed(RIGHT_TRIGGER) || FlxG.gamepads.anyJustReleased(ANY))
			{
				var keyPressed:FlxGamepadInputID = NONE;
				var keyReleased:FlxGamepadInputID = NONE;
				if(FlxG.gamepads.anyJustPressed(LEFT_TRIGGER))
					keyPressed = LEFT_TRIGGER;
				else if(FlxG.gamepads.anyJustPressed(RIGHT_TRIGGER))
					keyPressed = RIGHT_TRIGGER;
				else
				{
					for (i in 0...FlxG.gamepads.numActiveGamepads)
					{
						var gamepad:FlxGamepad = FlxG.gamepads.getByID(i);
						if(gamepad != null)
						{
							keyPressed = gamepad.firstJustPressedID();
							keyReleased = gamepad.firstJustReleasedID();
							if(keyPressed != NONE || keyReleased != NONE) break;
						}
					}
				}

				if(keyPressed != NONE && keyPressed != FlxGamepadInputID.BACK && keyPressed != FlxGamepadInputID.B)
				{
					changed = true;
					curOption.keys.gamepad = keyPressed;
				}
				else if(keyReleased != NONE && (keyReleased == FlxGamepadInputID.BACK || keyReleased == FlxGamepadInputID.B))
				{
					changed = true;
					curOption.keys.gamepad = keyReleased;
				}
			}

			if(changed)
			{
				var key:String = null;
				if(!controls.controllerMode)
				{
					if(curOption.keys.keyboard == null) curOption.keys.keyboard = 'NONE';
					curOption.setValue(curOption.keys.keyboard);
					key = InputFormatter.getKeyName(FlxKey.fromString(curOption.keys.keyboard));
				}
				else
				{
					if(curOption.keys.gamepad == null) curOption.keys.gamepad = 'NONE';
					curOption.setValue(curOption.keys.gamepad);
					key = InputFormatter.getGamepadName(FlxGamepadInputID.fromString(curOption.keys.gamepad));
				}
				updateBind(key);
				FlxG.sound.play(Paths.sound('confirmMenu'));
				closeBinding();
			}
		}
	}

	function updateBind(?text:String = null, ?option:Option = null)
	{
		if(option == null) option = curOption;
		if(text == null)
		{
			text = option.getValue();
			if(text == null) text = 'NONE';

			if(!controls.controllerMode)
				text = InputFormatter.getKeyName(FlxKey.fromString(text));
			else
				text = InputFormatter.getGamepadName(FlxGamepadInputID.fromString(text));
		}

		var bind:FlxText = cast option.child;
		var attach:FlxText = new FlxText(0, 0, 0, text, 24);
		attach.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		attach.borderSize = 2;
		attach.scrollFactor.set();
		attach.ID = bind.ID;

		var targetCam = OptionsSubState.instance != null ? OptionsSubState.instance.optionCam : null;
		if(targetCam != null) attach.cameras = [targetCam];

		option.child = attach;
		grpTexts.insert(grpTexts.members.indexOf(bind), attach);
		grpTexts.remove(bind);
		bind.destroy();
	}

	function closeBinding()
	{
		bindingKey = false;
		if(bindingBlack != null) { bindingBlack.destroy(); remove(bindingBlack); }
		if(bindingText != null) { bindingText.destroy(); remove(bindingText); }
		if(bindingText2 != null) { bindingText2.destroy(); remove(bindingText2); }
		ClientPrefs.toggleVolumeKeys(true);
	}

	function updateTextFrom(option:Option) {
		if(option.type == KEYBIND)
		{
			updateBind(option);
			return;
		}

		var text:String = option.displayFormat;
		var val:Dynamic = option.getValue();
		if(option.type == PERCENT) val *= 100;
		var def:Dynamic = option.defaultValue;
		option.text = text.replace('%v', val).replace('%d', def);

		if(option.child != null)
		{
			var textChild:FlxText = cast option.child;
			textChild.text = '' + val;
		}
	}
	
	function changeSelection(change:Int = 0)
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, optionsArray.length - 1);

		descText.text = optionsArray[curSelected].description;

		var targetCam = OptionsSubState.instance != null ? OptionsSubState.instance.optionCam : null;
		if (targetCam != null) {
			descText.y = targetCam.height - 55;
			descText.fieldWidth = targetCam.width - 80;
			descText.x = 40;
		}

		for (num => item in grpOptions.members)
		{
			item.alpha = (num == curSelected) ? 1.0 : 0.6;
		}
		for (text in grpTexts)
		{
			text.alpha = (text.ID == curSelected) ? 1.0 : 0.6;
		}
		for (checkbox in checkboxGroup)
		{
			checkbox.alpha = (checkbox.ID == curSelected) ? 1.0 : 0.6;
		}

		descBox.setPosition(descText.x - 10, descText.y - 5);
		descBox.setGraphicSize(Std.int(descText.width + 20), Std.int(descText.height + 10));
		descBox.updateHitbox();

		curOption = optionsArray[curSelected];
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function reloadCheckboxes()
	{
		for (checkbox in checkboxGroup)
		{
			checkbox.daValue = Std.string(optionsArray[checkbox.ID].getValue()) == 'true';
		}
	}
}
