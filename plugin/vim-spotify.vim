" ---------------------------------------------------------------------------------
" Spotify Client for Vim
" ---------------------------------------------------------------------------------

if exists('g:vim_spotify_loaded') || &cp
  finish
endif

let g:vim_spotify_loaded       = 1
let g:vim_spotify_current_song = ''

" Commands
" ---------------------------------------------------------------------------------
command!          Spotify                   call s:VimSpotifyCreateBuffer()
command! -nargs=1 SpotifySearchTracks       call s:VimSpotifySearchTracks(<f-args>)
command! -nargs=1 SpotifySearchArtists      call s:VimSpotifySearchArtists(<f-args>)
command! -nargs=1 SpotifySearchAlbums       call s:VimSpotifySearchAlbums(<f-args>)
command!          SpotifySearchSelected     call s:SpotifySearchSelected()
command!          SpotifyPlayTrack          call s:VimSpotifyPlayTrack()
command!          SpotifyPlayPause          call s:VimSpotifyPlayPause()
command!          SpotifyNextTrack          call s:VimSpotifyNextTrack()
command!          SpotifyPreviousTrack      call s:VimSpotifyPreviousTrack()

" Create buffer
" ---------------------------------------------------------------------------------
function! s:VimSpotifyCreateBuffer()
  new "Spotify"
  buffer "Spotify"

  setlocal filetype=vim-spotify
  setlocal buftype=nofile
  setlocal nobuflisted
  setlocal noswapfile
  setlocal nonumber
  setlocal nowrap

  map <buffer> S <esc>:SpotifySearchTracks<space>
  map <buffer> s <esc>:SpotifySearchTracks<space>
  map <buffer> P <esc>:SpotifyPlayTrack<cr>
  map <buffer> p <esc>:SpotifyPlayTrack<cr>
  map <buffer> l <esc>:SpotifySearchSelected<cr>
endfunction

" ---------------------------------------------------------------------------------
" Search Tracks
" ---------------------------------------------------------------------------------
function! s:VimSpotifySearchTracks(search_string)
  setlocal modifiable

  ruby VimSpotify::get_tracks_by_name(VIM::evaluate('a:search_string'))
  setlocal nomodifiable
endfunction

" Search Artists
" ---------------------------------------------------------------------------------
function! s:VimSpotifySearchArtists(search_string)
  setlocal modifiable

  ruby VimSpotify::get_artists_by_name(VIM::evaluate('a:search_string'))
  setlocal nomodifiable
endfunction

" Search Albums
" ---------------------------------------------------------------------------------
function! s:VimSpotifySearchAlbums(search_string)
  setlocal modifiable

  ruby VimSpotify::get_albums_by_name(VIM::evaluate('a:search_string'))
  setlocal nomodifiable
endfunction

" Search Spotify " ---------------------------------------------------------------------------------
function! s:SpotifySearchSelected()
  setlocal cursorline
  setlocal modifiable

  ruby VimSpotify::display_selected(VIM::evaluate("getline('.')"))
  setlocal nomodifiable
endfunction

" Play Selected Track
" ---------------------------------------------------------------------------------
function! s:VimSpotifyPlayTrack()
    setlocal cursorline
  ruby VimSpotify::play_track(VIM::evaluate("getline('.')"))
endfunction

" Toggle Pause
" ---------------------------------------------------------------------------------
function! s:VimSpotifyPlayPause()
  ruby VimSpotify::play_pause()
endfunction

" Next Track
" ---------------------------------------------------------------------------------
function! s:VimSpotifyNextTrack()
  ruby VimSpotify::next_track()
endfunction

" Previous Track
" ---------------------------------------------------------------------------------
function! s:VimSpotifyPreviousTrack()
  ruby VimSpotify::previous_track()
endfunction

" Ruby extension
" ---------------------------------------------------------------------------------
ruby << EOF

require 'rspotify'

module VimSpotify
  class << self
    def authenticate
      parse_key
      RSpotify.authenticate(@client_id, @client_secret)
    end

    def get_tracks_by_name(track_name)
      tracks = RSpotify::Track.search(track_name)

      display(collect_tracks(tracks))
    end

    def get_artists_by_name(artist_name)
      artists = RSpotify::Artist.search(artist_name)

      display(collect_artists(artists))
    end

    def get_albums_by_name(album_name)
      albums = RSpotify::Album.search(album_name)

      display(collect_albums(albums))
    end

    def tracks_for_album(album)
      album = RSpotify::Album.find(album)

      display(collect_tracks(album.tracks))
    end

    def albums_for_artist(artist)
      artist = RSpotify::Artist.find(artist)

      display(collect_albums(artist.albums))
    end

    def dispaly_selected(selected)
      collect_selected(selected)
    end

    def play_track(track)
      `osascript -e 'tell application "Spotify" to play track "#{get_href(track)}"'`
    end

    def play_pause
      `osascript -e 'tell application "Spotify" to playpause'`
    end

    def next_track
      `osascript -e 'tell application "Spotify" to next track'`
    end

    def previous_track
      `osascript -e 'tell application "Spotify" to previous track'`
      `osascript -e 'tell application "Spotify" to previous track'`
    end

    private

    def display(items)
      50.times do |i|
        $curbuf.append i, ""
      end

      items.each.with_index do |item, index|
        $curbuf.append index, item
      end
    end

    def parse_key
      key_params = {}
      key_location = '/usr/local/etc/spotify/spotify.key'

      json = JSON.parse(File.read(key_location))

      @user = json['user']
      @client_id = json['client_id']
      @client_secret = json['client_secret']
    end

    def clear_results
      @results = []
    end

    def collect_selected(selected)
      clear_results

      href = get_href(selected)
      type = get_type(href)

      @user = json['user']
      @client_id = json['client_id']
      @client_secret = json['client_secret']
    end

    def clear_results
      @results = []
    end

    def collect_selected(selected)
      clear_results

      href = get_href(selected)
      type = get_type(href)

      if type == 'artist'
        albums_for_artist(get_uri(href))
      elsif type == 'album'
        tracks_for_album(get_uri(href))
      end
    end

    def get_href(line)
      x,*meta   = *line.split('|').map {|c| c.strip}
      song   = meta.first
      artist = meta[1]
      href   = meta.last

      href
    end

    def collect_tracks(tracks)
      clear_results

      tracks.each.with_index do |track, index|
        artist = track.artists[0].name.byteslice(0..17).rjust(18).force_encoding('ASCII-8BIT')
        song = track.name.byteslice(0..35).ljust(36).force_encoding('ASCII-8BIT')
        album_name = track.album.name.byteslice(0..39).ljust(40).force_encoding('ASCII-8BIT')
        uri = track.uri

        @results[index] = create_track_row(song, artist, album_name, uri)
      end

      @results
    end

    def collect_artists(artists)
      clear_results

      artists.each do |artist, index|
        artist_name = artist.name.byteslice(0..35).ljust(36).force_encoding('ASCII-8BIT')
        uri = artist.uri

        @results[index] = create_row(artist_name, uri)
      end

      @results
    end

    def collect_tracks(tracks)
      clear_results

      tracks.each.with_index do |track, index|
        artist = track.artists[0].name.byteslice(0..17).rjust(18).force_encoding('ASCII-8BIT')
        song = track.name.byteslice(0..35).ljust(36).force_encoding('ASCII-8BIT')
        album_name = track.album.name.byteslice(0..39).ljust(40).force_encoding('ASCII-8BIT')
        uri = track.uri

        @results[index] = create_track_row(song, artist, album_name, uri)
      end

      @results
    end

    def collect_artists(artists)
      clear_results

      artists.each do |artist, index|
        artist_name = artist.name.byteslice(0..35).ljust(36).force_encoding('ASCII-8BIT')
        uri = artist.uri

        @results[index] = create_row(artist_name, uri)
      end

      @results
    end

    def collect_albums(albums)
      clear_results

      albums.each do |album, index|
        album_name = album.name.byteslice(0..35).ljust(36).force_encoding('ASCII-8BIT')
        uri = album.uri

        @results[index] = create_row(album_name, uri)
      end

      @results
    end

    def create_track_row(song, artist, album_name, uri)
      "| ♫ | #{song} | #{artist} | #{album_name} | #{uri} |"
    end

    def collect_albums(albums)
      clear_results

      albums.each do |album, index|
        album_name = album.name.byteslice(0..35).ljust(36).force_encoding('ASCII-8BIT')
        uri = album.uri

        @results[index] = create_row(album_name, uri)
      end

      @results
    end

    def create_track_row(song, artist, album_name, uri)
      "| ♫ | #{song} | #{artist} | #{album_name} | #{uri} |"
    end

    def create_row(name, uri)
      "| ♫ | #{name} | #{} | #{} | #{uri} |"
    end

    def get_uri(href)
      href.split(':')[2]
    end

    def get_type(href)
      href.split(':')[1]
    end

    def collect_albums(albums)
      clear_results

      albums.each do |album, index|
        album_name = album.name.byteslice(0..35).ljust(36).force_encoding('ASCII-8BIT')
        uri = album.uri

        @results[index] = create_row(album_name, uri)
      end

      @results
    end

    def create_track_row(song, artist, album_name, uri)
      "| ♫ | #{song} | #{artist} | #{album_name} | #{uri} |"
    end

    def create_row(name, uri)
      "| ♫ | #{name} | #{} | #{} | #{uri} |"
    end

    def get_uri(href)
      href.split(':')[2]
    end

    def get_type(href)
      href.split(':')[1]
    end

  end
end

EOF
