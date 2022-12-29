require "helper"
local style = require "style"

local ui = require("LGUI").new();

local input = { text = "???" }
local id = { text = "10000" }
local name = { text = "fox~" }
local desc = { text = "hello imlgui." }


local sw = true;


local selectBtn = { text = "switch button", selected = false }
local selectIndex = 0;
local y = 20;


local win = { title = "Question", x = 80, y = 23 };

function love.update(dt)
    if ui:beginFrame() then

        if ui:windowBegin("Title Bar", 0, 0, { elementSpacing = 5, border_radius = 0, padding_top = 3, padding_bottom = 3, width = love.graphics.getWidth(), height = 32, flags = { ui.Flags.WindowFlags_NoTitleBar, ui.Flags.WindowFlags_NoMove } }) then
            ui:layoutRow(22, { 80, 80, 80, 80, 80 });
            ui:selection("File", true);
            ui:selection("Edit", false);
            ui:selection("Help", false);
            ui:windowEnd();
        end

        if ui:windowBegin(win, { width = 500, height = 500 }) then
            ui:layoutRow(24, { 50, -1, 60 });
            ui:label("title");
            ui:edit(desc)
            if ui:button("publis") then
                print("publis.")
            end
            ui:layoutRow(400, { 0.4, 0.2, 0.4 });
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

                ui:layoutRow(20, { -0.2, 0., -1 })
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
                    ui:label("group bottom")

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

        if ui:windowBegin("ID Card", 800, 20, { width = 300, height = 600 }) then
            ui:layoutRow(24, { 36, -1, 48 });
            ui:label("id");
            ui:edit(id)
            ui:button("change");
            ui:label("name");
            ui:edit(name)
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
            if ui:groupBegin("group.", {}) then
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
                ui:label("")

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

            ui:windowEnd();
        end

        ui:endFrame();
    end

end

function love.draw()
    ui:draw();
    love.graphics.setColor(1, 1, 1, 1);
    love.graphics.print("Fps:" .. love.timer.getFPS(), 10, 40);
    love.graphics.print("Drawcalls:" .. love.graphics.getStats().drawcalls, 10, 58);

end

function love.textinput(text, a)
    ui:textinput(text, a)
end

function love.keypressed(a, b, c)
    ui:keypressed(a, b, c);
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