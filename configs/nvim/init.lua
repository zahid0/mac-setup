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
end
vim.opt.rtp:prepend(lazypath)

local plugins = {
  {
    "numToStr/Comment.nvim",
    enabled = true
  },
  {
    "cossonleo/dirdiff.nvim",
    enabled = true
  },
  {
    "kiyoon/jupynium.nvim",
    enabled = true
  },
  {
    -- "robitx/gp.nvim",
    dir = "~/projects/gp.nvim",
    enabled = true,
    dev = {true},
    opts = {
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
      agents = {
        {
          name = "deepseekr1",
          provider = "groq",
          chat = true,
          command = false,
          system_prompt = "You are senior Software Engineer.",
          model = "deepseek-r1-distill-llama-70b"
        },
        {
          name = "Codestral Chat",
          provider = "codestral",
          chat = true,
          command = false,
          -- string with model name or table with model name and parameters
          --
          model = { model = "codestral-latest", temperature = 1.1, top_p = 1 },
          -- system prompt (use this to specify the persona/role of the AI)
          system_prompt = "You are a general AI assistant.\n\n"
                  .. "The user provided the additional info about how they would like you to respond:\n\n"
                  .. "- If you're unsure don't guess and say you don't know instead.\n"
                  .. "- Ask question if you need clarification to provide better answer.\n"
                  .. "- Think deeply and carefully from first principles step by step.\n"
                  .. "- Zoom out first to see the big picture and then zoom in to details.\n"
                  .. "- Use Socratic method to improve your thinking and coding skills.\n"
                  .. "- Don't elide any code from your output if the answer requires coding.\n"
                  .. "- Take a deep breath; You've got this!\n",
        },
        {
          name = "CodestralCoder",
          provider = "codestral",
          chat = false,
          command = true,
          -- string with model name or table with model name and parameters
          model = { model = "codestral-latest", temperature = 0.8, top_p = 1 },
          -- system prompt (use this to specify the persona/role of the AI)
          system_prompt = "You are an AI working as a code editor.\n\n"
          .. "Please AVOID COMMENTARY OUTSIDE OF THE SNIPPET RESPONSE.\n"
          .. "START AND END YOUR ANSWER WITH:\n\n```",
        },
      },
    },
  },
  {
    "github/copilot.vim",
    enabled = false
  }
}

local opts = {}

require("lazy").setup(plugins, opts)
require('Comment').setup()

vim.opt.mouse = ''
vim.opt.number = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.foldmethod = 'indent'
vim.opt.foldlevel = 99

if vim.fn.executable("ag") then
  vim.opt.grepprg = "ag --nogroup --nocolor"
end

vim.keymap.set('n', '-', ':Explore<CR>', {noremap = true})
vim.keymap.set('n', 'K', ':grep! "\\b<C-R><C-W>\\b"<CR>:cw<CR><CR>', {noremap = true})

vim.api.nvim_create_user_command("Diff", function()
  local filetype = vim.bo.filetype
  vim.cmd("vnew")
  vim.cmd("0read #")
  vim.cmd("setlocal nomodifiable bt=nofile bh=wipe nobl noswf ro ft=" .. filetype)
  vim.cmd("windo diffthis")
end, {})

