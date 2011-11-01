zeroPad = (n) -> ("0" + n)[-2..]
timeFormat = (s) ->
  
  "#{zeroPad Math.floor s/60 }:#{zeroPad Math.floor s%60}"

escapeAttr = (attr) -> attr.replace /"/g, "&quot;"

$(document).ready ->

  $.ajaxSetup contentType: 'application/json', processData: false


  time = 0
  playing = false
  anchor = new Date
  setInterval ->
    if playing
      $('#current-song .time').html timeFormat parseFloat(time) + (new Date - anchor)/1000
  , 1000

  currentId = null

  songDisplay = (artist, album, title) ->
    $('#current-song .artist').html artist
    $('#current-song .album').html album
    $('#current-song .title').html title

  update = ->
    $.ajax '/songs/current', success: (song) ->
      
      if song.Title
        songDisplay song.Artist, song.Album, song.Title
      else if song.file
        path = song.file.split('/')
        songDisplay "", path[path.length-2], path[path.length-1]
      else
        songDisplay "Nothing Playing", "", ""        
        $('#current-song .length').html ""
        playing = false

      # Clear old highlight
      $('#playlist li.track').removeClass('ui-btn-up-e')
      $('#playlist li.track a').removeClass('ui-btn-up-e')
      
      currentId = song.Id

      if song.Id
        $("#playlist li[data-id=#{song.Id}]").addClass('ui-btn-up-e')
        $("#playlist li[data-id=#{song.Id}] a").addClass('ui-btn-up-e')

        $('#current-song .length').html timeFormat song.Time



    $.ajax '/time', success: (newTime) ->
      time = newTime
      anchor = new Date    
      $('#current-song .time').html timeFormat time

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

  $('#clear-playlist').click (ev) ->
    ev.preventDefault()
    $.ajax "/songs", type: 'DELETE', success: ->
      console.log "OK!"
      updateSongs()


  delayID = null
  delayedUpdate = ->
    clearTimeout delayID
    delayID = setTimeout updateSongs, 200

  $('.addalbum').live 'click', (ev) ->    
    album = $(ev.target).parents('li').data('album')
    $("#results a[data-album='#{album}']").each (i, el) ->
      file = $(el).data('file')

      $.ajax '/songs/', type: 'POST', data: JSON.stringify({file}), success: ->
        console.log "added song"
        delayedUpdate()


  $('.delalbum').live 'click', (ev) ->    
    album = $(ev.target).parents('li').data('album')
    $("#playlist li.track[data-album='#{album}']").each (i, el) ->
      id = $(el).data('id')
      
      console.log "deleting", id, el
      $.ajax "/songs/#{id}", type: 'DELETE', success: ->
          console.log "deleted song", id
          delayedUpdate()


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
        if !song.Album
          path = song.file.split('/')
          song.Album = path[path.length-2] unless song.Album
          file = path[path.length-1]


        if song.Album isnt album
          row = song.Album
          row = "#{song.Artist} &mdash; #{row}" if song.Artist
          el.append "<li data-role='list-divider' data-album='#{escape song.Album}'>
            <span>#{row}</span>
            <button data-icon='plus' data-inline='true' class='addalbum'>Album</button>
          </li>"
          album = song.Album
          
        if song.Title?
          row = "#{song.Track?.match(/^\d+/)[0] or '??'}. #{song.Title}"
        else
          row = "#{file}"
        el.append "<li data-icon='plus'><a href='#' data-file=\"#{escapeAttr song.file}\" data-album='#{escape song.Album}'>
          #{row}
        </a></li>"

      el.listview 'refresh'
      el.find('button').button()



  updateSongs = ->
    $.ajax '/songs/', success: (songs) ->
      console.log "songs", songs
      songs = [songs] if songs.constructor is Object
      el = $('#playlist')
      el.html('')
      album = null

      for song in songs when song.Id
        if !song.Album
          path = song.file.split('/')
          song.Album = path[path.length-2] unless song.Album
          file = path[path.length-1]

        if song.Album isnt album
          row = song.Album
          row = "#{song.Artist} &mdash; #{row}" if song.Artist
          el.append "<li data-role='list-divider' data-album='#{escape song.Album}'>
            #{row}
            <button data-icon='delete' data-inline='true' data-iconpos='notext' class='delalbum'></button>
          </li>"
          album = song.Album
          
        if song.Title?
          row = "#{song.Track?.match(/^\d+/)[0] or '??'}. #{song.Title}"
        else
          row = "#{file}"
        el.append "<li class='track #{if song.Id is currentId then "ui-btn-up-e" else ''} data-icon='false' data-id='#{song.Id}' data-album='#{escape song.Album}'><a href='#' class='play'>
          #{row}
        </a><a class='del'></a></li>"

      el.listview 'refresh'
      el.find('button').button()
  updateSongs()
