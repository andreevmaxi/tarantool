
-- write data recover from latest snapshot
env = require('test_run')
test_run = env.new()

test_run:cmd("setopt delimiter ';'")
function check_slab_stats(slab_stats, granularity)
    for _, stats in pairs(slab_stats) do
        assert(type(stats) == "table")
        for key, value in pairs(stats) do
            if key == "item_size" then
                assert((value % granularity) == 0)
            end
        end
    end
end;
test_run:cmd("setopt delimiter ''");

test_run:cmd("setopt delimiter ';'")
test_run:cmd('create server test with script=\z
             "box/gh-5518-add-granularity-option.lua"');
test_run:cmd("setopt delimiter ''");
-- Start server test with granularity == 2 failed
-- (must be greater than or equal to 4)
test_run:cmd('start server test with args="2" with crash_expected=True')
-- Start server test with granularity == 7 failed (must be exponent of 2)
test_run:cmd('start server test with args="7" with crash_expected=True')

test_run:cmd('start server test with args="4"')
test_run:cmd('switch test')

s = box.schema.space.create('test')
_ = s:create_index('test')

-- Granularity determines not only alignment of objects,
-- but also size of the objects in the pool. Thus, the greater
-- the granularity, the greater the memory loss per one memory allocation,
-- but tuples with different sizes are allocated from the same mempool,
-- and we do not lose memory on the slabs, when we have highly
-- distributed tuple sizes. This is somewhat similar to a large alloc factor

-- Try to insert/delete to space, in case when UB sanitizer on,
-- we check correct memory aligment
for i = 1, 1000 do s:insert{i, i + 1} end
slab_stats = box.slab.stats()
slab_info = box.slab.info()
test_run:cmd('switch default')
slab_stats = test_run:eval('test', "slab_stats")
slab_info = test_run:eval('test', "slab_info")
slab_stats_4 = slab_stats[1]
slab_info_4 = slab_info[1]
check_slab_stats(slab_stats_4, 4)
test_run:cmd('switch test')
s:drop()
test_run:cmd('switch default')
test_run:cmd('stop server test')

test_run:cmd('start server test with args="64"')
test_run:cmd('switch test')
s = box.schema.space.create('test')
_ = s:create_index('test')
for i = 1, 1000 do s:insert{i, i + 1} end
slab_stats = box.slab.stats()
slab_info = box.slab.info()
test_run:cmd('switch default')
slab_stats = test_run:eval('test', "slab_stats")
slab_info = test_run:eval('test', "slab_info")
slab_stats_64 = slab_stats[1]
slab_info_64 = slab_info[1]
check_slab_stats(slab_stats_64, 64)
test_run:cmd('switch test')
s:drop()
test_run:cmd('switch default')
test_run:cmd('stop server test')

-- Start server test with granularity = 8192
-- This is not a user case (such big granularity leads
-- to an unacceptably large memory consumption).
-- For test purposes only.
test_run:cmd('start server test with args="8192"')
test_run:cmd('switch test')
s = box.schema.space.create('test')
_ = s:create_index('test')
for i = 1, 1000 do s:insert{i, i + 1} end
slab_stats = box.slab.stats()
slab_info = box.slab.info()
test_run:cmd('switch default')
slab_stats = test_run:eval('test', "slab_stats")
slab_info = test_run:eval('test', "slab_info")
slab_stats_8192 = slab_stats[1]
slab_info_8192 = slab_info[1]
check_slab_stats(slab_stats_8192, 8192)
test_run:cmd('switch test')
s:drop()
test_run:cmd('switch default')
test_run:cmd('stop server test')

-- Check that the larger the granularity,
-- the larger memory usage.
test_run:cmd("setopt delimiter ';'")
for key, value_4 in pairs(slab_info_4) do
    local value_64 = slab_info_64[key]
    local value_8192 = slab_info_8192[key]
    if (key == "items_used_ratio" or key == "arena_used_ratio") then
        local p = string.find(value_4, "%%")
        value_4 = string.sub(value_4, 0, p - 1)
        p = string.find(value_64, "%%")
        value_64 = string.sub(value_64, 0, p - 1)
        p = string.find(value_8192, "%%")
        value_8192 = string.sub(value_8192, 0, p - 1)
    end
    if (key == "items_used" or key == "arena_used" or
        key == "items_used_ratio" or key == "arena_used_ratio") then
        assert(tonumber(value_4) < tonumber(value_64) and
               tonumber(value_64) < tonumber(value_8192))
    end
end;
test_run:cmd("setopt delimiter ''");

test_run:cmd('cleanup server test')
test_run:cmd('delete server test')