type States = { table }

type Indexes = { string }

type InputFunction = (any) -> any

type StateMachineConfig = {
	InputFunction: InputFunction,
	States: States,
	DefaultState: string,
	Data: table,
}

local Trove = require(script.Parent.Trove)
local Signal = require(script.Parent.Signal)
local Symbol = require(script.Parent.Symbol)

local StateMachine = {}
StateMachine.__index = StateMachine

StateMachine.State = require(script.State)

local KEY_TROVE = Symbol("Trove")

local KEY_STATES = Symbol("States")

local KEY_DEFAULT_STATE = Symbol("DefaultState")
local KEY_CURRENT_STATE = Symbol("CurrentState")
local KEY_DATA = Symbol("Data")

local KEY_INPUT_FUNCTION = Symbol("Input")

function StateMachine.new(config: StateMachineConfig)
	local self = setmetatable({}, StateMachine)

	self[KEY_TROVE] = Trove.new()

	self.StateChanged = self[KEY_TROVE]:Construct(Signal)

	self[KEY_STATES] = {}

	self[KEY_DEFAULT_STATE] = config.DefaultState
	self[KEY_DATA] = config.Data or {}

	self[KEY_INPUT_FUNCTION] = config.InputFunction

	self:AddStates(config.States or {})

	return self
end

function StateMachine:AddStates(states: States)
	for _, state in ipairs(states) do
		local index: string = state.index
		self[KEY_STATES][index] = state
	end

	local currentState = self:GetCurrentState()
	if currentState then
		self:SetState(currentState.index)
	end
end

function StateMachine:SetState(index: string)
	local state = self:GetState(index)

	local currentState = getmetatable(self:GetCurrentState())
	if currentState == state then
		return
	end

	if not state.CanEnter(table.unpack(self[KEY_DATA])) then
		return
	end

	if self[KEY_CURRENT_STATE] then
		self[KEY_CURRENT_STATE]:Destroy()
	end

	self[KEY_CURRENT_STATE] = state.new()
	self[KEY_CURRENT_STATE]:Enter(table.unpack(self[KEY_DATA]))

	self.StateChanged:Fire(self[KEY_CURRENT_STATE])
	-- Should the update method run here?

	return self[KEY_CURRENT_STATE]
end

function StateMachine:GetCurrentState(): table
	return self[KEY_CURRENT_STATE]
end

function StateMachine:GetState(index: string): table
	return self[KEY_STATES][index]
end

function StateMachine:Update()
	local initalState = self:GetCurrentState()

	if not initalState then
		initalState = self:SetState(self[KEY_DEFAULT_STATE])
	end

	local input = self[KEY_INPUT_FUNCTION]()
	local state = initalState

	while state do
		local newState = state.HandleInput(initalState, input)
		if newState then
			local status = self:SetState(newState)
			if status then
				return status
			end
		end

		state = getmetatable(getmetatable(state))
	end
end

function StateMachine:Extend(...): table
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

	return stateMachine
end

function StateMachine:Inherit(...): table
	-- Creates related machine
	local stateMachine = StateMachine.new(...)

	self[KEY_TROVE]:Connect(stateMachine.StateChanged, function()
		self:Update()
	end)

	self[KEY_TROVE]:Connect(self.StateChanged, function()
		stateMachine:Update()
	end)

	return stateMachine
end

function StateMachine:Destroy()
	self[KEY_TROVE]:Destroy()
end

return StateMachine
