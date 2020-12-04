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
local lu = require('luaunit')
local mockagne = require('mockagne')
local file_exists, lines_from
local when = mockagne.when
local any = mockagne.any
local verify = mockagne.verify

-----------------------------------------
			--	QUEUE  --
-----------------------------------------
local lqueue = require ('deque')
TestQueue = {}

	function TestQueue:setUp()
		self.q = lqueue.new()
	end
	
	
	function TestQueue:test_popFromEmpty_ReturnNil()
		local poped = self.q:pop_left()
		
		lu.assertNil(poped)
		lu.assertTrue(self.q:is_empty())
    end
	
	function TestQueue:test_popSomeFromEmpty_ReturnNil()
		local poped = self.q:pop_left_some()
		
		lu.assertNil(poped)
		lu.assertTrue(self.q:is_empty())
    end
	
	
	function TestQueue:test_push1_len1()
		self.q:push_right({id = 1})
		
		lu.assertEquals(self.q:length(), 1)
		lu.assertEquals(self.q.head, 0)
		lu.assertEquals(self.q.tail, 1)
    end
	
	function TestQueue:test_push1pop1_len0()
		self.q:push_right({id = 1})
		
		local poped = self.q:pop_left()
		
		lu.assertTrue(self.q:is_empty())
		lu.assertEquals(self.q:length(), 0)
		lu.assertEquals(type(poped), 'table')
		lu.assertEquals(poped.id, 1)
		lu.assertEquals(self.q.head, 0)
		lu.assertEquals(self.q.tail, 0)
    end
	
	function TestQueue:test_pushSomeToEmpty_notEmpty()
		self.q:push_right_some({{id = 1}, {id = 2}, {id = 3}})
		
		lu.assertFalse(self.q:is_empty())
		lu.assertEquals(self.q:length(), 3)
		lu.assertEquals(self.q.head, 0)
		lu.assertEquals(self.q.tail, 3)
	end
	
	function TestQueue:test_pushSomeToNotEmpty_lenRaised()
		self.q:push_right_some({{id = 1}, {id = 2}, {id = 3}})
		
		self.q:pop_left()
		self.q:push_right_some({{id = 4}, {id = 5}})
		
		lu.assertFalse(self.q:is_empty())
		lu.assertEquals(self.q:length(), 4)
		lu.assertNotNil(self.q:peek_left())
		lu.assertEquals(self.q:peek_left().id, 2)
		lu.assertEquals(self.q.head, 1)
		lu.assertEquals(self.q.tail, 5)
	end
	
	
	function TestQueue:test_pushLeftSomeAfterPushRight_didntRewrite()
		self.q:push_right_some({{id = 4}, {id = 5}})
		self.q:push_right({id = 6})
		
		self.q:push_left_some({{id = 1}, {id = 2}, {id = 3}})
		
		local data = self.q:contents()
		lu.assertEquals(self.q:length(), 6)
		lu.assertEquals(self.q.head, -3)
		lu.assertEquals(self.q.tail, 3)
		lu.assertEquals(data[1].id, 1)
		lu.assertEquals(data[2].id, 2)
		lu.assertEquals(data[3].id, 3)
		lu.assertEquals(data[4].id, 4)
		lu.assertEquals(data[5].id, 5)
		lu.assertEquals(data[6].id, 6)
	end
	
	
	function TestQueue:test_getContents_AfterPush_Valid()
		self.q:push_right_some({{id = 1}, {id = 2}, {id = 3}})
		
		local cont = self.q:contents()
		
		lu.assertEquals(#cont, 3)
		lu.assertEquals(self.q:length(), 3)
		lu.assertEquals(cont[1].id, 1)
		lu.assertEquals(cont[3].id, 3)
		lu.assertNil(cont[0])
	end
	
	function TestQueue:test_getContents_AfterPop_Valid()
		self.q:push_right_some({{id = 1}, {id = 2}, {id = 3}})
		
		self.q:pop_left()
		local cont = self.q:contents()
		
		lu.assertEquals(#cont, 2)
		lu.assertEquals(self.q:length(), 2)
		lu.assertNil(cont[0])
		lu.assertEquals(cont[1].id, 2)
		lu.assertEquals(cont[2].id, 3)
		lu.assertNil(cont[3])
	end
	
	function TestQueue:test_getContents_FromEmpty_returnNil()
		local cont = self.q:contents()
		
		lu.assertNil(cont)
		lu.assertEquals(self.q.head, 0)
		lu.assertEquals(self.q.tail, 0)
	end
	
	
	function TestQueue:test_popLessQueueLen_isNotEmpty()
		self.q:push_right_some({{id = 1}, {id = 2}, {id = 3}})
		
		local poped = self.q:pop_left_some(2)
		local rest = self.q:contents()
		
		lu.assertEquals(type(poped), 'table')
		lu.assertEquals(#poped, 2)
		lu.assertEquals(poped[1].id, 1)
		lu.assertEquals(poped[2].id, 2)
		lu.assertEquals(self.q:length(), 1)
		lu.assertEquals(self.q.head, 2)
		lu.assertEquals(self.q.tail, 3)
	end
	
	
	function TestQueue:test_popGreaterQueueLen_queueIsEmpty()
		self.q:push_right_some({{id = 1}, {id = 2}, {id = 3}})
		
		local poped = self.q:pop_left_some(4)
		local rest = self.q:contents()
		
		lu.assertEquals(type(poped), 'table')
		lu.assertEquals(#poped, 3)
		lu.assertEquals(poped[1].id, 1)
		lu.assertEquals(poped[3].id, 3)
		lu.assertTrue(self.q:is_empty())
		lu.assertEquals(self.q.head, 0)
		lu.assertEquals(self.q.tail, 0)
	end
	
	
	function TestQueue:test_popEqualQueueLen_queueIsEmpty()
		self.q:push_right_some({{id = 1}, {id = 2}, {id = 3}})
		
		local poped = self.q:pop_left_some(3)
		local rest = self.q:contents()
		
		lu.assertEquals(type(poped), 'table')
		lu.assertEquals(#poped, 3)
		lu.assertEquals(poped[1].id, 1)
		lu.assertEquals(poped[3].id, 3)
		lu.assertTrue(self.q:is_empty())
		lu.assertEquals(self.q.head, 0)
		lu.assertEquals(self.q.tail, 0)
	end
	
	
	function TestQueue:test_extractData_queueIsEmpty()
		self.q:push_right_some({{id = 1}, {id = 2}, {id = 3}})
		
		local ext = self.q:extract_data()
		
		lu.assertTrue(self.q:is_empty())
		lu.assertEquals(self.q.head, 0)
		lu.assertEquals(self.q.tail, 0)
		lu.assertEquals(#ext, 3)
		lu.assertEquals(ext[1].id, 1)
		lu.assertNil(ext[0])
	end
	
	function TestQueue:test_extractDataFromEmpty_returnNil()
		
		local ext = self.q:extract_data()
		
		lu.assertTrue(self.q:is_empty())
		lu.assertEquals(self.q.head, 0)
		lu.assertEquals(self.q.tail, 0)
		lu.assertNil(ext)
	end
	

-----------------------------------------
			--	CACHE  --
-----------------------------------------
local lcache = require ("qdbccache")
TestCache = {}

	function TestCache:setUp()
		self.dir = io.popen("cd"):read('*l')..'\\'
		self.c = lcache:create(self.dir)
		self.cache_path = self.dir.."cache\\"..tostring(os.date('%Y%m%d'))..".txt"
	end
	
	function TestCache:tearDown()
		os.remove(self.c.filepath)
	end
	
	-- -------------------------
	
	function TestCache:test_recreate_fileNotRewrite()
		self.c:append({id = 1})
		self.c:append({id = 2})
		
		local cch = lcache:create(self.dir)
		cch:append({id = 3})
		
		lu.assertFalse(self.c:is_empty())
		lu.assertFalse(cch:is_empty())
		lu.assertEquals(cch:length(), 3)
		lu.assertEquals(self.c:length(), 3)
	end
	
	function TestCache:test_create_pathsCorrect()
		lu.assertNotNil(self.c)
		lu.assertEquals(self.c.dir, self.dir)
		lu.assertEquals(self.c.filepath, self.cache_path)
		lu.assertFalse(file_exists(self.c.filepath))
		lu.assertTrue(self.c:is_empty())
	end
	
	function TestCache:test_createWithEmptyDir_throwError()
		lu.assertError(function() c = lcache:create("") end)
	end
	
	function TestCache:test_appendObjectToCache_appendedToFile()
		self.c:append({id = 1})
		
		local flines = lines_from(self.c.filepath)
		
		lu.assertTrue(file_exists(self.c.filepath))
		lu.assertEquals(#flines, 1)
		lu.assertEquals(flines[1], '{"id":1}')
		lu.assertFalse(self.c:is_empty())
	end
	
	function TestCache:test_appendCollectionToCache_appendedToFile()
		self.c:appendCollection({{id = 1}, {id = 2}, {id = 3}})
		
		local flines = lines_from(self.c.filepath)
		
		lu.assertTrue(file_exists(self.c.filepath))
		lu.assertEquals(#flines, 3)
		lu.assertEquals(flines[2], '{"id":2}')
		lu.assertFalse(self.c:is_empty())
	end
	
	function TestCache:test_append3_length3()
		self.c:appendCollection({{id = 1}, {id = 2}, {id = 3}})
		
		local clen = self.c:length()
		
		lu.assertTrue(file_exists(self.c.filepath))
		lu.assertEquals(clen, 3)
	end
	
	-- -------------------------
	
	function TestCache:test_extractJsonWithClean_CacheIsEmpty()
		self.c:appendCollection({{id = 1}, {id = 2}, {id = 3}})	
		local datas = self.c:extractDataAsJson()
		lu.assertTrue(self.c:is_empty())
		lu.assertFalse(file_exists(self.c.filepath))
	end
	
	function TestCache:test_extractJsonWithoutClean_CacheIsNotEmpty()
		self.c:appendCollection({{id = 1}, {id = 2}, {id = 3}})
		local datas = self.c:extractDataAsJson(false)
		lu.assertFalse(self.c:is_empty())
		lu.assertTrue(file_exists(self.c.filepath))
	end
		
	function TestCache:test_extractJson_ReturnValidStrings()
		self.c:appendCollection({{id = 1}, {id = 2}, {id = 3}})
		
		local datas = self.c:extractDataAsJson()
		
		lu.assertNotNil(datas)
		lu.assertEquals(#datas, 3)
		lu.assertEquals(type(datas[1]), 'string')
		lu.assertEquals(datas[1], '{"id":1}')
		lu.assertEquals(datas[2], '{"id":2}')
		lu.assertEquals(datas[3], '{"id":3}')
	end
	
	-- -------------------------

	function TestCache:test_extractObjWithClean_CacheIsEmpty()
		self.c:appendCollection({{id = 1}, {id = 2}, {id = 3}})	
		local datas = self.c:extractData()
		lu.assertTrue(self.c:is_empty())
		lu.assertFalse(file_exists(self.c.filepath))
	end
	
	function TestCache:test_extractObjWithoutClean_CacheIsNotEmpty()
		self.c:appendCollection({{id = 1}, {id = 2}, {id = 3}})
		local datas = self.c:extractData(false)
		lu.assertFalse(self.c:is_empty())
		lu.assertTrue(file_exists(self.c.filepath))
	end
	
	function TestCache:test_extractObj_ReturnValidTables()
		self.c:appendCollection({{id = 1}, {id = 2}, {id = 3}})
		
		local datas = self.c:extractData()
		
		lu.assertNotNil(datas)
		lu.assertEquals(#datas, 3)
		lu.assertEquals(type(datas[1]), 'table')
		lu.assertEquals(datas[1], {id = 1})
		lu.assertEquals(datas[2], {id = 2})
		lu.assertEquals(datas[3], {id = 3})
	end
	
	
-----------------------------------------
		   --	RECEIVERAPI  --
-----------------------------------------
local lreceiver = require('receiverapi')
socket = mockagne.getMock()

TestReceiverApi = {}
		function TestReceiverApi:setUp()
			self.dr = lreceiver:create('127.0.0.1', 9091)
			self.r = lreceiver:create('127.0.0.1', 9090)
			local conv = function()
				if not self.server_running then return nil end
				return { send = function(...) return self.server_running, self.server_running end}
			end
			when(socket.connect('127.0.0.1', 9090)).thenAnswerFn(conv)
			when(socket.connect('127.0.0.1', 9091)).thenAnswer(nil)
		end
		---------------------------------
		
		function TestReceiverApi:test_connect2DS_False()
			self.server_running = false
			local res = self.r:connect()
			lu.assertFalse(res)
			lu.assertFalse(self.r.is_connected)
		end
		
		function TestReceiverApi:test_connect2RS_True()
			self.server_running = true
			local res = self.r:connect()
			lu.assertTrue(res)
			lu.assertTrue(self.r.is_connected)
		end
		
		function TestReceiverApi:test_disconnect2DS_False()
			self.server_running = false
			local res = self.dr:disconnect()
			lu.assertFalse(res)
			lu.assertFalse(self.dr.is_connected)
		end
				
		function TestReceiverApi:test_disconnect2RS_True()
			self.server_running = true
			local cres = self.r:connect()
			lu.assertTrue(self.r.is_connected)
			lu.assertTrue(cres)
			
			local res = self.r:disconnect()
			lu.assertFalse(self.r.is_connected)
			lu.assertTrue(res)
		end
		
		function TestReceiverApi:test_disconnect2RSShooted_True()
			self.server_running = true
			local cres = self.r:connect()
			lu.assertTrue(self.r.is_connected)
			lu.assertTrue(cres)
			
			self.server_running = false
			
			local res = self.r:disconnect()
			lu.assertFalse(self.r.is_connected)
			lu.assertTrue(res)
		end
		
		---------------------------------
		
		function TestReceiverApi:test_sendMsg2RS_ReturnTrue()
			self.server_running = true
			local cres = self.r:connect()
			
			local sres = self.r:sendStr("asdasd")
			
			lu.assertTrue(self.r.is_connected)
			lu.assertTrue(cres)
			lu.assertNotNil(self.r.callback_client)
			lu.assertTrue(sres)
		end
		
		function TestReceiverApi:test_sendMsg2DS_ReturnNil()
			self.server_running = false
			local cres = self.dr:connect()
			
			local sres = self.dr:sendStr("asdasd")
			
			lu.assertFalse(self.dr.is_connected)
			lu.assertFalse(cres)
			lu.assertNil(self.r.callback_client)
			lu.assertNil(sres)
		end
		
		function TestReceiverApi:test_sendMsg2RSShooted_ReturnFalse()
			self.server_running = true
			local cres = self.r:connect()
			lu.assertTrue(self.r.is_connected)
			lu.assertTrue(cres)
			
			self.server_running = false
			local sres = self.r:sendStr("asdasd")
			
			lu.assertFalse(sres)
			lu.assertFalse(self.r.is_connected)
			lu.assertNil(self.r.callback_client)
		end
		


function file_exists(file)
  local f = io.open(file, "rb")
  if f then f:close() end
  return f ~= nil
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



