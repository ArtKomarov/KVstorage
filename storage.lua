
local http_port = os.getenv('HTTP_PORT') or '8080'

local http_client = require('http.server').new('127.0.0.1', http_port)

box.cfg{}

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

box.schema.user.grant('guest', 'read,write,execute', 'universe')





