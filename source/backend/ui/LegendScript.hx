package backend.ui;

import flixel.FlxObject;
import flixel.input.keyboard.FlxKey;
import flixel.util.FlxDestroyUtil;
import flash.events.KeyboardEvent;
import openfl.events.TextEvent;
import lime.system.Clipboard;
import backend.ui.LegendUIInputText.AccentCode;
import backend.ui.LegendUIInputText.FilterMode;
import backend.ui.LegendUIInputText.CaseMode;

class LegendScript extends FlxSpriteGroup
{
	public static final CHANGE_EVENT = "script_change";

	static final KEY_TILDE = 126;
	static final KEY_ACUTE = 180;

	public static var focusOn(default, set):LegendScript = null;

	public var name:String;
	public var bg:FlxSprite;
	public var behindText:FlxSprite;
	public var selection:FlxSprite;
	public var textObj:FlxText;
	public var caret:FlxSprite;
	public var onChange:String->String->Void;

	public var fieldWidth(default, set):Int = 0;
	public var maxLength(default, set):Int = 0;
	public var passwordMask(default, set):Bool = false;
	public var text(default, set):String = null;
	
	public var forceCase(default, set):CaseMode = ALL_CASES;
	public var filterMode(default, set):FilterMode = NO_FILTER;
	public var customFilterPattern(default, set):EReg;

	public var selectedFormat:FlxTextFormat = new FlxTextFormat(FlxColor.WHITE);

	public function new(x:Float = 0, y:Float = 0, wid:Int = 100, ?text:String = '', size:Int = 8)
	{
		super(x, y);
		this.bg = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		this.behindText = new FlxSprite(1, 1).makeGraphic(1, 1, FlxColor.WHITE);
		this.selection = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
		this.textObj = new FlxText(1, 1, Math.max(1, wid - 2), '', size);
		this.caret = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
		add(this.bg);
		add(this.behindText);
		add(this.selection);
		add(this.textObj);
		add(this.caret);

		this.textObj.setFormat(Paths.font("vcr.ttf"), size, FlxColor.BLACK, LEFT);
		this.textObj.textField.selectable = false;
		this.textObj.textField.wordWrap = true;
		this.textObj.textField.multiline = true;
		this.selection.color = FlxColor.GRAY;

		@:bypassAccessor fieldWidth = wid;
		setGraphicSize(wid + 2, this.textObj.height + 2);
		updateHitbox();
		this.text = text;

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		FlxG.stage.addEventListener(TextEvent.TEXT_INPUT, onTextInput);
	}
	
	public var selectIndex:Int = -1;
	public var caretIndex(default, set):Int = -1;
	var _caretTime:Float = 0;

	var _nextAccent:AccentCode = NONE;
	public var inInsertMode:Bool = false;
	function onKeyDown(e:KeyboardEvent)
	{
		if(focusOn != this) return;

		var keyCode:Int = e.keyCode;
		var charCode:Int = e.charCode;
		var flxKey:FlxKey = cast keyCode;

		// Fix missing cedilla
		switch(keyCode)
		{
			case 231: //ç and Ç
				charCode = e.shiftKey ? 0xC7 : 0xE7;
		}

		// Control key actions
		if(e.controlKey)
		{
			switch(flxKey)
			{
				case Z: //undo / redo(Shift)
					if(e.shiftKey) redo(); else undo();
					updateCaret();
					return;

				case Y: //redo
					redo();
					updateCaret();
					return;

				case A: //select all text
					selectIndex = Std.int(Math.min(0, text.length - 1));
					caretIndex = text.length;

				case X, C: //cut/copy selected text to clipboard
					if(caretIndex >= 0 && selectIndex != 0 && caretIndex != selectIndex)
					{
						Clipboard.text = text.substring(caretIndex, selectIndex);
						if(flxKey == X)
							deleteSelection();
					}

				case V: //paste from clipboard
					if(Clipboard.text == null) return;

					if(selectIndex > -1 && selectIndex != caretIndex)
						deleteSelection();

					var lastText = text;
					text = text.substring(0, caretIndex) + Clipboard.text + text.substring(caretIndex);
					caretIndex += Clipboard.text.length;
					if(onChange != null) onChange(lastText, text);
					if(broadcastInputTextEvent) LegendUIEventHandler.event(CHANGE_EVENT, this);

				case BACKSPACE:
					if(selectIndex < 0 || selectIndex == caretIndex)
					{
						var lastText = text;
						var deletedText:String = text.substr(0, Std.int(Math.max(0, caretIndex-1)));
						var space:Int = deletedText.lastIndexOf(' ');
						if(space > -1 && space != caretIndex-1)
						{
							var start:String = deletedText.substring(0, space+1);
							var end:String = text.substring(caretIndex);
							caretIndex -= Std.int(Math.max(0, text.length - (start.length + end.length)));
							text = start + end;
						}
						else
						{
							text = text.substring(caretIndex);
							caretIndex = 0;
						}
						selectIndex = -1;
						if(onChange != null) onChange(lastText, text);
						if(broadcastInputTextEvent) LegendUIEventHandler.event(CHANGE_EVENT, this);
					}
					else deleteSelection();

				case DELETE:
					if(selectIndex < 0 || selectIndex == caretIndex)
					{
						// This is| a test
						// This is test
						var deletedText:String = text.substring(caretIndex);
						var spc:Int = 0;
						var space:Int = deletedText.indexOf(' ');
						while(deletedText.substr(spc, 1) == ' ')
						{
							spc++;
							space = deletedText.substr(spc).indexOf(' ');
						}

						var lastText = text;
						if(space > -1)
						{
							text = text.substr(0, caretIndex) + text.substring(caretIndex + space + spc);
						}
						else text = text.substr(0, caretIndex);
						if(onChange != null) onChange(lastText, text);
						if(broadcastInputTextEvent) LegendUIEventHandler.event(CHANGE_EVENT, this);
					}
					else deleteSelection();

				case LEFT:
					if(caretIndex > 0)
					{
						do
						{
							caretIndex--;
							var a:String = text.substr(caretIndex-1, 1);
							var b:String = text.substr(caretIndex, 1);
							//trace(a, b);
							if(a == ' ' && b != ' ') break;
						}
						while(caretIndex > 0);
					}

				case RIGHT:
					if(caretIndex < text.length)
					{
						do
						{
							caretIndex++;
							var a:String = text.substr(caretIndex-1, 1);
							var b:String = text.substr(caretIndex, 1);
							//trace(a, b);
							if(a != ' ' && b == ' ') break;
						}
						while(caretIndex < text.length);
					}

				default:
			}
			updateCaret();
			return;
		}

		static final ignored:Array<FlxKey> = [SHIFT, CONTROL, ESCAPE];
		if(ignored.contains(flxKey)) return;

		var lastAccent = _nextAccent;
		switch(keyCode)
		{
			case KEY_TILDE:
				_nextAccent = !e.shiftKey ? TILDE : CIRCUMFLEX;
				if(lastAccent == NONE) return;
			case KEY_ACUTE:
				_nextAccent = !e.shiftKey ? ACUTE : GRAVE;
				if(lastAccent == NONE) return;
			default:
				lastAccent = NONE;
		}

		_keepWantX = false;
		switch(flxKey)
		{
			case LEFT: //move caret to left
				if(!FlxG.keys.pressed.SHIFT) selectIndex = -1;
				else if(selectIndex == -1) selectIndex = caretIndex;
				caretIndex = Std.int(Math.max(0, caretIndex - 1));

			case RIGHT: //move caret to right
				if(!FlxG.keys.pressed.SHIFT) selectIndex = -1;
				else if(selectIndex == -1) selectIndex = caretIndex;
				caretIndex = Std.int(Math.min(text.length, caretIndex + 1));

			case HOME: //move caret to the begin
				if(!FlxG.keys.pressed.SHIFT) selectIndex = -1;
				else if(selectIndex == -1) selectIndex = caretIndex;
				caretIndex = getLineStart(caretIndex);

			case END: //move caret to the end
				if(!FlxG.keys.pressed.SHIFT) selectIndex = -1;
				else if(selectIndex == -1) selectIndex = caretIndex;
				caretIndex = getLineEnd(caretIndex);

			case UP:
				if(!FlxG.keys.pressed.SHIFT) selectIndex = -1;
				else if(selectIndex == -1) selectIndex = caretIndex;
				caretIndex = moveVisualLine(-1);
				_keepWantX = true;

			case DOWN:
				if(!FlxG.keys.pressed.SHIFT) selectIndex = -1;
				else if(selectIndex == -1) selectIndex = caretIndex;
				caretIndex = moveVisualLine(1);
				_keepWantX = true;

			case INSERT: //change to insert mode
				inInsertMode = !inInsertMode;

			case BACKSPACE: //Delete letter to the left of caret
				if(caretIndex <= 0) return;

				if(selectIndex > -1 && selectIndex != caretIndex)
					deleteSelection();
				else
				{
					var lastText = text;
					text = text.substring(0, caretIndex-1) + text.substring(caretIndex);
					caretIndex--;
					if(onChange != null) onChange(lastText, text);
					if(broadcastInputTextEvent) LegendUIEventHandler.event(CHANGE_EVENT, this);
				}
				_nextAccent = NONE;

			case DELETE: //Delete letter to the right of caret
				if(selectIndex > -1 && selectIndex != caretIndex)
				{
					deleteSelection();
					updateCaret();
					return;
				}

				if(caretIndex >= text.length) return;

				var lastText = text;
				if(caretIndex < 1)
					text = text.substr(1);
				else
					text = text.substring(0, caretIndex) + text.substring(caretIndex+1);

				if(caretIndex >= text.length) caretIndex = text.length;
				
				if(onChange != null) onChange(lastText, text);
				if(broadcastInputTextEvent) LegendUIEventHandler.event(CHANGE_EVENT, this);
			
			case SPACE: //space or last accent pressed
				if(_nextAccent != NONE) _typeLetter(getAccentCharCode(_nextAccent));
				else _typeLetter(charCode);
				_nextAccent = NONE;

			case A, O: //these support all accents
				var grave:Int = 0x0;
				var capital:Int = 0x0;
				switch(flxKey)
				{
					case A:
						grave = 0xC0;
						capital = 0x41;
					case O:
						grave = 0xD2;
						capital = 0x4f;
					default:
				}
				if(_nextAccent != NONE)
					charCode += grave - capital + _nextAccent;

				_typeLetter(charCode);
				_nextAccent = NONE;

			case E, I, U: //these support grave, acute and circumflex
				var grave:Int = 0x0;
				var capital:Int = 0x0;
				switch(flxKey)
				{
					case E:
						grave = 0xC8;
						capital = 0x45;
					case I:
						grave = 0xCC;
						capital = 0x49;
					case U:
						grave = 0xD9;
						capital = 0x55;
					default:
				}
				if(_nextAccent == GRAVE || _nextAccent == ACUTE || _nextAccent == CIRCUMFLEX) //Supported accents
					charCode += grave - capital + _nextAccent;
				else if(_nextAccent == TILDE) //Unsupported accent
					_typeLetter(getAccentCharCode(_nextAccent));

				_typeLetter(charCode);
				_nextAccent = NONE;

			case N: //it only supports tilde
				if(_nextAccent == TILDE)
					charCode += 0xD1 - 0x4E;
				else
					_typeLetter(getAccentCharCode(_nextAccent));

				_typeLetter(charCode);
				_nextAccent = NONE;

			case ESCAPE:
				focusOn = null;

			case ENTER:
				onPressEnter(e);

			default:
				if(charCode < 1)
					if((charCode = getAccentCharCode(_nextAccent)) < 1)
						return;

				if(lastAccent != NONE) _typeLetter(getAccentCharCode(lastAccent));
				else if(_nextAccent != NONE) _typeLetter(getAccentCharCode(_nextAccent));
				_typeLetter(charCode);
				_nextAccent = NONE;
		}
		if(!_keepWantX) _wantX = -1;
		updateCaret();
	}

	// ---- 줄 단위 계산 헬퍼 ----
	function getLineStart(idx:Int):Int
	{
		if(idx <= 0) return 0;
		return text.lastIndexOf('\n', idx - 1) + 1;
	}

	function getLineEnd(idx:Int):Int
	{
		var e:Int = text.indexOf('\n', idx);
		return e == -1 ? text.length : e;
	}

	// 논리 줄(\n 기준) 번호
	function getLineNumber(idx:Int):Int
	{
		var n:Int = 0;
		for(i in 0...idx) if(text.charAt(i) == '\n') n++;
		return n;
	}

	// 화면 줄(자동 줄바꿈 포함) 번호
	function getVisualLine(idx:Int):Int
	{
		if(text.length == 0) return 0;
		var tf = textObj.textField;
		var i:Int = Std.int(Math.max(0, Math.min(text.length - 1, idx)));
		var ln:Int = tf.getLineIndexOfChar(i);
		if(ln < 0) ln = getLineNumber(idx);
		// 맨 끝이 개행 뒤라면 표시용 공백이 있는 마지막 줄
		if(idx >= text.length && text.charAt(text.length - 1) == '\n') ln = Std.int(Math.max(0, tf.numLines - 1));
		return ln;
	}

	// 화면 줄 n의 위쪽 y(글자 영역 기준)
	function getLineTop(n:Int):Float
	{
		var tf = textObj.textField;
		var y:Float = 0;
		var last:Int = Std.int(Math.max(0, tf.numLines - 1));
		var upto:Int = Std.int(Math.min(n, tf.numLines));
		for(i in 0...upto)
		{
			var m = tf.getLineMetrics(Std.int(Math.min(i, last)));
			y += m.height;
		}
		return y;
	}

	// 현재 커서가 있는 줄의 실제 높이
	function getLineHeight():Float
	{
		var tf = textObj.textField;
		var n:Int = Std.int(Math.max(0, Math.min(tf.numLines - 1, getVisualLine(caretIndex))));
		var m = tf.getLineMetrics(n);
		return m.height > 0 ? m.height : tf.textHeight / Math.max(1, tf.numLines);
	}

	// lineStart 줄에서 idx 글자 앞까지의 가로 폭
	function getXInLine(lineStart:Int, idx:Int):Float
	{
		if(idx <= lineStart) return 0;
		var tf = textObj.textField;
		var a = tf.getCharBoundaries(lineStart);
		var b = tf.getCharBoundaries(idx - 1);
		return (a != null && b != null) ? b.x + b.width - a.x : 0;
	}


	// ---- 화면 줄 이동: 같은 가로 위치(_wantX)에 가장 가까운 글자로 ----
	var _wantX:Float = -1;
	var _keepWantX:Bool = false;

	// 줄 시작 글자 기준 idx 앞까지의 폭 (줄 맨 앞 = 0)
	function xOfIndex(idx:Int):Float
	{
		var tf = textObj.textField;
		var ln:Int = getVisualLine(idx);
		var start:Int = tf.getLineOffset(ln);
		return getXInLine(start, idx);
	}

	function moveVisualLine(dir:Int):Int
	{
		var tf = textObj.textField;
		if(text.length == 0) return 0;
		var cur:Int = getVisualLine(caretIndex);
		var target:Int = cur + dir;
		if(target < 0) return 0;
		if(target > tf.numLines - 1) return text.length;

		if(_wantX < 0) _wantX = xOfIndex(caretIndex);

		var start:Int = tf.getLineOffset(target);
		var len:Int = tf.getLineLength(target);
		var end:Int = start + len;
		// 줄 끝의 개행/표시용 공백은 커서가 올라설 수 없다
		while(end > start && (text.charAt(end - 1) == '\n' || end > text.length)) end--;

		var best:Int = start;
		var prevW:Float = 0;
		for(c in start...end)
		{
			var w:Float = getXInLine(start, c + 1);
			// 글자 폭의 중간점보다 왼쪽이면 그 글자 앞, 아니면 뒤
			if(_wantX >= prevW + (w - prevW) / 2) best = c + 1;
			else break;
			prevW = w;
		}
		return best;
	}

	// ---- IME(한글 등) 입력: 조합이 끝난 문자열이 TEXT_INPUT으로 온다 ----
	var _handledByKey:Bool = false;

	function onTextInput(e:TextEvent)
	{
		if(focusOn != this) return;
		// KEY_DOWN에서 이미 넣은 영문/숫자/기호는 건너뛴다
		if(_handledByKey) { _handledByKey = false; return; }
		var t:String = e.text;
		if(t == null || t.length == 0) return;
		// 제어 문자 제외(개행은 Enter 경로로 처리)
		var cleaned:String = '';
		for(k in 0...t.length)
		{
			var cc:Int = t.charCodeAt(k);
			if(cc >= 32 && cc != 127) cleaned += t.charAt(k);
		}
		if(cleaned.length == 0) return;
		_typeString(cleaned);
		updateCaret();
	}

	function _typeString(str:String)
	{
		if(selectIndex > -1 && selectIndex != caretIndex)
			deleteSelection();
		str = filter(str);
		if(str.length == 0) return;
		if(maxLength != 0 && (text.length + str.length) > maxLength) return;

		var lastText = text;
		_mergeNext = true;
		if(!inInsertMode)
			text = text.substring(0, caretIndex) + str + text.substring(caretIndex);
		else
			text = text.substring(0, caretIndex) + str + text.substring(caretIndex + str.length);
		_mergeNext = false;
		caretIndex += str.length;
		if(onChange != null) onChange(lastText, text);
		if(broadcastInputTextEvent) LegendUIEventHandler.event(CHANGE_EVENT, this);
		_caretTime = 0;
	}

	// ---- undo / redo: 편집 직전의 (text, caretIndex) 스냅샷 스택 ----
	static inline var UNDO_LIMIT:Int = 200;
	var _undo:Array<{t:String, c:Int}> = [];
	var _redo:Array<{t:String, c:Int}> = [];
	var _restoring:Bool = false;
	var _mergeNext:Bool = false; // 연속 타이핑이면 같은 덩어리로 묶는다
	var _lastMerged:Bool = false;

	// text가 바뀌기 직전에 호출: 이전 상태 저장
	function _recordUndo(prev:String)
	{
		if(_restoring) return;
		// 같은 덩어리 연속 타이핑이면 새 스냅샷을 만들지 않는다
		if(_mergeNext && _lastMerged && _undo.length > 0) { _redo = []; return; }
		_undo.push({t:prev, c:caretIndex});
		if(_undo.length > UNDO_LIMIT) _undo.shift();
		_redo = [];
		_lastMerged = _mergeNext;
	}

	public function undo()
	{
		if(_undo.length == 0) return;
		var st = _undo.pop();
		_redo.push({t:text, c:caretIndex});
		_applySnapshot(st);
	}

	public function redo()
	{
		if(_redo.length == 0) return;
		var st = _redo.pop();
		_undo.push({t:text, c:caretIndex});
		_applySnapshot(st);
	}

	function _applySnapshot(st:{t:String, c:Int})
	{
		var lastText = text;
		_restoring = true;
		text = st.t;
		_restoring = false;
		selectIndex = -1;
		caretIndex = Std.int(Math.max(0, Math.min(text.length, st.c)));
		_lastMerged = false;
		if(onChange != null) onChange(lastText, text);
		if(broadcastInputTextEvent) LegendUIEventHandler.event(CHANGE_EVENT, this);
	}

	public dynamic function onPressEnter(e:KeyboardEvent) {
		if(selectIndex > -1 && selectIndex != caretIndex)
			deleteSelection();
	
		var pos:Int = caretIndex < 0 ? 0 : caretIndex;
		text = text.substr(0, pos) + '\n' + text.substr(pos);
		caretIndex = pos + 1;
	}

	public var unfocus:Void->Void;
	public static function set_focusOn(v:LegendScript)
	{
		if(focusOn != null && focusOn != v && focusOn.exists)
		{
			if(focusOn.unfocus != null) focusOn.unfocus();
			focusOn.resetCaret();
		}
		return (focusOn = v);
	}

	override function update(elapsed:Float)
	{
		// KEY_DOWN과 TEXT_INPUT은 같은 프레임 안에서 연달아 오므로 프레임이 지나면 중복 방지 플래그를 푼다
		_handledByKey = false;
		super.update(elapsed);

		if(FlxG.mouse.justPressed)
		{
			if(FlxG.mouse.overlaps(behindText, camera))
			{
				if(!FlxG.keys.pressed.SHIFT) selectIndex = -1;
				else if(selectIndex == -1) selectIndex = caretIndex;
				focusOn = this;
				caretIndex = 0;
				var textObjX:Float = textObj.getScreenPosition(camera).x;
				var textObjY:Float = textObj.getScreenPosition(camera).y;
				var mousePosX:Float = FlxG.mouse.getScreenPosition(camera).x;
				var mousePosY:Float = FlxG.mouse.getScreenPosition(camera).y;

				var lines:Int = Std.int(Math.max(1, textObj.textField.numLines));
				var relY:Float = mousePosY - textObjY - GUTTER;
				var ln:Int = 0;
				while(ln < lines - 1 && getLineTop(ln + 1) <= relY) ln++;

				var tfc = textObj.textField;
				var start:Int = text.length == 0 ? 0 : tfc.getLineOffset(ln);
				var end:Int = text.length == 0 ? 0 : start + tfc.getLineLength(ln);
				if(end > start && text.charAt(end - 1) == '\n') end--;

				caretIndex = start;
				var relX:Float = mousePosX - (textObjX + GUTTER - textObj.textField.scrollH);
				for(c in start...end)
				{
					var prevW:Float = getXInLine(start, c);
					var w:Float = getXInLine(start, c + 1);
					if(relX >= prevW + (w - prevW) / 2) caretIndex = c + 1;
					else break;
				}
				updateCaret();
			}
			else if(focusOn == this)
				focusOn = null;

			//trace('changed focus to: ' + this);
		}

		if(focusOn == this)
		{
			_caretTime = (_caretTime + elapsed) % 1;
			if(textObj != null && textObj.exists)
			{
				var drewSelection:Bool = false;
				if(selection != null && selection.exists)
				{
					if(selectIndex != -1 && selectIndex != caretIndex)
					{
						selection.visible = true;
						drewSelection = true;
					}
					else selection.visible = false;
				}
	
				if(caret != null && caret.exists)
				{
					if(!drewSelection && _caretTime < 0.5 && caret.x >= textObj.x)
					{
						caret.visible = true;
						caret.color = textObj.color;
					}
					else caret.visible = false;
				}
			}
		}
		else
		{
			_caretTime = 0;
			inInsertMode = false;
			if(selection != null && selection.exists) selection.visible = false;
			if(caret != null && caret.exists) caret.visible = false;
		}
	}

	public function resetCaret()
	{
		selectIndex = -1;
		caretIndex = 0;
		updateCaret();
	}

	public function updateCaret()
	{
		if(textObj == null || !textObj.exists) return;

		var textField = textObj.textField;
		textField.setSelection(caretIndex, caretIndex);
		_caretTime = 0;

		var lh:Float = getLineHeight();
		if(caret != null && caret.exists)
		{
			caret.setGraphicSize(1, Math.max(1, lh));
			caret.updateHitbox();
			caret.y = textObj.y + GUTTER + getLineTop(getVisualLine(caretIndex));
			caret.x = textObj.x + GUTTER - textField.scrollH + getXInLine(getLineStart(caretIndex), caretIndex);
		}

		if(selection != null && selection.exists)
		{
			// 같은 줄 안의 선택만 하이라이트 (여러 줄에 걸치면 글자 색 포맷만 적용)
			var sameLine:Bool = selectIndex > -1 && selectIndex != caretIndex && getLineNumber(selectIndex) == getLineNumber(caretIndex);
			if(sameLine)
			{
				var ls:Int = getLineStart(caretIndex);
				var x1:Float = getXInLine(ls, caretIndex);
				var x2:Float = getXInLine(ls, selectIndex);
				selection.x = textObj.x + GUTTER - textField.scrollH + Math.min(x1, x2);
				selection.y = textObj.y + GUTTER + getLineTop(getVisualLine(caretIndex));
				selection.scale.y = lh;
				selection.scale.x = Math.abs(x1 - x2);
				selection.updateHitbox();
			}
			else
			{
				selection.scale.x = 0;
				selection.updateHitbox();
			}

			if(text.length > 0)
			{
				textObj.removeFormat(selectedFormat);
				if(selectIndex != -1 && selectIndex != caretIndex)
					textObj.addFormat(selectedFormat, Std.int(Math.min(caretIndex, selectIndex)), Std.int(Math.max(caretIndex, selectIndex)));
			}
		}
		else if(text.length > 0) textObj.removeFormat(selectedFormat);
	}

	function deleteSelection()
	{
		var lastText:String = text;
		if(selectIndex > caretIndex)
		{
			text = text.substring(0, caretIndex) + text.substring(selectIndex);
		}
		else
		{
			text = text.substring(0, selectIndex) + text.substring(caretIndex);
			caretIndex = selectIndex;
		}
		selectIndex = -1;
		if(onChange != null) onChange(lastText, text);
		if(broadcastInputTextEvent) LegendUIEventHandler.event(CHANGE_EVENT, this);
	}

	override public function destroy()
	{
		if(focusOn == this) focusOn = null;
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		FlxG.stage.removeEventListener(TextEvent.TEXT_INPUT, onTextInput);
		super.destroy();
	}

	function set_caretIndex(v:Int)
	{
		caretIndex = v;
		updateCaret();
		return v;
	}

	override public function setGraphicSize(width:Float = 0, height:Float = 0)
	{
		super.setGraphicSize(width, height);
		bg.setGraphicSize(width, height);
		behindText.setGraphicSize(width - 2, height - 2);
		if(textObj != null && textObj.exists)
		{
			textObj.scale.x = 1;
			textObj.scale.y = 1;
			if(caret != null && caret.exists) caret.setGraphicSize(1, Math.max(1, getLineHeight()));
		}
	}
	
	override public function updateHitbox()
	{
		super.updateHitbox();
		bg.updateHitbox();
		behindText.updateHitbox();
		if(textObj != null && textObj.exists)
		{
			textObj.updateHitbox();
			if(caret != null && caret.exists) caret.updateHitbox();
		}
	}

	function set_fieldWidth(v:Int)
	{
		textObj.fieldWidth = Math.max(1, v - 2);
		textObj.textField.selectable = false;
		textObj.textField.wordWrap = true;
		textObj.textField.multiline = true;
		return (fieldWidth = v);
	}

	function set_maxLength(v:Int)
	{
		var lastText = text;
		v = Std.int(Math.max(0, v));
		if(v > 0 && text.length > v) text = text.substr(0, v);
		if(onChange != null) onChange(lastText, text);
		if(broadcastInputTextEvent) LegendUIEventHandler.event(CHANGE_EVENT, this);
		return (maxLength = v);
	}

	function set_passwordMask(v:Bool)
	{
		passwordMask = v;
		text = text;
		return passwordMask;
	}

	// openfl TextField는 사방에 2px 내부 여백(거터)을 두고 글자를 그린다
	static inline var GUTTER:Float = 2;
	// 입력칸 세로 최대 크기(0 이하면 글자 높이만큼 제한 없이 늘어남)
	public var maxHeight(default, set):Float = 0;
	function set_maxHeight(v:Float):Float
	{
		maxHeight = v;
		_appliedH = 0;
		if(textObj != null && text != null) text = text;
		return v;
	}
	var _appliedH:Float = 0;
	function set_text(v:String)
	{
		if(text != null && v != text) _recordUndo(text);
		v = filter(v);

		var shown:String = '';
		if(v != null && v.length > 0)
		{
			if(!passwordMask) shown = v;
			else
			{
				for(k in 0...v.length) shown += (v.charAt(k) == '\n') ? '\n' : '*';
			}
		}
		// openfl은 끝이 개행이면 그 뒤 빈 줄을 numLines에 안 센다 -> 표시용으로만 공백 1칸을 붙여 줄을 확보
		if(shown.length > 0 && shown.charAt(shown.length - 1) == '\n') shown += ' ';
		if(textObj.text != shown) textObj.text = shown;
		text = v;
		var wantH:Float = textObj.textField.textHeight + GUTTER * 2 + 2;
		if(maxHeight > 0 && wantH > maxHeight) wantH = maxHeight;
		if(Math.abs(_appliedH - wantH) > 0.5)
		{
			_appliedH = wantH;
			setGraphicSize(fieldWidth + 2, wantH);
			updateHitbox();
		}
		updateCaret();
		return v;
	}

	public static function getAccentCharCode(accent:AccentCode)
	{
		switch(accent)
		{
			case TILDE:
				return 0x7E;
			case CIRCUMFLEX:
				return 0x5E;
			case ACUTE:
				return 0xB4;
			case GRAVE:
				return 0x60;
			default:
				return 0x0;
		}
	}

	public var broadcastInputTextEvent:Bool = true;
	function _typeLetter(charCode:Int)
	{
		if(charCode < 1) return;
		
		if(selectIndex > -1 && selectIndex != caretIndex)
			deleteSelection();

		var letter:String = String.fromCharCode(charCode);
		letter = filter(letter);
		if(letter.length > 0 && (maxLength == 0 || (text.length + letter.length) <= maxLength))
		{
			var lastText = text;
			_handledByKey = true;
			_mergeNext = letter != '\n';
			if(!inInsertMode)
				text = text.substring(0, caretIndex) + letter + text.substring(caretIndex);
			else
				text = text.substring(0, caretIndex) + letter + text.substring(caretIndex+1);

			_mergeNext = false;
			caretIndex += letter.length;
			if(onChange != null) onChange(lastText, text);
			if(broadcastInputTextEvent) LegendUIEventHandler.event(CHANGE_EVENT, this);
		}
		_caretTime = 0;
	}

	// from FlxInputText
	function set_forceCase(v:CaseMode)
	{
		forceCase = v;
		text = filter(text);
		return forceCase;
	}

	function set_filterMode(v:FilterMode)
	{
		filterMode = v;
		text = filter(text);
		return filterMode;
	}

	function set_customFilterPattern(cfp:EReg)
	{
		customFilterPattern = cfp;
		filterMode = CUSTOM_FILTER;
		return customFilterPattern;
	}
	
	private function filter(text:String):String
	{
		switch(forceCase)
		{
			case UPPER_CASE:
				text = text.toUpperCase();
			case LOWER_CASE:
				text = text.toLowerCase();
			default:
		}
		if (forceCase == UPPER_CASE)
			text = text.toUpperCase();
		else if (forceCase == LOWER_CASE)
			text = text.toLowerCase();

		if (filterMode != NO_FILTER)
		{
			var pattern:EReg;
			switch (filterMode)
			{
				case ONLY_ALPHA:
					pattern = ~/[^a-zA-Z]*/g;
				case ONLY_NUMERIC:
					pattern = ~/[^0-9]*/g;
				case ONLY_ALPHANUMERIC:
					pattern = ~/[^a-zA-Z0-9]*/g;
				case ONLY_HEXADECIMAL:
					pattern = ~/[^a-fA-F0-9]*/g;
				case CUSTOM_FILTER:
					pattern = customFilterPattern;
				default:
					throw new flash.errors.Error("FlxInputText: Unknown filterMode (" + filterMode + ")");
			}
			text = pattern.replace(text, "");
		}
		return text;
	}
}
