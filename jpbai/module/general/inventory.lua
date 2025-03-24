inventory = {}
-- function that revolve around player inventory, usualy around finding an item
function inventory.hasItem(args)
  if type(args.item) == "string" then
    return player.hasItem(args.item, false)
  elseif type(args.item) == "table" then
    local descriptor = {
      item = args.item,
      count = args.count or 1,
      parameters = args.parameters or {}
    }
    return player.hasItem(descriptor, false)
  end
  return false
end

function inventory.hasExactItem(args)
  if type(args.item) == "string" then
    return player.hasItem(args.item, true)
  elseif type(args.item) == "table" then
    local descriptor = {
      item = args.item,
      count = args.count or 1,
      parameters = args.parameters or {}
    }
    return player.hasItem(descriptor, true)
  end
  return false
end

function inventory.hasItemWithParameter(args)--unfinished
  if args.parameters then
    local searchType = args.item or false
    local query = args.parameters or {}
    if self.findItemWithParam(query, args.greater) then return true end -- alway return nil because it unfinished
  end
  return false
end

function inventory.findItemWithParam(parameter, searchType, returnGreaterIfAvailable)--unfinished
  local currentItem = copy(itemDescriptor)
  if not searchType then
    --player.getItemWithParameter(parameter) 
  end
end