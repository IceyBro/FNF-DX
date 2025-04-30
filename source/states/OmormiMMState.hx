package states;

import flixel.FlxState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.text.FlxText;
import openfl.utils.Assets as OpenFLAssets;

class OmormiMMState extends FlxState
{
    var options:Array<String> = ['newgame', 'continue', 'back'];
    var menuSprites:Array<FlxSprite> = [];
    var selected:Int = 0;
    var logoSprites:Map<String, FlxSprite> = new Map();
    var handSprite:FlxSprite;

    override function create():Void
    {
        super.create();

        // ===== Add white background =====
        var whiteSquare = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.WHITE);
        add(whiteSquare);

        // ===== Load Logos =====
        var layers:Array<String> = ['Dude', 'omormi'];

        for (layerName in layers)
        {
            if (Paths.fileExists('images/' + layerName + '.png', TEXT))
            {
                var sprite = new FlxSprite();

                if (Paths.fileExists('images/' + layerName + '.xml', TEXT))
                {
                    sprite.frames = Paths.getSparrowAtlas(layerName);

                    if (sprite.frames != null && sprite.frames.frames.length > 0)
                    {
                        sprite.animation.addByPrefix('idle', layerName + ' idle', 12, true);
                        sprite.animation.play('idle');

                        sprite.origin.set(sprite.frameWidth / 2, sprite.frameHeight / 2);
                        sprite.centerOffsets();
                        sprite.antialiasing = true;
                    }
                    else
                    {
                        trace('⚠️ No frames found for ' + layerName + '. Using static image.');
                        sprite.loadGraphic(Paths.image(layerName));
                    }
                }
                else
                {
                    sprite.loadGraphic(Paths.image(layerName));
                }

                sprite.setGraphicSize(Std.int(sprite.width * 1.3), Std.int(sprite.height * 1.3));
                sprite.updateHitbox();
                sprite.x = (FlxG.width - sprite.width) / 2;

                logoSprites.set(layerName, sprite);
                add(sprite);
            }
            else
            {
                trace('⚠️ Layer not found: ' + layerName + '.png');
            }
        }

        // Position Omormi at top
        if (logoSprites.exists('omormi'))
        {
            var omormiSprite = logoSprites.get('omormi');
            omormiSprite.y = -10;
        }

        // Position Dude at bottom
        if (logoSprites.exists('Dude'))
        {
            var dudeSprite = logoSprites.get('Dude');
            dudeSprite.y = FlxG.height - dudeSprite.height + 5;
        }

        // ===== Load Sprite Buttons =====
        var totalWidth:Float = 0;
        var spacing:Float = 35;
        var buttonWidths:Array<Float> = [];

        // First pass: measure widths
        for (option in options)
        {
            var tempSprite = new FlxSprite(Paths.image(option));
            tempSprite.updateHitbox();
            buttonWidths.push(tempSprite.width);
            totalWidth += tempSprite.width;
        }
        totalWidth += spacing * (options.length - 1);

        var startX = (FlxG.width - totalWidth) / 2;
        var currentX = startX;

        for (i in 0...options.length)
        {
            var option = options[i];

            if (Paths.fileExists('images/' + option + '.png', TEXT))
            {
                var sprite = new FlxSprite(Paths.image(option));
                sprite.antialiasing = true;

                sprite.updateHitbox();

                sprite.x = currentX;
                sprite.y = FlxG.height - sprite.height + 50;

                currentX += sprite.width + spacing;

                menuSprites.push(sprite);
                add(sprite);
            }
            else
            {
                trace('⚠️ Menu sprite missing: ' + option + '.png');
            }
        }

        // ===== Add Red Hand Sprite =====
        handSprite = new FlxSprite();
        handSprite.loadGraphic(Paths.image("redhand"));
        handSprite.antialiasing = true;
        handSprite.updateHitbox(); // Ensure width/height are correct
        add(handSprite);

        updateSelection();

        // ===== Load Menu Music =====
        if (Paths.fileExists('music/RPGMenuTheme.ogg', TEXT))
        {
            FlxG.sound.music.stop();
            FlxG.sound.playMusic(Paths.music('RPGMenuTheme'), 1, true);
            trace('✅ Music loaded: RPGMenuTheme.ogg');
        }
        else
        {
            trace('⚠️ Music file not found: RPGMenuTheme.ogg');
        }
    }

    override function update(elapsed:Float):Void
    {
        super.update(elapsed);

        if (FlxG.keys.justPressed.LEFT)
        {
            selected = (selected - 1 + options.length) % options.length;
            FlxG.sound.play(Paths.sound("select"));
            updateSelection();
        }
        else if (FlxG.keys.justPressed.RIGHT)
        {
            selected = (selected + 1) % options.length;
            FlxG.sound.play(Paths.sound("select"));
            updateSelection();
        }
        else if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.SPACE)
        {
            handleSelection();
        }
    }

    function updateSelection():Void
    {
        if (menuSprites.length > selected)
        {
            var selectedButton = menuSprites[selected];
            handSprite.x = selectedButton.x - 5;
            handSprite.y = selectedButton.y + (selectedButton.height / 2) - (handSprite.height / 2);
        }
    }

    function handleSelection():Void
    {
        switch (selected)
        {
            case 0:
                FlxG.switchState(new PlayState());
            case 1:
                FlxG.sound.play(Paths.sound('cancel'));
            case 2:
                FlxG.sound.play(Paths.sound('cancel'));
                FlxG.sound.music.fadeOut(0.5, 0);
                FlxG.switchState(new MainMenuState());
        }
    }

    override function destroy():Void
    {
        for (sprite in menuSprites)
        {
            if (sprite != null)
            {
                sprite.kill();
                remove(sprite);
            }
        }
        menuSprites = [];

        FlxG.sound.music.stop();
        super.destroy();
    }
}
