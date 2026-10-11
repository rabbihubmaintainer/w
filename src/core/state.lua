-- language: Lua, file: src/core/state.lua, target: Roblox Executor
-- Global runtime state, drawing pools, key bindings, and theme definitions

return function(ctx)
    local shared = {
        is_unloading = false,
        on_teleport_setup = false,
        on_teleport_connection = nil,
        drawing_containers = {
            menu = {},
            notification = {},
            esp = {},
            status = {},
        },
        connections = {},
        hidden_connections = {},
        blatant_features = {
            "flight", "better_flight", "no_fall", "no_killbrick", "auto_bag", 
            "NoStun", "PerfloraTeleport", "parry_ignore_visibility", "forcefield", 
            "anti_globus", "fling", "loop_orderly", "start_path", "test_path", "enable_aa_bypass"
        },
        blatant_toggles = {},
        theme = {
            inline = Color3.fromRGB(3, 3, 3),
            dark = Color3.fromRGB(24, 24, 24),
            text = Color3.fromRGB(155, 155, 155),
            section = Color3.fromRGB(60, 60, 60),
            accent = Color3.fromRGB(255, 0, 0),
        },
        accents = {},
        moveKeys = {
            ["Movement"] = {
                ["Up"] = "Up",
                ["Down"] = "Down"
            },
            ["Action"] = {
                ["Left"] = "Left",
                ["Right"] = "Right"
            }
        },
        allowedKeyCodes = {
            "Q","W","E","R","T","Y","U","I","O","P","A","S","D","F","G","H","J","K","L","Z","X","C","V","B","N","M",
            "One","Two","Three","Four","Five","Six","Seven","Eight","Nine","Zero",
            "F1","F2","F3","F4","F5","F6","F7","F8","F9","F10","F11","F12",
            "KeypadOne","KeypadTwo","KeypadThree","KeypadFour","KeypadFive","KeypadSix","KeypadSeven","KeypadEight","KeypadNine","KeypadZero",
            "KeypadPeriod","KeypadDivide","KeypadMultiply","KeypadMinus","KeypadPlus","KeypadEnter",
            "Insert","Tab","Home","End","LeftAlt","LeftControl","LeftShift","RightAlt","RightControl","RightShift","CapsLock","Return","Up","Down","Left","Right"
        },
        allowedInputTypes = {"MouseButton1", "MouseButton2", "MouseButton3"},
        shortenedInputs = {
            ["LeftControl"] = 'left control',
            ["RightControl"] = 'right control',
            ["LeftShift"] = 'left shift',
            ["RightShift"] = 'right shift',
            ["Backquote"] = "grave",
            ["Tilde"] = "~",
            ["At"] = "@",
            ["Hash"] = "#",
            ["Dollar"] = "$",
            ["Percent"] = "%",
            ["Caret"] = "^",
            ["Ampersand"] = "&",
            ["Asterisk"] = "*",
            ["LeftParenthesis"] = "(",
            ["RightParenthesis"] = ")",
            ["Underscore"] = '_',
            ["Minus"] = '-',
            ["Plus"] = '+',
            ["Period"] = '.',
            ["Slash"] = '/',
            ["BackSlash"] = '\\',
            ["Question"] = '?',
            ["PageUp"] = "pgup",
            ["PageDown"] = "pgdwn",
            ["Comma"] = ",",
            ["Semicolon"] = ",",
            ["Colon"] = ":",
            ["GreaterThan"] = ">",
            ["LessThan"] = "<",
            ["LeftBracket"] = "[",
            ["RightBracket"] = "]",
            ["LeftCurly"] = "{",
            ["RightCurly"] = "}",
            ["Pipe"] = "|",
            ["NumLock"] = "num lock",
            ["KeypadNine"] = "num 9",
            ["KeypadEight"] = "num 8",
            ["KeypadSeven"] = "num 7",
            ["KeypadSix"] = "num 6",
            ["KeypadFive"] = "num 5",
            ["KeypadFour"] = "num 4",
            ["KeypadThree"] = "num 3",
            ["KeypadTwo"] = "num 2",
            ["KeypadOne"] = "num 1",
            ["KeypadZero"] = "num 0",
            ["KeypadMultiply"] = "num multiply",
            ["KeypadDivide"] = "num divide",
            ["KeypadPeriod"] = "num decimal",
            ["KeypadPlus"] = "num plus",
            ["KeypadMinus"] = "num sub",
            ["KeypadEnter"] = "num enter",
            ["KeypadEquals"] = "num equals",
            ["MouseButton1"] = 'mouse1',
            ["MouseButton2"] = 'mouse2',
            ["MouseButton3"] = 'mouse3',
        },
        colors = {
            Color3.fromRGB(255, 0, 0), Color3.fromRGB(255, 100, 0), Color3.fromRGB(255, 200, 0), Color3.fromRGB(210, 255, 0),
            Color3.fromRGB(110, 255, 0), Color3.fromRGB(10, 255, 0), Color3.fromRGB(0, 255, 90), Color3.fromRGB(0, 255, 190),
            Color3.fromRGB(0, 220, 255), Color3.fromRGB(0, 120, 255), Color3.fromRGB(0, 20, 255), Color3.fromRGB(80, 0, 255),
            Color3.fromRGB(180, 0, 255), Color3.fromRGB(255, 0, 230), Color3.fromRGB(255, 0, 130), Color3.fromRGB(255, 255, 255),
            Color3.fromRGB(0, 0, 0)
        },
        windowActive = true,
        notifications = {},
    }

    ctx.shared = shared
    ctx.watched_guis = {}
    ctx.hooked_connections = {}
    ctx.playerLabels = {}
    ctx.streamer_connections = {}
    ctx.disabled_connections = {}
    ctx.transparent_parts = {}
    ctx.original_names = {}
    ctx.original_days = {}
    ctx.original_materials = {}
    ctx.mana_overlay = {}

    return shared
end
