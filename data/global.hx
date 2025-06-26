import CSSScript;
import Type;


static var themes = [];

function postUpdate() {
    for (i in themes) {
        i.update();
    }
}

function focusGained() {
    for (i in themes) {
        i.reload();
    }
}

function preStateSwitch() {
    themes = [];
}
function postStateSwitch() {
    themes.push(new CSSScript(getStateName()));
}

static function addTheme(theme:CSSScript)
    themes.push(theme);


function getStateName():Void {
	var split:Array<String> = Type.getClassName(Type.getClass(FlxG.game._requestedState)).split('.');
	return split[split.length - 1];
}
