return {
  {
    "nvim-neotest/neotest",
    cmd = { "Neotest" },
    dependencies = { "fredrikaverpil/neotest-golang" },
    opts = function(_, opts)
      opts.adapters = {
        require("neotest-golang")({}),
      }
    end,
  },
}
