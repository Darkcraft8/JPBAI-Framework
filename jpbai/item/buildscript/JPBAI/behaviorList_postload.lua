local behaviorCfgs = assets.byExtension("jpbaiBehaviorCfg")
local listPath = "/jpbai/item/buildscript/JPBAI/behaviorList.config"
local behaviorList = assets.json(listPath)
local count = 0
local registered = {}

for i = 1, #behaviorCfgs do --Search for named behavior and add them to the buildscript
  local behaviorCfg = behaviorCfgs[i]
  local behaviorName = assets.json(behaviorCfg)["behaviorName"]
  if behaviorName then
    if not behaviorList[behaviorName] then
        registered[behaviorName] = behaviorCfg
        --sb.logInfo("[BehaviorList Postload] added at %s : %s", behaviorName, behaviorCfg)
        count = count + 1
    end
  end
end

local path = listPath .. ".patch"
assets.add(path, registered)
assets.patch(listPath, path)

if count > 0 then
  sb.logInfo("[JPBAI | BehaviorList Postload] Registered %s named behavior into %s", count, listPath)
end