local style = {
    label = {
        color = "#9f9f9f",
        textAlign = "center",
        textVerticalAlign = "middle",
    },
    button = {
        backgound_color = "#323232",
        color = "#9f9f9f",
        border_radius = 0,
        border_color = "#3c3c3c",
        border_width = 1,
        textAlign = "center",
        textVerticalAlign = "middle",
        hover = {
            backgound_color = "#282828",
            color = "#cccccc",
        },
        focus = {
            backgound_color = "#232323",
            color = "#cccccc",
            -- color = "#eeeeee",
        },
    },
    selection = {
        backgound_color = "#323232",
        color = "#9f9f9f",
        border_radius = 0,
        border_color = "#3c3c3c",
        border_width = 0,
        textAlign = "center",
        textVerticalAlign = "middle",
        hover = {
            backgound_color = "#282828",
            color = "#cccccc",
        },
        focus = {
            backgound_color = "#232323",
            color = "#cccccc",
            -- color = "#eeeeee",
        },
    },
    edit = {
        backgound_color = "#262626",
        border_radius = 0,
        border_color = "#383838",
        border_width = 1,
        color = "#9f9f9f",
        textAlign = "left",
        textVerticalAlign = "middle",
        focus = {
            color = "#eeeeee",
        },
    },
    window = {
        color = "#9f9f9f",
        border_radius = 2,
        border_color = "#3c3c3c",
        border_width = 2,
        backgound_color = "#2d2d2d",
        padding_top = 8,
        padding_bottom = 8,
        padding_left = 8,
        padding_right = 8,
        elementSpacing = 2,
        lineSpacing = 4,
        title_background_color = "#282828",
        noTitleBar = false,
        title_height = 30,
        scrollX = 0,
        scrollY = 0,
        isContainer = true,
        textAlign = "left",
        textVerticalAlign = "middle",
        flags = {},
    },
    group = {
        color = "#9f9f9f",
        border_radius = 2,
        border_color = "#3c3c3c",
        border_width = 1,
        backgound_color = "#2d2d2d",
        padding_top = 4,
        padding_bottom = 4,
        padding_left = 4,
        padding_right = 4,
        elementSpacing = 2,
        lineSpacing = 4,
        title_background_color = "#282828",
        noTitleBar = false,
        title_height = 26,
        scrollX = 0,
        scrollY = 0,
        isContainer = true,
        textAlign = "center",
        textVerticalAlign = "middle",
        flags = {},
    }
}

return style;