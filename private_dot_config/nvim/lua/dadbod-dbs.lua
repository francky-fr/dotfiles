local vim_setup_path = vim.fn.stdpath('config')
vim.env.PYTHONPATH = vim_setup_path .. '/py:' .. (vim.env.PYTHONPATH or '')
vim.g.python3_host_prog = vim_setup_path .. "/.venv/bin/python3"

vim.cmd([[
py3 << EOF
import dadbod
def vim_get_iam_connection_str(region, host, workgroup, port, db):
    return dadbod.get_iam_connection_str(region, host, workgroup, port, db)
def vim_get_connection_str_from_sm(region, sm_path):
    return dadbod.get_iam_connection_str_from_sm(region, sm_path)
def vim_get_connection_str_from_sso(profile, region, host, workgroup, port, db):
    return dadbod.get_sso_connection_str(profile, region, host, workgroup, port, db)
EOF
]])

vim.g.db_verbose = 1


local function wilson_red_franck_dev_url()
    ret = vim.fn.py3eval(string.format(
        [[vim_get_iam_connection_str('%s', '%s', '%s', %d, '%s')]],
        "eu-central-1",
        "wilson-dev.891239948857.eu-central-1.redshift-serverless.amazonaws.com",
        "wilson-dev",
        5439,
        "dev"
    ))
    return ret
end

local function wilson_red_narbonne_dev_url()
    ret = vim.fn.py3eval(string.format(
        [[vim_get_connection_str_from_sso('%s', '%s', '%s', '%s', %d, '%s')]],
	"narbonne_fc",
        "eu-central-1",
        "wilson-dev.891239948857.eu-central-1.redshift-serverless.amazonaws.com",
        "wilson-dev",
        5439,
        "dev"
    ))
    return ret
end

local function wilson_red_admin_dev_url()
    ret = vim.fn.py3eval(string.format(
        [[vim_get_connection_str_from_sso('%s', '%s', '%s', '%s', %d, '%s')]],
	"production_admin",
        "eu-central-1",
        "wilson-dev.891239948857.eu-central-1.redshift-serverless.amazonaws.com",
        "wilson-dev",
        5439,
        "dev"
    ))
    return ret
end

local function wilson_pg_dev_url()
    ret = vim.fn.py3eval(string.format(
	[[vim_get_connection_str_from_sm('%s', '%s')]],
	"eu-central-1",
	"/dev/wilson/DATABASES"
    ))
    return ret
end

local function airbyte_workload_pg_url()
    ret = vim.fn.py3eval(string.format(
	[[vim_get_connection_str_from_sm('%s', '%s')]],
	"eu-central-1",
	"airbyte_db_user"
    ))
    return ret
end


local M = {}

local base_dbs = {
  {
    name = '(Dev)franck@Wilson-Red',
    url = function() return wilson_red_franck_dev_url() end
  },
  {
    name = '(Dev)Wilson-PG',
    url = function() return wilson_pg_dev_url() end
  }
}

local admin_dbs = {
  {
    name = '(Dev)admin@Wilson-Red',
    url = function() return wilson_red_admin_dev_url() end
  },
  {
    name = 'airbyte_admin@airbyte-workload',
    url = function() return airbyte_workload_pg_url() end
  }
}

function M.setup_dbs()
  local dbs = {}

  for _, db in ipairs(base_dbs) do
    local name = db.name
    local url = db.url()
    dbs[name] = url
  end

  if vim.fn.getenv("WITH_ADMIN_DB") == "1" then
    for _, db in ipairs(admin_dbs) do
      local name = '🔴' .. db.name
      local url = db.url()
      dbs[name] = url
    end
  end

  vim.g.dbs = dbs
end

function _G.db_refresh_all()
  vim.notify("Going to refresg dynamic dbs")
  M.setup_dbs()
  vim.notify("Refreshed dynamic DB URLs", vim.log.levels.INFO)
end

return M

