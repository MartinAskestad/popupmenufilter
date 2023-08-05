vim9script
export def PopupMenuFilter(items: list<string>, options: dict<any>)
  var temp: list<string> = copy(items)
  var filter_str: string = ''

  var _options = {
    filter: (popup: number, key: string): bool => {
      var filter_changed: bool = false
      var is_backspace: bool = key == "\<BS>" || key == "\<C-H>"
      var is_ctrl_u: bool = key == "\<C-U>"
      var is_movement_key: bool = key == "\<C-F>" || key == "\<C-B>" || key == "\<PageUp>" || key == "\<PageDown>" || key == "\<C-Home>" || key == "\<C-End>" || key == "\<C-N>" || key == "\<C-P>"
      var is_letter_or_digit: bool = key =~ '^\f$' || key == "\<Space>"

      if is_backspace && len(filter_str) >= 1
        filter_str = filter_str[: -2]
        filter_changed = true
      elseif is_ctrl_u
        filter_str = ''
        filter_changed = true
      elseif is_letter_or_digit
        filter_str ..= key
        filter_changed = true
      endif

      if filter_changed
        var ps: list<list<number>> = []
        if filter_str != ''
          var ms: list<list<any>> = matchfuzzypos(items, filter_str)
          temp = ms[0]
          ps = ms[1]
        else
          temp = copy(items)
        endif

        var _items: list<string> = copy(temp)
        var text: list<dict<any>> = []
        if len(ps) > 0
          text = mapnew(_items, (i: number, v: string): dict<any> => ({ text: v, props: mapnew(ps[i], (_, w: number): dict<any> => ({ col: w + 1, length: 1, type: 'pickfilter'} )) } ))
        else
          text = mapnew(_items, (_, v: string): dict<string> => ({ text: v}))
        endif

        popup_settext(popup, text)

        if has_key(options, 'title')
          echo $"{options.title} {filter_str}"
        endif
        return true
      endif
        return popup_filter_menu(popup, key)
      },
      callback: (id: number, result: number) => {
        if result < 0
          options.cb(id, result)
          return
        endif
        var res_value = temp[result - 1]
        var my_idx = index(items, res_value)
        options.cb(id, my_idx + 1)
        }
  }

  var popup_id = popup_menu(items, extend(options, _options))
  prop_type_add('pickfilter', { bufnr: winbufnr(popup_id), highlight: 'Search' })
enddef
