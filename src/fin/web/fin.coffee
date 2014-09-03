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

Ledger = React.createClass
  displayName: 'Ledger'

  getInitialState: -> {col:0, reverse:true}

  render: ->
    renderPayee = (e) ->
      console.log e

    cols = [
      { name: 'date',   get: (e) -> e.date  },
      { name: 'payee',  get: (e) -> e.payee },
      { name: 'amount', get: (e) -> e.amount },
    ]

    entries = @props.entries
    sortFn = cols[@state.col].get
    entries.sort (a, b) -> cmp sortFn(a), sortFn(b)
    entries.reverse() if @state.reverse

    total = 0
    R.table {className:'ledger', cellSpacing:0},
      R.thead null,
        R.tr {className:'clickable'},
          for col, i in cols
            R.th {key:i, onClick:@sort}, col.name
      R.tbody null,
        for e, i in @props.entries
          total += e.amount
          R.tr {key:i},
            R.td {className:'date'}, e.date
            R.td {className:'payee'},
              e.payee + ' ',
              for tag in (e.tags or [])
                R.span {key:tag, className:'tag-bubble'}, tag
            R.td {className:'amount'}, formatAmount(e.amount)
        if entries.length > 0
          R.tr null,
            R.td null
            R.td null, 'total'
            R.td {className:'amount'}, formatAmount(total)

  sort: (e) ->
    col = e.target.cellIndex
    reverse = @state.reverse
    if col == @state.col
      reverse = !reverse
    @setState {col, reverse}


Filter = React.createClass
  displayName: 'Filter'

  render: ->
    R.label null,
      'filter: ',
      SearchInput {size:30, autoFocus:true, onSearch:@search}

  search: (query) ->
    @props.onSearch(@parseQuery(query))

  parseQuery: (query) ->
    terms = for tok in query.split(/\s+/)
      continue if tok == ''
      do (tok) ->
        negate = false
        if /^-/.test tok
          negate = true
          tok = tok.substr(1)
        if /^t:/.test tok
          tok = tok.substr(2)
          if tok == ''
            f = (e) -> e.tags?
          else
            f = (e) -> e.tags and tok in e.tags
        else if /^y:/.test tok
          tok = tok.substr(2)
          f = (e) -> e.date.substr(0, tok.length) == tok
        else if /^>/.test tok
          val = parseInt(tok.substr(1)) * 100
          f = (e) -> Math.abs(e.amount) > val
        else if /^</.test tok
          val = parseInt(tok.substr(1)) * 100
          f = (e) -> Math.abs(e.amount) < val
        else
          r = new RegExp(tok, 'i')
          f = (e) -> r.test(e.payee)
        if negate
          (e) -> not f(e)
        else
          f
    return null unless terms.length > 0
    return (e) ->
      for q in terms
        return false if not q(e)
      return true


TagView = React.createClass
  displayName: 'TagView'

  render: ->
    R.div null,
      R.div null,
        'tag: '
        AutoC {options:@props.tags, onCommit:@onTag}
      Ledger {entries:@props.entries}

  onTag: (text) ->
    data =
      tags: text.split(/\s+/)
      ids: (entry.id for entry in @props.entries)

    req = new XMLHttpRequest()
    req.onload = () => @props.reload()
    req.open('post', '/')
    req.send(JSON.stringify(data))

    return true


Summary = React.createClass
  displayName: 'Summary'

  getInitialState: ->
    @props.entries.sort (a, b) -> cmp a.date, b.date

    first = @props.entries[0]
    last = @props.entries[@props.entries.length - 1]

    {tags:@gatherTagsByAmount(), off:{}, \
     firstDate:first.date, lastDate:last.date}

  # Sort tags by total amounts.
  # Returns a list of tags in descending order of amount.
  gatherTagsByAmount: ->
    # Sum total amount attributed to each tag.
    tagsums = {}
    for e in @props.entries
      if e.tags
        for t in e.tags
          tagsums[t] = (tagsums[t] or 0) + e.amount
    # Sort tags in order of amount.
    tagsums = d3.entries(tagsums)
    tagsums.sort((a, b) -> d3.descending(a.value, b.value))
    return (t.key for t in tagsums)

  # Assign each entry to one of @state.tags and compute total amount
  # in each tag.
  # Returns a map of tag -> amount.
  computeBuckets: ->
    chooseBucket = (e) =>
      if e.tags
        # Assign the largest bucket to this entry.  Go through
        # @state.tags in order as it's sorted in order of tag size.
        for t in @state.tags
          return t if t in e.tags
      return 'unknown'

    d3.nest()
      .key(chooseBucket)
      .rollup((d) -> d3.sum(e.amount for e in d))
      .map(@props.entries)

  render: ->
    delta = parseDate(@state.lastDate) - parseDate(@state.firstDate)
    deltaMonths = delta / 1000 / 60 / 60 / 24 / 365 * 12

    buckets = pairs(@computeBuckets())
    buckets.sort (a, b) -> cmp b[1], a[1]
    total = 0
    for t in buckets
      if t[0] of @state.off
        t[1] = null
      else
        total += t[1]

    R.div null,
      if @state.firstDate
        R.div null,
          'dates span '
          DatePicker {text:@state.firstDate, onCommit:@onDate.bind(@, 0)}
          ' \u2013 '
          DatePicker {text:@state.lastDate, onCommit:@onDate.bind(@, 1)}
      R.table {cellSpacing:0, className:'ledger'},
        R.thead null,
          R.tr null,
            R.th null, 'tag'
            R.th null, 'amount'
            R.th null, 'per month'
            R.th null, '%'
        R.tbody null,
          for b in buckets
            [tag, amount] = b
            className = ''
            className = 'off' if tag of @state.off
            R.tr {key:tag, className},
              R.td {onClick:@toggle.bind(@, tag), className:'tag clickable'}, tag
              R.td {className:'amount'},
                approx(amount) if amount?
              R.td {className:'amount'},
                approx(amount / deltaMonths) if amount?
              R.td {className:'amount'},
                (100 * amount / total).toFixed(0) + '%' if amount?
          if total
            R.tr {key:tag},
              R.td null, 'total'
              R.td {className:'amount'},
                approx(total) if total
              R.td {className:'amount'},
                if amount and deltaMonths
                  approx(total / deltaMonths)


  toggle: (tag) ->
    if tag of @state.off
      delete @state.off[tag]
    else
      @state.off[tag] = true
    @setState(@state)
    return

  onDate: (which, text) ->
    switch which
      when 0 then @setState {firstDate:text}
      when 1 then @setState {lastDate:text}
    return


App = React.createClass
  displayName: 'App'

  getInitialState: -> {mode:'browse', search:null}

  getEntries: ->
    entries = @props.entries
    if @state.search
      entries = entries.filter(@state.search)
    return entries

  render: ->
    entries = @getEntries()

    R.main null,
      R.header null,
        R.div null,
          'mode:'
          for mode in ['browse', 'chart', 'tag']
            do (mode) =>
              R.span {key:mode},
                ' '
                R.a {href:'#', onClick:((e) => @viewMode(e, mode))}, mode
        R.div {className:'spacer'}
        Filter {onSearch:@onSearch}
      switch @state.mode
        when 'browse'
          Summary {tags:@props.tags, entries}
        when 'tag'
          TagView {tags:@props.tags, entries, reload:@props.reload}
        when 'chart'
          null

  viewMode: (e, mode) ->
    e.preventDefault()
    @setState {mode}
    return true

  onSearch: (search) ->
    @setState {search}
    return


AppShell = React.createClass
  displayName: 'AppShell'

  getInitialState: -> {}

  render: ->
    unless @state.entries or @state.loading
      @reload()
      return R.div()
    App {entries:@state.entries, tags:@state.tags, \
         reload:(=> @reload(); return)}

  load: (data) ->
    entries = data.entries.sort (a, b) -> cmp a.date, b.date
    entries = entries.filter (e) -> e.amount != 0

    tags = {}
    for entry in entries
      entry.amount = -entry.amount
      if entry.tags
        for tag in entry.tags
          tags[tag] = true
    tags = Object.keys(tags)

    window.data = {entries, tags}
    @setState {entries, tags}

  reload: ->
    @setState {loading:true}
    req = new XMLHttpRequest()
    req.onload = (e) =>
      @load(JSON.parse(req.responseText))
      @setState {loading:false}
      return
    req.open('get', '/data')
    req.send()
    return


init = ->
  React.renderComponent(AppShell(), document.body)

init()
