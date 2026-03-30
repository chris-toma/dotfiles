-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("n", "<leader>gx", function()
  Snacks.picker.git_branches()
end, { desc = "Git Branches" })

vim.keymap.set("n", "<leader>gk", function()
  vim.system({ "git", "push" }, { text = true }, function(out)
    if out.code == 0 then
      Snacks.notify.info("Git push successful")
    else
      Snacks.notify.error("Git push failed:\n" .. out.stderr)
    end
  end)
end, { desc = "Git Push" })

vim.keymap.set("n", "<leader>gj", function()
  vim.system({ "git", "pull" }, { text = true }, function(out)
    if out.code == 0 then
      Snacks.notify.info("Git pull successful")
    else
      Snacks.notify.error("Git pull failed:\n" .. out.stderr)
    end
  end)
end, { desc = "Git Pull" })
