package options;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import backend.MusicBeatState;
import states.MainMenuState;
import states.CreditsState;
import states.PlayState;
import backend.ClientPrefs;
import backend.Paths;
import backend.StageData;
import backend.Language;
import objects.Alphabet;

class OptionsState extends MusicBeatState
{
    var options:Array<String> = [
        'Note Colors',
        'Controls',
        'Adjust Delay and Combo',
        'Graphics',
        'Visuals',
        'Gameplay',
        'Credits',
        #if TRANSLATIONS_ALLOWED 'Language' #end
    ];

    private var grpOptions:FlxGroup;
    private static var curSelected:Int = 0;
    public static var onPlayState:Bool = false;

    /* ---------- sub-state router ---------- */
    function openSelectedSubstate(label:String)
    {
        switch (label)
        {
            case 'Note Colors':
                openSubState(new options.NotesColorSubState());
            case 'Controls':
                openSubState(new options.ControlsSubState());
            case 'Graphics':
                openSubState(new options.GraphicsSettingsSubState());
            case 'Visuals':
                openSubState(new options.VisualsSettingsSubState());
            case 'Gameplay':
                openSubState(new options.GameplaySettingsSubState());
            case 'Adjust Delay and Combo':
                MusicBeatState.switchState(new options.NoteOffsetState());
            case 'Language':
                #if TRANSLATIONS_ALLOWED
                openSubState(new options.LanguageSubState());
                #end
            case 'Credits':
                FlxG.switchState(new CreditsState());
        }
    }

    var selectorLeft:Alphabet;
    var selectorRight:Alphabet;

    override function create()
    {
        #if DISCORD_ALLOWED
        DiscordClient.changePresence("Options Menu", null);
        #end

        var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
        bg.antialiasing = ClientPrefs.data.antialiasing;
        bg.color = FlxColor.fromRGB(234, 113, 253);
        bg.screenCenter();
        add(bg);

        grpOptions = new FlxGroup();
        add(grpOptions);

        for (i => opt in options)
        {
            var txt:Alphabet = new Alphabet(0, 0, Language.getPhrase('options_$opt', opt), true);
            txt.screenCenter();
            txt.y += (92 * (i - (options.length / 2))) + 45;
            grpOptions.add(txt);
        }

        selectorLeft  = new Alphabet(0, 0, '>', true);
        selectorRight = new Alphabet(0, 0, '<', true);
        add(selectorLeft);
        add(selectorRight);

        changeSelection();
        ClientPrefs.saveSettings();
        super.create();
    }

    override function closeSubState()
    {
        super.closeSubState();
        ClientPrefs.saveSettings();
        #if DISCORD_ALLOWED
        DiscordClient.changePresence("Options Menu", null);
        #end
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if (controls.UI_UP_P)   changeSelection(-1);
        if (controls.UI_DOWN_P) changeSelection(1);

        if (controls.BACK)
        {
            FlxG.sound.play(Paths.sound('cancelMenu'));
            if (onPlayState)
            {
                StageData.loadDirectory(PlayState.SONG);
                LoadingState.loadAndSwitchState(new PlayState());
                FlxG.sound.music.volume = 0;
            }
            else
            {
                MusicBeatState.switchState(new MainMenuState());
            }
        }
        else if (controls.ACCEPT) openSelectedSubstate(options[curSelected]);
    }

    /* ---------- selection helpers ---------- */
    function changeSelection(change:Int = 0)
    {
        curSelected = FlxMath.wrap(curSelected + change, 0, options.length - 1);

        var i:Int = 0;
        for (item in grpOptions)
        {
            var txt:Alphabet = cast item;          // we know it’s only Alphabet objects
            txt.targetY = i - curSelected;
            txt.alpha   = (txt.targetY == 0) ? 1.0 : 0.6;

            if (txt.targetY == 0)
            {
                selectorLeft.x  = txt.x - 63;
                selectorLeft.y  = txt.y;
                selectorRight.x = txt.x + txt.width + 15;
                selectorRight.y = txt.y;
            }
            i++;
        }
        FlxG.sound.play(Paths.sound('scrollMenu'));
    }

    override function destroy()
    {
        ClientPrefs.loadPrefs();
        super.destroy();
    }
}