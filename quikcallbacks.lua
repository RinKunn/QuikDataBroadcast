
package.path = package.path..";"..".\\?.lua;"..".\\?.luac"

local quikcallbacks = {}

local deque = require ("libs.deque")
require ("utils")
require ("quikfunc")
require ("config")

local tickId = 0

-- При запуске скрипта
function OnInit()
	is_quik_connected = numberToBool(isConnected())
	printConfigsToLog()
	if queue == nil then 
		queue = deque.new()
		logger:info("Queue is initialized")
	end
	is_started = true
end

-- При остановке скрипта
function OnStop(s)
	message("Script Stopped")
	logger:info("Script Stopped")
	is_started = false
	closeSocket()
    return 1000
end

-- При соединении с сервером Quik
function OnConnected()
	logger:info('Connetion with Quik Server is established')
	is_quik_connected = true
end


-- При разрыве соединении с сервером Quik
function OnDisconnected()
	is_quik_connected = false
	logger:info("Connection lost with Quik Server!")
end

function OnParam(class_code, sec_code)
	if arrayContain(MARKET_CLASS_CODES, class_code) == false then return end
	tickId = tickId + 1
	local dat = {}
	dat = getSecurityQuotesInfo(class_code, sec_code)
	dat.msg_type = 'OnParam'
	dat.id = tickId
	queue:push_right(string.format('%d:%s', dat.id, to_json(dat)))
end



function OnClose()
   logger:info("QuikApp is closing...")
   closeSocket()
end

return quikcallbacks
