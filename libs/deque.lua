local push_right = function(self, x)
  assert(x ~= nil)
  self.tail = self.tail + 1
  self[self.tail] = x
end

local push_left = function(self, x)
  assert(x ~= nil)
  self[self.head] = x
  self.head = self.head - 1
end

local push_right_some = function(self, tbl)
  assert(tbl ~= nil)
  for i, x in ipairs(tbl) do
	self.tail = self.tail + 1
	self[self.tail] = x
  end
  
end

local peek_right = function(self)
  return self[self.tail]
end

local peek_left = function(self)
  return self[self.head+1]
end

local pop_right = function(self)
  if self:is_empty() then return nil end
  local r = self[self.tail]
  self[self.tail] = nil
  self.tail = self.tail - 1
  if self:is_empty() then
	self.head = 0
	self.tail = 0
  end
  return r
end

local pop_left = function(self)
  if self:is_empty() then return nil end
  self.head = self.head + 1
  local r = self[self.head]
  self[self.head] = nil
  if self:is_empty() then
	self.head = 0
	self.tail = 0
  end
  return r
end

local pop_left_some = function(self, count)
  if self:is_empty() then return nil end
  if count < 1 then return nil end
  if count == 1 then return pop_left(self) end
  
  local r = {}, i
  for i=self.head+1,self.tail do
    r[i-self.head] = self[i]
	self[i] = nil
	if i-self.head == count then break end
  end
  
  self.head = self.head + count
  if self:is_empty() then
	self.head = 0
	self.tail = 0
  end
  return r
end

local length = function(self)
  return self.tail - self.head
end

local is_empty = function(self)
  return self:length() <= 0
end

local contents = function(self)
  if self:is_empty() then return nil end
  local r = {}
  for i=self.head+1,self.tail do
    r[i-self.head] = self[i]
  end
  return r
end

local extract_data = function(self)
	local data = contents(self)
	self:clear_data()
	return data
end

local iter_right = function(self)
  local i = self.tail+1
  return function()
    if i > self.head+1 then
      i = i-1
      return self[i]
    end
  end
end

local iter_left = function(self)
  local i = self.head
  return function()
    if i < self.tail then
      i = i+1
      return self[i]
    end
  end
end

local _remove_at_internal = function(self, idx)
  for i=idx, self.tail do self[i] = self[i+1] end
  self.tail = self.tail - 1
end

local remove_right = function(self, x)
  for i=self.tail,self.head+1,-1 do
    if self[i] == x then
      _remove_at_internal(self, i)
      return true
    end
  end
  return false
end

local remove_left = function(self, x)
  for i=self.head+1,self.tail do
    if self[i] == x then
      _remove_at_internal(self, i)
      return true
    end
  end
  return false
end

local remove_same_left = function(self, count)
	for i=idx, self.tail do self[i] = self[i+1] end
  self.tail = self.tail - 1
end

local clear_data = function(self)
	for i=self.head+1,self.tail do
		self [i] = nil
	end
	self.head = 0
	self.tail = 0
end



local methods = {
  push_right = push_right,
  push_right_some = push_right_some,
  push_left = push_left,
  peek_right = peek_right,
  peek_left = peek_left,
  pop_right = pop_right,
  pop_left = pop_left,
  pop_left_some = pop_left_some,
  rotate_right = rotate_right,
  rotate_left = rotate_left,
  remove_right = remove_right,
  remove_left = remove_left,
  iter_right = iter_right,
  iter_left = iter_left,
  length = length,
  is_empty = is_empty,
  contents = contents,
  clear_data = clear_data,
  extract_data = extract_data,
  
  
}

local new = function()
  local r = {head = 0, tail = 0}
  return setmetatable(r, {__index = methods})
end

return {
  new = new,
}