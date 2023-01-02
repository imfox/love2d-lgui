local style = require "style"

local ui = require("LGUI").new();

local title = { text = "input title." }
local id = { text = "10000" }
local name = { text = "fox~" }
local desc = { text = "hello imlgui." }

local sw = true;

local selectBtn = { text = "switch button", selected = false }
local selectIndex = 0;

local win = { title = "Question", width = 500, height = 500, x = 80, y = 40 };

local btns = {};

---@generic T
---@param object T
---@param base any
---@return T
local function clone(object, base)
    local lookup_table = base or {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for key, value in pairs(object) do
            new_table[_copy(key)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end

local bardata = { { text = "File", selected = false, type = "menu" }, { text = "b", selected = false, type = "menu" }, { text = "Question", selected = false }, { text = "ID Card", selected = false } };

local addMenus = {
    {
        text = "common",
        sub = {
            { text = "coin", },
            { text = "gold", },
            { text = "silver", },
            { text = "exp", },
        }
    },
    { text = "all", },
    { text = "item", },
    { text = "staff", },
    { text = "title" },
    {
        text = "equip",
        sub = {
            { text = "all", },
            {
                text = "weapon",
                sub = {
                    { text = "all", },
                    {
                        text = "jobA",
                        sub = {
                            { text = "all", },
                            { text = "weapon type 1", },
                            { text = "weapon type 2", },
                            { text = "weapon type 3", },
                            { text = "weapon type 4", },
                        }
                    },
                    { text = "jobB" },
                    { text = "jobC" },
                }
            },
            { text = "equip 2", },
            { text = "equip 3", },
            { text = "equip 4", },
            { text = "equip 5", },
            { text = "euqip 6", },
        },
    },
    {
        text = "other",
        sub = {
            { text = "all" },
            {
                text = "other 1",
                sub = {
                    { text = "all" },
                    { text = "jobA" },
                    { text = "jobB" },
                    { text = "jobC" },
                }
            },
            { text = "other 2" },
            { text = "other 3" },
            { text = "other 4" },
            { text = "other 5" },
            { text = "other 6" },
        },
    },
}

local menubardata = clone(addMenus);

local bst = { hover = { backgound_color = "#ffffff33", color = "#ffffff", border_radius = 3 }, focus = { backgound_color = "#ffffff33", color = "#ffffff", border_radius = 3 }, border_radius = 3 };
local bbst = { border_width = 1, lineSpacing = 0, padding_top = 4, padding_bottom = 4, padding_left = 4, padding_right = 4, flags = { ui.Flags.WindowFlags_AlwaysAutoResize, ui.Flags.WindowFlags_NoTitleBar } };
function menu(menuData, isOpen, callback, x)
    local j = 0;
    local function menus(ms, is, func, i)
        j = j + 1;
        for index, value in ipairs(ms) do
            if value.type == "input" then
                if value.body then
                    value.body();
                end
            elseif ui:menu(value) then
                -- func(value);
                if value.sub then
                    if ui:menuBegin("value" .. j, 0, 0, 120, 0, bbst) then
                        ui:layoutRow(22, { 100 });
                        menus(value.sub, true, func, i + 1);
                        ui:menuEnd();
                    end
                end
            end
        end
    end
    if ui:menuBegin("ms0", x or 0, 30, 100, 0, bbst) then
        ui:layoutRow(22, { 70, 30 });

        ui:edit(name);
        ui:button("ok", { margin_right = 2 });
        ui:blankline(2);

        ui:layoutRow(22, { 100 });
        menus(menuData, isOpen, callback, 0);

        ui:blankline(2)
        if ui:button("close") then
            ui:closeCurrentMenu();

        end
        ui:menuEnd();
    end
end

function love.update(dt)
    if ui:frameBegin() then

        if ui:windowBegin({ title = "TitleBar", x = 0, y = 0, width = love.graphics.getWidth(), height = 32 }, { border_width = 1, elementSpacing = 5, border_radius = 0, padding_top = 3, padding_bottom = 0, flags = { ui.Flags.WindowFlags_NoTitleBar, ui.Flags.WindowFlags_NoMove } }) then
            ui:layoutRow(22, { 80, 80, 80, 80, 80 });

            for index, value in ipairs(bardata) do
                if value.type == "menu" then
                    ui:mainMenu(value, {});
                else
                    ui:selection(value);
                end

                if value.selected then
                    if index == 1 then
                        menu(addMenus, nil, nil, 0);
                    elseif index == 2 then
                        menu(menubardata, nil, nil, 100);
                    end
                end
            end

            ui:windowEnd();
        end

        if bardata[3].selected then
            if ui:windowBegin(win, { flags = {} }) then
                ui:layoutRow(24, { 50, -1, 60 });
                ui:label("title");
                ui:edit(title)
                if ui:button("publis") then
                    print("publis.")
                end
                ui:layoutRow(450, { 0.4, 0.2, 0.4 });
                if ui:groupBegin("left group", { textAlign = ui.TextAlign.left }) then
                    ui:layoutRow();
                    ui:label("auto size.");

                    ui:layoutRow(12, { 0.6, 0.2, 0.2 });
                    ui:label("60%");
                    ui:label("20%");
                    ui:label("20%");

                    ui:layoutRow(20, { 40, 0.2, -1 })
                    ui:label("40px");
                    ui:label("20%");
                    ui:label("other");

                    ui:layoutRow(20, { -1, 80, -1 })
                    ui:label("other");
                    ui:label("80px");
                    ui:label("other");

                    ui:layoutRow(20, { -0.2, 0.1, -1 })
                    ui:label("-20%");
                    ui:label("10%");
                    ui:label("other");

                    ui:layoutRow(80, 1);
                    if ui:groupBegin("group..", { margin_left = 10, flags = { ui.Flags.WindowFlags_NoTitleBar } }) then
                        ui:layoutRow();
                        ui:label("margin_left 10px")

                        ui:layoutRow(12, { 30, 0.2, 0.6 });
                        ui:label("30px");
                        ui:label("20%");
                        ui:label("60%");
                        ui:layoutRow(24, 1);
                        ui:selection(selectBtn)
                        ui:groupEnd();
                    end
                    if ui:groupBegin("group2..", { margin_right = 40, flags = { ui.Flags.WindowFlags_NoTitleBar } }) then
                        ui:layoutRow();
                        ui:label("margin_left 40px")
                        ui:groupEnd();
                    end
                    if ui:groupBegin("margin_top 10px", { margin_top = 10, textAlign = ui.TextAlign.right }) then
                        ui:layoutRow();
                        ui:label("content.")
                        ui:groupEnd();
                    end
                    ui:groupEnd();
                end
                if ui:groupBegin("a", { border_width = 0, flags = { ui.Flags.WindowFlags_NoTitleBar } }) then
                    ui:layoutRow();
                    if ui:button("hide or show") then
                        sw = not sw;
                    end
                    if sw then
                        ui:label("center");
                        ui:label("group");

                        ui:layoutRow(100);
                        if ui:groupBegin("group", { backgound_color = "#333333", border_width = 0, flags = { ui.Flags.WindowFlags_NoTitleBar } }) then
                            ui:layoutRow();
                            ui:label("no border.");
                            ui:label("no titlebar.");
                            ui:label("background.");
                            ui:groupEnd();
                        end

                        ui:layoutRow();
                        ui:label("group bottom gfklsjfkldsjflkjsl")

                        ui:label("button.");
                        ui:button("blue", { backgound_color = "#4169E1", color = "#ffffff", hover = { backgound_color = "#0000ff" }, focus = { backgound_color = "#0000ff" } });
                        ui:button("red", { backgound_color = "#DC143C", color = "#ffffff", hover = { backgound_color = "#ff0000", color = "#000000" }, focus = { backgound_color = "#ff0000" } });
                        ui:button("green", { backgound_color = "#00FA9A", color = "#000000", hover = { backgound_color = "#00ff00", color = "#ffffff" }, focus = { backgound_color = "#00ff00" } });
                    end
                    ui:groupEnd();
                end

                if ui:groupBegin("right group", { border_radius = 10, width = 100, height = 100, title_height = 20, backgound_color = "#666666" }) then
                    ui:layoutRow(80, 1)
                    ui:label("Question content.");

                    ui:layoutRow(26, { -1, 60, 60, -1 })
                    ui:blank();
                    ui:button("accept", { border_radius = 4, border_width = 3 })
                    ui:button("取消", { border_radius = 13 })
                    ui:blank();

                    ui:layoutRow(20);
                    ui:label("black text", { color = "rgb(0,0,0)" });
                    ui:label("white text", { color = "rgb(255,255,255)" });
                    ui:label("alpha text", { color = "rgb(255,255,255,150)" });

                    ui:layoutRow(120)
                    if ui:groupBegin("group3", { border_radius = 4, border_width = 4, flags = { ui.Flags.WindowFlags_NoTitleBar } }) then
                        ui:layoutRow(22);

                        ui:label("你好");
                        ui:label("Привет");
                        ui:label("hello");
                        ui:label("こんにちは");

                        ui:groupEnd();
                    end

                    ui:groupEnd();
                end

                ui:windowEnd();
            end
        end

        if bardata[4].selected then
            if ui:windowBegin("ID Card", 800, 40, 0, 0, { flags = { ui.Flags.WindowFlags_AlwaysAutoResize } }) then
                ui:layoutRow(24, { 36, -1, 48 });
                ui:label("id");
                ui:edit(id, { flags = { ui.Flags.InputTextFlags_Password } })
                ui:button("change");
                ui:label("name");
                ui:edit(name, { flags = { ui.Flags.InputTextFlags_CharsNoBlank, ui.Flags.InputTextFlags_NumberOnly } })
                ui:button("设置");

                ui:layoutRow(24, 2);
                ui:label("hard mode:")
                ui:button(selectBtn);

                ui:layoutRow(24, 1);
                ui:label("your job.");
                local ls = { "NPC A", "NPC B", "NPC C", "Player" }
                for i = 1, 4 do
                    if ui:selection(i .. "." .. ls[i] .. (selectIndex == i and " : selcetd" or ""), selectIndex == i) then
                        selectIndex = i;
                    end
                end

                ui:layoutRow(22, 2);
                ui:label("left select index:" .. selectIndex, { textAlign = ui.TextAlign.left });
                ui:label("right selctTitle:" .. tostring(ls[selectIndex]), { textAlign = ui.TextAlign.right });

                ui:layoutRow(60, { 50, -1 });
                ui:label("profile", { textVerticalAlign = ui.TextAlign.middle, });
                ui:edit(desc)

                ui:layoutRow(20, 1);
                ui:label("next is blankline. height 10px.");
                ui:blankline(10)

                ui:layoutRow(100, 1)
                if ui:groupBegin("group.", { flags = { ui.Flags.WindowFlags_NoScrollbar } }) then
                    ui:layoutRow(20);
                    ui:label("next group. WindowFlags_NoTitleBar")

                    ui:layoutRow(40, 1)
                    if ui:groupBegin("", { flags = { ui.Flags.WindowFlags_NoTitleBar } }) then
                        ui:layoutRow(30, 2);
                        ui:label("im group content.");
                        ui:button("button");
                        ui:groupEnd();
                    end

                    ui:layoutRow();
                    ui:label("surprise");

                    ui:groupEnd();
                end

                ui:layoutRow(26, { 60, -1, 80, -1, 60 })
                ui:button("left")
                ui:blank();
                ui:button("center")
                ui:blank();
                ui:button("right")

                ui:layoutRow(26, { -1, 60, 60, -1 })
                ui:blank();
                ui:button("confrim")
                ui:button("cancel")
                ui:blank();

                ui:layoutRow(26, 2);
                if ui:button("add button.") then
                    table.insert(btns, "button" .. #btns + 1);
                end
                if ui:button("delete button.") then
                    if #btns > 0 then
                        table.remove(btns, 1);
                    end
                end

                ui:layoutRow();
                for index, value in ipairs(btns) do
                    if ui:button(value) then
                        print("hello index: " .. index)
                    end
                end

                -- for i = 1, 100 do
                --     ui:button("????" .. i);
                -- end

                ui:windowEnd();
            end
        end

        ui:frameEnd();
    end

end

function love.draw()
    ui:draw();
    love.graphics.setColor(1, 1, 1, 1);
    love.graphics.print("Fps:" .. love.timer.getFPS(), 760, 40);
    love.graphics.print("Drawcalls:" .. love.graphics.getStats().drawcalls, 760, 58);

end

function love.textinput(text, a)
    ui:textinput(text, a)
end

function love.keypressed(a, b, c)
    ui:keypressed(a, b, c);
    if a == "f1" then
        ui._debug = not ui._debug;
    end
end

function love.mousepressed(...)
    ui:mousepressed(...);
end

function love.mousemoved(...)
    ui:mousemoved(...);
end

function love.mousereleased(...)
    ui:mousereleased(...);
end

function love.wheelmoved(x, y)
    ui:wheelmoved(x, y)
end