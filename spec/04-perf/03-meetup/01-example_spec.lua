local perf = require("spec.helpers.perf")
local split = require("pl.stringx").split
local utils = require("spec.helpers.perf.utils")

perf.use_driver("docker")

local versions = { "2.5.0" }

for _, version in ipairs(versions) do

  describe("perf test for Kong " .. version, function()
    lazy_setup(function()
      local helpers = perf.setup()

      local bp = helpers.get_db_utils("postgres", {
        "routes",
        "services",
      })

      local upstream_uri = perf.start_upstream([[
      location = /test {
        return 200;
      }
      ]])

      local service = bp.services:insert {
        url = upstream_uri .. "/test",
      }

      bp.routes:insert {
        paths = { string.format("/s%d-r%d", i, j) },
        service = service,
        strip_path = true,
      }
    end)

    before_each(function()
      perf.start_kong(version, {
        --kong configs
      })
    end)

    after_each(function()
      perf.stop_kong()
    end)

    lazy_teardown(function()
      perf.teardown()
    end)

    it("#example", function()
      perf.start_load({
        path = "/s1-r1",
        connections = 1000,
        threads = 5,
        duration = LOAD_DURATION,
      })

      local result = assert(perf.wait_result())

      print(("### Result for Kong %s:\n%s"):format(version, result))

      perf.save_error_log("output/example.log")
    end)
  end)

end