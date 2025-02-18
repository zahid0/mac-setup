-- Install lazy.nvim if not already installed
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
  vim.cmd([[helptags ALL]])
end

-- Add lazy.nvim to runtime path
vim.opt.rtp:prepend(lazypath)

-- Define plugins
local plugins = {
  -- Comment plugin
  {
    "numToStr/Comment.nvim",
    enabled = true
  },

  -- Directory diff plugin
  {
    "cossonleo/dirdiff.nvim",
    enabled = true
  },

  -- Jupyter notebook integration
  {
    "kiyoon/jupynium.nvim",
    enabled = true
  },

  -- GP.nvim plugin
  {
    -- Local directory for development
    dir = "~/projects/gp.nvim",
    enabled = true,
    dev = { true },
    config = function()
      -- Base objects
      local base_chat = {
        chat = true,
        command = false,
        system_prompt = "You are a general AI assistant.\n\n"
        .. "The user provided the additional info about how they would like you to respond:\n\n"
        .. "- If you're unsure don't guess and say you don't know instead.\n"
        .. "- Ask question if you need clarification to provide better answer.\n"
        .. "- Think deeply and carefully from first principles step by step.\n"
        .. "- Zoom out first to see the big picture and then zoom in to details.\n"
        .. "- Use Socratic method to improve your thinking and coding skills.\n"
        .. "- Don't elide any code from your output if the answer requires coding.\n"
        .. "- Take a deep breath; You've got this!\n",
      }

      local base_command = {
        chat = false,
        command = true,
        system_prompt = "You are an AI working as a code editor.\n\n"
        .. "Please AVOID COMMENTARY OUTSIDE OF THE SNIPPET RESPONSE.\n"
        .. "START AND END YOUR ANSWER WITH:\n\n```",
      }

      local function merge_tables(base, overrides)
        local result = {}
        for k, v in pairs(base) do
          if type(v) == "table" then
            result[k] = type(overrides[k]) == "table" and merge_tables(v, overrides[k]) or {}
          else
            result[k] = v
          end
        end
        for k, v in pairs(overrides) do
          if type(v) == "table" then
            result[k] = merge_tables(result[k] or {}, v)
          else
            result[k] = v
          end
        end
        return result
      end

      local function get_models(cache_file)
        if vim.fn.filereadable(cache_file) ~= 0 then
          local file, err = io.open(cache_file, "r")
          if not file then
            print("Failed to open file for reading: " .. cache_file .. "\nError: " .. err)
            return nil
          end
          local content = file:read("*a")
          file:close()
          local tbl = vim.json.decode(content)
          local groq_models = tbl.groq_models
          if os.time() - tbl.updated < 86400 then
            return groq_models
          end
        end
        return nil
      end

      local cache_dir = vim.fn.stdpath('cache') .. '/gp'

      if not vim.fn.isdirectory(cache_dir) then
        vim.fn.mkdir(cache_dir, 'p')
      end

      local cache_file = cache_dir ..  '/models.json'

      local groq_models = get_models(cache_file)

      if groq_models == nil then
        print("Fetching groq models ...")
        local content = vim.fn.system(string.format(
        "curl -s -H \"Authorization: Bearer %s\" https://api.groq.com/openai/v1/models | jq -r '[.data[].id]'",
        os.getenv("GROQ_API_KEY")
        ))
        groq_models = vim.json.decode(content)
        local json = vim.json.encode({
          updated = os.time(),
          groq_models = groq_models
        })
        local file = io.open(cache_file, "w")
        if not file then
          print("Failed to open file for writing: " .. file_path)
          return
        end
        file:write(json)
        file:close()
      end

      -- Create agents for each model
      local agents = {
        merge_tables(base_chat, {
          name = "Codestral Chat",
          provider = "codestral",
          model = "codestral-latest",
        }),
        merge_tables(base_command, {
          name = "CodestralCoder",
          provider = "codestral",
          model = "codestral-latest",
        }),
      }

      for _seq, model_id in pairs(groq_models) do
        -- Skip models containing "whisper" in their name
        if not string.match(model_id, "whisper") then
          -- Base model configuration
          local model_config = { model = model_id }
          -- Add reasoning_format if model contains "deepseekr1"
          if string.match(model_id, "deepseek%-r1") then
            model_config.reasoning_format = "hidden"
          end

          -- Create chat agent
          local chat_agent = merge_tables(base_chat, {
            name = string.format("Groq %s (Chat)", model_id),
            provider = "groq",
            model = model_config
          })
          table.insert(agents, chat_agent)

          -- Create command agent
          local command_agent = merge_tables(base_command, {
            name = string.format("Groq %s (Command)", model_id),
            provider = "groq",
            model = model_config
          })
          table.insert(agents, command_agent)
        end
      end


      require("gp").setup({
        log_sensitive = true,
        providers = {
          groq = {
            endpoint = "https://api.groq.com/openai/v1/chat/completions",
            secret = os.getenv("GROQ_API_KEY"),
          },
          codestral = {
            endpoint = "https://codestral.mistral.ai/v1/chat/completions",
            secret = os.getenv("CODESTRAL_API_KEY"),
          },
          anthropic = {
            disable = false,
          },
        },
        agents = agents,
      })
    end
  },

  -- GitHub Copilot plugin (disabled)
  {
    "github/copilot.vim",
    enabled = false
  }
}

-- Setup lazy.nvim
local opts = {}
require("lazy").setup(plugins, opts)
-- General Settings {{{1
vim.opt.ruler = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.number = true
vim.opt.foldlevel = 20
vim.opt.foldmethod = "indent"
vim.opt.history = 10000
vim.opt.hls = true
vim.opt.colorcolumn = "80"
vim.opt.mouse = ""

-- Highlight Color Column
vim.api.nvim_set_hl(0, "ColorColumn", { ctermbg = "lightgray" })

-- Filetype-specific Settings {{{1
vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  callback = function()
    vim.keymap.set("n", "<C-h>", function()
      vim.api.nvim_put({ "import pdb;pdb.set_trace()" }, "l", 0, true)
    end, { silent = true })
  end
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "javascript",
  callback = function()
    vim.keymap.set("n", "<C-h>", function()
      vim.api.nvim_put({ "debugger" }, "l", 0, true)
    end, { silent = true })
  end
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.opt_local.iskeyword = vim.opt_local.iskeyword + "-"
  end
})

-- Key Mappings {{{1
vim.keymap.set("n", "<Space>", ":nohlsearch<CR>")
vim.keymap.set("n", "-", ":Explore<CR>")
vim.keymap.set("n", "K", function()
  local word = vim.fn.expand("<cword>")
  vim.cmd(string.format("grep! '\\b%s\\b'", word))
  vim.cmd.cw()
end)

vim.keymap.set("n", ",c", function()
  vim.cmd.s({ args = "//", args = "gn" })
end)

-- Functions {{{1

local function zdiff()
  local ft = vim.bo.ft
  vim.cmd("vnew | 0read #")
  vim.bo.modifiable = false
  vim.bo.buftype = "nofile"
  vim.bo.bufhidden = "wipe"
  vim.bo.bl = false
  vim.bo.swf = false
  vim.bo.ro = true
  vim.bo.ft = ft
  vim.cmd("windo diffthis")
end

local function diff_with_git_checked_out()
  local ft = vim.bo.ft
  vim.cmd("vnew | 0read !git show HEAD:#")
  vim.bo.modifiable = false
  vim.bo.buftype = "nofile"
  vim.bo.bufhidden = "wipe"
  vim.bo.bl = false
  vim.bo.swf = false
  vim.bo.ro = true
  vim.bo.ft = ft
  vim.cmd("windo diffthis")
end

local function get_stub_from_rspec()
  local line_number = vim.api.nvim_get_current_line()
  vim.cmd(string.format("vnew | 0read !GENERATE_STUBS=1 rspec #:%s", line_number))
end

local function re_tag()
  local ft = vim.bo.ft
  vim.cmd(string.format("!ctags -R --tag-relative --languages=%s", ft))
end

-- Commands {{{1
vim.api.nvim_create_user_command("Diff", zdiff, {})
vim.api.nvim_create_user_command("Diffg", diff_with_git_checked_out, {})
vim.api.nvim_create_user_command("GetStub", get_stub_from_rspec, {})
vim.api.nvim_create_user_command("Tag", re_tag, {})

-- Ag Configuration {{{1
if vim.fn.executable("ag") then
  vim.opt.grepprg = "ag --nogroup --nocolor"
  vim.g.ctrlp_user_command = "ag %s -l --nocolor -g \"\""
end

-- Spell Configuration {{{1
vim.opt.spelllang = "en_us"
vim.cmd("syntax enable")
