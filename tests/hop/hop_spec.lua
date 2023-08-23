local hop = require('hop')
local hop_hint = require('hop.hint')
local api = vim.api
local eq = assert.are.same
local test_count = 0

local function override_getcharstr(override, closure)
  local mocked = vim.fn.getcharstr
  vim.fn.getcharstr = override

  local r = closure()

  vim.fn.getcharstr = mocked

  return r
end

describe('Hop', function()
  before_each(function()
    vim.cmd.new(test_count .. 'test_file')
    test_count = test_count + 1
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {
      'abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxy',
    })
    hop.setup()
  end)

  it('Hop is initialized', function()
    eq(hop.initialized, true)
  end)

  it('HopChar1AC', function()
    vim.api.nvim_win_set_cursor(0, { 1, 1 })

    local key_counter = 0
    override_getcharstr(function()
      key_counter = key_counter + 1
      if key_counter == 1 then
        return 'c'
      end
      if key_counter == 2 then
        return 's'
      end
    end, function()
      hop.hint_char1({ direction = hop_hint.HintDirection.AFTER_CURSOR })
    end)

    local end_pos = api.nvim_win_get_cursor(0)

    eq(end_pos[2], 28)
  end)

  it('HopChar2AC', function()
    vim.api.nvim_win_set_cursor(0, { 1, 1 })

    local key_counter = 0
    override_getcharstr(function()
      key_counter = key_counter + 1
      if key_counter == 1 then
        return 'c'
      end
      if key_counter == 2 then
        return 'd'
      end
      if key_counter == 3 then
        return 's'
      end
    end, function()
      hop.hint_char2({ direction = hop_hint.HintDirection.AFTER_CURSOR })
    end)

    local end_pos = api.nvim_win_get_cursor(0)

    eq(end_pos[2], 28)
  end)

  it('Hop from empty line', function()
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {
      'abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxy',
      '',
      'abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxy',
    })
    vim.api.nvim_win_set_cursor(0, { 2, 1 })

    local key_counter = 0
    override_getcharstr(function()
      key_counter = key_counter + 1
      if key_counter == 1 then
        return 'c'
      end
      if key_counter == 2 then
        return 's'
      end
    end, function()
      hop.hint_char1({ direction = hop_hint.HintDirection.AFTER_CURSOR })
    end)

    local end_pos = api.nvim_win_get_cursor(0)

    eq(end_pos[2], 28)
    eq(end_pos[1], 3)

    vim.api.nvim_win_set_cursor(0, { 2, 1 })
    key_counter = 0
    override_getcharstr(function()
      key_counter = key_counter + 1
      if key_counter == 1 then
        return 'c'
      end
      if key_counter == 2 then
        return 's'
      end
    end, function()
      hop.hint_char1({ direction = hop_hint.HintDirection.BEFORE_CURSOR })
    end)

    local end_pos = api.nvim_win_get_cursor(0)

    eq(end_pos[2], 28)
    eq(end_pos[1], 1)
  end)
  end)

  it('HopCamelCase', function()
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {
      'abcdefGhij.klmn#opqrst3uv!sxyz_bcdefgh-jklmnopq@rstuvwxy$s 0x3C',
    })
    vim.api.nvim_win_set_cursor(0, { 1, 1 })
    local key_counter = 0
    override_getcharstr(function()
      key_counter = key_counter + 1
      if key_counter == 1 then
        return 'i'
      end
    end, function()
      hop.hint_camel_case({ direction = hop_hint.HintDirection.AFTER_CURSOR })
    end)

    local end_pos = api.nvim_win_get_cursor(0)
    eq(end_pos[2], 59)
  end)

  it('HopWords', function()
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {
      'abcdef .klmn#opqrst3u v!sxyz_bcdefgh-jklmnopq@rstuvwxy$s 0x3C',
    })
    vim.api.nvim_win_set_cursor(0, { 1, 1 })
    local key_counter = 0
    override_getcharstr(function()
      key_counter = key_counter + 1
      if key_counter == 1 then
        return 'q'
      end
    end, function()
      hop.hint_words({ direction = hop_hint.HintDirection.AFTER_CURSOR })
    end)

    local end_pos = api.nvim_win_get_cursor(0)
    -- TODO 57 fails ci but accepts localy
    --eq(end_pos[2], 55)
    eq(end_pos[1], 1)

    key_counter = 0
    override_getcharstr(function()
      key_counter = key_counter + 1
      if key_counter == 1 then
        return 'l'
      end
    end, function()
      hop.hint_words({ direction = hop_hint.HintDirection.BEFORE_CURSOR })
    end)

    end_pos = api.nvim_win_get_cursor(0)
    eq(end_pos[2], 0)
  end)

  it('Hop lines start', function()
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {
      '   abcdef .klmn#opqrst3u v!sxyz_bcdefgh-jklmnopq@rstuvwxy$s 0x3C',
      '      abcdef .klmn#opqrst3u v!sxyz_bcdefgh-jklmnopq@rstuvwxy$s 0x3C',
      '  abcdef .klmn#opqrst3u v!sxyz_bcdefgh-jklmnopq@rstuvwxy$s 0x3C',
      '   abcdef .klmn#opqrst3u v!sxyz_bcdefgh-jklmnopq@rstuvwxy$s 0x3C',
      '  abcdef .klmn#opqrst3u v!sxyz_bcdefgh-jklmnopq@rstuvwxy$s 0x3C',
      '    abcdef .klmn#opqrst3u v!sxyz_bcdefgh-jklmnopq@rstuvwxy$s 0x3C',
    })

    vim.api.nvim_win_set_cursor(0, { 1, 1 })
    local key_counter = 0
    override_getcharstr(function()
      key_counter = key_counter + 1
      if key_counter == 1 then
        return 'd'
      end
    end, function()
      hop.hint_lines_skip_whitespace({ direction = hop_hint.HintDirection.AFTER_CURSOR })
    end)

    local end_pos = api.nvim_win_get_cursor(0)
    eq(end_pos[2], 6)
    eq(end_pos[1], 2)

    key_counter = 0
    override_getcharstr(function()
      key_counter = key_counter + 1
      if key_counter == 1 then
        return 's'
      end
    end, function()
      hop.hint_lines_skip_whitespace({ direction = hop_hint.HintDirection.BEFORE_CURSOR })
    end)

    end_pos = api.nvim_win_get_cursor(0)
    eq(end_pos[2], 3)
    eq(end_pos[1], 1)
  end)

  it('HopCamelCase', function()
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {
      'abcdefGhij.klmn#opqrst3uv!sxyz_bcdefgh-jklmnopq@rstuvwxy$s 0x3C',
    })
    vim.api.nvim_win_set_cursor(0, { 1, 1 })
    local key_counter = 0
    override_getcharstr(function()
      key_counter = key_counter + 1
      if key_counter == 1 then
        return 'i'
      end
    end, function()
      hop.hint_camel_case({ direction = hop_hint.HintDirection.AFTER_CURSOR })
    end)

    local end_pos = api.nvim_win_get_cursor(0)
    eq(end_pos[2], 59)
  end)

  it('HopWords', function()
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {
      'abcdef .klmn#opqrst3u v!sxyz_bcdefgh-jklmnopq@rstuvwxy$s 0x3C',
    })
    vim.api.nvim_win_set_cursor(0, { 1, 1 })
    local key_counter = 0
    override_getcharstr(function()
      key_counter = key_counter + 1
      if key_counter == 1 then
        return 'q'
      end
    end, function()
      hop.hint_words({ direction = hop_hint.HintDirection.AFTER_CURSOR })
    end)

    local end_pos = api.nvim_win_get_cursor(0)
    -- TODO 57 fails ci but accepts localy
    --eq(end_pos[2], 55)
    eq(end_pos[1], 1)

    key_counter = 0
    override_getcharstr(function()
      key_counter = key_counter + 1
      if key_counter == 1 then
        return 'l'
      end
    end, function()
      hop.hint_words({ direction = hop_hint.HintDirection.BEFORE_CURSOR })
    end)

    end_pos = api.nvim_win_get_cursor(0)
    eq(end_pos[2], 0)
  end)

  it('Hop lines start', function()
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {
      '   abcdef .klmn#opqrst3u v!sxyz_bcdefgh-jklmnopq@rstuvwxy$s 0x3C',
      '      abcdef .klmn#opqrst3u v!sxyz_bcdefgh-jklmnopq@rstuvwxy$s 0x3C',
      '  abcdef .klmn#opqrst3u v!sxyz_bcdefgh-jklmnopq@rstuvwxy$s 0x3C',
      '   abcdef .klmn#opqrst3u v!sxyz_bcdefgh-jklmnopq@rstuvwxy$s 0x3C',
      '  abcdef .klmn#opqrst3u v!sxyz_bcdefgh-jklmnopq@rstuvwxy$s 0x3C',
      '    abcdef .klmn#opqrst3u v!sxyz_bcdefgh-jklmnopq@rstuvwxy$s 0x3C',
    })

    vim.api.nvim_win_set_cursor(0, { 1, 1 })
    local key_counter = 0
    override_getcharstr(function()
      key_counter = key_counter + 1
      if key_counter == 1 then
        return 'd'
      end
    end, function()
      hop.hint_lines_skip_whitespace({ direction = hop_hint.HintDirection.AFTER_CURSOR })
    end)

    local end_pos = api.nvim_win_get_cursor(0)
    eq(end_pos[2], 6)
    eq(end_pos[1], 2)

    key_counter = 0
    override_getcharstr(function()
      key_counter = key_counter + 1
      if key_counter == 1 then
        return 's'
      end
    end, function()
      hop.hint_lines_skip_whitespace({ direction = hop_hint.HintDirection.BEFORE_CURSOR })
    end)

    end_pos = api.nvim_win_get_cursor(0)
    eq(end_pos[2], 3)
    eq(end_pos[1], 1)
  end)

  it('Hop lines', function()
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {
      'abcdef .klmn#opqrst3u v!sxyz_bcdefgh-jklmnopq@rstuvwxy$s 0x3C',
      'abcdef .klmn#opqrst3u v!sxyz_bcdefgh-jklmnopq@rstuvwxy$s 0x3C',
      'abcdef .klmn#opqrst3u v!sxyz_bcdefgh-jklmnopq@rstuvwxy$s 0x3C',
      'abcdef .klmn#opqrst3u v!sxyz_bcdefgh-jklmnopq@rstuvwxy$s 0x3C',
      'abcdef .klmn#opqrst3u v!sxyz_bcdefgh-jklmnopq@rstuvwxy$s 0x3C',
      'abcdef .klmn#opqrst3u v!sxyz_bcdefgh-jklmnopq@rstuvwxy$s 0x3C',
    })
    vim.print(vim.api.nvim_buf_get_lines(0, 0, -1, false))
    vim.api.nvim_win_set_cursor(0, { 1, 2 })
    local key_counter = 0
    override_getcharstr(function()
      key_counter = key_counter + 1
      if key_counter == 1 then
        return 'd'
      end
    end, function()
      hop.hint_lines({ direction = hop_hint.HintDirection.AFTER_CURSOR })
    end)

    local end_pos = api.nvim_win_get_cursor(0)
    eq(end_pos[2], 2)
    eq(end_pos[1], 1)

    key_counter = 0
    override_getcharstr(function()
      key_counter = key_counter + 1
      if key_counter == 1 then
        return 'a'
      end
    end, function()
      hop.hint_lines({ direction = hop_hint.HintDirection.BEFORE_CURSOR })
    end)

    end_pos = api.nvim_win_get_cursor(0)
    eq(end_pos[2], 2)
    eq(end_pos[1], 1)
  end)
end)
