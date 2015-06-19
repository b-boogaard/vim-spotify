require 'rspotify'

module VimSpotify
  class << self
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

    def display_selected(selected)
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

      artists.each.with_index do |artist, index|
        artist_name = artist.name.byteslice(0..35).ljust(36).force_encoding('ASCII-8BIT')
        uri = artist.uri

        @results[index] = create_row(artist_name, uri)
      end

      @results
    end

    def collect_albums(albums)
      clear_results

      albums.each.with_index do |album, index|
        album_name = album.name.byteslice(0..35).ljust(36).force_encoding('ASCII-8BIT')
        uri = album.uri

        @results[index] = create_row(album_name, uri)
      end

      @results
    end

    def create_track_row(song, artist, album_name, uri)
      "| ♫ | #{song} | #{artist} | #{album_name} | #{uri} |"
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
