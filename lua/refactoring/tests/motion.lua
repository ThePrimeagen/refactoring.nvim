local function vim_motion(motion)
    vim.cmd(string.format(':exe "norm! %s\\<esc>"', motion))
end

return vim_motion
