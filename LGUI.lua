local lstyle = require("style");
local color2 = require("color2");
local InputField = require("InputField")

local gr = love.graphics;

---@class LGUI
---@field new fun():LGUI
---@field _widgets table<string,any>
---@field _widgetStyles table<string,any>
---@field _currentWindow LGUI.WidgetData
---@field _windows LGUI.WidgetData[]
---@field _uuid number
---@field _textInput any
---@field _list table<string,{data:LGUI.WidgetData,use:boolean,parentId:any,pos:LGUI.ContainerPos,}>
---@field _prefixId string[]
---@field _containerStack LGUI.WidgetData[]
---@field _windowPos table<string,LGUI.ContainerPos>
---@field _lastWidget LGUI.WidgetData
---@field stateDrag {x:number,y:number,widget:any}
---@field stateMenu {selected:any[],list:any[]}
---@field state {focusId:any,hoverId:any,pressId:any,inputId:any,mainMenuId:any}
local lui = {}

local WidgetName = {
    label = "label";
    button = "button";
    selection = "selection";
    edit = "edit";
    window = "window";
    group = "group";
    menuBar = "menuBar";
    menu = "menu";
    mainmenu = "mainmenu";
};

local WidgetState = {
    measure = "measure";
    update = "update";
    draw = "draw";
    hover = "hover";
    unhover = "unhover";
    focus = "focus";
    unfocus = "unfocus";
    draw_top = "drawtop";
    lclick = "lclick";
};

lui.TextAlign = {
    left = "left",
    right = "right",
    center = "center",
    top = "top",
    bottom = "bottom",
    middle = "middle",
}

lui.Flags = {
    WindowFlags_NoScrollbar = "WindowFlags_NoScrollbar",
    WindowFlags_NoMove = "WindowFlags_NoMove",
    WindowFlags_NoTitleBar = "WindowFlags_NoTitleBar",
    WindowFlags_NoResize = "WindowFlags_NoResize",
    WindowFlags_AlwaysAutoResize = "WindowFlags_AlwaysAutoResize",
    WindowFlags_AlwaysVerticalScrollbar = "WindowFlags_AlwaysVerticalScrollbar",
    WindowFlags_NoScrollWithMouse = "WindowFlags_NoScrollWithMouse",
    WindowFlags_HorizontalScrollbar = "WindowFlags_HorizontalScrollbar",
    WindowFlags_AlwaysHorizontalScrollbar = "WindowFlags_AlwaysHorizontalScrollbar",

    InputTextFlags_NoUndoRedo = "InputTextFlags_NoUndoRedo",
    InputTextFlags_Password = "InputTextFlags_Password",
    InputTextFlags_ReadOnly = "InputTextFlags_ReadOnly",
    InputTextFlags_NoHorizontalScroll = "InputTextFlags_NoHorizontalScroll",
    InputTextFlags_CharsNoBlank = "InputTextFlags_CharsNoBlank",
    InputTextFlags_NumberOnly = "InputTextFlags_NumberOnly",

    EditPaste = "EditPaste",
    EditCopy = "EditCopy",
    EditAllSelection = "EditAllSelection",
    EditSelection = "EditSelection",
    EditRedo = "EditRedo",
    EditUndo = "EditUndo",
}

lui.Event = {
    keypressed = "keypressed",
    textinput = "textinput",
    mousepressed = "mousepressed",
    mousemoved = "mousemoved",
    mousereleased = "mousereleased",
    wheelmoved = "wheelmoved",
}

function lui.new()
    local inst = setmetatable({}, { __index = lui });
    inst:ctor();
    return inst;
end

---@generic T:any
---@param arr T[]
---@param value T
---@return number
local function arrayIndexOf(arr, value)
    if arr then
        for i, v in ipairs(arr) do
            if v == value then
                return i;
            end
        end
    end
    return -1;
end

local function mround(v)
    return math.floor(v + 0.5);
end

local function mclump(v, m, mx)
    return math.max(math.min(v, math.max(mx, m)), m);
end

local function pointHitRect(x, y, x1, y1, w, h)
    return x >= x1 and x <= x1 + w and y >= y1 and y < y1 + h;
end

local function dclone(dst, src)
    src = src or {}
    if dst then
        for key, value in pairs(dst) do
            if not src[key] then
                src[key] = value;
            end
        end
    end
    return src;
end

local function assignStyle(dst, src)
    src = src or {};
    src.hover = dclone(dst.hover, src.hover);
    src.focus = dclone(dst.focus, src.focus);
    setmetatable(src, { __index = dst });
    setmetatable(src.hover, { __index = src });
    setmetatable(src.focus, { __index = src });
    return src;
end

local function assignValue(dst, src)
    for key, value in pairs(dst) do
        src[key] = value == nil and src[key] or value;
    end
    return src;
end


local function textAlign(align, vAlign, textWdith, textHeight, width, height)
    local cx = 0;
    local cy = 0;
    local isCenter = align == lui.TextAlign.center;
    local isMiddle = vAlign == lui.TextAlign.middle;
    if isCenter or align == lui.TextAlign.right then
        if isCenter then
            cx = (width - math.min(width, textWdith or 0)) / 2;
        else
            cx = (width - math.min(width, textWdith or 0));
        end
    end
    if isMiddle or vAlign == lui.TextAlign.bottom then
        if isMiddle then
            cy = (height - math.min(height, textHeight or 0)) / 2;
        else
            cy = (height - math.min(height, textHeight or 0));
        end
    end
    return cx, cy;
end

---@param x number
---@param y number
---@param w number
---@param h number
---@param cw number
---@param ch number
---@param pdl number
---@param pdr number
---@param pdt number
---@param pdb number
---@param bw number
---@param align string
---@param vAlign string
local function pos(x, y, w, h, cw, ch, pdl, pdr, pdt, pdb, bw, align, vAlign)
    local rw = w - (pdl or 0) - (pdr or 0) - (bw * 2);
    local rh = h - (pdt or 0) - (pdb or 0) - (bw * 2);
    local rx, ry = textAlign(align, vAlign, cw, ch, rw, rh);
    return x + (pdl or 0) + (bw) + rx, y + (pdt or 0) + (bw) + ry, rw, rh;
end

---@param str string
---@param font love.Font
local function strSize(str, font)
    font = font or gr.getFont();
    local height = font:getHeight();
    return font:getWidth(str), height;
end

---@param x number
---@param y number
---@param width number
---@param height number
---@param backgound_color? any
---@param border_radius? number
---@param border_width? number
---@param border_color? any
local function mrectangle(x, y, width, height, backgound_color, border_radius, border_width, border_color)
    border_width = border_width or 0;
    if border_width > 0 then
        if border_color then
            gr.setColor(color2(border_color));
        end
        gr.rectangle("fill", math.ceil(x), math.ceil(y), math.floor(width), math.floor(height), border_radius or 0);
    end
    if backgound_color then
        gr.setColor(color2(backgound_color));
    end
    gr.rectangle("fill", math.ceil(x + border_width), math.ceil(y + border_width), math.floor(width - border_width * 2), math.floor(height - border_width * 2), border_radius or 0);
end

local function mprint(str, color, ...)
    gr.setColor(color2(color));
    gr.print(str, ...);
end


---@param t number 1.scrollV(0~(actualSize-size)) 2.range(0~1) 3.barPos(0~barSize)
---@param value number
---@param size number
---@param actualSize number
---@param barSize number
---@return number @range
---@return number @blockSize
---@return number @barPos
---@return number @scrollV
local function scrollPos(t, value, size, actualSize, barSize)
    local blockSize = math.max(5, 1 / (actualSize / size) * size);
    local rate;
    if t == 1 then
        rate = value / (actualSize - size);
    elseif t == 3 then
        rate = (value - blockSize / 2) / (barSize - blockSize);
    else
        rate = value;
    end
    return rate, blockSize, rate * (barSize - blockSize), rate * (actualSize - size);
end

---@class LGUI.Graphic
---@field new fun(ui:LGUI):LGUI.Graphic
---@field ui LGUI
---@field cmds {name:string,args:any[]}[]
local Graphic = {};

function Graphic.new(...)
    local inst = setmetatable({}, { __index = Graphic });
    inst:ctor(...);
    return inst;
end

---@param ui LGUI
function Graphic:ctor(ui)
    self.ui = ui;
    self.cmds = {};
end

function Graphic:sort()
    table.sort(self.cmds, function(a, b)
        if a.name ~= b.name then
            return true;
        end
        return false;
    end);
end

function Graphic:print(...)
    table.insert(self.cmds, { name = "print", args = { ... } })
end

function Graphic:rectangle(...)
    table.insert(self.cmds, { name = "rectangle", args = { ... } })
end

function Graphic:draw()
    for index, value in ipairs(self.cmds) do
        local func = love.graphics[value.name] or value.name;
        func(unpack(value.args));
    end
end

---小部件
---@class LGUI.Widget
local Widget = {}

---@param state string
---@param wt LGUI.WidgetData
---@param ui LGUI
function Widget.image(state, wt, ui)

end


---@param state string
---@param wt LGUI.WidgetData
---@param ui LGUI
function Widget.button(state, wt, ui, push)
    local values, position, style = wt.values, wt.position, wt.style;
    if state == WidgetState.measure then
        local font = gr.getFont();

        local strw, strh = strSize(values.text or "", font);

        position.contentWidth = strw;
        position.contentHeight = strh;

        position.measureWidth = strw + (style.padding_left or 0) + (style.padding_right or 0) + (style.border_width or 0) * 2;
        position.measureHeight = strh + (style.padding_top or 0) + (style.padding_bottom or 0) + (style.border_width or 0) * 2;

        return position.measureWidth, position.measureHeight;
    elseif state == WidgetState.draw then
        local lst = style;
        if --[[ ui:isFocus(wt) or --]] ui:isDown(wt) or values.selected then
            lst = style.focus;
        elseif ui:isHover(wt) then
            lst = style.hover;
        end

        local dx, dy = pos(position.x, position.y, position.width, position.height, position.contentWidth, position.contentHeight, lst.padding_left, lst.padding_right, lst.padding_top, lst.padding_bottom, lst.border_width, lst.textAlign, lst.textVerticalAlign);
        mrectangle(position.x, position.y, position.width, position.height, lst.backgound_color, lst.border_radius, lst.border_width, lst.border_color);
        mprint(values.text or "", lst.color, mround(dx), mround(dy));
    elseif state == WidgetState.lclick then
        if values.selected ~= nil then
            values.selected = not values.selected;
        end
    elseif state == lui.Event.mousepressed or state == lui.Event.mousereleased then
        return push;
    elseif state == lui.Event.mousemoved then
        return ui:isDown(wt);
    end

end


---@param state string
---@param wt LGUI.WidgetData
---@param ui LGUI
function Widget.mainMenu(state, wt, ui, push)
    local values, position, style = wt.values, wt.position, wt.style;
    if state == WidgetState.measure then
        local font = gr.getFont();

        local strw, strh = strSize(values.text or "", font);

        position.contentWidth = strw;
        position.contentHeight = strh;

        position.measureWidth = strw + (style.padding_left or 0) + (style.padding_right or 0) + (style.border_width or 0) * 2;
        position.measureHeight = strh + (style.padding_top or 0) + (style.padding_bottom or 0) + (style.border_width or 0) * 2;

        return position.measureWidth, position.measureHeight;
    elseif state == WidgetState.draw then
        local lst = style;
        if --[[ ui:isFocus(wt) or --]] ui:isDown(wt) or values.selected then
            lst = style.focus;
        elseif ui:isHover(wt) then
            lst = style.hover;
        end

        local dx, dy = pos(position.x, position.y, position.width, position.height, position.contentWidth, position.contentHeight, lst.padding_left, lst.padding_right, lst.padding_top, lst.padding_bottom, lst.border_width, lst.textAlign, lst.textVerticalAlign);
        mrectangle(position.x, position.y, position.width, position.height, lst.backgound_color, lst.border_radius, lst.border_width, lst.border_color);
        mprint(values.text or "", lst.color, mround(dx), mround(dy));
    elseif state == WidgetState.hover then
        if ui.state.mainMenuId then
            if ui.state.mainMenuId ~= values then
                ui:setReturnValues(ui.state.mainMenuId, nil, { selected = false });
                ui:_closeOtherMenuPopup();

                values.selected = true;
                ui.state.mainMenuId = values;
            end
        end
    elseif state == WidgetState.unfocus then
        if ui:_isMenuChild(ui.state.focusId) then
            ------------------
        else
            values.selected = false;
            if ui.state.mainMenuId == wt._ then
                ui:setReturnValues(ui.state.mainMenuId, nil, { selected = false });
                ui.state.mainMenuId = nil;
                ui:_closeOtherMenuPopup();
            end
        end
    elseif state == WidgetState.lclick then
        values.selected = not values.selected;
        if values.selected then
            ui.state.mainMenuId = wt._;
        else
            ui:_closeOtherMenuPopup();
            ui.state.mainMenuId = nil;
        end
    elseif state == lui.Event.mousepressed or state == lui.Event.mousereleased then
        return push;
    elseif state == lui.Event.mousemoved then
        return ui:isDown(wt);
    end

end


---@param state string
---@param wt LGUI.WidgetData
---@param ui LGUI
function Widget.menuBar(state, wt, ui, push, t)
    local values, position, style, uuid = wt.values, wt.position, wt.style, wt._;
    if state == WidgetState.measure then
        local font = gr.getFont();

        local strw, strh = strSize(values.text or "", font);

        position.contentWidth = strw;
        position.contentHeight = strh;

        position.measureWidth = strw + (style.padding_left or 0) + (style.padding_right or 0) + (style.border_width or 0) * 2;
        position.measureHeight = strh + (style.padding_top or 0) + (style.padding_bottom or 0) + (style.border_width or 0) * 2;

        return position.measureWidth, position.measureHeight;
    elseif state == WidgetState.hover or state == WidgetState.unhover then
        values.selected = ui:isHover(wt);
        local cpid = ui._list[uuid].parentId;
        if state == WidgetState.unhover and t then
            local tid = t.name == WidgetName.window and t._ or ui._list[t._].parentId;
            local np = cpid ~= tid;
            values.selected = np and arrayIndexOf(ui.stateMenu.list, tid) > 0;
        end

        if values.selected then
            local j = #ui.stateMenu.selected + 1;
            for index = 1, #ui.stateMenu.selected do
                local uid = ui.stateMenu.selected[index];
                local pid = ui._list[uid] and ui._list[uid].parentId;
                if cpid == pid then
                    j = index;
                    break;
                end
            end

            while #ui.stateMenu.selected >= j do -- close other
                local uid = table.remove(ui.stateMenu.selected, j);
                ui:setReturnValues(uid, { false }, { selected = false });
            end

            if arrayIndexOf(ui.stateMenu.selected, uuid) <= 0 then
                table.insert(ui.stateMenu.selected, uuid);
            end

        end

        ui:setReturnValues(uuid, { values.selected });
    elseif state == WidgetState.update then
        ui:setReturnValues(uuid, { values.selected });
    elseif state == WidgetState.draw then
        local lst = style;
        if --[[ ui:isFocus(wt) or --]] ui:isDown(wt) or values.selected then
            lst = style.focus;
        elseif ui:isHover(wt) then
            lst = style.hover;
        end

        local dx, dy = pos(position.x, position.y, position.width, position.height, position.contentWidth, position.contentHeight, lst.padding_left, lst.padding_right, lst.padding_top, lst.padding_bottom, lst.border_width, lst.textAlign, lst.textVerticalAlign);
        mrectangle(position.x, position.y, position.width, position.height, lst.backgound_color, lst.border_radius, lst.border_width, lst.border_color);
        mprint(values.text or "", lst.color, mround(dx), mround(dy));
    elseif state == lui.Event.mousepressed or state == lui.Event.mousereleased or state == lui.Event.mousemoved then
        return push or push == nil;
    end

end

---@param state string
---@param wt LGUI.WidgetData
---@param ui LGUI
function Widget.label(state, wt, ui)
    local values, position, style = wt.values, wt.position, wt.style;
    if state == WidgetState.measure then
        local strw, strh = strSize(values.text or "", gr.getFont());

        position.contentWidth = strw;
        position.contentHeight = strh;

        position.measureWidth = strw + (style.padding_left or 0) + (style.padding_right or 0) + (style.border_width or 0) * 2;
        position.measureHeight = strh + (style.padding_top or 0) + (style.padding_bottom or 0) + (style.border_width or 0) * 2;

        return position.measureWidth, position.measureHeight;
    elseif state == WidgetState.update then

    elseif state == WidgetState.draw then
        local lst = style;
        if ui:isFocus(wt) then
            lst = lst.focus;
        elseif ui:isHover(wt) then
            lst = lst.hover;
        end

        local dx, dy = pos(position.x, position.y, position.width, position.height, position.contentWidth, position.contentHeight, lst.padding_left, lst.padding_right, lst.padding_top, lst.padding_bottom, (lst.border_width or 0), lst.textAlign, lst.textVerticalAlign);
        mprint(values.text or "", lst.color, mround(dx), mround(dy));
    end
end

---@param state string
---@param wt LGUI.WidgetData
---@param ui LGUI
function Widget.edit(state, wt, ui, push, x, y, ...)
    local values, position, style = wt.values, wt.position, wt.style;
    if state == WidgetState.measure then
        local font = gr.getFont();
        local strw, strh = strSize(values.text or "", font);

        position.contentWidth = strw;
        position.contentHeight = strh;

        position.measureWidth = strw + (style.padding_left or 0) + (style.padding_right or 0) + (style.border_width or 0) * 2;
        position.measureHeight = strh + (style.padding_top or 0) + (style.padding_bottom or 0) + (style.border_width or 0) * 2;

        return position.measureWidth, position.measureHeight;
    elseif state == WidgetState.update then
        if ui:isFocus(wt) then
            ui._textInput:update(love.timer.getDelta());
        end
    elseif state == WidgetState.draw then
        local font = gr:getFont();
        local fontHeight = font:getHeight();

        local lst = style;
        local isFocus = ui:isFocus(wt);
        if isFocus then
            lst = lst.focus;
        elseif ui:isHover(wt) then
            lst = lst.hover;
        end
        gr.push("all");

        mrectangle(position.x, position.y, position.width, position.height, lst.backgound_color, lst.border_radius, lst.border_width, lst.border_color);
        local dx, dy = pos(position.x, position.y, position.width, position.height, position.contentWidth, position.contentHeight, lst.padding_left, lst.padding_right, lst.padding_top, lst.padding_bottom, lst.border_width, lst.textAlign, lst.textVerticalAlign);

        local gx, gy = gr.inverseTransformPoint(0, 0);
        gr.intersectScissor(position.x + 3, position.y - gy, math.max(1, position.width - 3), math.max(1, position.height));
        local offsetX = 0;
        if isFocus then
            local textInput = ui._textInput;
            local s1, e1 = textInput:getSelectionOffset();
            local cx = textInput:getCursorOffset();
            offsetX = textInput:getTextOffset();
            if cx then
                if e1 > s1 then
                    mrectangle(dx + s1, dy, e1 - s1, fontHeight, "#ffffff33");
                end
                local blink = textInput:getBlinkPhase();
                if (blink - math.floor(blink)) < 0.5 then
                    mrectangle(dx + cx, dy, 1, fontHeight, "#ffffff");
                end
            end
        end

        local text = values.text or "";
        if arrayIndexOf(style.flags, lui.Flags.InputTextFlags_Password) > 0 then
            text = ("*"):rep(#text);
        end
        mprint(text, lst.color, mround(dx + offsetX), mround(dy));
        gr.pop();
    elseif state == lui.Event.mousepressed then
        local isTrue = ui:isFocus(wt);
        if push then
            if not ui.state.inputId or not isTrue then
                ui:_setEditBox(wt);
                isTrue = true;
            end
        end
        if push then
            ui._textInput[state](ui._textInput, x - (position.x + position.contentX), y - (position.y + position.contentY), ...);
        end
        return push or isTrue;
    elseif state == WidgetState.unfocus then
        ui:_setEditBox(nil);
    elseif state == lui.Event.mousemoved then
        if (push or push == nil) and ui:isFocus(wt) then
            ui._textInput[state](ui._textInput, x - (position.x + position.contentX), y - (position.y + position.contentY), ...);
            return true;
        end
    elseif state == lui.Event.mousereleased then
        if (push or push == nil) and ui:isFocus(wt) then
            ui._textInput[state](ui._textInput, x - (position.x + position.contentX), y - (position.y + position.contentY), ...);
            return true;
        end
    end
end


---@param state string
---@param wt LGUI.WidgetData
---@param ui LGUI
function Widget.window(state, wt, ui, push, x, y)
    local values, position, style = wt.values, wt.position, wt.style;
    if state == WidgetState.measure then
        -- local font = gr.getFont();
        -- local str = values.title or "window";
        -- local h = font:getHeight();
        -- if str and str ~= "" then
        --     local w = font:getWidth(str);
        --     return w, h;
        -- end
        wt.position.contentWidth = 0;
        wt.position.contentHeight = 0;
        wt.position.measureWidth = 0;
        wt.position.measureHeight = 0;
        return 0, 0;
    elseif state == WidgetState.draw then
        local lst = style;
        local isFocus = ui:isFocus(wt);

        -- if isFocus then
        --     lst = lst.focus;
        -- else
        if ui:isHover(wt) then
            lst = lst.hover;
        end

        local titleWidth = wt.position.width - wt.style.border_width * 2;

        mrectangle(position.x, position.y, position.width, position.height, lst.backgound_color, lst.border_radius, lst.border_width, lst.border_color);

        local titleHeight = 0;
        --- titlebar
        if arrayIndexOf(wt.style.flags, ui.Flags.WindowFlags_NoTitleBar) <= 0 then
            local title = values.title or "window"
            titleHeight = wt.style.title_height;

            gr.setColor(color2(wt.style.title_background_color));
            gr.rectangle("fill", wt.position.x + wt.style.border_width, wt.position.y + wt.style.border_width, math.floor(titleWidth), wt.style.title_height, wt.style.border_radius);

            local sx, sy = strSize(title, gr.getFont())
            local dx, dy = pos(position.x, position.y, position.width, titleHeight, sx, sy, lst.padding_left, lst.padding_right, 0, 0, (lst.border_width or 0), lst.textAlign, lst.textVerticalAlign);

            mprint(title, lst.color, mround(dx), mround(dy))
        end
    elseif state == WidgetState.draw_top then
        --- scroll
        if arrayIndexOf(wt.style.flags, ui.Flags.WindowFlags_NoScrollbar) <= 0 then
            local outsize = (position.actualHeight > position.contentHeight);
            if outsize or arrayIndexOf(style.flags, lui.Flags.WindowFlags_AlwaysVerticalScrollbar) > 0 then
                local topBottomSpacing, leftRightSpacing, blockWidth = 2, 2, 10;
                local barHeight = (position.contentHeight + wt.style.padding_top + wt.style.padding_bottom - topBottomSpacing * 2);
                local posX, posY = wt.position.x + position.width - wt.style.border_width - blockWidth - leftRightSpacing, wt.position.y + wt.position.contentY + topBottomSpacing - wt.style.padding_top;

                local _, blockHeight, pos = scrollPos(1, position.scrollY, position.contentHeight, position.actualHeight, barHeight);

                gr.setColor(0.1, 0.1, 0.1, 0.6);
                gr.rectangle("fill", posX, posY, blockWidth, barHeight, style.border_radius);
                if outsize then
                    gr.setColor(0.3, 0.3, 0.3, 0.8);
                    gr.rectangle("fill", posX, posY + mclump(pos, 0, barHeight - blockHeight), blockWidth, blockHeight, style.border_radius);
                end
            end
        end
    elseif state == ui.Event.mousepressed then
        --- scroll
        if push then
            if wt.position.actualHeight > wt.position.contentHeight and arrayIndexOf(wt.style.flags, ui.Flags.WindowFlags_NoScrollbar) <= 0 then
                local topBottomSpacing, leftRightSpacing, blockWidth = 2, 2, 10;
                local barHeight = (position.contentHeight + wt.style.padding_top + wt.style.padding_bottom - topBottomSpacing * 2);
                local posX, posY = wt.position.x + position.width - wt.style.border_width - blockWidth - leftRightSpacing, wt.position.y + wt.position.contentY + topBottomSpacing - wt.style.padding_top;

                local v, blockHeight, pos, lastV = scrollPos(1, position.scrollY, position.contentHeight, position.actualHeight, barHeight);

                if pointHitRect(x, y, posX, posY, blockWidth, barHeight) then
                    ui._windowPos[wt._].temp.scroll = true;
                    local v2, _, _, scrollY = scrollPos(3, y - posY, position.contentHeight, position.actualHeight, barHeight);
                    ui._windowPos[wt._].temp.scrollValue = scrollY - lastV;
                    if not pointHitRect(x, y, posX, posY + pos, blockWidth, blockHeight) then --click blank
                        ui._windowPos[wt._].temp.scrollValue = 0;
                        ui._windowPos[wt._].scrollY = scrollY;
                    end
                    return "scroll";
                end
            end
            if wt.name == WidgetName.window then
                return "drag";
            end
        end
    elseif state == ui.Event.mousemoved then
        if push or push == nil then
            if ui._windowPos[wt._].temp.scroll then
                local topBottomSpacing, leftRightSpacing, blockWidth = 2, 2, 10;
                local barHeight = (position.contentHeight + wt.style.padding_top + wt.style.padding_bottom - topBottomSpacing * 2);
                local posX, posY = wt.position.x + position.width - wt.style.border_width - blockWidth - leftRightSpacing, wt.position.y + wt.position.contentY + topBottomSpacing - wt.style.padding_top;

                local _, _, _, lastV = scrollPos(3, y - posY, position.contentHeight, position.actualHeight, barHeight);
                local _, _, _, scrollY = scrollPos(1, lastV - ui._windowPos[wt._].temp.scrollValue, position.contentHeight, position.actualHeight, barHeight);
                ui._windowPos[wt._].scrollY = math.max(scrollY, 0);
                return true;
            else
                return ui:isDown(wt);
            end
        end
    elseif state == ui.Event.mousereleased then
        ui._windowPos[wt._].temp.scrollValue = nil;
        ui._windowPos[wt._].temp.scroll = nil;
    end
end

function lui:ctor()
    self._widgets = {};
    self._windows = {};
    self._widgetStyles = {};
    self._list = {};
    self._debug = nil;
    self._containerStack = {};
    self._windowPos = {};
    self.state = {};
    self.stateMenu = {};
    self.stateDrag = {};
    self:registerWidget(Widget.label, WidgetName.label, lstyle[WidgetName.label]);
    self:registerWidget(Widget.button, WidgetName.button, lstyle[WidgetName.button]);
    self:registerWidget(Widget.button, WidgetName.selection, lstyle[WidgetName.selection]);
    self:registerWidget(Widget.edit, WidgetName.edit, lstyle[WidgetName.edit]);
    self:registerWidget(Widget.window, WidgetName.window, lstyle[WidgetName.window]);
    self:registerWidget(Widget.window, WidgetName.group, lstyle[WidgetName.group]);
    self:registerWidget(Widget.menuBar, WidgetName.menuBar, lstyle[WidgetName.menuBar]);
    self:registerWidget(Widget.mainMenu, WidgetName.mainmenu, lstyle[WidgetName.menuBar]);
    self._widgetStyles[WidgetName.menu] = lstyle[WidgetName.menu];
end

function lui:keypressed(key, scancode, isRepeat)
    self:_event(lui.Event.keypressed, key, scancode, isRepeat);
end

function lui:textinput(text, a)
    self:_event(lui.Event.textinput, text, a);
end

function lui:mousepressed(...)
    self:_event(lui.Event.mousepressed, ...);
end

function lui:mousemoved(...)
    self:_event(lui.Event.mousemoved, ...);
end

function lui:mousereleased(...)
    self:_event(lui.Event.mousereleased, ...);
end

function lui:wheelmoved(x, y)
    self:_event(lui.Event.wheelmoved, x, y);
end

---@param widget function
---@param name string
---@param style LGUI.Style
function lui:registerWidget(widget, name, style)
    if self._widgets[name] then
        print("widget is exist:", name);
    end
    self._widgets[name] = widget;
    self._widgetStyles[name] = style;
end

---@protected
---@param style? LGUI.Style
---@return any
function lui:_widget(name, style, values, static)
    local cur = self:_curContainer();
    if not cur then
        return;
    end

    values = values or {};

    local uuid = self:uuid(values, static)
    local retData, lastValus = self:_lastData(uuid);

    assignValue(lastValus, values);

    local len = #cur.rows;
    if len >= 1 then
        local wgt = cur.rows[len].widgets;
        if name then
            local o = { _ = uuid, name = name, position = {}, values = values, style = style or {} };
            local obj = self:_last(uuid, cur._);
            obj.parentId = cur._;
            obj.data = o;
            table.insert(wgt, o);
        else
            table.insert(wgt, { _ = uuid, position = {}, values = values, style = style or {} });
        end
    end

    if WidgetName.menuBar == name then
        if values.selected then
            table.insert(self.stateMenu.selected, uuid);
        end
    end

    return unpack(retData);
end

---@return {data:LGUI.WidgetData,use:boolean,parentId:any,pos:LGUI.ContainerPos,}
function lui:_last(uuid, parentId)
    if not self._list[uuid] then
        self._list[uuid] = { _ = uuid };
    end
    self._list[uuid].use = true;
    self._list[uuid].parentId = parentId;
    return self._list[uuid];
end

---@return any
function lui:uuid(values, static)
    if not self._uuid then self._uuid = 0; end
    self._uuid = self._uuid + 1;

    local oid;
    oid = (values.id or values.title or values.text or tostring(self._uuid)) .. "," .. table.concat(self._prefixId, ",");
    local uuid = static and oid or values;
    return uuid;
end

function lui:_lastData(uuid)
    local t = self._list[uuid];
    local ret, data;
    if t then
        ret = t.return_;
        data = t.values;
        -------
        t.return_ = nil;
        t.values = nil;
    end
    return ret or {}, data or {};
end

---@param uuid any
---@param ret any[]
function lui:setReturnValues(uuid, ret, values)
    local t = self._list[uuid];
    if t then
        t.return_ = ret;
        t.values = values;
    end
end

---@protected
---@param name string
---@param st? LGUI.Style
---@param static boolean
function lui:_widgetBegin(name, values, st, static)
    local cur = self:_curContainer();

    values = values or {};

    local uuid = self:uuid(values, static);

    local retData, lastValus = self:_lastData(uuid);

    local unchanged;
    if self:_isContainer(name) then
        if not self._windowPos[uuid] then
            self._windowPos[uuid] = { x = values.x, y = values.y, lastX = values.x, lastY = values.y, sort = os.clock(), scrollY = 0, layer = 0, temp = {} };
        else
            unchanged = self._windowPos[uuid].lastX == values.x and self._windowPos[uuid].lastY == values.y;
            if not unchanged then
                self._windowPos[uuid].x     = values.x;
                self._windowPos[uuid].y     = values.y;
                self._windowPos[uuid].lastX = values.x;
                self._windowPos[uuid].lastY = values.y;
            end
        end
    end

    assignValue(lastValus, values);
    if unchanged then
        self._windowPos[uuid].x = values.x or self._windowPos[uuid].x;
        self._windowPos[uuid].y = values.y or self._windowPos[uuid].y;
    end

    if name == WidgetName.window then
        if self._windowPos[uuid] then
            values.x = self._windowPos[uuid].x;
            values.y = self._windowPos[uuid].y;
            values.scrollY = self._windowPos[uuid].scrollY;
        end
        local _currentWindow = { _ = uuid, values = values or {}, name = name, rows = {}, position = values, style = assignStyle(self._widgetStyles[name], st) };
        self._list[uuid] = { data = _currentWindow, use = true, parentId = cur and cur._ };
        table.insert(self._windows, _currentWindow);
        self:_pushStack(_currentWindow);
    elseif name == WidgetName.group then
        if cur then
            if self._windowPos[uuid] then
                values.scrollY = self._windowPos[uuid].scrollY;
            end
            ---@type LGUI.WidgetData
            local _currentWindow = { _ = uuid, measureSize = true, values = values, name = name, rows = {}, position = values, style = assignStyle(self._widgetStyles[name], st) };
            self._list[uuid] = { data = _currentWindow, use = true, parentId = cur._ };
            local len = #cur.rows;
            local wgt = cur.rows[len].widgets;
            table.insert(wgt, _currentWindow)
            self:_pushStack(_currentWindow);
        end
    end
    local rt = self._currentContainer;
    -- if r and r.ret then
    --     rt = not r.ret;
    -- end
    return rt, uuid, self._windowPos[uuid];
end

---@protected
function lui:_widgetEnd()
    self._currentContainer = nil;
    if #self._prefixId then
        table.remove(self._prefixId, 1);
    end
    self:_popStack();
end

---@protected
function lui:_curContainer()
    return self._currentContainer;
end

---@protected
---@param wt LGUI.WidgetData
function lui:_pushStack(wt)
    if self:_isContainer(wt.name) then
        table.insert(self._prefixId, 1, wt._);
    end
    table.insert(self._containerStack, wt);
    self._currentContainer = wt;
end

---@protected
function lui:_popStack()
    if #self._containerStack > 0 then
        table.remove(self._containerStack, #self._containerStack);
    end
    self._currentContainer = self._containerStack[#self._containerStack];
end


---@param width number
---@param widths number[]|number ---sample {20,15,0,12,-1}       0~1. -0~-1
local function layoutRowSize(width, widths)
    if type(widths) == "number" then
        local ws = {};
        for i = 1, widths do
            table.insert(ws, width / widths);
        end
        widths = ws;
    end

    local sumWidth = 0;
    local measure = false;
    local percent = 0;
    local percent2 = 0;
    local p2 = 0;
    local r = {};
    for index, value in ipairs(widths) do
        local autoWidth = (value >= -1 and value < 0);
        if autoWidth or (value > 0 and value <= 1) then
            measure = true;
            r[index] = 0;
            if autoWidth then
                if value == -1 then
                    p2 = p2 + 1;
                else
                    percent2 = percent2 + value;
                end
            else
                percent = percent + value;
            end
        else
            r[index] = value;
        end
    end
    if measure then
        for index, value in ipairs(widths) do
            if value > 1 then
                r[index] = value;
                sumWidth = sumWidth + value;
            end
        end
        local remainWidth = width - sumWidth;
        for index, _ in ipairs(r) do
            local value = widths[index];
            if remainWidth <= 0 then -- outsize
                break;
            end
            if value > 0 and value <= 1 then
                local w = math.min(remainWidth, value * width);
                remainWidth = remainWidth - w;
                r[index] = w;
            end
        end

        if remainWidth > 0 then
            local w = remainWidth * -percent2;
            local sw = 0;
            if remainWidth - w > 0 then
                sw = (remainWidth - w) / p2;
            end
            for index, _ in ipairs(r) do
                local value = widths[index];
                if value >= -1 and value < 0 then
                    if value == -1 then
                        r[index] = sw;
                    else
                        r[index] = -(value) * remainWidth
                    end
                end
            end


        end
    end
    return r;
end

---@param height? number default 26
---@param count? number|number[] default 1
function lui:layoutRow(height, count)
    local cur = self:_curContainer();
    height = height or 26;
    count = count or 1;
    if cur and count then
        local ty = type(count);
        -- local width = cur.position.width;
        local num = count;
        if ty == "table" then
            num = #count;
        end
        -- width = cur.position.width - cur.style.padding_left - cur.style.padding_right - math.max(0, (num - 1) * cur.style.elementSpacing) - cur.style.border_width * 2;
        local widths;
        local measure = true;
        -- if not cur.measureSize then
        --     widths = layoutRowSize(width, count);
        --     measure = false;
        -- else
        if ty == "table" then
            widths = count;
        elseif num > 0 then
            widths = {};
            for i = 1, num do
                table.insert(widths, 1 / num);
            end
        end
        -- end
        -- table.insert(cur.rows, { info = { count = num, height = height, widths = widths, measureSize = measure }, widgets = {} });
        table.insert(cur.rows, { info = { count = num, height = height, measureSize = measure, widths = widths }, widgets = {} });
    end
end

function lui:blank()
    self:_widget(nil, nil, nil);
end

function lui:blankline(height)
    local cur = self:_curContainer();
    if not cur then
        return;
    end
    local n;
    if #cur.rows > 0 then
        n = assignStyle(cur.rows[#cur.rows].info, {});
    end
    self:layoutRow(height or 2, 0);
    if n then
        self:layoutRow(n.height, n.widths or n.count);
    end
end


---@overload fun(self:LGUI,text:{text:string,selected:boolean},st?:LGUI.Style):boolean
---@param text string
---@param st? LGUI.Style
function lui:button(text, st)
    if type(text) == "table" then
        return self:_widget(WidgetName.button, assignStyle(self._widgetStyles[WidgetName.button], st), text);
    else
        return self:_widget(WidgetName.button, assignStyle(self._widgetStyles[WidgetName.button], st), { text = text }, true);
    end
end

---@param text string
---@param st? LGUI.Style
function lui:label(text, st)
    self:_widget(WidgetName.label, assignStyle(self._widgetStyles[WidgetName.label], st), { text = text }, true);
end

---
---@overload fun(self:LGUI,title:string,selected:boolean,st?:LGUI.Style):boolean
---@param value? {text:string,selected:boolean}
---@param st? LGUI.Style
---@return boolean
function lui:selection(value, st, c)
    if type(value) == "table" then
        return self:_widget(WidgetName.selection, assignStyle(self._widgetStyles[WidgetName.selection], st), value);
    else
        return self:_widget(WidgetName.selection, assignStyle(self._widgetStyles[WidgetName.selection], c), { text = value, selected = st }, true);
    end
end

---@overload fun(self:LGUI,title:string,selected:boolean,st?:LGUI.Style):boolean
---@param value? {text:string,selected:boolean}
---@param style? LGUI.Style
function lui:mainMenu(value, style)
    if type(value) == "table" then
        return self:_widget(WidgetName.mainmenu, assignStyle(self._widgetStyles[WidgetName.selection], st), value);
    else
        return self:_widget(WidgetName.mainmenu, assignStyle(self._widgetStyles[WidgetName.selection], c), { text = value, selected = st }, true);
    end
end

---
---@overload fun(self:LGUI,title:string,selected:boolean,st?:LGUI.Style):boolean
---@param value? {text:string,selected:boolean}
---@param st? LGUI.Style
---@return boolean
function lui:menu(value, st, c)
    if type(value) == "table" then
        return self:_widget(WidgetName.menuBar, assignStyle(self._widgetStyles[WidgetName.menuBar], st), value);
    else
        return self:_widget(WidgetName.menuBar, assignStyle(self._widgetStyles[WidgetName.menuBar], c), { text = value, selected = st }, true);
    end
end

---@overload fun(self:LGUI,window:{title:string,x:number,y:number,scrollX:number,scrollY:number,widht:number,height:number},st?:LGUI.Style)
---@overload fun(self:LGUI,title:string,st?:LGUI.Style)
---@overload fun(self:LGUI,title:string,x:number,y:number,st?:LGUI.Style)
---@param title string
---@param x? number
---@param y? number
---@param width? number
---@param height? number
---@param st? LGUI.Style
---@return boolean
function lui:menuBegin(title, x, y, width, height, st)
    local cur = self:_curContainer();
    local ox, oy = 0, 0;

    local values;
    local isTab = type(title) == "table";
    if isTab then
        title.width = title.width or 200;
        title.height = title.height or 200;
        title.scrollX = title.scrollX or 0;
        title.scrollY = title.scrollY or 0;
        values = title;
        st = x;
        isTab = false;
    else
        values = { title = title, x = x, y = y, width = width, height = height, scrollX = 0, scrollY = 0 };
    end

    local closeOtherMenu = false;
    local layer = 1;
    if arrayIndexOf(self.stateMenu.list, cur and cur._) > 0 then --last is menu
        ox, oy = self:curPos();
        values.x = ox + 100;
        values.y = oy;
        layer = self._windowPos[cur._].layer + 1;
    elseif #self.stateMenu.list > 0 then
        closeOtherMenu = true;
    elseif cur then -- first one
        layer = self._windowPos[cur._].layer + 1;
    end

    local w, uuid = self:_widgetBegin(WidgetName.window, values, self._widgetStyles[WidgetName.menu], not isTab);
    local wp = self._windowPos[uuid];
    if wp then
        wp.layer = layer;
    end

    -- if closeOtherMenu then
    --     self:_closeOtherMenuPopup();
    -- end

    table.insert(self.stateMenu.list, 1, uuid);
    return not not w;
end

function lui:menuEnd()
    self:popupEnd();
    -- table.remove(self.stateMenu.list, 1);
end

---@param x number
---@param y number
function lui:setNextWindowPos(x, y)

end


---@param value {text:string}
---@param st? LGUI.Style
function lui:edit(value, st)
    if not self._textInput then
        self._textInput = InputField("");
    end
    self:_widget(WidgetName.edit, assignStyle(self._widgetStyles[WidgetName.edit], st), value);
end

---@overload fun(self:LGUI,window:{title:string,x:number,y:number,scrollX:number,scrollY:number,widht:number,height:number},st?:LGUI.Style)
---@param title string
---@param x? number
---@param y? number
---@param width? number
---@param height? number
---@param st? LGUI.Style
---@return boolean
function lui:windowBegin(title, x, y, width, height, st)
    local values;
    local isTab = type(title) == "table";
    if isTab then
        title.width = title.width or 200;
        title.height = title.height or 200;
        title.scrollX = title.scrollX or 0;
        title.scrollY = title.scrollY or 0;
        values = title;
        st = x;
        isTab = false;
    else
        values = { title = title, x = x, y = y, width = width, height = height, scrollX = 0, scrollY = 0 };
    end
    local w = self:_widgetBegin(WidgetName.window, values, st, not isTab);
    return not not w;
end

function lui:windowEnd()
    self:_widgetEnd();
end

---@overload fun(self:LGUI,window:{title:string,x:number,y:number,scrollX:number,scrollY:number,widht:number,height:number},st?:LGUI.Style)
---@param title string
---@param x? number
---@param y? number
---@param width? number
---@param height? number
---@param st? LGUI.Style
---@return boolean
function lui:popupBegin(title, x, y, width, height, st)
    local values;
    local isTab = type(title) == "table";
    if isTab then
        title.width = title.width or 200;
        title.height = title.height or 200;
        title.scrollX = title.scrollX or 0;
        title.scrollY = title.scrollY or 0;
        values = title;
        st = x;
        isTab = false;
    else
        values = { title = title, x = x, y = y, width = width, height = height, scrollX = 0, scrollY = 0 };
    end
    local cur = self:_curContainer();
    local w, uuid = self:_widgetBegin(WidgetName.window, values, st, not isTab);
    local wp = self._windowPos[uuid];
    if wp then
        wp.layer = 1;
    end
    return not not w;
end


function lui:popupEnd()
    self:_widgetEnd();
end


---@protected
---@param name string
---@param state string
---@param wt LGUI.WidgetData
function lui:_widgetState(name, state, wt, ...)
    local comp = self._widgets[name] or name;
    if type(comp) == "function" then
        return comp(state, wt, self, ...);
    end
end

---@protected
function lui:_closeOtherMenuPopup()
    while #self.stateMenu.selected > 0 do
        local uid = table.remove(self.stateMenu.selected, 1);
        self._list[uid].data.values.selected = false;
        -- self:setReturnValues(uid, { false }, { selected = false });
    end
    for key, uid in pairs(self.stateMenu.list) do
        self:setReturnValues(uid, { false }, { selected = false });
        self.stateMenu.list[key] = nil;
        self:_closeWindow(uid);
    end
end

function lui:closeCurrentMenu()
    if self.state.mainMenuId then
        self:setReturnValues(self.state.mainMenuId, { false }, { selected = false });
        self:_closeOtherMenuPopup();
        self.state.mainMenuId = nil;
    end
end

---@protected
function lui:_closeWindow(uuid)
    for index, value in ipairs(self._windows) do
        if value._ == uuid then
            table.remove(self._windows, index);
        end
    end
end

function lui:curPos()
    local cur = self:_curContainer();
    if not cur then
        return 0, 0;
    end

    -- print(cur.position.x, cur.position.y);
    local h = 0;
    local lh = 0;
    for index, row in ipairs(cur.rows) do
        if row.info.count > 0 then
            h = h + math.ceil(#row.widgets / row.info.count) * (row.info.height + cur.style.lineSpacing);
            lh = row.info.height + cur.style.lineSpacing;
        else --blankline
            h = h + row.info.height + cur.style.lineSpacing;
            lh = lh + row.info.height + cur.style.lineSpacing;
        end
    end

    return cur.position.x, cur.position.y + h - lh;
end


---@overload fun(self:LGUI,window:{title:string},st?:LGUI.Style)
---@param title string
---@param st? LGUI.Style
---@return boolean
function lui:groupBegin(title, st)
    local isTab = type(title) == "table";
    if not isTab then
        title = { title = title };
    end
    local w = self:_widgetBegin(WidgetName.group, title, st, not isTab);
    if w and st then
        w.position.width = st.width or w.position.width;
        w.position.height = st.height or w.position.height;
    end
    return true;
end

function lui:groupEnd()
    self:_widgetEnd();
end

---@param wt LGUI.WidgetData
function lui:isHover(wt)
    return self.state.hoverId and self.state.hoverId == (wt and wt._);
end

---@param wt LGUI.WidgetData
function lui:isFocus(wt)
    return self.state.focusId and self.state.focusId == (wt and wt._);
end

---@param wt LGUI.WidgetData
function lui:isDown(wt)
    return self.state.pressId and self.state.pressId == (wt and wt._);
end

---@protected
function lui:_isMenuChild(uuid)
    local id = uuid;
    while id do
        if arrayIndexOf(self.stateMenu.list, id) > 0 then
            return true;
        end
        local wt = self._list[id];
        if wt then
            id = wt.parentId;
        else
            id = nil;
        end
    end
end

function lui:frameBegin()
    self._uuid = 0;
    self._windows = {};
    self._prefixId = {};
    self._containerStack = {};
    self._currentContainer = nil;
    self.stateMenu.list = {};
    self.stateMenu.selected = {};
    return true;
end


---@protected
function lui:_isContainer(name)
    return name == WidgetName.window or name == WidgetName.group;
end

---@protected
---@param window LGUI.WidgetData
---@param isTop? boolean
function lui:_updateElement(window, isTop)
    if not window.name or window.name == "" then return end
    --------

    local titleHeight = 0;
    if arrayIndexOf(window.style.flags, lui.Flags.WindowFlags_NoTitleBar) <= 0 then
        titleHeight = (window.style.title_height or 0);
    end

    if isTop and arrayIndexOf(window.style.flags, lui.Flags.WindowFlags_AlwaysAutoResize) > 0 then
        local rw, rh = self:getSize(window);
        window.position.width = rw + (window.style.padding_left or 0) + (window.style.padding_right or 0) + (window.style.border_width or 0) * 2;
        window.position.height = rh + (window.style.padding_top or 0) + (window.style.padding_bottom or 0) + (window.style.border_width or 0) * 2 + titleHeight;
    end

    window.position.contentX = (window.style.padding_left or 0) + (window.style.border_width or 0);
    window.position.contentY = (window.style.padding_top or 0) + (window.style.border_width or 0) + titleHeight;

    self:_widgetState(window.name, WidgetState.update, window);
    window.position.measureWidth, window.position.measureHeight = self:_widgetState(window.name, WidgetState.measure, window); -- size

    local isPanel = self:_isContainer(window.name);
    if isPanel then
        window.position.contentWidth = (window.position.width or 0) - (window.style.padding_left or 0) - (window.style.padding_right or 0) - (window.style.border_width or 0) * 2;
        window.position.contentHeight = (window.position.height or 0) - (window.style.padding_top or 0) - (window.style.padding_bottom or 0) - (window.style.border_width or 0) * 2 - titleHeight;
    end

    local ox, oy = (window.position.x or 0) + window.position.contentX, (window.position.y or 0) + window.position.contentY;
    local width = window.position.contentWidth;

    window.position.actualWidth = window.position.contentWidth;
    window.position.actualHeight = 0;

    --- calc height
    if window.rows then
        local h = 0;
        for _, row in ipairs(window.rows) do
            local lineHeight = row.info.height + window.style.lineSpacing;
            local count = #row.widgets;
            if count > 0 then
                h = h + math.ceil(count / row.info.count) * lineHeight;
            elseif row.info.count == 0 then
                h = h + lineHeight;
            end
        end
        window.position.actualHeight = h;
    end

    local hasScroller = arrayIndexOf(window.style.flags, lui.Flags.WindowFlags_AlwaysVerticalScrollbar) > 0;
    if isPanel and (hasScroller or (window.position.actualHeight > window.position.contentHeight)) then
        if hasScroller then
            width = width - 12;
        else
            window.position.scrollY = math.min(window.position.scrollY, window.position.actualHeight - window.position.contentHeight)
            if arrayIndexOf(window.style.flags, lui.Flags.WindowFlags_NoScrollbar) <= 0 then
                width = width - 12;
            end
        end
    elseif window.position.scrollY ~= 0 then
        window.position.scrollY = 0;
    end

    -------------------------------------------
    local dx, dy = ox, oy;
    if window.rows then
        for i, row in ipairs(window.rows) do
            dx = ox;
            local j = 0;
            if row.info.measureSize then
                local widths = layoutRowSize(width - math.max(0, window.style.elementSpacing * (row.info.count - 1)), row.info.widths or row.info.count);
                row.info.widths = widths;
                row.info.measureSize = false;
            end
            local lineHeight = row.info.height + window.style.lineSpacing;
            if #row.widgets > 0 then
                for index, wt in ipairs(row.widgets) do
                    j = j + 1;
                    local ww = row.info.widths[j];

                    wt.position.globalOffsetX = (window.position.globalOffsetX or 0) + (window.position.scrollX or 0);
                    wt.position.globalOffsetY = (window.position.globalOffsetY or 0) + (window.position.scrollY or 0);
                    wt.position.x = dx + (wt.style.margin_left or 0);
                    wt.position.y = dy + (wt.style.margin_top or 0);
                    wt.position.width = ww - (wt.style.margin_left or 0) - (wt.style.margin_right or 0);
                    wt.position.height = row.info.height - (wt.style.margin_top or 0) - (wt.style.margin_bottom or 0);

                    self:_updateElement(wt);
                    dx = dx + ww + window.style.elementSpacing;
                    if j >= row.info.count then
                        dy = dy + lineHeight;
                        dx = ox;
                        j = 0;
                    end
                end
                if j > 0 then
                    dy = dy + lineHeight;
                end
            elseif row.info.count == 0 then
                dy = dy + lineHeight;
            end
        end
    end

end

---@param info LGUI.RowInfo
---@return number|nil
local function getStaticWidth(info)
    if info and info.widths then
        local s = 0;
        for _, value in ipairs(info.widths) do
            if value <= 1 then
                return nil;
            end
            s = s + value;
        end
        return s;
    end
end


---@param widths number[]
---@param values number[]
---@return number
local function getPercentWidth(widths, values)
    local sumWidth = 0;
    for i, value in ipairs(values) do
        sumWidth = sumWidth + math.max(widths[i], value);
    end

    local t, r, p, c, o = 0, 0, 0, 0, 0;
    for index, value in ipairs(widths) do
        if value > 1 then
            t = t + value;
        elseif value < 1 then
            if value < 0 then
                if value <= -1 then
                    c = c + 1;
                else
                    r = r + value;
                end
            else
                p = p + value;
            end
        end
    end
    o = (1 - r) / c;

    for index, size in ipairs(values) do
        local value = widths[index];
        if size == 0 or value == 0 then
            error();
        end
        if value < 1 then
            if value < 0 then
                if value == -1 then
                    value = o;
                end
                sumWidth = math.max((size / value + t), sumWidth);
            else
                sumWidth = math.max((size / value), sumWidth);
            end
        end
    end

    return sumWidth;
end


---@param wt LGUI.WidgetData;
function lui:getSize(wt)
    local w, h = 0, 0;
    if not self:_isContainer(wt.name) then
        self:_widgetState(wt.name, WidgetState.measure, wt);
        w = (wt.position.measureWidth or 30);
        h = (wt.position.measureHeight or 30);
    else
        if wt.rows then
            for index, row in ipairs(wt.rows) do
                local lineHeight = row.info.height + (wt.style.lineSpacing or 0);
                if row.info.count > 0 then
                    local count = #row.widgets;
                    local round = math.ceil(count / row.info.count)
                    h = h + round * lineHeight;
                    ----
                    local sw = getStaticWidth(row.info);
                    if sw then
                        w = math.max(w, sw);
                    elseif count > 0 then
                        local k = 0;
                        for i = 1, round do
                            local arr = {};
                            for j = 1, row.info.count do
                                k = k + 1;
                                if not row.widgets[k] then
                                    break;
                                end
                                local ww, hh = self:getSize(row.widgets[k]);
                                table.insert(arr, ww);
                            end

                            local ww = getPercentWidth(row.info.widths, arr);
                            w = math.max(ww + math.max(#arr - 1, 0) * wt.style.elementSpacing, w);
                        end
                    end
                else
                    h = h + lineHeight;
                end
            end
        end
    end
    return w, h;
end

function lui:frameEnd()
    --- 标记失效
    for k, item in pairs(self._list) do
        if not item.use then
            self._list[k] = nil;
            self._windowPos[k] = nil;
        else
            item.use = false;
        end
    end

    for _, window in ipairs(self._windows) do
        self:_updateElement(window, true);
    end
    table.sort(self._windows, function(a, b)
        local l = self._windowPos[a._].layer - self._windowPos[b._].layer;
        if l == 0 then
            return self._windowPos[a._].sort < self._windowPos[b._].sort;
        end
        return l < 0;
    end)
end

---@protected
---@param x number
---@param y number
---@return LGUI.WidgetData @mouse target
---@return {item:LGUI.WidgetData,x:number,y:number}[] @list
function lui:curPosWidget(x, y)
    local ls;
    local target;

    ---@param w LGUI.WidgetData
    local function find(w, x, y, arr)
        if pointHitRect(x, y, w.position.x, w.position.y, w.position.width, w.position.height) then
            table.insert(arr, { item = w, x = x, y = y });
            if w.rows then
                local beginY = w.position.y + w.position.contentY;
                if y > beginY and y < beginY + w.position.contentHeight then -- content rect
                    for _, row in ipairs(w.rows) do
                        for _, wt in ipairs(row.widgets) do
                            local tar = find(wt, x, y + (w.position.scrollY or 0), arr);
                            if tar then
                                return tar;
                            end
                        end
                    end
                end
            end
            return w;
        end
    end

    for i = #self._windows, 1, -1 do
        ls = {};
        target = find(self._windows[i], x, y, ls);
        if target then
            break;
        end
        if self._windowPos[self._windows[i]._].layer == 1000 then --top popup
            break;
        end
    end

    return target, target and ls;
end

---@param target? LGUI.WidgetData
function lui:_setEditBox(target)
    if target then
        self.state.inputId = target._;
        self._textInput:clearHistory();
        self._textInput:setPasswordActive(arrayIndexOf(target.style.flags, lui.Flags.InputTextFlags_Password) > 0);
        self._textInput:setEditable(arrayIndexOf(target.style.flags, lui.Flags.InputTextFlags_ReadOnly) <= 0);
        self._textInput:setFont(gr.getFont());

        local flags = target.style.flags;
        self._textInput:setFilter(function(char)
            if arrayIndexOf(flags, lui.Flags.InputTextFlags_NumberOnly) > 0 then
                if not (char):match("%d") then
                    return true;
                end
            end
            if arrayIndexOf(flags, lui.Flags.InputTextFlags_CharsNoBlank) > 0 then
                if (char):match("%s") then
                    return true;
                end
            end
        end)
        self._textInput:setWidth(target.position.width - target.style.padding_left - target.style.padding_right);
        self._textInput:setText(target.values.text or "");
        self._textInput:moveCursor(999);
        self._textInput:setScroll(0);
        love.keyboard.setKeyRepeat(true);
    else
        self.state.inputId = false;
        love.keyboard.setKeyRepeat(false);
    end
end

---@param target LGUI.WidgetData @mouse target
---@param ls {item:LGUI.WidgetData,x:number,y:number}[] @list
function lui:_dispatchEvent(etype, target, ls, p1, p2, p3, p4, p5)
    local isMouseDown = etype == lui.Event.mousepressed;
    local isDragWindow, ret;
    if ls and #ls > 0 then
        local dealIndex = 1;
        for i = 1, #ls do --- push
            local value = ls[i];
            ret = self:_widgetState(value.item.name, etype, value.item, true, value.x, value.y, p3, p4, p5);
            if i == 1 then
                isDragWindow = isMouseDown and tostring(ret) == "drag";
            end
            local isTrue = false;
            if #ls == 1 or i ~= 1 then
                isTrue = ret;
            end

            if isTrue then
                target = value.item;
                dealIndex = i;
                break;
            end
        end

        for i = dealIndex, 1, -1 do --- pop
            local value = ls[i];
            local ret = self:_widgetState(value.item.name, etype, value.item, false, value.x, value.y, p3, p4, p5);
            if ret then
                break;
            end
        end

        if not target and isDragWindow then
            target = ls[1].item;
        end
    end

    return target, isDragWindow, ret;
end

---@protected
---@param etype string
---@param p1 any
---@param p2 any
---@param p3 any
---@param p4 any
---@param p5 any
function lui:_event(etype, p1, p2, p3, p4, p5)
    local isMouseDown   = etype == lui.Event.mousepressed;
    local isMouseRelase = etype == lui.Event.mousereleased;
    local isTouchEvent  = isMouseDown or isMouseRelase or etype == lui.Event.mousemoved;
    local windowId;

    local lastHoverId = self.state.hoverId;
    local lastFocusId = self.state.focusId;
    local lastTouchId = self.state.pressId;

    if isTouchEvent then
        local hoverTarget, ls = self:curPosWidget(p1, p2);
        if ls and #ls > 0 then
            windowId = ls[1].item._;
        end

        local target, ret;
        local isDragWindow;

        self.state.hoverId = hoverTarget and hoverTarget._;

        if isMouseDown then
            target, isDragWindow, ret = self:_dispatchEvent(etype, target, ls, p1, p2, p3, p4, p5);

        else
            if lastHoverId ~= self.state.hoverId then
                if lastHoverId then
                    local wgt = self._list[lastHoverId];
                    if wgt then
                        self:_widgetState(wgt.data.name, WidgetState.unhover, wgt.data, true, hoverTarget);
                    end
                end
                if self.state.hoverId then
                    self:_dispatchEvent(WidgetState.hover, hoverTarget, ls, p1, p2, p3, p4, p5);
                end
            end

            target, ret = self:_dispatchEvent(etype, target, ls, p1, p2, p3, p4, p5);

        end

        local targetId = target and target._;
        if isMouseDown then
            -- if targetId then
            self.state.pressId = targetId;
            self.state.focusId = targetId;
            -- end
            if windowId then
                self._windowPos[windowId].sort = os.clock();
                if isDragWindow and windowId == targetId then
                    if arrayIndexOf(self._list[windowId].data.style.flags, lui.Flags.WindowFlags_NoMove) < 0 then
                        self.stateDrag.x      = love.mouse.getX() - self._list[windowId].data.position.x;
                        self.stateDrag.y      = love.mouse.getY() - self._list[windowId].data.position.y;
                        self.stateDrag.widget = true;
                    end
                end
            end
        else
            if lastTouchId and lastTouchId ~= targetId then
                local widget = self._list[lastTouchId];
                if widget then
                    _, pushData = self:_widgetState(widget.data.name, etype, widget.data, nil, p1 + (widget.data.position.globalOffsetX or 0), p2 + (widget.data.position.globalOffsetY or 0), p3, p4, p5);
                end
            end

            if isMouseRelase then
                if target then
                    if self.state.pressId == targetId then
                        local ret = self:_widgetState(target.name, WidgetState.lclick, target);
                        self:setReturnValues(targetId, ret or { true });
                    end
                end
                self.state.pressId = nil;
                self.stateDrag.widget = nil;
                self.stateDrag.x = nil;
                self.stateDrag.y = nil;
            else -- mousemove
                if self.stateDrag.widget then
                    local tar = self._list[self.state.pressId];
                    if tar then
                        local x = love.mouse.getX() - self.stateDrag.x;
                        local y = love.mouse.getY() - self.stateDrag.y;
                        self:setReturnValues(tar.data._, { true }, { x = x, y = y });
                    end
                end
            end
        end
    elseif etype == lui.Event.wheelmoved then
        local tar, ls = self:curPosWidget(love.mouse.getX(), love.mouse.getY());
        if tar then
            if #ls > 0 and ls[1].item.name == WidgetName.window then
                local panel;
                local step = p2 * 5;
                for i = #ls, 1, -1 do
                    if self:_isContainer(ls[i].item.name) then
                        panel = ls[i].item;
                        local max = panel.position.actualHeight - panel.position.contentHeight;
                        if max > 0 then
                            local next = mclump((panel.position.scrollY or 0) - step, 0, max);
                            if (panel.position.scrollY or 0) ~= next then
                                break;
                            end
                        end
                    end
                end

                if panel then
                    local panelId = panel._;
                    local max = panel.position.actualHeight - panel.position.contentHeight;
                    local value = self._windowPos[panelId].scrollY - step;
                    self._windowPos[panelId].scrollY = mclump(value, 0, max);
                end

            end
        end

    else
        if self.state.focusId and self.state.inputId then
            self._textInput[etype](self._textInput, p1, p2, p3, p4, p5);
            self:setReturnValues(self.state.focusId, { true }, { text = self._textInput:getText() });
        end
    end

    if self.state.focusId ~= lastFocusId then
        if self.state.mainMenuId and self.state.mainMenuId ~= self.state.focusId then
            local menuWidget = self._list[self.state.mainMenuId];
            if menuWidget then
                self:_widgetState(menuWidget.data.name, WidgetState.unfocus, menuWidget.data);
            end
        end
        local focusWidget = self._list[lastFocusId];
        if focusWidget then
            self:_widgetState(focusWidget.data.name, WidgetState.unfocus, focusWidget.data);
        end
    end

end

---
---滚动到当前元素的位置
---
---scroll to the position of the current element
---@param x number
---@param y number
function lui:scrollTo(x, y)

end

---comment
---@protected
---@param element LGUI.WidgetData
function lui:_drawElement(element)
    if not element or not element.name or element.name == "" then
        return;
    end
    gr.push("all");
    self:_widgetState(element.name, WidgetState.draw, element);
    -----
    if self._debug then
        gr.setColor(1, 1, 1, 0.5);
        gr.rectangle("line", element.position.x or 0, element.position.y or 0, element.position.width or 0, element.position.height or 0);
    end
    if self:_isContainer(element.name) and element.position.actualHeight > element.position.contentHeight then
        ---------
        local scrollX, scrollY = gr.inverseTransformPoint(0, 0);
        gr.intersectScissor(
            element.position.x + element.position.contentX - scrollX,
            element.position.y + element.position.contentY - scrollY,
            math.max(element.position.contentWidth, 0) + 1,
            math.max(element.position.contentHeight, 0) + 1
        );
        gr.translate(-(element.position.scrollX or 0), -math.floor(element.position.scrollY or 0));
    end
    if element.rows then
        for i, row in ipairs(element.rows) do
            for _, wt in ipairs(row.widgets) do
                self:_drawElement(wt);
            end
        end
    end
    gr.pop();
    self:_widgetState(element.name, WidgetState.draw_top, element);

end

function lui:draw()
    gr.push("all");
    for _, window in ipairs(self._windows) do
        gr.setScissor();
        self:_drawElement(window);
    end
    gr.pop();
end

return lui;


---@class LGUI.RowInfo
---@field count number
---@field height number
---@field measureSize boolean
---@field widths number[]

---@class LGUI.ContainerPos : LGUI.Position
---@field lastX number
---@field lastY number
---@field sort number
---@field layer number
---@field temp any
---@field parentId any

---@class LGUI.WidgetData
---@field id string
---@field _ any    // static id
---@field name string
---@field values {id:string}|any
---@field style LGUI.Style
---@field position LGUI.Position
---@field measureSize boolean
---@field rows {info:LGUI.RowInfo,widgets:LGUI.WidgetData[]}[]

---@class LGUI.Position
---@field width number
---@field height number
---@field measureWidth number
---@field measureHeight number
---@field actualWidth number
---@field actualHeight number
---@field contentWidth number --内容宽
---@field contentHeight number --内容高
---@field contentX number
---@field contentY number
---@field globalOffsetX number
---@field globalOffsetY number
---@field x number
---@field y number
---@field scrollX number
---@field scrollY number

---@class LGUI.BaseStyle
---@field width number image
---@field height number image
---@field icon love.Drawable --button image
---@field color string
---@field strokeColor string
---@field text string --button label
---@field displayText string --button label
---@field backgound_color string --button
---@field lineSpacing number --window
---@field elementSpacing number --window
---@field textAlign "left"|"right"|"center" --label button
---@field textVerticalAlign "top"|"bottom"|"middle" --label button
---@field border_radius number -- button window
---@field border_color number -- button window
---@field border_width number -- button window
---@field padding_left number -- button window
---@field padding_right number -- button window
---@field padding_top number -- button window
---@field padding_bottom number -- button window
---@field margin_left number
---@field margin_right number
---@field margin_top number
---@field margin_bottom number
---@field title_background_color string
---@field title_height number

---@class LGUI.Style : LGUI.BaseStyle
---@field flags? string[]
---@field hover LGUI.BaseStyle
---@field focus LGUI.BaseStyle