# Copyright 2014 Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# An input box with autocompletions.
# props:
#   options: [string], list of completion options
#   onCommit: function(string), called when user hits enter
AutoC = React.createClass
  displayName: 'AutoC'

  getInitialState: ->
    {sel:null, text:'', focus:false}

  render: ->
    words = @state.text.split(/\s+/)
    word = words[words.length - 1]
    @filteredOptions = @props.options.filter (opt) ->
      word.length > 0 and opt.indexOf(word) == 0

    R.div className:'autoc',
      R.input {ref:'input', autoComplete:false, \
               onChange:@onChange, onKeyDown:@onKeyDown, \
               onFocus:@onFocus, onBlur:@onBlur, \
               value:@state.text}
      if @filteredOptions.length > 0 and @state.focus
        R.div {className:'dropdown'},
          for o, i in @filteredOptions
            className = 'item'
            className += ' sel' if i == @state.sel
            do (o) =>
              R.div {key:i, className, onMouseDown:(=> @complete(o); return)},
                o

  onChange: ->
    text = @refs.input.getDOMNode().value
    @setState {text}
    return

  onKeyDown: (e) ->
    return if e.shiftKey or e.altKey or e.metaKey
    sel = @state.sel
    if e.key == 'ArrowDown' or e.key == 'Tab'
      sel = if sel? then sel + 1 else 0
    else if e.key == 'ArrowUp'
      sel-- if sel?
    else if e.key == 'Enter'
      if sel?
        @complete(@filteredOptions[sel])
        sel = null
      else if @props.onCommit
        if @props.onCommit(@state.text)
          @setState text:''
    else
      return
    e.preventDefault()
    sel = null unless @filteredOptions.length
    if sel?
      sel = 0 if sel < 0
      sel = @filteredOptions.length - 1 if sel >= @filteredOptions.length
    @setState {sel}
    return

  onFocus: ->
    @setState focus:true
    return

  onBlur: ->
    @setState sel:null, focus:false
    return

  complete: (text) ->
    words = @state.text.split(/\s+/)
    words[words.length - 1] = text
    text = words.join(' ') + ' '
    @setState {text}
    return


# An <input type=search>, because React doesn't know about it (?).
SearchInput = React.createClass
  displayName: SearchInput

  render: ->
    # The incremental:true here doesn't seem to do anything (?).
    @transferPropsTo(
      R.input ref:'i', type:'search', incremental:true
    )

  componentDidMount: ->
    i = @refs.i.getDOMNode()
    i.incremental = true
    i.addEventListener 'search', @onSearch
    return

  onSearch: ->
    @props.onSearch(@refs.i.getDOMNode().value)
    return
