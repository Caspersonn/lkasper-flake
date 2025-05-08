return {
  'linden-project/linny.vim',
  enabled = function()

    local filename = os.getenv( "HOME" ) .. "/git/personal/lkasper-linny"
    local f=io.open( filename ,"r")

    if f~=nil then
      io.close(f)
      return true
    else
      return false
    end
  end,

  config = function()
    vim.fn['linny#Init']()
  end,
}
