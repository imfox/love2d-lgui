_GAME_DEBUGGER_ = os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1";
if _GAME_DEBUGGER_ then
    require("lldebugger").start()
end

function love.load()
    if love.filesystem.getInfo("msyh.ttc") then
        local font = love.graphics.newFont("msyh.ttc", 12);
        love.graphics.setFont(font);
    end

    require("sample.sample1");
end