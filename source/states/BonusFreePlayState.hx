package states;

import flixel.FlxState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;

import states.FreePlayChoose;
import backend.ClientPrefs;

class BonusFreePlayState extends FlxState {
    override public function create():Void {
        super.create();

        var yScroll:Float = 0.25;
        var bg:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image('menuBG'));
        bg.antialiasing = ClientPrefs.data.antialiasing;
        bg.scrollFactor.set(0, yScroll);
        bg.setGraphicSize(Std.int(bg.width * 1.175));
        bg.updateHitbox();
        bg.screenCenter();
        add(bg);

        var title = new FlxText(0, 40, FlxG.width, "Bonus Freeplay Menu", 32);
        title.setFormat(null, 32, FlxColor.WHITE, "center");
        add(title);
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);

        if (FlxG.keys.justPressed.ESCAPE) {
            FlxG.sound.play(Paths.sound('cancelMenu'));
            FlxG.switchState(new FreePlayChoose());
        }
    }
}
