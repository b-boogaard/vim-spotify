" ---------------------------------------------------------------------------------
" Spotify Client for Vim
" ---------------------------------------------------------------------------------

if exists('g:vim_spotify_loaded') || &cp
  finish
endif

let g:vim_spotify_loaded       = 1
let g:vim_spotify_current_song = ''

ruby load 'vim_spotify.rb'

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
