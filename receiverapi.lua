local socket = require ("socket")

local receiverapi = { version = "1.0"}
receiverapi.__index = receiverapi


function receiverapi:create(host, port)
	local r = {}
	setmetatable(r, receiverapi)
	r.host = host or '127.0.0.1'
	r.port = port or 9090
	r.is_connected = false
	return r
end

-- connect to remote tcp server
function receiverapi:connect()
	if not self.callback_client then
		self.callback_client = socket.connect(self.host, self.port)
		if self.callback_client then
			self.is_connected = true
			pcall(self.callback_client.settimeout, self.callback_client, 1000, 't')
			return true
		end
    end
	return false
end

-- disconnect from remote tcp server
function receiverapi:disconnect()
	if self.is_connected then
		self.is_connected = false
		if self.callback_client then
			pcall(self.callback_client.close, self.callback_client)
			self.callback_client = nil
		end
	else
		return false
	end
	return self.callback_client == nil
end

-- send str message to tcp
function receiverapi:sendStr(msg_str)
    if self.is_connected and self.callback_client then
        local status, res = pcall(self.callback_client.send, self.callback_client, msg_str..'\n')
        if status and res then
            return true
        else
            self:disconnect()
            return false, "Connection lost with server: "..self.host..":"..self.port
        end
	else
		return nil, "Connection not established with server: "..self.host..":"..self.port
    end
end


return receiverapi