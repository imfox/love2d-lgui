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
---@field _fucusWidgetId any
---@field _hoverWidgetId any
---@field _touchWidgetId any
---@field _isInput boolean
---@field _push table<string,any>
---@field _list table<string,{data:LGUI.WidgetData,use:boolean}>
---@field _prefixId string[]
---@field _containerStack LGUI.WidgetData[]
---@field _dragX number
---@field _dragY number
---@field _windowPos table<string,LGUI.ContainerPos>
local lui = {}

local WidgetName = {
    label = "label";
    button = "button";
    selection = "selection";
    edit = "edit";
    window = "window";
    group = "group";
};

local WidgetState = {
    measure = "measure";
    update = "update";
    draw = "draw";
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


---@class LGUI.Graphic
---@field new fun(ui:LGUI):LGUI.Graphic
---@field ui LGUI
local Graphic = {};

function Graphic.new(...)
    local inst = setmetatable({}, { __index = Graphic });
    inst:ctor(...);
    return inst;
end

---@param ui LGUI
function Graphic:ctor(ui)
    self.ui = ui;
end

function Graphic:print()
end


---小部件
---@class LGUI.Widget
local Widget = {}

---@param state string
---@param values any
---@param position LGUI.Position
---@param style LGUI.Style
---@param wt LGUI.WidgetData
---@param ui LGUI
function Widget.image(state, values, position, style, wt, ui)

end


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
        gr.setColor(color2(lst.border_color));
        gr.rectangle("fill"--[[DrawMode.FILL]] , math.ceil(position.x), math.ceil(position.y), math.floor(position.width), math.floor(position.height), lst.border_radius or 0);
        gr.setColor(color2(lst.backgound_color));
        gr.rectangle("fill"--[[DrawMode.FILL]] , math.ceil(position.x + lst.border_width), math.ceil(position.y + lst.border_width), math.floor(position.width - lst.border_width * 2), math.floor(position.height - lst.border_width * 2),
            lst.border_radius or 0);
        local dx = position.x; -- math.max(0, mround(position.x + (position.width - position.measureWidth) / 2));
        local dy = math.max(0, mround(position.y + (position.height - math.max(fontHeight, position.measureHeight or 0)) / 2));
        local gx, gy = gr.inverseTransformPoint(0, 0);
        gr.intersectScissor(position.x + 3, position.y - gy, position.width - 3, position.height);
        local offsetX = 0;
        if isFocus then
            local textInput = ui._textInput;
            local x1, x2 = textInput:getSelectionOffset();
            local cx = textInput:getCursorOffset();
            offsetX = textInput:getTextOffset();
            if cx then
                if x2 > x1 then
                    gr.setColor(1, 1, 1, 0.2);
                    gr.rectangle("fill", dx + x1 + lst.border_width + lst.padding_left, dy, x2 - x1, fontHeight);
                end
                gr.setColor(1, 1, 1, 1);
                local blink = textInput:getBlinkPhase();
                if (blink - math.floor(blink)) < 0.5 then
                    gr.rectangle("fill", dx + cx + lst.border_width + lst.padding_left, dy, 1, fontHeight)
                end
            end
        end
        gr.setColor(color2(lst.color or "#ffffff"));
        gr.print(values.text or "", mround(dx + offsetX + lst.border_width + lst.padding_left), mround(dy));
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

        --- border
        if wt.style.border_width > 0 then
            gr.setColor(color2(wt.style.border_color));
            gr.rectangle("fill", wt.position.x, wt.position.y, wt.position.width, wt.position.height, wt.style.border_radius);
        end

        --- background
        gr.setColor(color2(wt.style.backgound_color));
        gr.rectangle("fill", wt.position.x + wt.style.border_width, wt.position.y + wt.style.border_width, titleWidth, wt.position.height - wt.style.border_width * 2, wt.style.border_radius);

        local titleHeight = 0;
        --- titlebar
        if arrayIndexOf(wt.style.flags, ui.Flags.WindowFlags_NoTitleBar) <= 0 then
            titleHeight = wt.style.title_height;
            local strTitleWidth = titleWidth - lst.padding_left - lst.padding_right;

            gr.setColor(color2(wt.style.title_background_color));
            gr.rectangle("fill", wt.position.x + wt.style.border_width, wt.position.y + wt.style.border_width, titleWidth, wt.style.title_height, wt.style.border_radius);
            local title = values.title or "窗口"
            local x, y  = textAlign(wt.style.textAlign, wt.style.textVerticalAlign, wt.position.measureWidth, wt.position.measureHeight, strTitleWidth, wt.style.title_height);
            gr.setColor(color2(lst.color or "#ffffff"));
            gr.print(title, mround(wt.position.x + wt.style.border_width + x + wt.style.padding_left), mround(wt.position.y + y));
        end
    elseif state == WidgetState.draw_top then
        local titleHeight = 0;
        --- titlebar
        if arrayIndexOf(wt.style.flags, ui.Flags.WindowFlags_NoTitleBar) <= 0 then
            titleHeight = wt.style.title_height;
        end
        --- scroll
        if arrayIndexOf(wt.style.flags, ui.Flags.WindowFlags_NoScrollbar) <= 0 then
            if position.actualHeight > position.contentHeight then
                local blockHeight, blockWidth = math.max(5, 1 / (position.actualHeight / position.contentHeight) * position.contentHeight), 10;
                local topBottomSpacing, leftRightSpacing = 2, 2;
                local displayHeight = (position.contentHeight - blockHeight + wt.style.padding_top + wt.style.padding_bottom - topBottomSpacing * 2);
                local rate = position.scrollY / (position.actualHeight - position.contentHeight);

                local posX, posY = wt.position.x + position.width - wt.style.border_width - blockWidth - leftRightSpacing, topBottomSpacing + wt.position.y + wt.style.border_width + titleHeight;
                gr.setColor(0.1, 0.1, 0.1, 0.6);
                gr.rectangle("fill", posX, posY, blockWidth, displayHeight + blockHeight, style.border_radius);
                gr.setColor(0.3, 0.3, 0.3, 0.8);
                gr.rectangle("fill", posX, posY + mclump(rate * displayHeight, 0, displayHeight), blockWidth, blockHeight, style.border_radius);
            end
        end
    end
end

function lui:ctor()
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

---@return number
function lui:uuid()
    if not self._uuid then
        self._uuid = 0;
    end
    self._uuid = self._uuid + 1;
    return self._uuid;
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
---@param static boolean
function lui:_widgetBegin(name, values, st, static)
    local cur = self:_curContainer();

    local id = tostring(self:uuid());
    table.insert(self._prefixId, 1, values.id or values.title or values.text or id);

    local oid = table.concat(self._prefixId, ",");
    values = values or {};
    local uuid = static and oid or values;

    local r = self._push[uuid];
    self._push[uuid] = nil;

    local unchanged;
    if self:_isContainer(name) then
        if not self._windowPos[uuid] then
            self._windowPos[uuid] = { x = values.x, y = values.y, lastX = values.x, lastY = values.y, sort = os.clock(), scrollY = 0 };
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
        if self._windowPos[uuid] then
            values.x = self._windowPos[uuid].x;
            values.y = self._windowPos[uuid].y;
            values.scrollY = self._windowPos[uuid].scrollY;
        end
        local _currentWindow = { id = id, _ = uuid, values = values or {}, name = name, rows = {}, position = values, style = assignStyle(self._widgetStyles[name], st) };
        self._list[uuid] = { data = _currentWindow, use = true };
        table.insert(self._windows, _currentWindow);
        self:_pushStack(_currentWindow);
    elseif name == WidgetName.group then
        if cur then
            if self._windowPos[uuid] then
                values.scrollY = self._windowPos[uuid].scrollY;
            end
            ---@type LGUI.WidgetData
            local _currentWindow = { id = id, _ = uuid, measureSize = true, values = values, name = name, rows = {}, position = values, style = assignStyle(self._widgetStyles[name], st) };
            self._list[uuid] = { data = _currentWindow, use = true };
            local len = #cur.rows;
            local wgt = cur.rows[len].widgets;
            table.insert(wgt, _currentWindow)
            self:_pushStack(_currentWindow);
        end
    end

    return self._currentContainer;
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

---@protected
---@param name string
---@param state string
---@param wt LGUI.WidgetData
function lui:_widgetState(name, state, wt)
    local comp = self._widgets[name] or name;
    if type(comp) == "function" then
        return comp(state, wt.values, wt.position, wt.style, wt, self)
    end
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
    return self._hoverWidgetId and self._hoverWidgetId == (wt and wt._);
end

---@param wt LGUI.WidgetData
function lui:isFocus(wt)
    return self._fucusWidgetId and self._fucusWidgetId == (wt and wt._);
end

---@param wt LGUI.WidgetData
function lui:isDown(wt)
    return self._touchWidgetId and self._touchWidgetId == (wt and wt._);
end

function lui:frameBegin()
    self._uuid = 0;
    self._windows = {};
    self._prefixId = {};
    self._containerStack = {};
    self._currentContainer = nil;
    return true;
end


---@protected
function lui:_isContainer(name)
    return name == WidgetName.window or name == WidgetName.group;
end

---@protected
---@param window LGUI.WidgetData
function lui:_updateElement(window)
    local titleHeight = 0;
    if arrayIndexOf(window.style.flags, lui.Flags.WindowFlags_NoTitleBar) <= 0 then
        titleHeight = (window.style.title_height or 0);
    end
    window.position.contentX = (window.style.padding_left or 0) + (window.style.border_width or 0);
    window.position.contentY = (window.style.padding_top or 0) + (window.style.border_width or 0) + titleHeight;
    window.position.contentWidth = (window.position.width or 0) - (window.style.padding_left or 0) - (window.style.padding_right or 0) - (window.style.border_width or 0) * 2;
    window.position.contentHeight = (window.position.height or 0) - (window.style.padding_top or 0) - (window.style.padding_bottom or 0) - (window.style.border_width or 0) * 2 - titleHeight;

    local ox, oy = (window.position.x or 0) + window.position.contentX, (window.position.y or 0) + window.position.contentY;
    local width = window.position.contentWidth;

    window.position.actualWidth = window.position.contentWidth;
    window.position.actualHeight = 0;

    self:_widgetState(window.name, WidgetState.update, window);
    window.position.measureWidth, window.position.measureHeight = self:_widgetState(window.name, WidgetState.measure, window); -- size

    --- calc height
    if window.rows then
        local h = 0;
        for _, row in ipairs(window.rows) do
            local lineHeight = row.info.height + window.style.lineSpacing;
            if #row.widgets > 0 then
                h = h + math.ceil(#row.widgets / row.info.count) * lineHeight;
            elseif row.info.count == 0 then
                h = h + lineHeight;
            end
        end
        window.position.actualHeight = h;
        if window.position.actualHeight > window.position.contentHeight then
            window.position.scrollY = math.min(window.position.scrollY, window.position.actualHeight - window.position.contentHeight)
            if arrayIndexOf(window.style.flags, lui.Flags.WindowFlags_NoScrollbar) <= 0 then
                width = width - 12;
            end
        elseif window.position.scrollY ~= 0 then
            window.position.scrollY = 0;
        end
    end

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

---@protected
---@param x number
---@param y number
---@return LGUI.WidgetData @mouse target
---@return LGUI.WidgetData[] @list
function lui:curPosWidget(x, y)
    local ls;
    local target;

    ---@param w LGUI.WidgetData
    local function find(w, x, y, arr)
        if pointHitRect(x, y, w.position.x, w.position.y, w.position.width, w.position.height) then
            table.insert(arr, w);
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
    end

    return target, target and ls;
end

---@param target? LGUI.WidgetData
function lui:_setEditBox(target)
    if target then
        self._isInput = true;
        self._textInput:setFont(gr.getFont());
        self._textInput:setWidth(target.position.contentWidth);
        self._textInput:setText(target.values.text or "");
        self._textInput:moveCursor(999);
        self._textInput:setScroll(0);
        love.keyboard.setKeyRepeat(true);
    else
        self._isInput = false;
        love.keyboard.setKeyRepeat(false);
    end
end

---@protected
---@param etype string
---@param p1 any
---@param p2 any
---@param p3 any
---@param p4 any
---@param p5 any
function lui:_event(etype, p1, p2, p3, p4, p5)
    local isMouseDown = etype == lui.Event.mousepressed;
    local isMouseRelase = etype == lui.Event.mousereleased;
    local isTouchEvent = isMouseDown or isMouseRelase or etype == lui.Event.mousemoved;
    local windowId;
    if isTouchEvent then
        local target, ls = self:curPosWidget(p1, p2);
        if ls and #ls > 0 then
            windowId = ls[1]._;
        end

        local targetId = target and target._;
        local focusWidget = self._list[self._fucusWidgetId];

        local isLastEditBox = focusWidget and (focusWidget.data.name == WidgetName.edit);
        if isMouseDown then
            isLastEditBox = (self._fucusWidgetId == targetId) and self._isInput;
        end

        self._hoverWidgetId = targetId;

        if isLastEditBox then --last edit
            local tarX = focusWidget.data.position.x + focusWidget.data.position.contentX;
            local tarY = focusWidget.data.position.y + focusWidget.data.position.contentY;
            self._textInput[etype](self._textInput, p1 - tarX, p2 - tarY, p3, p4);
        else
            if isMouseDown then
                self._fucusWidgetId = nil;
                self._isInput = nil;
                if target then
                    if targetId ~= self._fucusWidgetId then
                        self._fucusWidgetId = targetId;
                        self._touchWidgetId = targetId;
                        if target.name == WidgetName.edit then
                            local tarX = target.position.x + target.position.contentX;
                            local tarY = target.position.y + target.position.contentY;

                            self:_setEditBox(target);

                            self._textInput[etype](self._textInput, p1 - tarX, p2 - tarY, p3, p4);
                        else
                            self:_setEditBox(nil);
                        end
                    end
                    if windowId then
                        self._windowPos[windowId].sort = os.clock();
                        if target.name == WidgetName.window then
                            if arrayIndexOf(self._list[windowId].data.style.flags, lui.Flags.WindowFlags_NoMove) < 0 then
                                self._dragX      = love.mouse.getX() - target.position.x;
                                self._dragY      = love.mouse.getY() - target.position.y;
                                self._dragWindow = true;
                            end
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
                self._dragX = 0;
                self._dragY = 0;
            else -- mousemove
                if self._dragWindow then
                    local tar = self._list[self._touchWidgetId];
                    if tar then
                        local x = love.mouse.getX() - self._dragX;
                        local y = love.mouse.getY() - self._dragY;

                        self._push[tar.data._] = { ret = { true }, values = { x = x, y = y } }
                    end

                end
            end
        end
    elseif etype == lui.Event.wheelmoved then
        local tar, ls = self:curPosWidget(love.mouse.getX(), love.mouse.getY());
        if tar then
            if #ls > 0 and ls[1].name == WidgetName.window then
                local panel;
                local step = p2 * 5;
                for i = #ls, 1, -1 do
                    if self:_isContainer(ls[i].name) then
                        panel = ls[i];
                        local max = panel.position.actualHeight - panel.position.contentHeight;
                        if max > 0 then
                            local next = mclump(panel.position.scrollY - step, 0, max);
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
        if self._fucusWidgetId and self._isInput then
            self._textInput[etype](self._textInput, p1, p2, p3, p4, p5);
            self._push[self._fucusWidgetId] = { ret = { true }, values = { text = self._textInput:getText() } };
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
    if self:_isContainer(element.name) then
        ---------
        local scrollX, scrollY = gr.inverseTransformPoint(0, 0);
        gr.intersectScissor(
            element.position.x + element.position.contentX - scrollX,
            element.position.y + element.position.contentY - scrollY,
            math.max(element.position.contentWidth, 0) + 1,
            math.max(element.position.contentHeight, 0) + 1
        );
        gr.translate(-(element.position.scrollX or 0), -(element.position.scrollY or 0));
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
---@field contentWidth number
---@field contentHeight number
---@field contentX number
---@field contentY number
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