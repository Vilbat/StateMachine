local Trove = require(script.Parent.Trove)

local State = {}
State.__index = State

function State.CanEnter(): boolean
	return true
end

function State.new()
	local self = setmetatable({}, State)

	self.trove = Trove.new()

	return self
end

function State:HandleInput() end

function State:Destroy()
	self.trove:Destroy()
end

return State
