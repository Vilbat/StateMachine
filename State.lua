local Trove = require(script.Parent.Parent.Trove)

local State = {}
State.__index = State

State.index = nil

function State.CanEnter(): boolean
	return true
end

function State.new(): table
	local state = {}
	state.__index = state

	state.trove = Trove.new()

	setmetatable(state, State)
	return state
end

function State:Extend()
	local state = {}
	state.__index = state

	setmetatable(state, self)
	return state
end

function State.Enter()
	
end

function State:HandleInput() 
end

function State:Destroy()
	self.trove:Destroy()
end

return State
