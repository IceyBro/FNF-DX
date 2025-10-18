package substates;

import states.MainMenuState;
import states.WardrobeState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;

import backend.MusicBeatSubstate;
import backend.MusicBeatState; // needed for switchState
import StringTools;           // for startsWith

class ShopSubState extends MusicBeatSubstate {
    // ─────────────────────────────────────────────────────────────
    // Multi-shop tabs (Q/E to switch)
    // id conventions:
    //   skin_char_*  → own_skin_char_<*>
    //   skin_note_*  → own_skin_note_<*>
    //   song_*       → own_song_<*>
    // ─────────────────────────────────────────────────────────────
    var shopTabs:Array<{name:String, items:Array<Item>}> = [
        { name: "Cosmetics", items: [
            new Item("skin_char_bf-red", "BF: Red Hoodie", 120),
            new Item("skin_note_blue",   "Note Skin: Blue", 60),
            new Item("healthCharm",      "Health Charm", 120)
        ]},
        { name: "Songs", items: [
            new Item("song_bopeebo",   "Song: Bopeebo", 75),
            new Item("song_fresh",     "Song: Fresh",   90),
            new Item("song_dadbattle", "Song: Dad Battle", 120),
			new Item("song_chopped", "Song: chopped", 100)
        ]}
    ];

    var tabIndex:Int = 0;
    var selected:Int = 0;

    // Coins
    var coins:Int = 0;

    // UI
    var dim:FlxSprite;
    var panel:FlxSprite;
    var title:FlxText;
    var help:FlxText;
    var coinsText:FlxText;
    var rows:Array<{caret:FlxText, line:FlxText}> = [];

    public function new() {
        super();
    }

    override function create():Void {
        // Background
        dim = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        dim.alpha = 0.6;
        add(dim);

        panel = new FlxSprite(140, 60).makeGraphic(FlxG.width - 280, FlxG.height - 120, 0xFF101018);
        panel.alpha = 0.95;
        add(panel);

        title = mkText("", 0, 80, 42, true);
        add(title);

        help = mkText("UP/DOWN select • ENTER buy • Q/E switch shop • TAB wardrobe • ESC back", 0, FlxG.height - 64, 18, true);
        add(help);

        coinsText = mkText("", 160, 130, 24, false);
        add(coinsText);

        loadProgress();
        rebuildRows(); // build rows for current tab
        refreshUI();

        super.create();
    }

    override function update(elapsed:Float):Void {
        super.update(elapsed);

        if (FlxG.keys.justPressed.UP) {
            selected = (selected - 1 + items().length) % items().length;
            playScroll();
            refreshUI();
        } else if (FlxG.keys.justPressed.DOWN) {
            selected = (selected + 1) % items().length;
            playScroll();
            refreshUI();
        } else if (FlxG.keys.justPressed.Q) {
            tabIndex = (tabIndex - 1 + shopTabs.length) % shopTabs.length;
            selected = 0;
            playScroll();
            rebuildRows();
            refreshUI();
        } else if (FlxG.keys.justPressed.E) {
            tabIndex = (tabIndex + 1) % shopTabs.length;
            selected = 0;
            playScroll();
            rebuildRows();
            refreshUI();
        } else if (FlxG.keys.justPressed.TAB) {
            // Open wardrobe
            FlxG.sound.play(Paths.sound("scrollMenu"), 0.7);
            MusicBeatState.switchState(new WardrobeState());
        } else if (FlxG.keys.justPressed.ENTER) {
            onBuy();
            refreshUI();
        } else if (FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.BACKSPACE) {
            // Exit to main menu
            FlxG.sound.play(Paths.sound("cancelMenu"), 0.8);
            MusicBeatState.switchState(new MainMenuState());
        }
    }

    // Current tab's item list
    inline function items():Array<Item> return shopTabs[tabIndex].items;

    // ───────────── Logic ─────────────
    function onBuy():Void {
        var it = items()[selected];
        var isOwned = getOwnedFlag(it.id);

        if (isOwned) {
            playCancel();
            return;
        }
        if (coins < it.price) {
            playCancel();
            return;
        }

        coins -= it.price;

        // Mark ownership based on type:
        if (StringTools.startsWith(it.id, "skin_char_")) {
            setOwnedFlag(it.id, true); // own_skin_char_<idSuffix>
        } else if (StringTools.startsWith(it.id, "skin_note_")) {
            setOwnedFlag(it.id, true); // own_skin_note_<idSuffix>
        } else if (StringTools.startsWith(it.id, "song_")) {
            var songId = it.id.substr("song_".length);
            Reflect.setField(FlxG.save.data, "own_song_" + songId, true);
        } else {
            // legacy/generic items
            Reflect.setField(FlxG.save.data, "own_" + it.id, true);
        }

        saveProgress();
        playConfirm();
    }

    // ───────── Persistence ─────────
    function loadProgress():Void {
        if (!FlxG.save.isBound) FlxG.save.bind("psych-save", "FNF");
        var savedCoins:Null<Int> = cast FlxG.save.data.shopCoins;
        coins = savedCoins != null ? savedCoins : 0;
    }

    function saveProgress():Void {
        FlxG.save.data.shopCoins = coins;
        FlxG.save.flush();
    }

    inline function getOwnedFlag(id:String):Bool {
        var key:String;
        if (StringTools.startsWith(id, "skin_char_")) key = "own_skin_char_" + id.substr("skin_char_".length);
        else if (StringTools.startsWith(id, "skin_note_")) key = "own_skin_note_" + id.substr("skin_note_".length);
        else if (StringTools.startsWith(id, "song_"))     key = "own_song_"     + id.substr("song_".length);
        else key = "own_" + id;
        var v:Dynamic = Reflect.field(FlxG.save.data, key);
        return (v is Bool) ? cast v : false;
    }

    inline function setOwnedFlag(id:String, val:Bool):Void {
        var key:String;
        if (StringTools.startsWith(id, "skin_char_")) key = "own_skin_char_" + id.substr("skin_char_".length);
        else if (StringTools.startsWith(id, "skin_note_")) key = "own_skin_note_" + id.substr("skin_note_".length);
        else key = "own_" + id;
        Reflect.setField(FlxG.save.data, key, val);
    }

    // ───────────── UI helpers ─────────────
    function rebuildRows():Void {
        // Clear existing rows
        for (r in rows) { remove(r.caret); remove(r.line); }
        rows.resize(0);

        var startY = 200;
        var list = items();
        for (i in 0...list.length) {
            var caret = mkText(" ", 180, startY + i * 56, 26, false);
            var line  = mkText("", 210, startY + i * 56, 26, false);
            add(caret); add(line);
            rows.push({caret: caret, line: line});
        }
    }

    function refreshUI():Void {
        // Header + coins
        title.text = 'SHOP — ' + shopTabs[tabIndex].name;
        title.x = (FlxG.width - title.width) * 0.5;

        coinsText.text = "Coins: " + coins;

        // List
        var list = items();
        for (i in 0...rows.length) {
            var it = list[i];
            var isOwned = getOwnedFlag(it.id);
            rows[i].caret.text = (i == selected) ? ">" : " ";
            rows[i].line.text = '${it.label}  -  ${it.price}';

            if (isOwned) {
                rows[i].line.color = 0xFF7CFC00; // green (owned)
            } else if (coins < it.price) {
                rows[i].line.color = 0xFFFF5A5A; // red (cannot afford)
            } else {
                rows[i].line.color = FlxColor.WHITE;
            }
        }
    }

    inline function mkText(txt:String, x:Float, y:Float, size:Int, centerX:Bool):FlxText {
        var t = new FlxText(x, y, 0, txt, size);
        t.scrollFactor.set();
        if (centerX) {
            t.alignment = CENTER;
            t.x = (FlxG.width - t.width) * 0.5;
        }
        return t;
    }

    inline function playScroll():Void { FlxG.sound.play(Paths.sound("scrollMenu"), 0.7); }
    inline function playConfirm():Void { FlxG.sound.play(Paths.sound("confirmMenu"), 0.8); }
    inline function playCancel():Void { FlxG.sound.play(Paths.sound("cancelMenu"), 0.8); }
}

// Simple item model
class Item {
    public var id:String;
    public var label:String;
    public var price:Int;
    public function new(id:String, label:String, price:Int) {
        this.id = id; this.label = label; this.price = price;
    }
}
