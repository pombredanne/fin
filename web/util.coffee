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

class RDate
  constructor: (@y, @m, @d) ->

  @parse: (a) ->
    [y, m, d] = a.split /\//
    new RDate(parseInt(y), parseInt(m), parseInt(d))

  str: ->
    [d3.format('04')(@y), d3.format('02')(@m), d3.format('02')(@d)].join '/'

  diff: (d) ->
    new RDateDelta(@y-d.y, @m-d.m, @d-d.d)


class RDateDelta
  constructor: (@dy, @dm, @dd) ->
    @normalize()

  normalize: ->
    if @dm < 0
      @dy -= 1
      @dm += 12
    if @dd < 0
      @dm -= 1
      @dd += 30


fmt = (str, args...) ->
  start = 0
  out = []
  for i in [0..str.length]
    if i == str.length or str[i] == '$'
      out.push(str.substr(start, i - start))
      start = i + 1
      if str[i] == '$'
        out.push(args.shift())
  return out.join('')

cmp = (a, b) ->
  return -1 if a < b
  return 1 if a > b
  return 0

pairs = (o) ->
  [k, o[k]] for k of o

approx = (amt) ->
  prefix = '$'
  dollars = parseInt(amt / 100)
  if dollars < 0
    dollars = -dollars
    prefix += '-'
  if dollars > 1000
    return prefix + (dollars / 1000).toFixed(1) + 'k'
  else
    return prefix + dollars
