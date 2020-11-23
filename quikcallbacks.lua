


local quikcallbacks = {}

local deque = require ("libs.deque")
require ("utils")
require ("quikfunc")
require ("config")


-- При запуске скрипта
function OnInit()
	quote_id = 0
	is_quik_connected = tobool(isConnected())
	printConfigsToLog()
	if queue == nil then
		queue = deque.new()
		logger:info("Queue is initialized")
	end
	is_started = true
end

-- При остановке скрипта
function OnStop(s)
	is_started = false
	message("Script Stopped")
	logger:info("Script Stopped")
	--closeSocket()
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




function printConfigsToLog()
	logger:info("-------------------------")
	logger:info("Detected Quik version: ".. quikVersion .." and using cpath: "..package.cpath  , 0)
	logger:info("Parameters:")
	logger:info("host=%s, port=%s", CALLBACK_HOST, CALLBACK_PORT)
	logger:info("Normal delay=%d ms, Boost delay=%d ms,", DEFAULT_PROCC_TIME, BOOST_PROCC_TIME)
	logger:info("Cache path=%s", cache_path)
	if cacheIsEmpty() then 
		logger:info("Cache file is empty")
	else
		logger:info("Cache file has datas")
	end
	logger:info("Connection with Quik's DataServer: %s", tobool(isConnected()))
	logger:info("Connection with Remote data receiver: %s", tostring(is_connected))
	logger:info("-------------------------")
end


function tobool(num)
	if num == 1 then return true end
	return false
end

return quikcallbacks
