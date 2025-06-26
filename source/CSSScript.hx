import Reflect;

class CSSScript {

    public var inch:Int = 96;
    public var pt:Float = inch * (1/72);
    public var pc:Int = 12;
    public var cm:Float = inch/2.54;
    public var mm:Float = cm/10;

    public var variables:Map<String, Map<String, Dynamic>> = [];

    public var cssScript:String;
    public var cssPath:String;

    public function new(cssPath:String) {
        this.cssPath = cssPath;
        if (Assets.exists(Paths.file('data/themes/' + cssPath + '.css'))) {
            cssScript = Assets.getText(Paths.file('data/themes/' + cssPath + '.css'));
        } else {
            trace("Failed to find theme \"" + cssPath + "\"");
        }
        if (cssScript == null) return;
        parseScript();
    }

    public function parseCSSVariable(variable:Dynamic) {
        if (StringTools.startsWith(variable, "#")) {
            return FlxColor.fromString(variable);
        } else if (StringTools.endsWith(variable, "px")) {
            return Std.parseFloat(StringTools.replace(variable, "px", ""));
        } else if (StringTools.endsWith(variable, "in")) {
            return Std.parseFloat(StringTools.replace(variable, "in", "")) * inch;
        } else if (StringTools.endsWith(variable, "pt")) {
            return Std.parseFloat(StringTools.replace(variable, "pt", "")) * pt;
        } else if (StringTools.endsWith(variable, "pc")) {
            return Std.parseFloat(StringTools.replace(variable, "pc", "")) * pc;
        } else if (StringTools.endsWith(variable, "cm")) {
            return Std.parseFloat(StringTools.replace(variable, "cm", "")) * cm;
        } else if (StringTools.endsWith(variable, "mm")) {
            return Std.parseFloat(StringTools.replace(variable, "mm", "")) * mm;
        }
        variable = StringTools.replace(variable, 'screenWidth', FlxG.width);
        variable = StringTools.replace(variable, 'screenHeight', FlxG.height);
        variable = StringTools.replace(variable, '"', "");
        variable = StringTools.replace(variable, '\\n', "\n");
        return variable;
    }

    public function reload() { // if you put this in update it WILL lag (prolly)
        cssScript = Assets.getText(Paths.file('data/themes/' + cssPath + '.css'));
        if (cssScript == null) return;
        parseScript();
    }

    public function parseScript() {
        var baseScript = "";
        for (i in cssScript.split("\n")) {
            baseScript += (StringTools.trim(i));
        }
        //baseScript = StringTools.replace(baseScript, "", "");
        baseScript = StringTools.replace(baseScript, "\t", "");
        var splitScript = baseScript.split("");

        var withinObject:Bool = false;

        var colonToggle:Bool = false;

        var variableList = [];
        var values = [];
        var currentObjectName:String = "";
        var currentVariable:String = "";
        var currentValue:String = "";

        for (i in splitScript) {
            if (i == "}") {
                var currentData:Map<String, Dynamic> = [];
                for (index=>variable in variableList) {
                    currentData.set(StringTools.trim(variable), parseCSSVariable(StringTools.trim(values[index])));
                }
                variables.set(StringTools.trim(currentObjectName), currentData);
                currentObjectName = "";
                currentVariable = "";
                currentValue = "";
                withinObject = false;
                continue;
            }
            if (i == "{") {
                variableList = [];
                values = [];
                withinObject = true;
            }
            if (!withinObject) {
                currentObjectName += i;
            } else if (i != "{") {
                if (i == ":") colonToggle = !colonToggle;
                if (i == ";") colonToggle = false;
                if (colonToggle) {
                    if (i != ":") {
                        currentValue += i;
                    }
                } else {
                    if (i == ";") {
                        variableList.push(currentVariable);
                        values.push(currentValue);
                        currentVariable = "";
                        currentValue = "";
                    } else {
                        currentVariable += i;
                    }
                }
            }
        }
    }

    public function applyCssToObj(obj, param, ?alignType) {
        if (obj.updateHitbox != null)
            obj.updateHitbox();
        if (obj.offset != null) {
            obj.offset.x = 0;
            obj.offset.y = 0;
            obj.offset.x -= param.get("margin-left") ?? 0;
            obj.offset.x += param.get("margin-right") ?? 0;
            obj.offset.y -= param.get("margin-top") ?? 0;
            obj.offset.y += param.get("margin-bottom") ?? 0;
        }
        if (obj.text != null) {
            obj.text = param.get("content") ?? obj.text;
        }

        if (obj.loadGraphic != null) {
            if (param.get("src") != null) {
                obj.loadGraphic(Paths.image(param.get("src")));
            }
        }

        if (obj.color != null) {
            obj.color = param.get("color") ?? obj.color;
        }

        if (obj.fieldWidth != null) {
            obj.fieldWidth = param.get("max-width") ?? obj.fieldWidth;
        }

        if (param.get("align-" + (alignType ?? 'self')) != null) {
            if (obj.alignment != null) {
                obj.alignment = param.get("align-" + (alignType ?? 'self'));
            } else {
                switch (param.get("align-" + (alignType ?? 'self'))) {
                    case "left":
                        obj.x = 0;
                    case "center":
                        obj.screenCenter(FlxAxes.X);
                    case "right":
                        obj.x = FlxG.width - obj.width;
                }
            }
        }
        if (obj.members != null) {
            for (i in obj.members) {
                applyCssToObj(i, param, "items");
            }
        }
    }

    public function update() {
        for (key in variables.keys()) {
            var param = variables.get(key);
            var obj = Reflect.field(FlxG.state, key);
            if (obj != null) {
                applyCssToObj(obj, param);
            }
        }
    }

    public var getObj = variables.get;
}