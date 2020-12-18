local quikcallbacks = {}
local qfunc = require ("quikfunc")
local lqueue = require ("deque")
local lcache = require ("qdbccache")
local lreceiver = require ("receiverapi")

quote_id = 0

local isBondChanged, LogPrintInitParams, tobool, getMessageFromData, AddBondsInfoToQueueIfNotSended
bondsinfo_sendeddate = nil

-- При запуске скрипта
function OnInit()
	is_connected = tobool(isConnected())
	queue = lqueue:new()
	cache = lcache:create(getScriptPath()..'\\')
	receiver = lreceiver:create('127.0.0.1', 9090)
	bondsLastInfo = {}
	LogPrintInitParams()
	is_started = true
	AddBondsInfoToQueueIfNotSended()
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
	AddBondsInfoToQueueIfNotSended()
end

-- При разрыве соединении с сервером Quik
function OnDisconnected()
	logger:info("Connection lost with Quik Server!")
	is_connected = false
	quote_id = 0
end

-- При получении новых данных из таблицы обезличенных сделок
function OnParam(class_code, sec_code)
	local dat = {}
	if qfunc.isBond(class_code) then
		if not isBondChanged(class_code, sec_code) then return end
		dat = getMessageFromData(qfunc.getRealTimeInfo(class_code, sec_code), 'info')
		bondsLastInfo[sec_code] = dat.data
	elseif qfunc.isRFS(class_code) then
		dat = getMessageFromData(qfunc.getRealTimeRPSInfo(class_code, sec_code), 'rpsinfo')
	else 
		return
	end
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

function getBondsInfo()
	return getBondsInfoList()
end

function AddBondsInfoToQueueIfNotSended()
	if bondsinfo_sendeddate == nil or bondsinfo_sendeddate ~= os.date('%x') then
		logger:info("Bondinfo didnt send today. Collecting...")
		local bonds = getBondsInfo()
		if bonds == nil or #bonds == 0 then
			error('Cannot load bonds info!')
		end
		for i = 1, #bonds do
			bonds[i] = getMessageFromData(bonds[i], 'bondinfo')
		end
		logger:info("To queue added %d data of bondinfo", #bonds)
		queue:push_left_some(bonds)
		bondsinfo_sendeddate = os.date('%x')
	else
		logger:info("bondsinfo_sendeddate = %s", bondsinfo_sendeddate)
	end
end

function getMessageFromData(data, msg_type)
	quote_id = quote_id + 1
	local dat = {}
	dat.data = data
	dat.msg_type = msg_type
	dat.id = quote_id
	return dat
end


bondinfo = {}



return quikcallbacks
