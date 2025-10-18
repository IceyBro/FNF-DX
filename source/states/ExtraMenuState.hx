package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.tweens.FlxEase;
import backend.MusicBeatState;
import backend.Song;
import backend.Difficulty;
import backend.Paths;
import states.PlayState;
import states.LoadingState;
import states.MainMenuState;
import StringTools;

class ExtraMenuState extends MusicBeatState
{
    /* ----------  visual members (same as FreeplayState) ---------- */
    var curSelected:Int = 0;
    var grpSongs:FlxTypedGroup<ExtraMenuItem>;   // ← FIXED
    var scoreText:FlxText;
    var diffText:FlxText;
    var bg:FlxSprite;
    var intendedColor:FlxColor;
    var colorTween:FlxTween;

    /* ----------  song list (only purchased ones) ---------- */
    var songs:Array<String> = [];

    override public function create():Void
    {
        super.create();

        /* ---------- basic camera / bg ---------- */
        bg = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
        bg.scale.set(FlxG.width, FlxG.height);
        bg.screenCenter();
        add(bg);

        /* ---------- fetch owned songs ---------- */
        if (!FlxG.save.isBound) FlxG.save.bind("psych-save", "FNF");

        for (field in Reflect.fields(FlxG.save.data))
        {
            if (StringTools.startsWith(field, "own_song_"))
            {
                var id = field.substr("own_song_".length);
                if (Reflect.field(FlxG.save.data, field) == true)
                    songs.push(id);
            }
        }
        songs.sort(Reflect.compare);

        /* ---------- nothing bought -> show stub ---------- */
        if (songs.length == 0)
        {
            var t = new FlxText(0, 0, 0, "No purchased songs yet!", 32);
            t.screenCenter();
            add(t);
            return;
        }

        /* ---------- create song items ---------- */
        grpSongs = new FlxTypedGroup<ExtraMenuItem>();   // ← FIXED
        add(grpSongs);

        var yPos:Float = 80;
        for (i in 0...songs.length)
        {
            var item = new ExtraMenuItem(songs[i], yPos);   // ← FIXED
            grpSongs.add(item);
            yPos += 60;
        }

        /* ---------- score & diff text ---------- */
        scoreText = new FlxText(FlxG.width * 0.35, FlxG.height - 80, 0, "", 20);
        scoreText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, LEFT);
        add(scoreText);

        diffText = new FlxText(FlxG.width * 0.7, FlxG.height - 80, 0, "", 20);
        diffText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, RIGHT);
        add(diffText);

        changeSelection(0);
    }

    /* ---------------------------------------------------------- */
    /*  INPUT  (Psych 1.0.3 style)                              */
    /* ---------------------------------------------------------- */
    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        if (songs.length == 0)
        {
            if (FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.BACKSPACE)
                MusicBeatState.switchState(new MainMenuState());
            return;
        }

        var up   = FlxG.keys.justPressed.UP   || controls.UI_UP_P;
        var down = FlxG.keys.justPressed.DOWN || controls.UI_DOWN_P;

        if (up)   changeSelection(-1);
        if (down) changeSelection( 1);

        var left  = FlxG.keys.justPressed.LEFT  || controls.UI_LEFT_P;
        var right = FlxG.keys.justPressed.RIGHT || controls.UI_RIGHT_P;

        if (left)  changeDiff(-1);
        if (right) changeDiff( 1);

        if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.SPACE)
            playSelectedSong();

        if (FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.BACKSPACE)
            MusicBeatState.switchState(new MainMenuState());
    }

    /* ---------------------------------------------------------- */
    /*  SELECTION / DIFFICULTY / PLAY                             */
    /* ---------------------------------------------------------- */
    function changeSelection(delta:Int):Void
    {
        curSelected += delta;
        curSelected = FlxMath.wrap(curSelected, 0, songs.length - 1);

        for (i in 0...grpSongs.length)
        {
            var item = grpSongs.members[i];
            var targetY:Float = 80 + (i - curSelected) * 60;

            /* 1.0.3-safe tween (slide whole sprite) */
            FlxTween.tween(item, {y: targetY}, 0.15, {ease: FlxEase.quadOut});

            item.alpha = 1 - Math.abs(i - curSelected) * 0.15;
            item.scale.set(1 - Math.abs(i - curSelected) * 0.05,
                           1 - Math.abs(i - curSelected) * 0.05);
        }

        updateScoreText();
        updateDiffText();
        intendedColor = getSongColor();
        if (colorTween != null) colorTween.cancel();
        colorTween = FlxTween.color(bg, 0.4, bg.color, intendedColor);
    }

    function changeDiff(delta:Int):Void
    {
        var list = Difficulty.list;
        var cur  = Difficulty.getFilePath();
        var idx  = list.indexOf(cur);
        if (idx < 0) idx = 0;
        idx += delta;
        idx = FlxMath.wrap(idx, 0, list.length - 1);

        /* 1.0.3 has no setter – we change the save-key directly */
        FlxG.save.data.difficulty = list[idx];

        updateScoreText();
        updateDiffText();
    }

    function updateScoreText():Void
    {
        var song = songs[curSelected];
        var diff = Difficulty.getFilePath();
        var key  = 'score_${song}${diff}';
        var score:Int = FlxG.save.data.exists(key) ? FlxG.save.data.get(key) : 0;
        scoreText.text = 'Personal Best: $score';
    }

    function updateDiffText():Void
    {
        diffText.text = Difficulty.getString();
    }

    function getSongColor():FlxColor
    {
        var song = songs[curSelected];
        var raw:Dynamic = Song.loadFromJson(song, song);
        return raw == null ? FlxColor.GRAY : FlxColor.fromRGB(raw.songColor[0],
                                                               raw.songColor[1],
                                                               raw.songColor[2]);
    }

    function playSelectedSong():Void
    {
        var song = songs[curSelected];
        var diff = Difficulty.getFilePath();
        Song.loadFromJson(song + diff, song);
        FlxG.sound.music.stop();
        LoadingState.prepareToSong();
        LoadingState.loadAndSwitchState(new PlayState(), false, false);
    }
}

/* -------------------------------------------------------------- */
/*  ExtraMenuItem : simple capsule                               */
/* -------------------------------------------------------------- */
class ExtraMenuItem extends FlxSprite        // ← FIXED
{
    public var targetY:Float = 0;

    public function new(song:String, startY:Float)
    {
        super(40, startY);
        makeGraphic(Std.int(FlxG.width - 80), 50, FlxColor.TRANSPARENT);

        /* draw grey box */
        var box = new FlxSprite(2, 2).makeGraphic(Std.int(width - 4), Std.int(height - 4), 0xFF444444);
        box.drawFrame();
        graphic.bitmap.draw(box.graphic.bitmap, new openfl.geom.Matrix(1, 0, 0, 1, 2, 2));

        /* draw text */
        var txt = new FlxText(20, 12, 0, song, 24);
        txt.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, LEFT);
        txt.drawFrame();
        graphic.bitmap.draw(txt.graphic.bitmap, new openfl.geom.Matrix(1, 0, 0, 1, 20, 12));
    }
}