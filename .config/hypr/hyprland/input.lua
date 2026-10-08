local vars = require("variables")

hl.config({
    input = {
        kb_layout          = "us",
        kb_variant         = "altgr-intl",
        numlock_by_default = false,
        repeat_delay       = 300,
        repeat_rate        = 35,
        focus_on_close     = 1,
        sensitivity        = 0.15,
        scroll_factor      = 2.0,

        touchpad           = {
            natural_scroll       = true,
            disable_while_typing = vars.touchpadDisableTyping,
            scroll_factor        = vars.touchpadScrollFactor,
            drag_lock            = 1,
        },
    },

    binds = {
        scroll_event_delay = 0,
    },

    cursor = {
        hotspot_padding = 1,
    },
})
