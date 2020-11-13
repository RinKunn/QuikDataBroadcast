
local socket = require ("libs.socket")
local json = require ("libs.dkjson")
local deque = require ("libs.deque")
require ("config")


local utils = {}

local is_connected = false
local is_quik_connected = false

local callback_client

function ensureConnected()
    if not callback_client then
		logger:warn("Trying to connecting to server: "..CALLBACK_HOST..":"..CALLBACK_PORT)
		callback_client = socket.connect(CALLBACK_HOST, CALLBACK_PORT)
		if callback_client then
			if not cacheIsEmpty() then
				loadQueueFromCache()
			end
			logger:info("Connected to server: "..CALLBACK_HOST..":"..CALLBACK_PORT)
			logger:info("---------")
			is_connected = true
			pcall(callback_client.settimeout, callback_client, 1000, 't')
		end
    end
	return callback_client ~= nil
end


function sendCallback(msg_json)
    if is_connected and callback_client then
        local status, res = pcall(callback_client.send, callback_client, msg_json..'\n')
        if status and res then
            return true
        else
			logger:warn("Connection lost with server: "..CALLBACK_HOST..":"..CALLBACK_PORT)
            closeSocket()
            return nil, res
        end
	else
		return false
    end
end

function closeSocket()
	if is_connected then
		logger:info("Closing socket with %s:%s...", host, port)
		is_connected = false
		logger:info("Отправлено %d сообщений", message_sended_count)
		if callback_client then
			pcall(callback_client.close, callback_client)
			callback_client = nil
		end
	end
end


function queueLenGreater(count)
	return queue:length() > count
end

----------------CACHE-----------------
local cache_basedir = getScriptPath().."\\buffer";
local cache_path = cache_basedir.."\\"..tostring(os.date('%Y%m%d'))..".txt"


function cacheIsEmpty()
	return not file_exists(cache_path)
end

-- Загружает в очередь все из кэша
function loadQueueFromCache()
	logger:info('Loading data from cache...')
	local rlines = {}
	for line in io.lines(cache_path) do
		rlines[#rlines + 1] = line
	end
	os.remove(cache_path)
	logger:info('Loaded %d messages from local cache', #rlines)
	queue:push_right_datas(rlines)
end

function addToCache(msg_json)
	append_to_file(cache_path, msg_json)
end

function addQueueToCache()
	if queue:length() == 0 then return end
	local msg_list = queue:extract_data()
	local file = io.open(cache_path, "a+")
	for i, msg_json in ipairs(msg_list) do
		file:write(msg_json.."\n")
	end
	io.close(file)
	logger:debug("Added %d messages to local cache", #msg_list)
end

--------

function append_to_file(fname, msg_json)
	local file = io.open(fname, "a+")
	file:write(msg_json.."\n")
	io.close(file)
end

function file_exists(file)
  local f = io.open(file, "rb")
  if f then f:close() end
  return f ~= nil
end
--------------------------------------

function to_json(msg)
    local status, str= pcall(json.encode, msg, { indent = false }) -- dkjson
    if status then
        return str
    else
        error(str)
    end
end

function timemsec()
    local st, res = pcall(socket.gettime)
    if st then
        return (res) * 1000
    else
        error("unexpected error in timemsec")
		logger:error("unexpected error in timemsec")
    end
end

function numberToBool(num)
	if num == 1 then return true end
	return false
end

function arrayContain(tbl, val)
	for ind=1, #tbl, 1 do
		if tbl[ind] == val then return true end
	end
	return false
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
	logger:info("Connection with Quik's DataServer: %s", numberToBool(isConnected()))
	logger:info("Connection with Remote data receiver: %s", tostring(is_connected))
	logger:info("-------------------------")
end



return utils