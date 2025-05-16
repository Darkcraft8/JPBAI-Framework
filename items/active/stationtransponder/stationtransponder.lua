function init()
  if config.getParameter("replacementScripts") then
	if type(config.getParameter("replacementScripts")) == "table" then
		for _, scriptPath in ipairs(config.getParameter("replacementScripts") or {}) do 
			require (scriptPath)
		end
	else
		require (config.getParameter("replacementScripts"))
	end
  else
	require ("/items/active/stationtransponder/vanilla_stationtransponder.lua")
  end
  init()
end