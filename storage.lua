
local http_port = os.getenv('HTTP_PORT') or '8080'

local http_client = require('http.server').new('127.0.0.1', http_port)

local log = require('log')

local BODY_INCORRECT_RESP = 400
local KEY_NOT_FOUND_RESP  = 404
local DUPLICATED_KEY_RESP = 409

local OK_RESP       = 200
local CREATED_RESP  = 201

box.cfg{log='./TestKVstorage_log.log'}

-- Create space
space1 = box.schema.space.create('TestKVstorage')

space1:format({
    {name = 'key', type = 'string'},
    {name = 'value', type = 'string'}
})

space1:create_index('primary', {
    type = 'HASH';
    parts = {'key'};
    if_not_exists = true;
})

-- Insert few tuples
box.space.TestKVstorage:insert{'one', 'one_val'}
box.space.TestKVstorage:insert{'two', '{"hello" : "world", "hello2" : "world2"}'}

-- Method for logging
local function logMethod(response, method, key, value)
     log.info('%s(%s, %s) - RESPONSE: %d',  method, key, value, response)
end

-- POST /kv body: {key: "test", "value": {SOME ARBITRARY JSON}} 
local function post(request)
    local method_name = 'POST'

    local body = request:json()
    
    if body['key'] == nil or body['value'] == nil or type(body['key']) ~= 'string' or type(body['value']) ~= 'string' then
        logMethod(BODY_INCORRECT_RESP, method_name, body['key'], body['value'])
        return {body = 'Body is incorrect!', status = BODY_INCORRECT_RESP}
    end

    local selected = box.space.TestKVstorage:select(body['key'])
    
    if table.getn(selected) ~= 0 then
        logMethod(DUPLICATED_KEY_RESP, method_name, body['key'], body['value'])
        return {body = 'Key already exists!', status = DUPLICATED_KEY_RESP}
    end


    box.space.TestKVstorage:insert{body['key'], body['value']}

    logMethod(CREATED_RESP, method_name, body['key'], body['value'])
    
    local response = request:render{
            json = {key = body['key'], value = body['value']}
        }
    response.status = CREATED_RESP

    return response
end

-- PUT kv/{id} body: {"value": {SOME ARBITRARY JSON}} 
local function put(request)
    local method_name = 'PUT'

    local key = request:stash('key')

    local body = request:json()

    if body['value'] == nil or type(body['value']) ~= 'string' then
        logMethod(BODY_INCORRECT_RESP, method_name, key, '')
        return {body = 'Body is incorrect!', status = BODY_INCORRECT_RESP}
    end

    local selected = box.space.TestKVstorage:select{key}

    if table.getn(selected) == 0 then
        logMethod(KEY_NOT_FOUND_RESP, method_name, key, body['value'])
        return {body = 'Key not found!', status = KEY_NOT_FOUND_RESP}
    end

    box.space.TestKVstorage:update(selected[1][1], {{'=', 2, body['value']}})
    logMethod(OK_RESP, method_name, selected[1][1], body['value'])

    local response = request:render{
            json = {key = selected[1][1], value = body['value']}
        }
    response.status = OK_RESP

    return response
end

-- GET kv/{id} 
local function get(request)
    local method_name = 'GET'
    local key = request:stash('key')

    local selected = box.space.TestKVstorage:select{key}

    if table.getn(selected) == 0 then
        logMethod(KEY_NOT_FOUND_RESP, method_name, key, '')

        return {body = 'Key not found!', status = KEY_NOT_FOUND_RESP}
    end

    logMethod(OK_RESP, method_name, key, selected[1][2])

    local response = request:render{
            json = {key = selected[1][1], value = selected[1][2]}
        }
    response.status = OK_RESP

    return response

end

-- DELETE kv/{id}
local function delete(request)
    local method_name = 'DELETE'
    local key = request:stash('key')

    local selected = box.space.TestKVstorage:select(key)

    if table.getn(selected) == 0 then
        logMethod(KEY_NOT_FOUND_RESP, method_name, key, '')
        return {body = 'Key not found!', status = KEY_NOT_FOUND_RESP}
    end

    box.space.TestKVstorage:delete(key)

    local response = request:render{
            json = {key = selected[1][1], value = selected[1][2]}
        }
    response.status = OK_RESP

    return response
end

-- Create router
local router = require('http.router').new()

-- Set our functions
router:route({ path = '/kv',      method = 'POST' },   post)
router:route({ path = '/kv/:key', method = 'GET' },    get)
router:route({ path = '/kv/:key', method = 'PUT' },    put)
router:route({ path = '/kv/:key', method = 'DELETE' }, delete)

http_client:set_router(router)

box.schema.user.grant('guest', 'read,write,execute', 'universe')

http_client:start()
