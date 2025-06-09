require ("/items/active/stationtransponder/jpbai_scriptLoader.lua")
local jpbai_scriptLoaderActif = false
function init()
  if config.getParameter("replacementScripts") then loadScript() jpbai_scriptLoaderActif = true return end
  if storage.consumed then
    item.consume(1)
    return
  end
  storage.consumed = false

  message.setHandler("holdingTransponder", function() return true end)
  message.setHandler("setTransponderConsumed", function() storage.consumed = true end)
  message.setHandler("consumeTransponder", function() item.consume(1) end)
end

function activate(fireMode, shiftHeld)
  if jpbai_scriptLoaderActif then return end
  activeItem.interact(config.getParameter("interactAction"), config.getParameter("interactData"));
end

function uninit()
  if jpbai_scriptLoaderActif then return end
  if storage.consumed and item.count() > 0 then
    item.consume(1)
  end
end
