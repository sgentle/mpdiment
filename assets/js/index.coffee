zeroPad = (n) -> ("0" + n)[-2..]
timeFormat = (s) ->
  
  "#{zeroPad Math.floor s/60 }:#{zeroPad Math.floor s%60}"

$(document).ready ->

  $.ajaxSetup contentType: 'application/json', processData: false


  time = 0
  anchor = new Date
  setInterval ->
    if playing
      $('#now-playing .time').html timeFormat parseFloat(time) + (new Date - anchor)/1000
  , 1000

  update = ->
    $.ajax '/songs/current', success: (song) ->
      $('#now-playing .artist').html "#{song.Artist}"
      $('#now-playing .album').html "#{song.Album}"
      $('#now-playing .title').html "#{song.Title}"
      $('#now-playing .length').html timeFormat song.Time

    $.ajax '/time', success: (newTime) ->
      time = newTime
      anchor = new Date    
      $('#now-playing .time').html timeFormat time

  setInterval update, 5000
  update()

  active = (el, val) ->
    if val
      el.addClass 'ui-btn-active'
    else      
      el.removeClass 'ui-btn-active'

  updateRandom = ->
    $.ajax '/random', success: (random) ->
      active $('#random').parent(), random
    
  updateRepeat = ->
    $.ajax '/repeat', success: (repeat) ->
      active $('#repeat').parent(), repeat

  playing = false
  updatePlay = ->
    el = $('#play').parent().find('.ui-btn-text')
    $.ajax '/playing', success: (_playing) ->
      playing = _playing
      if playing
        el.html('Pause')
      else      
        el.html('Play')

  $('#play').click ->
    el = $('#play').parent().find('.ui-btn-text')
    playing = not playing
    $.ajax '/playing', type: 'PUT', data: JSON.stringify(playing), success: ->
      if playing
        el.html('Pause')
      else      
        el.html('Play')

  $('#prev').click ->
    $.ajax '/songs/current', type: 'POST', data: JSON.stringify({Id: 'prev'}), success: ->
      console.log "OK!"
      update()

  $('#next').click ->
    $.ajax '/songs/current', type: 'POST', data: JSON.stringify({Id: 'next'}), success: ->
      console.log "OK!"
      update()

  $('#random').click ->
    random = not $('#random').parent().hasClass 'ui-btn-active'
    $.ajax '/random', type: 'PUT', data: JSON.stringify(random), success: ->
      active $('#random').parent(), random
      
  $('#repeat').click ->
    repeat = not $('#repeat').parent().hasClass 'ui-btn-active'
    $.ajax '/repeat', type: 'PUT', data: JSON.stringify(repeat), success: ->
      active $('#repeat').parent(), repeat

  updateRandom()
  updateRepeat()
  updatePlay()


  $('#playlist a.play').live 'click', (ev) ->
    ev.preventDefault()
    id = $(ev.target).parents('li').data 'id'
    $.ajax '/songs/current', type: 'POST', data: JSON.stringify({Id: id}), success: ->
      console.log "OK!"
      update()
      updatePlay()

  $('#playlist a.del').live 'click', (ev) ->
    ev.preventDefault()
    id = $(ev.target).parents('li').data 'id'
    $.ajax "/songs/#{id}", type: 'DELETE', success: ->
      console.log "OK!"
      updateSongs()

  $('#results a').live 'click', (ev) ->
    ev.preventDefault()
    file = $(ev.target).data 'file'
    $.ajax '/songs/', type: 'POST', data: JSON.stringify({file}), success: ->
      console.log "OK!"
      updateSongs()


  $('#search').submit (ev) ->
    ev.preventDefault()
    ev.stopPropagation()
    q = $(ev.target.elements.search).val()
    $.ajax '/db/search/', data: {q}, processData: true, success: (songs) ->
      console.log "songs", songs
      songs = [songs] if songs.constructor is Object
      
      el = $('#results')
      el.html('')
      el.listview 'refresh'
      album = null

      for song in songs when song.file
        if song.Album isnt album
          el.append "<li data-role='list-divider' data-icon='plus'>
            #{song.Artist} &mdash; #{song.Album}
          </li>"
          album = song.Album
          
        el.append "<li data-icon='plus'><a data-file='#{song.file}'>
          #{song.Track?.match(/^\d+/)[0]}. #{song.Title}
        </a></li>"

      el.listview 'refresh'
      



  updateSongs = ->
    $.ajax '/songs/', success: (songs) ->
      console.log "songs", songs
      songs = [songs] if songs.constructor is Object
      el = $('#playlist')
      el.html('')
      album = null

      for song in songs when song.Id
        if song.Album isnt album
          el.append "<li data-role='list-divider'>
            #{song.Artist} &mdash; #{song.Album}
          </li>"
          album = song.Album
          
        el.append "<li data-icon='false' data-id='#{song.Id}'><a class='play'>
          #{song.Track.match(/^\d+/)[0]}. #{song.Title}
        </a><a class='del'></a></li>"

      el.listview 'refresh'
  updateSongs()
