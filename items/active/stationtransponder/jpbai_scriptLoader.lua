function loadScript()
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
	if entity.entityType() == "player" then
		local itemVersioner = config.getParameter("itemVersioner", {})
		if itemVersioner.path then
			local r, m 
			if not root.assetOrigin then 
				r, m = pcall(root.assetJson, itemVersioner.path)
			else
				r, m = root.assetOrigin(string.gsub(itemVersioner.path, ":.*", ""))
			end
			if r then
				local itemVersionerCfg = root.assetJson(itemVersioner.path)
				if (itemVersioner.version or -404) ~= itemVersionerCfg.itemVersioner.version then
					itemVersionerCfg.parameters.scriptStorage = config.getParameter("scriptStorage" or {})
					itemVersionerCfg.parameters.itemVersioner = itemVersionerCfg.itemVersioner
					itemVersionerCfg.count = item.count()
					if itemVersionerCfg.itemVersioner.keepParameters then
						for _, paramName in pairs(itemVersioner.keepParameters or itemVersionerCfg.itemVersioner.keepParameters or {}) do
							itemVersionerCfg.parameters[paramName] = config.getParameter(paramName)
						end
						if not itemVersioner.keepParameters then
							itemVersionerCfg.parameters.itemVersioner.keepParameters = nil
						end
					end
					item.consume(item.count())
					player.giveItem(itemVersionerCfg)
				end
			else
				sb.logError("asset doesn't exist at %s", itemVersioner.path)
			end
		end
	end
  	init()
end