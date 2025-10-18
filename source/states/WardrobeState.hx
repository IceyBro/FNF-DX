package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;

// If your fork needs older import, use: import MusicBeatState;
import backend.MusicBeatState;

class WardrobeState extends MusicBeatState {
    var bg:FlxSprite;
    var title:FlxText;
    var help:FlxText;
    var listLeftTitle:FlxText;
    var listRightTitle:FlxText;
    var charRows:Array<FlxText> = [];
    var noteRows:Array<FlxText> = [];

    var charSkins:Array<String> = []; // filled from save: keys own_skin_char_<id>
    var noteSkins:Array<String> = []; // filled from save: keys own_skin_note_<id>

    var selSide:Int = 0; // 0 = character column, 1 = note column
    var selChar:Int = 0;
    var selNote:Int = 0;

    override public function create():Void {
        super.create();
        if (!FlxG.save.isBound) FlxG.save.bind("psych-save", "FNF");

        // fallback bg
        bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF101018);
        add(bg);

        title = mkText("WARDROBE", 0, 24, 36, true);
        add(title);

        help = mkText("LEFT/RIGHT switch column • UP/DOWN move • ENTER equip • ESC to exit", 0, FlxG.height - 48, 18, true);
        add(help);

        listLeftTitle = mkText("Character Skins", 80, 90, 22, false);
        listRightTitle = mkText("Note Skins", FlxG.width - 80 - 240, 90, 22, false);
        add(listLeftTitle); add(listRightTitle);

        // Build lists from owned flags
        charSkins = collectOwned("own_skin_char_");
        noteSkins = collectOwned("own_skin_note_");

        if (charSkins.length == 0) charSkins = ["default"];
        if (noteSkins.length == 0) noteSkins = ["default"];

        var y0 = 130;
        for (i in 0...charSkins.length) {
            var t = mkText(charSkins[i], 80, y0 + i * 32, 20, false);
            add(t); charRows.push(t);
        }
        for (i in 0...noteSkins.length) {
            var t = mkText(noteSkins[i], FlxG.width - 80 - 240, y0 + i * 32, 20, false);
            add(t); noteRows.push(t);
        }

        // Preselect currently equipped
        var eqChar:String = getStr("equippedCharSkin", "default");
        var eqNote:String = getStr("equippedNoteSkin", "default");

        var cIdx:Int = charSkins.indexOf(eqChar);
        selChar = (cIdx >= 0) ? cIdx : 0;

        var nIdx:Int = noteSkins.indexOf(eqNote);
        selNote = (nIdx >= 0) ? nIdx : 0;


        refreshUI();
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);

        if (FlxG.keys.justPressed.LEFT)  { selSide = 0; refreshUI(); }
        if (FlxG.keys.justPressed.RIGHT) { selSide = 1; refreshUI(); }

        if (FlxG.keys.justPressed.UP) {
            if (selSide == 0) selChar = (selChar - 1 + charSkins.length) % charSkins.length;
            else               selNote = (selNote - 1 + noteSkins.length) % noteSkins.length;
            refreshUI();
        }
        if (FlxG.keys.justPressed.DOWN) {
            if (selSide == 0) selChar = (selChar + 1) % charSkins.length;
            else               selNote = (selNote + 1) % noteSkins.length;
            refreshUI();
        }

        if (FlxG.keys.justPressed.ENTER) {
            if (selSide == 0) setStr("equippedCharSkin", charSkins[selChar]);
            else              setStr("equippedNoteSkin", noteSkins[selNote]);
            FlxG.save.flush();
            FlxG.sound.play(Paths.sound("confirmMenu"), 0.8);
            refreshUI();
        }

        if (FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.BACKSPACE) {
            MusicBeatState.switchState(new MainMenuState());
        }
    }

    function collectOwned(prefix:String):Array<String> {
        var out:Array<String> = [];
        // Scan save fields for prefix
        for (field in Reflect.fields(FlxG.save.data)) {
            if (StringTools.startsWith(field, prefix)) {
                var id = field.substr(prefix.length);
                var val:Bool = Reflect.field(FlxG.save.data, field);
                if (val) out.push(id);
            }
        }
        out.sort(function(a,b) return Reflect.compare(a,b));
        out.insert(0, "default"); // always available
        return out;
    }

    function refreshUI():Void {
        for (i in 0...charRows.length) {
            var t = charRows[i];
            t.color = (selSide == 0 && i == selChar) ? 0xFFFFFF00 : FlxColor.WHITE;
            // mark equipped with *
            var isEquipped = getStr("equippedCharSkin","default") == charSkins[i];
            t.text = (isEquipped ? "* " : "  ") + charSkins[i];
        }
        for (i in 0...noteRows.length) {
            var t = noteRows[i];
            t.color = (selSide == 1 && i == selNote) ? 0xFFFFFF00 : FlxColor.WHITE;
            var isEquipped = getStr("equippedNoteSkin","default") == noteSkins[i];
            t.text = (isEquipped ? "* " : "  ") + noteSkins[i];
        }
    }

    inline function mkText(txt:String, x:Float, y:Float, size:Int, centerX:Bool):FlxText {
        var t = new FlxText(x, y, centerX ? 0 : 240, txt, size);
        t.scrollFactor.set();
        if (centerX) { t.alignment = CENTER; t.x = (FlxG.width - t.width) * 0.5; }
        return t;
    }

    inline function getStr(key:String, def:String):String {
        var v:Null<String> = cast Reflect.field(FlxG.save.data, key);
        return v != null ? v : def;
    }
    inline function setStr(key:String, v:String):Void {
        Reflect.setField(FlxG.save.data, key, v);
    }
}
