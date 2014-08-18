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
command!          Spotify            call s:VimSpotifyCreateBuffer()
command! -nargs=1 SpotifySearch      call s:VimSpotifySearch(<f-args>)
command!          SpotifyPlay        call s:VimSpotifyPlayTrack()
command!          SpotifyGetPlaylist call s:VimSpotifyGetPlaylist()
command!          SpotifyShowPlaylistTracks call s:VimSpotifyShowPlaylistTracks()

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

  map <buffer> S <esc>:SpotifySearch<space>
  map <buffer> s <esc>:SpotifySearch<space>
  map <buffer> P <esc>:SpotifyPlay<cr>
  map <buffer> p <esc>:SpotifyPlay<cr>
  map <buffer> pl <esc>:SpotifyGetPlaylist<cr>
  map <buffer> sl <esc>:SpotifyShowPlaylistTracks<cr>
endfunction

" Search Spotify
" ---------------------------------------------------------------------------------
function! s:VimSpotifySearch(search_string)
  let search_string = a:search_string
  call s:VimSpotifyGetURI(search_string)
endfunction

" Play Song
" ---------------------------------------------------------------------------------
function! s:VimSpotifyPlayTrack()
    setlocal cursorline
  ruby VimSpotify::play_track(VIM::evaluate("getline('.')"))
endfunction

" Get Playlist
" --------------------------------------------------------------------------------
function! s:VimSpotifyGetPlaylist()
  setlocal modifiable

  ruby VimSpotify::get_playlist()
  setlocal nomodifiable
endfunction

" Play Song
" ---------------------------------------------------------------------------------
function! s:VimSpotifyShowPlaylistTracks()
  setlocal modifiable

    setlocal cursorline
  ruby VimSpotify::show_playlist_tracks(VIM::evaluate("getline('.')"))

  setlocal nomodifiable
endfunction

" Vim -> Ruby interface
" ---------------------------------------------------------------------------------
function! s:VimSpotifyGetURI(search_string)
  setlocal modifiable

  ruby VimSpotify::get_search_uri(VIM::evaluate('a:search_string'))
  setlocal nomodifiable
endfunction

" Ruby extension
" ---------------------------------------------------------------------------------
ruby << EOF

require 'rspotify'

module VimSpotify
  class << self
    def get_search_uri(string)
      tracks = RSpotify::Track.search(string)

      clear_buffer

      tracks.each.with_index do |track, i|
        length = Time.at(track.duration_ms).gmtime.strftime('%M:%S')
        artists = track.artists[0].name.byteslice(0..17).rjust(18).force_encoding('ASCII-8BIT')
        song = track.name.byteslice(0..35).ljust(36).force_encoding('ASCII-8BIT')
        album_name = track.album.name.byteslice(0..39).ljust(40).force_encoding('ASCII-8BIT')
        uri = track.uri

        entry  = "| ♫ | #{song} | #{artists} | #{album_name} | #{uri} |"

        $curbuf.append i, entry
      end
    end

    def get_playlist
      parse_key
      RSpotify.authenticate(@client_id, @client_secret)

      user = RSpotify::User.find(@user)

      playlists = user.playlists

      clear_buffer

      playlists.each.with_index do |playlist, index|
        name = playlist.name.byteslice(0..35).ljust(36).force_encoding('ASCII-8BIT') unless playlist.nil?
        id = playlist.id unless playlist.nil?

        entry = "| #{index} | #{name} | #{id}"

        $curbuf.append index, entry
      end
    end

    def show_playlist_tracks(line)
      parse_key
      RSpotify.authenticate(@client_id, @client_secret)

      line_array = line.split('|')
      playlist_id = line_array[3].strip

      playlist = RSpotify::Playlist.find(@user, playlist_id)

      tracks = playlist.tracks

      clear_buffer

      tracks.each.with_index do |track, i|
        length = Time.at(track.duration_ms).gmtime.strftime('%M:%S')
        artists = track.artists[0].name.byteslice(0..17).rjust(18).force_encoding('ASCII-8BIT')
        song = track.name.byteslice(0..35).ljust(36).force_encoding('ASCII-8BIT')
        album_name = track.album.name.byteslice(0..39).ljust(40).force_encoding('ASCII-8BIT')
        uri = track.uri

        entry  = "| ♫ | #{song} | #{artists} | #{album_name} | #{uri} |"

        $curbuf.append i, entry
      end
    end

    def play_track(line)
      x,*meta   = *line.split('|').map {|c| c.strip}
      song   = meta.first
      artist = meta[1]
      href   = meta.last

      `osascript -e 'tell application "Spotify" to play track "#{href}"'`
    end

    def parse_key
      json = JSON.parse(File.read('/usr/local/etc/spotify/spotify.key'))

      @user = json['user']
      @client_id = json['client_id']
      @client_secret = json['client_secret']
    end

    def clear_buffer
      40.times do |line|
        $curbuf.append line, ''
      end
    end
  end
end

EOF
