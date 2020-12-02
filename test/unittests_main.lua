function getScriptPath() return io.popen("cd"):read('*l') end
getInfoParam = function(prm) 
	if prm == "VERSION" then 
		return "8.7" 
	else 
		error('Not applied for param: '..prm)
	end 
end

local function myget_parent_dir(str)
   local fpat = "\\"
   local last_end = #str-1
   local s, e, cap = str:find(fpat, last_end)
   while last_end >= 1 do
      if e ~= nil then
         return str:sub(1, e - 1)
      end
      last_end = last_end-1
      s, e, cap = str:find(fpat, last_end)
   end
   return nil
end

local script_path = getScriptPath()
local base_path = myget_parent_dir(script_path)
local socketcore_path = base_path.."\\clibs64\\53_MD\\"
local libs_path = base_path.."\\libs\\"
local testlibs_path = script_path.."\\libs\\"

package.path = package.path .. ";"..base_path.."\\?.lua;"..base_path.."\\?.luac;"..".\\?.lua;"..".\\?.luac;"..libs_path.."?.lua;"..testlibs_path.."?.lua"
package.cpath = package.cpath..";"..socketcore_path..'?.dll;' ..'.'..socketcore_path..'?.dll;'..testlibs_path.."?.lua"
-----------------------------------------

require ('DataBroadcaster')
local lu = require('luaunit')
local copas = require('copas')
local timer = require('copas.timer')
local mockagne = require('mockagne')
local when = mockagne.when
local any = mockagne.any
local verify = mockagne.verify

--- redefine global function ---
isConnected = function() return 1 end
message = function(msg) print(msg) end
sleep = function (...) return coroutine.yield() end
socket = mockagne.getMock()


TestMain = {}
	function TestMain:setUp()
		self.logfile = getScriptPath().."\\logs\\"..os.date("%Y-%m-%d")..".log"
		local conv = function()
			
				if not self.server_running then return nil end
				return { send = function(...) return self.server_running, self.server_running end}
			end
		when(socket.connect('127.0.0.1', 9090)).thenAnswerFn(conv)
		OnInit()
	end
	
	function TestMain:tearDown()
		if is_started then
			OnStop()
		end
		is_started = false
		is_connected = false
		msg_sended_amount = 0
		--os.remove(self.logfile)
		--os.remove(cache.filepath)
		queue = nil
		cache = nil
		receiver = nil
	end
	
	
	function TestMain:test_beforeRunning_logPrinted()
		lu.assertTrue(is_started)
		lu.assertTrue(is_connected)
		lu.assertTrue(file_exists(self.logfile))
		lu.assertNotNil(queue)
		lu.assertNotNil(cache)
		lu.assertNotNil(receiver)
		lu.assertTrue(queue:is_empty())
		lu.assertTrue(cache:is_empty())
		lu.assertFalse(receiver.is_connected)
	end
	
	function TestMain:test_OnStop_shutdownWork()
		local mr = coroutine.create(main)
		local resumeres = coroutine.resume(mr)
		lu.assertTrue(resumeres)
		lu.assertEquals(coroutine.status(mr), 'suspended')
		lu.assertTrue(is_started)
		lu.assertTrue(is_connected)
		
		OnStop()
		
		resumeres = coroutine.resume(mr)
		lu.assertTrue(resumeres)
		lu.assertEquals(coroutine.status(mr), 'dead')
		lu.assertFalse(is_started)
	end
	
	--[[ 
	@event: Добавление данных в очередь
	@condit: Quik connected, Remote disconnected
	@result: Переносит все данные с очереди в кэш
	]]
	function TestMain:test_addDataToQueue_QCSS_saveToCache()
		self.server_running = false
		local mr = coroutine.create(main)
		coroutine.resume(mr)
		
		queue:push_right({id = 1})
		
		coroutine.resume(mr)
		lu.assertEquals(queue:length(), 0)
		OnStop()
		coroutine.resume(mr)
		local cacheLines = lines_from(cache.filepath)
		lu.assertEquals(cacheLines[1], '{"id":1}')
		lu.assertTrue(file_exists(cache.filepath))
		
	end
	
	--[[ 
	@event: Добавление данных в очередь
	@condit: Quik connected, Remote connected
	@result: Отправляет все данные с очереди на сервер
	]]
	function TestMain:test_addDataToQueue_QCSR_sendToRemote()
		self.server_running = true
		local mr = coroutine.create(main)
		coroutine.resume(mr)
		
		queue:push_right({id = 1})
		
		coroutine.resume(mr)
		lu.assertEquals(queue:length(), 0)
		OnStop()
		coroutine.resume(mr)
		lu.assertFalse(file_exists(cache.filepath))
		lu.assertEquals(msg_sended_amount, 1)
	end
	
	--[[ 
	@event: Добавление данных в очередь при загрузке cache
	@condit: Quik connected, Remote connected
	@result: добавленный объект пересылается после cache
	]]
	function TestMain:test_addDataToQueue_cacheLoading_sendToRemoteAfterLoading()
		
	end
	
	
	------- QUIK CONNECTION EVENTS -------
	--[[ 
	@event: Разрыв связи с Quik'ом
	@condit: Remote connected, queue = 0
	@result: Закрывает соединение с сервером
	]]
	function TestMain:test_OnDisconnectedSR_closeRemote()
		self.server_running = true
		local mr = coroutine.create(main)
		coroutine.resume(mr)
		lu.assertTrue(receiver.is_connected)
		
		OnDisconnected()
		coroutine.resume(mr)
		
		lu.assertFalse(receiver.is_connected)
		lu.assertEquals(msg_sended_amount, 0)
		lu.assertTrue(queue:is_empty())
		lu.assertTrue(cache:is_empty())
		
		OnStop()
		coroutine.resume(mr)
	end
	
	--[[ 
	@event: Разрыв связи с Quik'ом
	@condit: Remote disconnected, queue = 0
	@result: ничего не делает
	]]
	function TestMain:test_OnDisconnectedSS_nothing()
		self.server_running = false
		local mr = coroutine.create(main)
		coroutine.resume(mr)
		lu.assertFalse(receiver.is_connected)
		
		OnDisconnected()
		coroutine.resume(mr)
		
		lu.assertFalse(receiver.is_connected)
		lu.assertEquals(msg_sended_amount, 0)
		lu.assertTrue(queue:is_empty())
		lu.assertTrue(cache:is_empty())
		
		OnStop()
		coroutine.resume(mr)
	end
	
	
	--[[ 
	@event: Разрыв связи с Quik'ом
	@condit: Remote connected, queue > 0
	@result: Отправляет все данные с очереди на сервер
	]]
	function TestMain:test_OnDisconnectedSRqueue_sendToRemote()
		self.server_running = true
		local mr = coroutine.create(main)
		coroutine.resume(mr)
		
		queue:push_right({id = 1})
		OnDisconnected()
		
		coroutine.resume(mr)
		lu.assertEquals(msg_sended_amount, 1)
		coroutine.resume(mr)
		
		lu.assertFalse(receiver.is_connected)
		lu.assertTrue(cache:is_empty())
		
		OnStop()
		coroutine.resume(mr)
	end
	
	
	--[[
	@event: Разрыв связи с Quik'ом
	@condit: Remote disconnected, queue > 0
	@result: Переносит все данные с очереди в кэш
	]]
	function TestMain:test_OnDisconnectedSSqueue_saveToCache() 
		self.server_running = false
		local mr = coroutine.create(main)
		coroutine.resume(mr)
		
		queue:push_right({id = 1})
		OnDisconnected()
		
		coroutine.resume(mr)
		lu.assertEquals(msg_sended_amount, 0)
		coroutine.resume(mr)
		
		lu.assertFalse(receiver.is_connected)
		lu.assertFalse(cache:is_empty())
		
		OnStop()
		coroutine.resume(mr)
	end
	
	
	--[[ 
	@event: Соединение с сервером Quik'а
	@condit: cache = 0, сервер не запущен
	@result: делает попытку подключения к Remote
	]]
	function TestMain:test_OnConnectedSS_connectntToRemote()
		self.server_running = false
		is_connected = false
		local mr = coroutine.create(main)
		coroutine.resume(mr)
		lu.assertFalse(receiver.is_connected)
		
		OnConnected()
		coroutine.resume(mr)
		
		lu.assertFalse(receiver.is_connected)
		lu.assertTrue(is_connected)
		
		OnStop()
		coroutine.resume(mr)
	end
	
	--[[ 
	@event: Соединение с сервером Quik'а
	@condit: cache = 0, сервер запущен
	@result: делает попытку подключения к Remote
	]]
	function TestMain:test_OnConnectedSR_connectToRemote()
		self.server_running = true
		is_connected = false
		local mr = coroutine.create(main)
		coroutine.resume(mr)
		lu.assertFalse(receiver.is_connected)
		
		OnConnected()
		coroutine.resume(mr)
		
		lu.assertTrue(receiver.is_connected)
		lu.assertTrue(is_connected)
		
		OnStop()
		coroutine.resume(mr)
	end
	
	--[[ 
	@event: Соединение с сервером Quik'а
	@condit: cache > 0, сервер не запущен
	@result: делает попытку подключения к Remote
	]]
	function TestMain:test_OnConnectedSScache_cacheDidntLoad()
		file_append(cache.filepath, '{"id": 1}\n{"id": 2}')
		self.server_running = false
		is_connected = false
		local mr = coroutine.create(main)
		coroutine.resume(mr)
		lu.assertFalse(receiver.is_connected)
		lu.assertFalse(cache:is_empty())
		
		OnConnected()
		coroutine.resume(mr)
		
		lu.assertFalse(receiver.is_connected)
		lu.assertTrue(is_connected)
		lu.assertTrue(queue:is_empty())
		lu.assertFalse(cache:is_empty())
		
		OnStop()
		coroutine.resume(mr)
	end
	
	--[[ 
	@event: Соединение с сервером Quik'а
	@condit: cache > 0, сервер запущен
	@result: делает попытку подключения к Remote
	]]
	function TestMain:test_OnConnectedSRcache_cacheLoaded()
		file_append(cache.filepath, '{"id": 1}\n{"id": 2}')
		self.server_running = true
		is_connected = false
		local mr = coroutine.create(main)
		coroutine.resume(mr)
		lu.assertFalse(receiver.is_connected)
		lu.assertFalse(cache:is_empty())
		
		OnConnected()
		coroutine.resume(mr)
		
		lu.assertTrue(receiver.is_connected)
		lu.assertTrue(is_connected)
		lu.assertFalse(queue:is_empty())
		lu.assertEquals(queue:length(), 1)
		lu.assertTrue(cache:is_empty())
		
		OnStop()
		coroutine.resume(mr)
	end
	
	------- REMOTE CONNECTION EVENT -------
	
	--[[ 
	@event: Cоединение с Remote сервером
	@condit: cache > 0, queue = 0
	@result: переносит данные из cache в queue
	]]
	function TestMain:test_remoteConnectedcache_loadToQueue()
		file_append(cache.filepath, '{"id":1}\n')
		self.server_running = false
		local mr = coroutine.create(main)
		coroutine.resume(mr)
		lu.assertEquals(cache:length(), 1)
		
		queue:push_right({id = 2})
		coroutine.resume(mr)
		lu.assertEquals(cache:length(), 2)
		lu.assertTrue(queue:is_empty())
		
		self.server_running = true
		coroutine.resume(mr)
		
		lu.assertTrue(receiver.is_connected)
		lu.assertTrue(cache:is_empty())
		lu.assertFalse(queue:is_empty())
		lu.assertEquals(queue:length(), 1)
		lu.assertEquals(msg_sended_amount, 1)
		
		OnStop()
		coroutine.resume(mr)
	end
	
	--[[ 
	@event: Разрыв соединения с Remote сервером
	@condit: queue > 0
	@result: переносит данные из queue в cache
	]]
	function TestMain:test_remoteDisconnectedqueue_saveToCache() 
		self.server_running = true
		local mr = coroutine.create(main)
		coroutine.resume(mr)
		
		queue:push_right({st = 'sended'})
		queue:push_right({st = 'send break and save to cache 1'})
		queue:push_right({st = 'saved to cache 2'})
		queue:push_right({st = 'saved to cache 3'})
		coroutine.resume(mr) -- обработал 1
		
		lu.assertTrue(cache:is_empty())
		lu.assertEquals(queue:length(), 3)
		lu.assertEquals(msg_sended_amount, 1)
		
		self.server_running = false
		coroutine.resume(mr)
		
		lu.assertFalse(receiver.is_connected)
		lu.assertEquals(cache:length(), 1)
		lu.assertEquals(queue:length(), 2)
		lu.assertEquals(msg_sended_amount, 0)
		
		OnStop()
		coroutine.resume(mr)
		lu.assertEquals(coroutine.status(mr), 'dead')
		lu.assertEquals(cache:length(), 3)
		
	end
	
	--[[ 
	@event: Cоединение с Remote сервером
	@condit: cache > 0, queue > 0 (перед соединением сервера Quik может занести новые данные)
	@result: переносит данные из cache в queue перед имеющимися данными
	]]
	function TestMain:test_remoteCon_cacheGt0queueGt0_loadToQueueBeforeExistData() end
	

function file_exists(file)
  local f = io.open(file, "rb")
  if f then f:close() end
  return f ~= nil
end

function file_append(file, line)
	local f = io.open(file, "a+")
	f:write(line)
	f:close()
end


function lines_from(file)
  if not file_exists(file) then return {} end
  local flines = {}
  for line in io.lines(file) do 
    flines[#flines + 1] = line
  end
  return flines
end

local runner = lu.LuaUnit.new()
--runner:setOutputType("junit", "unit_test_results")
runner:runSuite()



