local quikcallbacks = {}
local qfunc = require ("quikfunc")
local lqueue = require ("deque")
local lcache = require ("qdbccache")
local lreceiver = require ("receiverapi")

quote_id = 0

local isBondChanged, LogPrintInitParams, tobool

-- При запуске скрипта
function OnInit()
	is_connected = tobool(isConnected())
	queue = lqueue:new()
	cache = lcache:create(getScriptPath()..'\\')
	receiver = lreceiver:create('127.0.0.1', 9090)
	bondsLastInfo = {}
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

-- При получении новых данных из таблицы обезличенных сделок
function OnParam(class_code, sec_code)
	local dat = {}
	if qfunc.isBond(class_code) then
		if not isBondChanged(class_code, sec_code) then return end
		dat.msg_type = 'info'
		dat.data = qfunc.getRealTimeInfo(class_code, sec_code)
		bondsLastInfo[sec_code] = dat.data
	elseif qfunc.isRFS(class_code) then
		dat.msg_type = 'rpsinfo'
		dat.data = qfunc.getRealTimeRPSInfo(class_code, sec_code)
	else 
		return
	end
	
	quote_id = quote_id + 1
	dat.id = quote_id
	queue:push_right(dat)
end


----------------------------------------------------------------

function LogPrintInitParams()
	logger:info("-------------------------")
	logger:info("Detected Quik version: %s", quikVersion)
	logger:info("Parameters:")
	logger:info("host=%s, port=%s", receiver.host, receiver.port)
	logger:info("Cache dir=%s", cache.dir)
	logger:info("Cache path=%s", cache.filepath)
	if cache:is_empty() then 
		logger:info("Cache file is empty")
	else
		logger:info("Cache len: %d", cache:length())
	end
	logger:info("Connection with Quik's DataServer: %s", is_connected)
	--logger:info("Connection with Remote data receiver: %s", receiver.is_connected)
	logger:info("-------------------------")
end

function tobool(num)
	if num == 1 then return true end
	return false
end


function isBondChanged(class_code, sec_code)
	if bondsLastInfo[sec_code] == nil then return true end
	return qfunc.isChanged(class_code, sec_code, bondsLastInfo[sec_code])
end


return quikcallbacks
