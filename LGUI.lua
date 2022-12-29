local InputField = require("InputField")
local lstyle = require("style")

local gr = love.graphics;

---@class LGUI
---@field new fun():LGUI
---@field _widgets table<string,any>
---@field _widgetStyles table<string,any>
---@field _currentWindow LGUI.WidgetData
---@field _defaultWindow LGUI.WidgetData
---@field _windows LGUI.WidgetData[]
---@field _uuid number
---@field _textInput any
---@field _fucusWidgetId any
---@field _hoverWidgetId any
---@field _touchWidgetId any
---@field _isInput boolean
---@field _events {type:string,args:any[]}[]
---@field _push table<string,any>
---@field _list table<string,{data:LGUI.WidgetData,use:boolean}>
---@field _containerStack LGUI.WidgetData[]
---@field _dragX number
---@field _dragY number
---@field _windowPos table<string,{x:number,y:number,width:number,height:number,lastX:number,lastY:number,sort:number}>
local ui = {}

function ui.new()
    local inst = setmetatable({}, { __index = ui });
    inst.ctor(inst);
    return inst;
end

local c_white = { 1, 1, 1 };

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

local function pointHitRect(x, y, x1, y1, w, h)
    return x >= x1 and x <= x1 + w and y >= y1 and y < y1 + h;
end

local _c_colors_ = {};
---@param hex string|number
---@return number[] @r,g,b,a
local function color2(hex)
    local t = type(hex);
    local isString = t == "string"
    if isString or t == "number" then --16进制的颜色
        if _c_colors_[hex] then
            return _c_colors_[hex];
        end
        local colors;
        if isString then
            hex = string.gsub(string.lower(hex), " ", "");
            local len = #hex;
            if len > 3 then
                local unit = 0xff;
                if string.sub(hex, 1, 1) == "#" then
                    local step = 1;
                    if len > 5 then
                        hex = tonumber(string.sub(hex, 2, len), 16);
                    else
                        colors = { string.match(hex, "#([0-9a-f])([0-9a-f])([0-9a-f])([0-9a-f]?)") };
                        unit = 0xf;
                    end
                elseif string.sub(hex, 1, 2) == "0x" then
                    hex = tonumber(hex, 16);
                elseif string.sub(hex, 1, 3) == "rgb" then
                    colors = { string.match(hex, "%((%d+),(%d+),(%d+),?(%d-)%)") };
                end
                if colors then
                    if colors[4] == "" then
                        table.remove(colors, 4);
                    end
                    for i, v in ipairs(colors) do
                        colors[i] = (tonumber(v, (unit == 0xff) and 10 or 16) or unit) / unit;
                    end
                    ---------
                    _c_colors_[hex] = colors;
                    return colors;
                end
            else
                -- hex = 0xffffff;
                return c_white;
            end
        end
        colors = {};
        if bit.band(hex, bit.bnot(0xffffff)) ~= 0 then -- 存在aplha值
            table.insert(colors, bit.band(bit.rshift(hex, 24), 0xff) / 0xff);
        end
        table.insert(colors, bit.band(bit.rshift(hex, 16), 0xff) / 0xff);
        table.insert(colors, bit.band(bit.rshift(hex, 8), 0xff) / 0xff);
        table.insert(colors, bit.band(hex, 0xff) / 0xff);
        -------
        _c_colors_[hex] = colors;
        return colors;
    elseif t == "table" then
        return t;
    end
    return c_white;
end

local function assignStyle(dst, src)
    src = src or {};
    src.hover = src.hover or dst.hover or {};
    src.focus = src.focus or dst.focus or {};
    setmetatable(src, { __index = dst });
    setmetatable(src.hover, { __index = src });
    setmetatable(src.focus, { __index = src });
    return src;
end

local function assignValue(dst, src)
    for key, value in pairs(dst) do
        src[key] = value or src[key];
    end
    return src;
end


local function textAlign(align, vAlign, textWdith, textHeight, width, height)
    local cx = 0;
    local cy = 0;
    local isRight = align == ui.TextAlign.right;
    local isMiddle = vAlign == ui.TextAlign.middle;
    if isRight or align == ui.TextAlign.center then
        if isRight then
            cx = (width - math.min(width, textWdith or 0));
        else
            cx = (width - math.min(width, textWdith or 0)) / 2;
        end
    end
    if isMiddle or vAlign == ui.TextAlign.bottom then
        if isMiddle then
            cy = (height - math.min(height, textHeight or 0)) / 2;
        else
            cy = (height - math.min(height, textHeight or 0));
        end
    end
    return cx, cy;
end


local WidgetState = {
    measure = "measure";
    update = "update";
    draw = "draw";
    lclick = "lclick";
};

---小部件
---@class LGUI.Widget
local Widget = {}

---@param state string
---@param values any
---@param position LGUI.Position
---@param style LGUI.Style
---@param wt LGUI.WidgetData
---@param ui LGUI
function Widget.button(state, values, position, style, wt, ui)
    if state == WidgetState.measure then
        local font = gr.getFont();
        local str = values.text or "";
        local h = font:getHeight();
        if str ~= "" then
            local w = font:getWidth(str);
            return w, h;
        end
        return 0, h;
    elseif state == WidgetState.draw then
        local lst = style;
        if --[[ ui:isFocus(wt) or --]] ui:isDown(wt) or values.selected then
            lst = style.focus;
        elseif ui:isHover(wt) then
            lst = style.hover;
        end
        if lst.border_width > 0 then
            gr.setColor(color2(lst.border_color));
            gr.rectangle("fill"--[[DrawMode.FILL]] , math.ceil(position.x), math.ceil(position.y), math.floor(position.width), math.floor(position.height), lst.border_radius or 0);
        end
        gr.setColor(color2(lst.backgound_color));
        gr.rectangle("fill"--[[DrawMode.FILL]] , math.ceil(position.x + lst.border_width), math.ceil(position.y + lst.border_width), math.floor(position.width - lst.border_width * 2), math.floor(position.height - lst.border_width * 2),
            lst.border_radius or 0);

        local cx, cy = textAlign(lst.textAlign, lst.textVerticalAlign, wt.position.measureWidth, wt.position.measureHeight, position.width - lst.border_width * 2, position.height);
        gr.setColor(color2(lst.color or "#ffffff"));
        gr.print(values.text or "", mround(position.x + cx + lst.border_width), mround(position.y + math.max(0, cy)));
    elseif state == WidgetState.lclick then
        if values.selected ~= nil then
            values.selected = not values.selected;
        end
    end

end

---@param values any
---@param position LGUI.Position
---@param style LGUI.Style
---@param wt LGUI.WidgetData
---@param ui LGUI
function Widget.label(state, values, position, style, wt, ui)
    if state == WidgetState.measure then
        local font = gr.getFont();
        local str = values.text or "";
        local h = font:getHeight();
        if str ~= "" then
            local w = font:getWidth(str);
            return w, h;
        end
        return 0, h;
    elseif state == WidgetState.update then

    elseif state == WidgetState.draw then
        local lst = style;
        if ui:isFocus(wt) then
            lst = lst.focus;
        elseif ui:isHover(wt) then
            lst = lst.hover;
        end

        local cx, cy = textAlign(lst.textAlign, lst.textVerticalAlign, wt.position.measureWidth, wt.position.measureHeight, position.width, position.height);
        gr.setColor(color2(lst.color or "#ffffff"));
        gr.print(values.text or "", mround(position.x + cx), mround(position.y + math.max(0, cy)));
    end
end

---@param values any
---@param position LGUI.Position
---@param style LGUI.Style
---@param wt LGUI.WidgetData
---@param ui LGUI
function Widget.edit(state, values, position, style, wt, ui)
    if state == WidgetState.measure then
        local font = gr.getFont();
        local str = values.text or "";
        local h = font:getHeight();
        if str ~= "" then
            local w = font:getWidth(str);
            return w, h;
        end
        return 0, h;
    elseif state == WidgetState.update then
        if ui:isFocus(wt) then
            ui._textInput:update(love.timer.getDelta());
        end
    elseif state == WidgetState.draw then
        local font = love.graphics:getFont();
        local fontHeight = font:getHeight();

        local lst = style;
        local isFocus = ui:isFocus(wt);
        if isFocus then
            lst = lst.focus;
        elseif ui:isHover(wt) then
            lst = lst.hover;
        end
        gr.push("all");
        gr.setColor(color2(lst.border_color));
        gr.rectangle("fill"--[[DrawMode.FILL]] , math.ceil(position.x), math.ceil(position.y), math.floor(position.width), math.floor(position.height), lst.border_radius or 0);
        gr.setColor(color2(lst.backgound_color));
        gr.rectangle("fill"--[[DrawMode.FILL]] , math.ceil(position.x + lst.border_width), math.ceil(position.y + lst.border_width), math.floor(position.width - lst.border_width * 2), math.floor(position.height - lst.border_width * 2),
            lst.border_radius or 0);
        local dx = position.x; -- math.max(0, mround(position.x + (position.width - position.measureWidth) / 2));
        local dy = math.max(0, mround(position.y + (position.height - math.max(fontHeight, position.measureHeight or 0)) / 2));
        gr.intersectScissor(position.x + 3, position.y, position.width - 3, position.height);
        local offsetX = 0;
        if isFocus then
            local textInput = ui._textInput;
            local x1, x2 = textInput:getSelectionOffset();
            local cx = textInput:getCursorOffset();
            offsetX = textInput:getTextOffset();
            if cx then
                if x2 > x1 then
                    love.graphics.setColor(1, 1, 1, 0.2);
                    love.graphics.rectangle("fill", dx + x1 + lst.border_width + 3, dy, x2 - x1, fontHeight);
                end
                love.graphics.setColor(1, 1, 1, 1);
                local blink = textInput:getBlinkPhase();
                if (blink - math.floor(blink)) < 0.5 then
                    love.graphics.rectangle("fill", dx + cx + lst.border_width + 3, dy, 1, fontHeight)
                end
            end
        end
        gr.setColor(color2(lst.color or "#ffffff"));
        gr.print(values.text or "", mround(dx + offsetX + lst.border_width + 3), mround(dy));
        gr.pop();
    end
end

---@param values any
---@param position LGUI.Position
---@param style LGUI.Style
---@param wt LGUI.WidgetData
---@param ui LGUI
function Widget.window(state, values, position, style, wt, ui)
    if state == WidgetState.measure then
        local font = gr.getFont();
        local str = values.title or "窗口";
        local h = font:getHeight();
        if str and str ~= "" then
            local w = font:getWidth(str);
            return w, h;
        end
        return 0, h;
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
        local strTitleWidth = titleWidth - lst.padding_left - lst.padding_right;
        gr.setColor(color2(wt.style.border_color));
        gr.rectangle("fill", wt.position.x, wt.position.y, wt.position.width, wt.position.height, wt.style.border_radius);
        gr.setColor(color2(wt.style.backgound_color));
        gr.rectangle("fill", wt.position.x + wt.style.border_width, wt.position.y + wt.style.border_width, titleWidth, wt.position.height - wt.style.border_width * 2, wt.style.border_radius);
        if arrayIndexOf(wt.style.flags, ui.Flags.WindowFlags_NoTitleBar) <= 0 then
            gr.setColor(color2(wt.style.title_background_color));
            gr.rectangle("fill", wt.position.x + wt.style.border_width, wt.position.y + wt.style.border_width, titleWidth, wt.style.title_height, wt.style.border_radius);
            local title = values.title or "窗口"
            local x, y  = textAlign(wt.style.textAlign, wt.style.textVerticalAlign, wt.position.measureWidth, wt.position.measureHeight, strTitleWidth, wt.style.title_height);
            gr.setColor(color2(lst.color or "#ffffff"));
            gr.print(title, mround(wt.position.x + x + wt.style.padding_left), mround(wt.position.y + y));
        end
    end
end

local WidgetName = {};
WidgetName.label = "label";
WidgetName.button = "button";
WidgetName.selection = "selection";
WidgetName.edit = "edit";
WidgetName.panel = "panel";
WidgetName.window = "window";
WidgetName.group = "group";

ui.TextAlign = {
    left = "left",
    right = "right",
    center = "center",
    top = "top",
    bottom = "bottom",
    middle = "middle",
}

ui.Flags = {
    WindowFlags_NoScrollbar = "NoScrollbar",
    WindowFlags_NoMove = "NoMove",
    WindowFlags_NoTitleBar = "NoTitleBar",
    WindowFlags_NoResize = "NoResize",
    EditPaste = "EditPaste",
    EditCopy = "EditCopy",
    EditAllSelection = "EditAllSelection",
    EditSelection = "EditSelection",
    EditRedo = "EditRedo",
    EditUndo = "EditUndo",
}

ui.Event = {
    keypressed = "keypressed",
    textinput = "textinput",
    mousepressed = "mousepressed",
    mousemoved = "mousemoved",
    mousereleased = "mousereleased",
    wheelmoved = "wheelmoved",
}



function ui:ctor()
    self._events = {};
    self._widgets = {};
    self._windows = {};
    self._widgetStyles = {};
    self._push = {};
    self._list = {};
    self._debug = nil;
    self._containerStack = {};
    self._windowPos = {};
    self:registerWidget(Widget.label, WidgetName.label, lstyle[WidgetName.label]);
    self:registerWidget(Widget.button, WidgetName.button, lstyle[WidgetName.button]);
    self:registerWidget(Widget.button, WidgetName.selection, lstyle[WidgetName.selection]);
    self:registerWidget(Widget.edit, WidgetName.edit, lstyle[WidgetName.edit]);
    self:registerWidget(Widget.window, WidgetName.window, lstyle[WidgetName.window]);
    self:registerWidget(Widget.window, WidgetName.group, lstyle[WidgetName.group]);
    -- self._widgetStyles[WidgetName.window] = lstyle[WidgetName.window];
    -- self:registerWidget(Panel, WidgetName.panel, {});
end

function ui:keypressed(key, scancode, isRepeat)
    table.insert(self._events, { type = ui.Event.keypressed, args = { key, scancode, isRepeat } });
    self:_event();
end

function ui:textinput(text, a)
    table.insert(self._events, { type = ui.Event.textinput, args = { text, a } });
    self:_event();
end

function ui:mousepressed(...)
    table.insert(self._events, { type = ui.Event.mousepressed, args = { ... } });
    self:_event();
end

function ui:mousemoved(...)
    table.insert(self._events, { type = ui.Event.mousemoved, args = { ... } });
    self:_event();
end

function ui:mousereleased(...)
    table.insert(self._events, { type = ui.Event.mousereleased, args = { ... } });
    self:_event();
end

function ui:wheelmoved(x, y)
    table.insert(self._events, { type = ui.Event.wheelmoved, args = { x, y } });
    self:_event();
end


---@return number
function ui:uuid()
    if not self._uuid then
        self._uuid = 0;
    end
    self._uuid = self._uuid + 1;
    return self._uuid;
end

---@param widget function
---@param name string
---@param style LGUI.Style
function ui:registerWidget(widget, name, style)
    if self._widgets[name] then
        print("widget is exist:", name);
    end
    self._widgets[name] = widget;
    self._widgetStyles[name] = style;
end

---@protected
---@param style? LGUI.Style
---@return any
function ui:_widget(name, style, values, static)
    local cur = self:_curContainer();
    if not cur then
        return;
    end

    values = values or {};
    local id = tostring(self:uuid());

    local uuid = static and id or values;

    local r = self._push[uuid];
    self._push[uuid] = nil;

    if r and r.values then
        assignValue(r.values, values);
    end

    local len = #cur.rows;
    if len >= 1 then
        local wgt = cur.rows[len].widgets;
        if name then
            local o = { _ = uuid, name = name, id = id, position = {}, values = values, style = style or {} };
            self._list[uuid] = { data = o, use = true };
            table.insert(wgt, o);
        else
            table.insert(wgt, { _ = uuid, nil, id = id, position = {}, values = values, style = style or {} });
        end
    end

    return unpack(r and r.ret or {});
end


---@protected
---@param name string
---@param st? LGUI.Style
---@param static? boolean
function ui:_widgetBegin(name, values, st, static)
    local cur = self:_curContainer();

    local id = tostring(self:uuid());
    values = values or {};
    local uuid = static and id or values;

    local r = self._push[uuid];
    self._push[uuid] = nil;

    local unchanged;
    if name == WidgetName.window then
        if not self._windowPos[uuid] then
            self._windowPos[uuid] = { x = values.x, y = values.y, lastX = values.x, lastY = values.y, sort = os.clock() };
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

    if r and r.values then
        assignValue(r.values, values);
        if unchanged then
            self._windowPos[uuid].x = values.x or self._windowPos[uuid].x;
            self._windowPos[uuid].y = values.y or self._windowPos[uuid].y;
        end
    end
    if name == WidgetName.window then
        local posX, posY;
        if self._windowPos[uuid] then
            posX = self._windowPos[uuid].x;
            posY = self._windowPos[uuid].y;
        end
        local _currentWindow = { id = id, _ = uuid, values = values or {}, name = name, rows = {}, position = { width = 200, height = 300, x = posX or values.x, y = posY or values.y }, style = assignStyle(self._widgetStyles[name], st) };
        self._list[uuid] = { data = _currentWindow, use = true };
        table.insert(self._windows, _currentWindow);
        self:_pushStack(_currentWindow);
    elseif name == WidgetName.group then
        if cur then
            ---@type LGUI.WidgetData
            local _currentWindow = { id = id, _ = uuid, measureSize = true, values = values, name = name, rows = {}, position = { width = 0, height = 300, }, style = assignStyle(self._widgetStyles[name], st) };
            self._list[uuid] = { data = _currentWindow, use = true };
            local len = #cur.rows;
            local wgt = cur.rows[len].widgets;
            table.insert(wgt, _currentWindow)
            self:_pushStack(_currentWindow);
        end
    end

    return self._currentWindow;
end

---@protected
function ui:_widgetEnd()
    self._currentWindow = nil;
    self:_popStack();
end

---@protected
function ui:_curContainer()
    return self._currentWindow or self._defaultWindow;
end

---@protected
---@param wt LGUI.WidgetData
function ui:_pushStack(wt)
    table.insert(self._containerStack, wt);
    self._currentWindow = wt;
end

---@protected
function ui:_popStack()
    if #self._containerStack > 0 then
        table.remove(self._containerStack, #self._containerStack);
    end
    self._currentWindow = self._containerStack[#self._containerStack];
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
function ui:layoutRow(height, count)
    local cur = self:_curContainer();
    height = height or 26;
    count = count or 1;
    if cur and count then
        local ty = type(count);
        local width = cur.position.width;
        local num = count;
        if ty == "table" then
            num = #count;
        end
        width = cur.position.width - cur.style.padding_left - cur.style.padding_right - math.max(0, (num - 1) * cur.style.elementSpacing) - cur.style.border_width * 2;
        local widths;
        local measure = true;
        if not cur.measureSize then
            widths = layoutRowSize(width, count);
            measure = false;
        else
            if ty == "table" then
                widths = count;
            end
        end
        table.insert(cur.rows, { info = { count = num, height = height, widths = widths, measureSize = measure }, widgets = {} });
    end
end

function ui:blank()
    self:_widget(nil, nil, nil);
end

function ui:blankline(height)
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
function ui:button(text, st)
    if type(text) == "table" then
        return self:_widget(WidgetName.button, assignStyle(self._widgetStyles[WidgetName.button], st), text);
    else
        return self:_widget(WidgetName.button, assignStyle(self._widgetStyles[WidgetName.button], st), { text = text }, true);
    end
end

---@param text string
---@param st? LGUI.Style
function ui:label(text, st)
    self:_widget(WidgetName.label, assignStyle(self._widgetStyles[WidgetName.label], st), { text = text }, true);
end

---
---@overload fun(self:LGUI,title:string,selected:boolean,st?:LGUI.Style):boolean
---@param value? {text:string,selected:boolean}
---@param st? LGUI.Style
---@return boolean
function ui:selection(value, st, c)
    if type(value) == "table" then
        return self:_widget(WidgetName.selection, assignStyle(self._widgetStyles[WidgetName.selection], st), value);
    else
        return self:_widget(WidgetName.selection, assignStyle(self._widgetStyles[WidgetName.selection], c), { text = value, selected = st }, true);
    end
end


---@param value {text:string}
---@param st? LGUI.Style
function ui:edit(value, st)
    if not self._textInput then
        self._textInput = InputField("");
    end
    self:_widget(WidgetName.edit, assignStyle(self._widgetStyles[WidgetName.edit], st), value);
end

---@overload fun(self:LGUI,window:{title:string,x:number,y:number},st?:LGUI.Style)
---@param title string
---@param x? number
---@param y? number
---@param st? LGUI.Style
---@return boolean
function ui:windowBegin(title, x, y, st)
    local values;
    local static = true;
    if type(title) == "table" then
        values = title;
        st = x;
        static = false;
    else
        values = { title = title, x = x, y = y };
    end
    local w = self:_widgetBegin(WidgetName.window, values, st, static);
    if w then
        w.position.width = st.width or w.position.width;
        w.position.height = st.height or w.position.height;
    end
    return not not w;
end

function ui:windowEnd()
    self:_widgetEnd();
end

---@param title string
---@param st? LGUI.Style
---@return boolean
function ui:groupBegin(title, st)
    local w = self:_widgetBegin(WidgetName.group, { title = title }, st);
    if w and st then
        w.position.width = st.width or w.position.width;
        w.position.height = st.height or w.position.height;
    end
    return true;
end

function ui:groupEnd()
    self:_widgetEnd();
end

---@param wt LGUI.WidgetData
function ui:isHover(wt)
    return self._hoverWidgetId and self._hoverWidgetId == (wt and wt._);
end

---@param wt LGUI.WidgetData
function ui:isFocus(wt)
    return self._fucusWidgetId and self._fucusWidgetId == (wt and wt._);
end

---@param wt LGUI.WidgetData
function ui:isDown(wt)
    return self._touchWidgetId and self._touchWidgetId == (wt and wt._);
end


---@param w? number
---@param h? number
---@param x? number
---@param y? number
function ui:beginFrame(w, h, x, y)
    w = w or 800;
    h = h or 600;
    x = x or 0;
    y = y or 0;

    self._windows = {};
    self._containerStack = {};
    self._uuid = 0;
    self._currentWindow = nil;
    self._defaultWindow = nil;

    return true;
end


---@protected
---@param window LGUI.WidgetData
function ui:_updateElement(window)
    local otherWdith = (window.style.padding_left or 0) + (window.style.border_width or 0) + (window.style.padding_right or 0);
    local ox, oy = (window.position.x or 0) + (window.style.padding_left or 0) + (window.style.border_width or 0), ((window.position.y or 0) + (window.style.padding_top or 0) + (window.style.border_width or 0));
    if arrayIndexOf(window.style.flags, ui.Flags.WindowFlags_NoTitleBar) <= 0 then
        oy = oy + (window.style.title_height or 0);
    end
    local dx = ox;
    local dy = oy;
    local width, height = window.position.width, window.position.height;

    self:_widgetState(window.name, WidgetState.update, window);
    window.position.measureWidth, window.position.measureHeight = self:_widgetState(window.name, WidgetState.measure, window); -- size

    if window.rows then
        for i, row in ipairs(window.rows) do
            dx = ox;
            local j = 0;
            if row.info.measureSize then
                local widths = layoutRowSize(width - otherWdith, row.info.widths or row.info.count);
                row.info.widths = widths;
                row.info.measureSize = false;
            end
            if #row.widgets > 0 then
                for index, wt in ipairs(row.widgets) do
                    j = j + 1;
                    local ww = row.info.widths[j];
                    -- if wt.name then
                    --     local comp = self._widgets[wt.name];
                    --     if comp then
                    wt.position.x = dx + (wt.style.margin_left or 0);
                    wt.position.y = dy + (wt.style.margin_top or 0);
                    wt.position.width = ww - (wt.style.margin_left or 0) - (wt.style.margin_right or 0);
                    wt.position.height = row.info.height - (wt.style.margin_top or 0) - (wt.style.margin_bottom or 0);
                    --         if comp then
                    --             self:_widgetState(comp, WidgetState.update, wt);
                    --             wt.position.measureWidth, wt.position.measureHeight = self:_widgetState(comp, WidgetState.measure, wt); -- size
                    --         end
                    --     else
                    --         print("a???", wt.id, wt.name, type(wt.name))
                    --     end
                    -- end

                    self:_updateElement(wt);


                    dx = dx + ww + window.style.elementSpacing;
                    if j >= row.info.count then
                        dy = dy + row.info.height + window.style.lineSpacing;
                        dx = ox;
                        j = 0;
                    end
                end
                if j > 0 then
                    dy = dy + row.info.height + window.style.lineSpacing;
                end
            elseif row.info.count == 0 then
                dy = dy + row.info.height + window.style.lineSpacing;
            end
        end
    end

end


function ui:endFrame()
    --- 标记失效
    for k, item in pairs(self._list) do
        if not item.use then
            self._list[k] = nil;
            self._windowPos[k] = nil;
        else
            item.use = false;
        end
    end

    -- local count = 0;
    -- for key, value in pairs(self._list) do
    --     count = count + 1;
    -- end
    -- print(count, #self._windows)
    -- print(#self._containerStack)

    for _, window in ipairs(self._windows) do
        self:_updateElement(window);
    end
    table.sort(self._windows, function(a, b)
        return self._windowPos[a._].sort < self._windowPos[b._].sort;
    end)
end

---@param ele LGUI.WidgetData
local function find(ele, x, y)
    if pointHitRect(x, y, ele.position.x, ele.position.y, ele.position.width, ele.position.height) then
        if ele.rows then
            for index, row in ipairs(ele.rows) do
                for index, wt in ipairs(row.widgets) do
                    local tar = find(wt, x, y);
                    if tar then
                        return tar;
                    end
                end
            end
        end
        return ele;
    end
end

---@protected
---@param name string
---@param state string
---@param wt LGUI.WidgetData
function ui:_widgetState(name, state, wt)
    local comp = self._widgets[name] or name;
    if type(comp) == "function" then
        return comp(state, wt.values, wt.position, wt.style, wt, self)
    end
end

---@protected
function ui:_event()
    while #self._events > 0 do
        local e = table.remove(self._events, 1);
        local isMouseDown = e.type == ui.Event.mousepressed;
        local isMouseRelase = e.type == ui.Event.mousereleased;
        local isTouchEvent = isMouseDown or isMouseRelase or e.type == ui.Event.mousemoved;
        local windowId;
        if isTouchEvent then
            local target;
            local x, y = e.args[1], e.args[2];
            local num = #self._windows;
            for i = num, 1, -1 do
                target = find(self._windows[i], x, y);
                if target then
                    windowId = self._windows[i]._;
                    break;
                end
            end
            local targetId = target and target._;
            local isValid = self._isInput;
            if isMouseDown then
                self._touchWidgetId = targetId;
                if self._isInput then
                    if self._fucusWidgetId ~= targetId then -- release
                        isValid = false;
                        self._fucusWidgetId = nil;
                    end
                else
                    isValid = false;
                end

            end
            if isValid then
                local focusWidget = self._list[self._fucusWidgetId];
                local focusWidgetName;
                if focusWidget then
                    focusWidgetName = focusWidget.data.name;
                end
                if (target ~= nil and targetId == self._fucusWidgetId and target.name == WidgetName.edit) or (focusWidgetName == WidgetName.edit) then
                    local tar = target or focusWidget.data;
                    local xv, vy = e.args[1] - tar.position.x, e.args[2] - tar.position.y;
                    local iss = false;
                    if isMouseDown then
                        iss = (xv < 0) or (vy < 0) or (target ~= nil and targetId ~= self._fucusWidgetId);
                    end
                    vy = 4;
                    if not iss then
                        if xv > 0 then
                            if xv < 6 then
                                xv = 0;
                            end
                            self._textInput[e.type](self._textInput, xv, vy - tar.position.y, e.args[3], e.args[4]);
                        end

                    end
                end
            else
                if isMouseDown then
                    self._fucusWidgetId = nil;
                    self._isInput = nil;
                    if target then
                        if targetId ~= self._fucusWidgetId then
                            self._fucusWidgetId = targetId;
                            self._touchWidgetId = targetId;
                            if target.name == WidgetName.edit then
                                self._textInput:setFont(love.graphics.getFont());
                                self._textInput:setWidth(target.position.width - 6 - target.style.border_width * 2);
                                self._textInput:setText(targetId.text or "");
                                self._textInput:moveCursor(999)
                                self._textInput:setScroll(0);
                                love.keyboard.setKeyRepeat(true);
                                self._isInput = true;
                            end
                        end

                        self._windowPos[windowId].sort = os.clock();
                        if target.name == WidgetName.window then
                            if arrayIndexOf(self._list[windowId].data.style.flags, ui.Flags.WindowFlags_NoMove) < 0 then
                                self._dragX      = love.mouse.getX() - target.position.x;
                                self._dragY      = love.mouse.getY() - target.position.y;
                                self._dragWindow = true;
                            end
                        end
                    end
                elseif isMouseRelase then
                    if target then
                        if self._touchWidgetId == targetId then
                            local ret = self:_widgetState(target.name, WidgetState.lclick, target);
                            self._push[targetId] = { ret = ret or { true } };
                        end
                        self._touchWidgetId = nil;
                    end
                    self._dragWindow = nil;
                else -- mousemove
                    if self._dragWindow then
                        -- table.print(self._list, 1)
                        local tar = self._list[self._touchWidgetId];
                        if tar then
                            local x = love.mouse.getX() - self._dragX;
                            local y = love.mouse.getY() - self._dragY;

                            self._push[tar.data._] = { ret = { true }, values = { x = x, y = y } }
                        end

                        -- print(tar.data.position.x, tar.data.position.y);
                    end

                    self._hoverWidgetId = nil;
                    if target then
                        self._hoverWidgetId = targetId;
                    end

                end
            end
        else
            if self._fucusWidgetId and self._isInput then
                self._textInput[e.type](self._textInput, unpack(e.args));
                self._push[self._fucusWidgetId] = { ret = { true }, values = { text = self._textInput:getText() } };
            end
        end

    end


end

---comment
---@protected
---@param element LGUI.WidgetData
function ui:_drawElement(element)
    if not element or not element.name or element.name == "" then
        return;
    end

    gr.push("all");
    self:_widgetState(element.name, WidgetState.draw, element);
    if element.name == WidgetName.window or element.name == WidgetName.group then
        local titleHeight = 0;
        if arrayIndexOf(element.style.flags, ui.Flags.WindowFlags_NoTitleBar) <= 0 then
            titleHeight = element.style.title_height;
        end

        local w, h = element.position.width, element.position.height - element.style.padding_bottom - element.style.padding_top - titleHeight;
        gr.intersectScissor(element.position.x,
            element.position.y + element.style.padding_top + element.style.border_width + titleHeight,
            math.max(1, w), math.max(1, h));
        gr.translate(-element.style.scrollX or 0, -element.style.scrollY or 0);
    end
    if element.rows then
        for i, row in ipairs(element.rows) do
            local j = 0;
            for index, wt in ipairs(row.widgets) do
                self:_drawElement(wt);
                if self._debug then
                    gr.setColor(1, 0, 0, 0.5);
                    gr.rectangle("line", wt.position.x or 0, wt.position.y or 0, wt.position.width or 0, wt.position.height or 0);
                end
                j = j + 1;
            end
        end
        if self._debug then
            gr.setColor(1, 1, 1, 0.5);
            gr.rectangle("line", element.position.x or 0, element.position.y or 0, element.position.width or 0, element.position.height or 0);
        end
    end
    gr.pop();
end

function ui:draw()
    gr.push("all");
    for _, window in ipairs(self._windows) do
        gr.setScissor();
        self:_drawElement(window);
        -- gr.setScissor();
        -- self:_widgetState(window.name, WidgetState.draw, window);
        -- gr.intersectScissor(window.position.x,
        --     window.position.y + window.style.padding_top + window.style.border_width + window.style.title_height,
        --     window.position.width,
        --     window.position.height - window.style.padding_bottom - window.style.padding_top - window.style.title_height);
        -- gr.translate(-window.style.scrollX, -window.style.scrollY);
        -- for i, row in ipairs(window.rows) do
        --     local j = 0;
        --     for index, wt in ipairs(row.widgets) do
        --         if wt.name then
        --             local comp = self._widgets[wt.name];
        --             if comp then
        --                 comp(WidgetState.draw, wt.values, wt.position, wt.style, wt, self)
        --             end
        --         end
        --         if self._debug then
        --             gr.setColor(1, 0, 0, 0.5);
        --             gr.rectangle("line", wt.position.x or 0, wt.position.y or 0, wt.position.width or 0, wt.position.height or 0);
        --         end
        --         j = j + 1;
        --     end
        -- end
        -- if self._debug then
        --     gr.setColor(1, 1, 1, 0.5);
        --     gr.rectangle("line", window.position.x or 0, window.position.y or 0, window.position.width or 0, window.position.height or 0);
        -- end
    end
    gr.pop();
end

return ui;


---@class LGUI.RowInfo
---@field count number
---@field height number
---@field measureSize boolean
---@field widths number[]


---@class LGUI.WidgetData
---@field id string
---@field _ any    // static id
---@field name string
---@field style LGUI.Style
---@field position LGUI.Position
---@field measureSize boolean
---@field rows {info:LGUI.RowInfo,widgets:LGUI.WidgetData[]}[]
---@field curRow number
---@field values any

---@class GUI.vec4

---@class LGUI.Position
---@field width number
---@field height number
---@field measureWidth number
---@field measureHeight number
---@field actualWidth number
---@field actualHeight number
---@field x number
---@field y number

---@class LGUI.BaseStyle
---@field color string
---@field strokeColor string
---@field text string --button label
---@field displayText string --button label
---@field backgound_color string --button
---@field lineSpacing number --window
---@field elementSpacing number --window
---@field textAlign "left"|"right"|"center" --label button
---@field textVerticalAlign "top"|"bottom"|"middle" --label button
---@field icon love.Drawable --button
---@field moveable boolean --window
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

---@class LGUI.Style : LGUI.BaseStyle, LGUI.Position
---@field scrollX number
---@field scrollY number
---@field flags string[]
---@field hover LGUI.BaseStyle
---@field focus LGUI.BaseStyle