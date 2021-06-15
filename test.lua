local http_client = require('http.client').new()
local json=require('json')

local BODY_INCORRECT_RESP = 400
local KEY_NOT_FOUND_RESP  = 404
local DUPLICATED_KEY_RESP = 409

local OK_RESP       = 200
local CREATED_RESP  = 201
local ACCEPTED_RESP = 202

local tests_counter = 0
local failed_tests_counter = 0

local test_failed = 0

-- Compare answers and print error message if need to
local function compareAndPrintError(test_name, resp_name, resp_answer, true_answer)
    if resp_answer ~= true_answer then
        if test_failed == 0 then
            test_failed = 1
            failed_tests_counter = failed_tests_counter + 1
            print(test_name, "FAILED:")
        end

        print(resp_name, "must be", true_answer, "but", resp_answer, "accepted!")
    end
end

-- OK response test POST
local function OK_test_POST()
    test_failed = 0
    tests_counter = tests_counter + 1

    local test_name = "OK_test_POST"

    local json_data = json.encode({key = 'three', value = 'value_three'})
    local resp = http_client:request('POST', 'http://localhost:8080/kv/', json_data)
    
    compareAndPrintError(test_name, 'status', resp.status, CREATED_RESP)
    compareAndPrintError(test_name, 'body',   resp.body, '{"key":"three","value":"value_three"}')
    --assert(resp.body == '{"key":"three","value":"value_three"}')
    if test_failed == 0 then
        print(test_name, "PASSED")
    end
end

-- BODY_INCORRECT_RESP response test POST
local function FAIL_test_POST()
    test_failed = 0
    tests_counter = tests_counter + 1

    local test_name = "FAIL_test_POST"

    local json_data = json.encode({kay = 'three2', value = 'kay, not the key'})
    local resp = http_client:request('POST', 'http://localhost:8080/kv/', json_data)

    compareAndPrintError(test_name, 'status', resp.status, BODY_INCORRECT_RESP)
    compareAndPrintError(test_name, 'body',   resp.body, 'Body is incorrect!')

    if test_failed == 0 then
        print(test_name, "PASSED")
    end
end

-- BODY_INCORRECT_RESP response other test POST
local function FAIL_test2_POST()
    test_failed = 0
    tests_counter = tests_counter + 1

    local test_name = "FAIL_test2_POST"

    local json_data = json.encode({key = 3, value = 'number, not str'})
    local resp = http_client:request('POST', 'http://localhost:8080/kv/', json_data)

    compareAndPrintError(test_name, 'status', resp.status, BODY_INCORRECT_RESP)
    compareAndPrintError(test_name, 'body',   resp.body, 'Body is incorrect!')

    if test_failed == 0 then
        print(test_name, "PASSED")
    end
end

-- DUPLICATED_KEY_RESP response test POST
local function FAIL_test3_POST()
    test_failed = 0
    tests_counter = tests_counter + 1

    local test_name = "FAIL_test3_POST"

    local json_data = json.encode({key = 'four', value = 'value_four'})
    local resp = http_client:request('POST', 'http://localhost:8080/kv/', json_data)

    local json_data2 = json.encode({key = 'four', value = 'other_value_four'})
    local resp2 = http_client:request('POST', 'http://localhost:8080/kv/', json_data2)

    compareAndPrintError(test_name, 'status', resp2.status, DUPLICATED_KEY_RESP)
    compareAndPrintError(test_name, 'body',   resp2.body, 'Key already exists!')

    if test_failed == 0 then 
        print(test_name, "PASSED")
    end
end

-- OK response test PUT
local function OK_test_PUT()
    test_failed = 0
    tests_counter = tests_counter + 1

    local test_name = "OK_test_PUT"

    local json_data = json.encode({value = 'other_value_one'})
    local resp = http_client:request('PUT', 'http://localhost:8080/kv/one/', json_data)

    compareAndPrintError(test_name, 'status', resp.status, OK_RESP)
    compareAndPrintError(test_name, 'body',   resp.body, '{"key":"one","value":"other_value_one"}')

    if test_failed == 0 then 
        print(test_name, "PASSED")
    end
end

-- BODY_INCORRECT_RESP response test PUT
local function FAIL_test_PUT()
    test_failed = 0
    tests_counter = tests_counter + 1

    local test_name = "FAIL_test_PUT"

    local json_data = json.encode({val = 'val, not the value'})
    local resp = http_client:request('PUT', 'http://localhost:8080/kv/one/', json_data)

    compareAndPrintError(test_name, 'status', resp.status, BODY_INCORRECT_RESP)
    compareAndPrintError(test_name, 'body',   resp.body, 'Body is incorrect!')
    
    if test_failed == 0 then
        print(test_name, "PASSED")
    end
end

-- KEY_NOT_FOUND_RESP response test PUT
local function FAIL_test2_PUT()
    test_failed = 0
    tests_counter = tests_counter + 1

    local test_name = "FAIL_test2_PUT"

    local json_data = json.encode({value = 'value_for_incorrect_key'})
    local resp = http_client:request('PUT', 'http://localhost:8080/kv/incorrect_key/', json_data)

    compareAndPrintError(test_name, 'status', resp.status, KEY_NOT_FOUND_RESP)
    compareAndPrintError(test_name, 'body',   resp.body, 'Key not found!')

    if test_failed == 0 then
        print(test_name, "PASSED")
    end
end

-- OK response test GET
local function OK_test_GET()
    test_failed = 0
    tests_counter = tests_counter + 1

    local test_name = "OK_test_GET"

    local resp = http_client:request('GET', 'http://localhost:8080/kv/one/')

    compareAndPrintError(test_name, 'status', resp.status, OK_RESP)
    compareAndPrintError(test_name, 'body',   resp.body, '{"key":"one","value":"other_value_one"}')

    if test_failed == 0 then
        print(test_name, "PASSED")
    end
end

-- KEY_NOT_FOUND_RESP response test GET
local function FAIL_test_GET()
    test_failed = 0
    tests_counter = tests_counter + 1

    local test_name = "FAIL_test_GET"

    local resp = http_client:request('GET', 'http://localhost:8080/kv/incorrect_key/')

    compareAndPrintError(test_name, 'status', resp.status, KEY_NOT_FOUND_RESP)
    compareAndPrintError(test_name, 'body',   resp.body, 'Key not found!')

    if test_failed == 0 then
        print(test_name, "PASSED")
    end
end

-- OK response test DELETE
local function OK_test_DELETE()
    test_failed = 0
    tests_counter = tests_counter + 1

    local test_name = "OK_test_DEL"

    local resp = http_client:request('DELETE', 'http://localhost:8080/kv/one/')

    compareAndPrintError(test_name, 'status', resp.status, OK_RESP)
    compareAndPrintError(test_name, 'body',   resp.body, '{"key":"one","value":"other_value_one"}')

    if test_failed == 0 then
        print(test_name, "PASSED")
    end
end

-- KEY_NOT_FOUND_RESP response test DELETE
local function FAIL_test_DELETE()
    test_failed = 0
    tests_counter = tests_counter + 1

    local test_name = "FAIL_test_DEL"

    local resp = http_client:request('DELETE', 'http://localhost:8080/kv/one/')

    compareAndPrintError(test_name, 'status', resp.status, KEY_NOT_FOUND_RESP)
    compareAndPrintError(test_name, 'body',   resp.body, 'Key not found!')

    if test_failed == 0 then
        print(test_name, "PASSED")
    end
end

-- OK response test combined
local function test_STRONG()
    test_failed = 0
    tests_counter = tests_counter + 1

    local test_name = "test_STRONG"

    local json_data = json.encode({key = 'strong_key', value = 'strong_value'})
    local resp = http_client:request('POST', 'http://localhost:8080/kv/', json_data)

    resp = http_client:request('GET', 'http://localhost:8080/kv/strong_key/')

    compareAndPrintError(test_name, 'status', resp.status, OK_RESP)
    compareAndPrintError(test_name, 'body',   resp.body,   '{"key":"strong_key","value":"strong_value"}')

    if test_failed == 0 then
        print(test_name, "PASSED")
    end
end

-- OK response test combined
local function test2_STRONG()
    test_failed = 0
    tests_counter = tests_counter + 1

    local test_name = "test2_STRONG"

    local json_data = json.encode({value = 'other_strong_value'})
    local resp = http_client:request('PUT', 'http://localhost:8080/kv/strong_key/', json_data)

    resp = http_client:request('GET', 'http://localhost:8080/kv/strong_key/')

    compareAndPrintError(test_name, 'status', resp.status, OK_RESP)
    compareAndPrintError(test_name, 'body',   resp.body,   '{"key":"strong_key","value":"other_strong_value"}')

    if test_failed == 0 then
        print(test_name, "PASSED")
    end
end

-- KEY_NOT_FOUND_RESP response test combined
local function test3_STRONG()
    test_failed = 0
    tests_counter = tests_counter + 1

    local test_name = "test3_STRONG"

    local resp = http_client:request('DELETE', 'http://localhost:8080/kv/strong_key/')

    resp = http_client:request('GET', 'http://localhost:8080/kv/strong_key/')

    compareAndPrintError(test_name, 'status', resp.status, KEY_NOT_FOUND_RESP)
    compareAndPrintError(test_name, 'body',   resp.body,   'Key not found!')

    if test_failed == 0 then
        print(test_name, "PASSED")
    end
end

local function runAllTests()
    -- POST tests
    OK_test_POST()
    FAIL_test_POST()
    FAIL_test2_POST()
    FAIL_test3_POST()

    -- PUT tests
    OK_test_PUT()
    FAIL_test_PUT()
    FAIL_test2_PUT()

    -- GET tests
    OK_test_GET()
    FAIL_test_GET()

    -- DELETE tests
    OK_test_DELETE()
    FAIL_test_DELETE()

    -- Сombined tests
    test_STRONG()
    test2_STRONG()
    test3_STRONG()

    print("_______________________")
    print("SUMMARY:", tests_counter - failed_tests_counter, "tests passed", "|" , failed_tests_counter, "tests failed")
end

runAllTests()
