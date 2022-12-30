local _c_colors_ = {};
local c_white = { 1, 1, 1 };

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


return color2;