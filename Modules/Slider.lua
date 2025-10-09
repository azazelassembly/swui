local Slider = {}
Slider.__index = Slider

function Slider.new(context: table)
	local self = setmetatable(context, Slider)
	self.value = self.default or self.min
	self.autoSizeTextBox()
	self.TextBox:GetPropertyChangedSignal("Text"):Connect(self.autoSizeTextBox)
	self.TextBox.FocusLost:Connect(function()
		local number = tonumber(self.TextBox.Text)
		self:updateValue({ value = number })
	end)

	self.dragging = false
	self:updateValue({ value = self.value })

	return self
end

function Slider:handleSlider(connections)
	local UserInputService = game:GetService("UserInputService")
	local function round(number: number)
		if not self.step or self.step <= 0 then
			return number
		end
		local mult = 1 / self.step
		return math.floor(number * mult + 0.5) / mult
	end

	self.Line.TextButton.MouseButton1Down:Connect(function(input)
		self.dragging = true

		local touchMoved = UserInputService.TouchMoved:Connect(function(input)
			if self.dragging then
				local min, max = self.min, self.max
				local percent = math.clamp((input.Position.X - self.Line.AbsolutePosition.X) / self.Line.AbsoluteSize.X, 0, 1)
				local value = round((percent * (max - min)) + min)

				self.showInfo()
				self:updateValue({ value = value })
			end
		end)

		local touchEnded; touchEnded = UserInputService.TouchEnded:Connect(function()
			self.dragging = false
			self.dontShowInfo()
			touchEnded:Disconnect()
			touchMoved:Disconnect()
		end)

		local inputChanged = UserInputService.InputChanged:Connect(function(input)
			if self.dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
				local min, max = self.min, self.max
				local percent = math.clamp((input.Position.X - self.Line.AbsolutePosition.X) / self.Line.AbsoluteSize.X, 0, 1)
				local value = round((percent * (max - min)) + min)

				self.showInfo()
				self:updateValue({ value = value })
			end
		end)

		local inputEnded; inputEnded = UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				self.dragging = false
				self.dontShowInfo()
				inputEnded:Disconnect()
				inputChanged:Disconnect()
			end
		end)

		table.insert(self.Connections, touchMoved)
		table.insert(self.Connections, touchEnded)
		table.insert(self.Connections, inputChanged)
		table.insert(self.Connections, inputEnded)
	end)

	self:updateValue({ value = self.value })
end

function Slider:updateValue(options: table)
	local newValue = options.value or self.default or self.min

	if typeof(newValue) ~= "number" then
		newValue = self.default or self.min
	end
	newValue = math.clamp(newValue, self.min, self.max)
	if self.step and self.step > 0 then
		local mult = 1 / self.step
		newValue = math.floor(newValue * mult + 0.5) / mult
	end

	local percent = (newValue - self.min) / (self.max - self.min)

	self.updateFill(percent)
	self.value = newValue
	self.callback(newValue)
	self.CurrentValueLabel.Text = tostring(newValue)
	self.TextBox.Text = tostring(newValue)
end

return Slider
