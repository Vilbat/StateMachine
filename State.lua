local Trove = require(script.Parent.Parent.Trove)

local State = {}
State.__index = State

State.index = nil

function State.CanEnter(): boolean
	return true
end

function State.new(): table
	local self = setmetatable({}, State)

	self.trove = Trove.new()

	return self
end

function State:Enter() end

function State:HandleInput() end

function State:Destroy()
	self.trove:Destroy()
end

return State
