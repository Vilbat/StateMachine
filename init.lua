local Trove = require(script.Parent.Trove)
local Signal = require(script.Parent.Signal)
local Symbol = require(script.Parent.Symbol)

local StateMachine = {}
StateMachine.__index = StateMachine

local KEY_TROVE = Symbol("Trove")

local KEY_STATES = Symbol("States")

local KEY_DEFAULT_STATE = Symbol("DefaultState")
local KEY_CURRENT_STATE = Symbol("CurrentState")
local KEY_DATA = Symbol("Data")

local KEY_INPUT_FUNCTION = Symbol("Input")

function StateMachine.new(config: table)
	local self = setmetatable({}, StateMachine)

	self[KEY_TROVE] = Trove.new()

	self.StateChanged = self[KEY_TROVE]:Construct(Signal)

	self[KEY_STATES] = config.States
	self[KEY_DEFAULT_STATE] = config.DefaultState
	self[KEY_DATA] = config.Data or {}

	self[KEY_INPUT_FUNCTION] = config.InputFunction

	return self
end

function StateMachine:SetState(index: string)
	local state = self:GetState(index)

	local currentState = getmetatable(self[KEY_CURRENT_STATE])
	if currentState == state then
		return
	end

	if self[KEY_CURRENT_STATE] then
		self[KEY_CURRENT_STATE]:Destroy()
	end

	self[KEY_CURRENT_STATE] = state.new(table.unpack(self[KEY_DATA]))
	self[KEY_CURRENT_STATE].index = index

	self.StateChanged:Fire(self[KEY_CURRENT_STATE])

	return true
end

function StateMachine:GetState(index: string): table
	return self[KEY_STATES][index]
end

function StateMachine:Update()
	local state = self[KEY_CURRENT_STATE]

	while state do
		local newState = state:HandleInput(self[KEY_INPUT_FUNCTION]())
		if newState then
			local status = self:SetState(newState)
			return status
		end

		state = getmetatable(state)
	end
end

function StateMachine:Extend(...)
	-- Creates sub machine
	local stateMachine = StateMachine.new(...)

	self[KEY_TROVE]:Connect(stateMachine.StateChanged, function()
		local status = self:Update()
		if not status then
			self.StateChanged:Fire(self[KEY_CURRENT_STATE])
		end
	end)

	self[KEY_TROVE]:Connect(self.StateChanged, function()
		stateMachine:Update()
	end)
end

function StateMachine:Inherit(...)
	-- Creates related machine
	local stateMachine = StateMachine.new(...)

	self[KEY_TROVE]:Connect(stateMachine.StateChanged, function()
		self:Update()
	end)

	self[KEY_TROVE]:Connect(self.StateChanged, function()
		stateMachine:Update()
	end)
end

return StateMachine
