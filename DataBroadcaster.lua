----------------------------------------------------------------------------------------
function is_quik()
    if getScriptPath then return true else return false end
end

quikVersion = nil
script_path = "."

-- Loading suitable lua core lib for Quik
if is_quik() then
    script_path = getScriptPath()
    
	quikVersion = getInfoParam("VERSION")

	if quikVersion ~= nil then
		quikVersion = tonumber(quikVersion:match("%d+%.%d+"))
	end

	if quikVersion == nil then
		message("QUIK# cannot detect QUIK version", 3)
		return
	else
		libPath = "\\clibs"
	end
    
    -- MD dynamic, requires MSVCRT
    -- MT static, MSVCRT is linked statically with luasocket
    -- package.cpath contains info.exe working directory, which has MSVCRT, so MT should not be needed in theory, 
    -- but in one issue someone said it doesn't work on machines that do not have Visual Studio. 
    local linkage = "MD"
    
	if quikVersion >= 8.5 then
        libPath = libPath .. "64\\53_"..linkage.."\\"
	elseif quikVersion >= 8 then
        libPath = libPath .. "64\\5.1_"..linkage.."\\"
	else
		libPath = "\\clibs\\5.1_"..linkage.."\\"
	end
end
package.path = package.path .. ";" .. script_path .. "\\?.lua;" .. script_path .. "\\?.luac"..";"..".\\?.lua;"..".\\?.luac"
package.cpath = package.cpath .. ";" .. script_path .. libPath .. '?.dll'..";".. '.' .. libPath .. '?.dll'

----------------------------------------------------------------------------------------

local perf = {
	boost = {name = "Boost", sleeptime = 10},
	default = {name = "Default", sleeptime = 100},
	lazy = {name = "Lazy", sleeptime = 1000}
}

require ("libs.loggingfile")
local json = require ("libs.dkjson")
require ("quikcallbacks")
local lqueue = require ("libs.deque")
local lcache = require ("qdbccache")
local lreceiver = require ("receiverapi")

logger = logging.file(getScriptPath().."\\logs\\".."%s.log", "%Y-%m-%d", "%date|%level: %message\n")

is_started = false
is_connected = false
msg_sended_amount = 0


local runmode = perf.lazy
queue = lqueue:new()
cache = lcache:create(getScriptPath().."\\cache\\")
receiver = lreceiver:create('127.0.0.1', 9090)

function main()
	logger:info("Running mode: %s, run every %d ms.", runmode.name, runmode.sleeptime)
	while is_started do
		-- если нет соединения с сервером Quik, то данные не поступают
		-- если queue не пуст, то скрипт отправляет все данные с очереди
		-- а потом закрывает соединение с удаленным сервером
		--logger:debug("Quik: %s, Server: %s, queue: %d, sended: %d", is_connected, receiver.is_connected, queue:length(), msg_sended_amount)
		if is_connected or not queue:is_empty() then
		
			-- проверка соединения с сервером
			if not receiver.is_connected then
				if receiver:connect() then
					logger:info('Connected to remote server!')
					if not cache:isEmpty() then
						local collect, err_msg = cache:extractData()
						if collect == nil then error(err_msg) end
						logger:info('Loaded %d datas from cache', #collect)
						queue:push_right_datas(collect)
					else
						logger:info("Cache is empty")
					end
				end
			end
			
			if not receiver.is_connected then
				SaveQueueToCache()
			else
				local msg = queue:pop_left()
				if msg ~= nil then
					local res, err = receiver:sendStr(to_json(msg))
					if not res then
						-- не удалось отправить данные на сервер
						logger:warn('Connection with server is lost! (%s)', receiver.is_connected)
						CloseConnection()
					else
						msg_sended_amount = msg_sended_amount + 1
					end
				end
			end
		else
			CloseConnection()
		end
		CheckMode()
		sleep(runmode.sleeptime)
	end
	
	-- После остановки скрипта
	if not queue:is_empty() then
		logger:info("Before closing queue had data: %d", queue:length())
		SaveQueueToCache()
	else
		logger:info("Before closing queue was empty")
	end
end


function SaveQueueToCache()
	local data = queue:extract_data()
	cache:appendCollection(data)
	logger:info("To cache added %d data", #data)
end

function CloseConnection()
	if not receiver.is_connected then return end
	logger:info('Closing connection with remote server...')
	receiver:disconnect()
	logger:info('Connection closed!')
	logger:info('Before connection close %d datas were sent', msg_sended_amount)
	msg_sended_amount = 0
end

function to_json (obj)
    local status, str= pcall(json.encode, obj, { indent = false }) -- dkjson
    if status then
        return tostring(str)
    else
        error(str)
    end
end

function CheckMode()
	local old_mode = runmode
	if not receiver.is_connected then
		runmode = perf.lazy
	elseif queue:length() >= 100 then
		runmode = perf.boost
	elseif runmode ~= perf.default then
		runmode = perf.default
	end
	if old_mode ~= runmode then logger:debug("--Mode changed to %s", runmode.name) end
end