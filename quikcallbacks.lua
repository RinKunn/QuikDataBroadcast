local quikcallbacks = {}
require ("quikfunc")
local lqueue = require ("deque")
local lcache = require ("qdbccache")
local lreceiver = require ("receiverapi")


quote_id = 0

-- При запуске скрипта
function OnInit()
	is_connected = tobool(isConnected())
	LogPrintInitParams()
	is_started = true
end

-- При остановке скрипта
function OnStop(s)
	is_started = false
	logger:info("Script Stopped")
    return 1000
end

-- При соединении с сервером Quik
function OnConnected()
	logger:info('Connetion with Quik Server is established')
	local old_filepath = cache.filepath
	cache:refresh()
	if cache.filepath ~= old_filepath then
		logger:info('Cache path changed to: '..cache.filepath)
	end
	is_connected = true
end

-- При разрыве соединении с сервером Quik
function OnDisconnected()
	logger:info("Connection lost with Quik Server!")
	is_connected = false
end


function OnParam(class_code, sec_code)
	if not isBond(class_code) then return end
	quote_id = quote_id + 1
	local dat = {}
	dat = getSecurityQuotesInfo(class_code, sec_code)
	dat.id = quote_id
	dat.msg_type = 'OnParam'
	queue:push_right(dat)
end


----------------------------------------------------------------
----------------------------------------------------------------

function LogPrintInitParams()
	queue = lqueue:new()
	cache = lcache:create(getScriptPath().."\\cache\\")
	receiver = lreceiver:create('127.0.0.1', 9090)
	logger:info("-------------------------")
	logger:info("Detected Quik version: %s", quikVersion)
	logger:info("Parameters:")
	logger:info("host=%s, port=%s", receiver.host, receiver.port)
	logger:info("Cache dir=%s", cache.dir)
	logger:info("Cache path=%s", cache.filepath)
	if cache:is_empty() then 
		logger:info("Cache file is empty")
	else
		logger:info("Cache file has data")
	end
	logger:info("Connection with Quik's DataServer: %s", is_connected)
	--logger:info("Connection with Remote data receiver: %s", receiver.is_connected)
	logger:info("-------------------------")
end

function tobool(num)
	if num == 1 then return true end
	return false
end



return quikcallbacks
