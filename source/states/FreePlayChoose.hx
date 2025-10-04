package states;

import flixel.FlxState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.graphics.FlxGraphic; // Needed for graphic.height

import backend.ClientPrefs;
import states.FreeplayState;
import states.BonusFreePlayState;
import states.BonusWeekState;
import states.MainMenuState;

class FreePlayChoose extends FlxState {
    var buttonSprites:Array<FlxSprite> = [];
    var buttonStates:Array<Class<FlxState>> = [];
    var curSelected:Int = 0;

    override public function create():Void {
        super.create();

        // Background
        var bg:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image('menuBG'));
        bg.antialiasing = ClientPrefs.data.antialiasing;
        bg.scrollFactor.set(0, 0.25);
        bg.setGraphicSize(Std.int(bg.width * 1.175));
        bg.updateHitbox();
        bg.screenCenter();
        add(bg);

        // Menu sprite options
        var buttonY = 50;
        var spacing = 225;

        var options:Array<Dynamic> = [
            {image: "button_story", state: FreeplayState},
            {image: "button_bonus", state: BonusFreePlayState},
            {image: "button_weeks", state: BonusWeekState}
        ];

        for (i in 0...options.length) {
            var btn:FlxSprite = new FlxSprite();

            // Load full graphic and calculate frame height (assuming 2 vertical frames)
            var fullGraphicPath = Paths.image("mainmenu/" + options[i].image);
            var graphic:FlxGraphic = FlxG.bitmap.add(fullGraphicPath);
            var frameHeight:Int = Std.int(graphic.height / 2);

            // Load sprite with correct frame size
            btn.loadGraphic(fullGraphicPath, true, graphic.width, frameHeight);
            btn.animation.add("idle", [0]);
            btn.animation.add("selected", [1]);
            btn.animation.play("idle");

            // Align horizontally and space vertically
            btn.screenCenter(X);
            btn.y = buttonY + i * spacing;

            add(btn);
            buttonSprites.push(btn);
            buttonStates.push(options[i].state);
        }

        updateSelection();
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);

        if (FlxG.keys.justPressed.UP) {
            curSelected = (curSelected - 1 + buttonSprites.length) % buttonSprites.length;
            updateSelection();
            FlxG.sound.play(Paths.sound('scrollMenu'));
        }

        if (FlxG.keys.justPressed.DOWN) {
            curSelected = (curSelected + 1) % buttonSprites.length;
            updateSelection();
            FlxG.sound.play(Paths.sound('scrollMenu'));
        }

        if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.SPACE) {
            FlxG.sound.play(Paths.sound('confirmMenu'));
            FlxG.switchState(Type.createInstance(buttonStates[curSelected], []));
        }

        if (FlxG.keys.justPressed.ESCAPE) {
            FlxG.sound.play(Paths.sound('cancelMenu'));
            MusicBeatState.switchState(new MainMenuState());
        }
    }

    function updateSelection():Void {
        for (i in 0...buttonSprites.length) {
            if (i == curSelected)
                buttonSprites[i].animation.play("selected");
            else
                buttonSprites[i].animation.play("idle");
        }
    }
}
