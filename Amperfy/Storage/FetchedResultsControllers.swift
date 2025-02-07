import Foundation
import CoreData

enum PlaylistSortType: Int {
    case name = 0
    case lastPlayed = 1
    case lastChanged = 2
    
    static let defaultValue: PlaylistSortType = .name
}

enum DisplayCategoryFilter {
    case all
    case recentlyAdded
    case favorites
}

class PodcastFetchedResultsController: CachedFetchedResultsController<PodcastMO> {
    
    init(managedObjectContext context: NSManagedObjectContext, isGroupedInAlphabeticSections: Bool) {
        let library = LibraryStorage(context: context)
        let fetchRequest = PodcastMO.identifierSortedFetchRequest
        fetchRequest.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
            AbstractLibraryEntityMO.excludeRemoteDeleteFetchPredicate,
            library.getFetchPredicate(onlyCachedPodcasts: true),
        ])
        super.init(managedObjectContext: context, fetchRequest: fetchRequest, isGroupedInAlphabeticSections: isGroupedInAlphabeticSections)
    }
        
    func search(searchText: String, onlyCached: Bool) {
        if searchText.count > 0 || onlyCached {
            let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSCompoundPredicate(orPredicateWithSubpredicates: [
                    AbstractLibraryEntityMO.excludeRemoteDeleteFetchPredicate,
                    library.getFetchPredicate(onlyCachedPodcasts: true),
                ]),
                PodcastMO.getIdentifierBasedSearchPredicate(searchText: searchText),
                library.getFetchPredicate(onlyCachedPodcasts: onlyCached)
            ])
            search(predicate: predicate)
        } else {
            showAllResults()
        }
    }

}

class PodcastEpisodesReleaseDateFetchedResultsController: BasicFetchedResultsController<PodcastEpisodeMO> {
    
    init(managedObjectContext context: NSManagedObjectContext, isGroupedInAlphabeticSections: Bool) {
        let fetchRequest = PodcastEpisodeMO.publishedDateSortedFetchRequest
        let library = LibraryStorage(context: context)
        fetchRequest.predicate = library.getFetchPredicateForUserAvailableEpisodes()
        super.init(managedObjectContext: context, fetchRequest: fetchRequest, isGroupedInAlphabeticSections: isGroupedInAlphabeticSections)
    }
    
    func search(searchText: String, onlyCachedSongs: Bool) {
        if searchText.count > 0 || onlyCachedSongs {
            let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                library.getFetchPredicateForUserAvailableEpisodes(),
                PodcastEpisodeMO.getIdentifierBasedSearchPredicate(searchText: searchText),
                library.getFetchPredicate(onlyCachedPodcastEpisodes: onlyCachedSongs)
            ])
            search(predicate: predicate)
        } else {
            showAllResults()
        }
    }

}

class PodcastEpisodesFetchedResultsController: BasicFetchedResultsController<PodcastEpisodeMO> {
    
    let podcast: Podcast
    
    init(forPodcast podcast: Podcast, managedObjectContext context: NSManagedObjectContext, isGroupedInAlphabeticSections: Bool) {
        self.podcast = podcast
        let library = LibraryStorage(context: context)
        let fetchRequest = PodcastEpisodeMO.publishedDateSortedFetchRequest
        fetchRequest.predicate = library.getFetchPredicateForUserAvailableEpisodes(forPodcast: podcast)
        super.init(managedObjectContext: context, fetchRequest: fetchRequest, isGroupedInAlphabeticSections: isGroupedInAlphabeticSections)
    }
    
    func search(searchText: String, onlyCachedSongs: Bool) {
        if searchText.count > 0 || onlyCachedSongs {
            let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                library.getFetchPredicateForUserAvailableEpisodes(forPodcast: podcast),
                PodcastEpisodeMO.getIdentifierBasedSearchPredicate(searchText: searchText),
                library.getFetchPredicate(onlyCachedPodcastEpisodes: onlyCachedSongs)
            ])
            search(predicate: predicate)
        } else {
            showAllResults()
        }
    }

}

class GenreFetchedResultsController: CachedFetchedResultsController<GenreMO> {
    
    init(managedObjectContext context: NSManagedObjectContext, isGroupedInAlphabeticSections: Bool) {
        let fetchRequest = GenreMO.identifierSortedFetchRequest
        super.init(managedObjectContext: context, fetchRequest: fetchRequest, isGroupedInAlphabeticSections: isGroupedInAlphabeticSections)
    }
        
    func search(searchText: String, onlyCached: Bool) {
        if searchText.count > 0 || onlyCached {
            let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                GenreMO.getIdentifierBasedSearchPredicate(searchText: searchText),
                NSCompoundPredicate(orPredicateWithSubpredicates: [
                    library.getFetchPredicate(onlyCachedGenreArtists: onlyCached),
                    library.getFetchPredicate(onlyCachedGenreAlbums: onlyCached),
                    library.getFetchPredicate(onlyCachedGenreSongs: onlyCached)
                ])
            ])
            search(predicate: predicate)
        } else {
            showAllResults()
        }
    }

}

class GenreArtistsFetchedResultsController: BasicFetchedResultsController<ArtistMO> {
    
    let genre: Genre
    
    init(for genre: Genre, managedObjectContext context: NSManagedObjectContext, isGroupedInAlphabeticSections: Bool) {
        self.genre = genre
        let library = LibraryStorage(context: context)
        let fetchRequest = ArtistMO.identifierSortedFetchRequest
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSCompoundPredicate(orPredicateWithSubpredicates: [
                AbstractLibraryEntityMO.excludeRemoteDeleteFetchPredicate,
                library.getFetchPredicate(onlyCachedArtists: true)
            ]),
            library.getFetchPredicate(forGenre: genre)
        ])
        super.init(managedObjectContext: context, fetchRequest: fetchRequest, isGroupedInAlphabeticSections: isGroupedInAlphabeticSections)
    }
    
    func search(searchText: String, onlyCached: Bool) {
        if searchText.count > 0 || onlyCached {
            let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSCompoundPredicate(orPredicateWithSubpredicates: [
                    AbstractLibraryEntityMO.excludeRemoteDeleteFetchPredicate,
                    library.getFetchPredicate(onlyCachedArtists: true)
                ]),
                library.getFetchPredicate(forGenre: genre),
                library.getFetchPredicate(onlyCachedArtists: onlyCached),
                ArtistMO.getIdentifierBasedSearchPredicate(searchText: searchText)
            ])
            search(predicate: predicate)
        } else {
            showAllResults()
        }
    }

}

class GenreAlbumsFetchedResultsController: BasicFetchedResultsController<AlbumMO> {
    
    let genre: Genre
    
    init(for genre: Genre, managedObjectContext context: NSManagedObjectContext, isGroupedInAlphabeticSections: Bool) {
        self.genre = genre
        let library = LibraryStorage(context: context)
        let fetchRequest = AlbumMO.identifierSortedFetchRequest
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSCompoundPredicate(orPredicateWithSubpredicates: [
                AbstractLibraryEntityMO.excludeRemoteDeleteFetchPredicate,
                library.getFetchPredicate(onlyCachedAlbums: true)
            ]),
            library.getFetchPredicate(forGenre: genre)
        ])
        super.init(managedObjectContext: context, fetchRequest: fetchRequest, isGroupedInAlphabeticSections: isGroupedInAlphabeticSections)
    }
    
    func search(searchText: String, onlyCached: Bool) {
        if searchText.count > 0 || onlyCached {
            let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSCompoundPredicate(orPredicateWithSubpredicates: [
                    AbstractLibraryEntityMO.excludeRemoteDeleteFetchPredicate,
                    library.getFetchPredicate(onlyCachedAlbums: true)
                ]),
                library.getFetchPredicate(forGenre: genre),
                library.getFetchPredicate(onlyCachedAlbums: onlyCached),
                ArtistMO.getIdentifierBasedSearchPredicate(searchText: searchText)
            ])
            search(predicate: predicate)
        } else {
            showAllResults()
        }
    }

}

class GenreSongsFetchedResultsController: BasicFetchedResultsController<SongMO> {
    
    let genre: Genre
    
    init(for genre: Genre, managedObjectContext context: NSManagedObjectContext, isGroupedInAlphabeticSections: Bool) {
        self.genre = genre
        let library = LibraryStorage(context: context)
        let fetchRequest = SongMO.identifierSortedFetchRequest
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            SongMO.excludeServerDeleteUncachedSongsFetchPredicate,
            library.getFetchPredicate(forGenre: genre)
        ])
        super.init(managedObjectContext: context, fetchRequest: fetchRequest, isGroupedInAlphabeticSections: isGroupedInAlphabeticSections)
    }
    
    func search(searchText: String, onlyCachedSongs: Bool) {
        if searchText.count > 0 || onlyCachedSongs {
            let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                SongMO.excludeServerDeleteUncachedSongsFetchPredicate,
                library.getFetchPredicate(forGenre: genre),
                SongMO.getIdentifierBasedSearchPredicate(searchText: searchText),
                library.getFetchPredicate(onlyCachedSongs: onlyCachedSongs)
            ])
            search(predicate: predicate)
        } else {
            showAllResults()
        }
    }

}

class ArtistFetchedResultsController: CachedFetchedResultsController<ArtistMO> {
    
    init(managedObjectContext context: NSManagedObjectContext, isGroupedInAlphabeticSections: Bool) {
        let library = LibraryStorage(context: context)
        let fetchRequest = ArtistMO.identifierSortedFetchRequest
        fetchRequest.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
            AbstractLibraryEntityMO.excludeRemoteDeleteFetchPredicate,
            library.getFetchPredicate(onlyCachedArtists: true)
        ])
        super.init(managedObjectContext: context, fetchRequest: fetchRequest, isGroupedInAlphabeticSections: isGroupedInAlphabeticSections)
    }
    
    func search(searchText: String, onlyCached: Bool, displayFilter: DisplayCategoryFilter) {
        if searchText.count > 0 || onlyCached || displayFilter != .all {
            let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSCompoundPredicate(orPredicateWithSubpredicates: [
                    AbstractLibraryEntityMO.excludeRemoteDeleteFetchPredicate,
                    library.getFetchPredicate(onlyCachedArtists: true)
                ]),
                ArtistMO.getIdentifierBasedSearchPredicate(searchText: searchText),
                library.getFetchPredicate(onlyCachedArtists: onlyCached),
                library.getFetchPredicate(artistsDisplayFilter: displayFilter)
            ])
            search(predicate: predicate)
        } else {
            showAllResults()
        }
    }

}

class ArtistAlbumsItemsFetchedResultsController: BasicFetchedResultsController<AlbumMO> {

    let artist: Artist
    
    init(for artist: Artist, managedObjectContext context: NSManagedObjectContext, isGroupedInAlphabeticSections: Bool) {
        self.artist = artist
        let library = LibraryStorage(context: context)
        let fetchRequest = AlbumMO.releaseYearSortedFetchRequest
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSCompoundPredicate(orPredicateWithSubpredicates: [
                AbstractLibraryEntityMO.excludeRemoteDeleteFetchPredicate,
                library.getFetchPredicate(onlyCachedAlbums: true)
            ]),
            NSCompoundPredicate(orPredicateWithSubpredicates: [
                library.getFetchPredicate(forArtist: artist),
                AlbumMO.getFetchPredicateForAlbumsWhoseSongsHave(artist: artist)
            ])
        ])
        super.init(managedObjectContext: context, fetchRequest: fetchRequest, isGroupedInAlphabeticSections: isGroupedInAlphabeticSections)
    }

    func search(searchText: String, onlyCached: Bool) {
        if searchText.count > 0 || onlyCached {
            let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSCompoundPredicate(orPredicateWithSubpredicates: [
                    AbstractLibraryEntityMO.excludeRemoteDeleteFetchPredicate,
                    library.getFetchPredicate(onlyCachedAlbums: true)
                ]),
                NSCompoundPredicate(orPredicateWithSubpredicates: [
                    library.getFetchPredicate(forArtist: artist),
                    AlbumMO.getFetchPredicateForAlbumsWhoseSongsHave(artist: artist)
                ]),
                library.getFetchPredicate(onlyCachedAlbums: onlyCached),
                ArtistMO.getIdentifierBasedSearchPredicate(searchText: searchText)
            ])
            search(predicate: predicate)
        } else {
            showAllResults()
        }
    }

}

class ArtistSongsItemsFetchedResultsController: BasicFetchedResultsController<SongMO> {

    let artist: Artist
    
    init(for artist: Artist, managedObjectContext context: NSManagedObjectContext, isGroupedInAlphabeticSections: Bool) {
        self.artist = artist
        let library = LibraryStorage(context: context)
        let fetchRequest = SongMO.identifierSortedFetchRequest
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            SongMO.excludeServerDeleteUncachedSongsFetchPredicate,
            library.getFetchPredicate(forArtist: artist)
        ])
        super.init(managedObjectContext: context, fetchRequest: fetchRequest, isGroupedInAlphabeticSections: isGroupedInAlphabeticSections)
    }

    func search(searchText: String, onlyCachedSongs: Bool) {
        if searchText.count > 0 || onlyCachedSongs {
            let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                SongMO.excludeServerDeleteUncachedSongsFetchPredicate,
                library.getFetchPredicate(forArtist: artist),
                SongMO.getIdentifierBasedSearchPredicate(searchText: searchText),
                library.getFetchPredicate(onlyCachedSongs: onlyCachedSongs)
            ])
            search(predicate: predicate)
        } else {
            showAllResults()
        }
    }

}

class AlbumFetchedResultsController: CachedFetchedResultsController<AlbumMO> {
    
    init(managedObjectContext context: NSManagedObjectContext, isGroupedInAlphabeticSections: Bool) {
        let library = LibraryStorage(context: context)
        let fetchRequest = AlbumMO.identifierSortedFetchRequest
        fetchRequest.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
            AbstractLibraryEntityMO.excludeRemoteDeleteFetchPredicate,
            library.getFetchPredicate(onlyCachedAlbums: true)
        ])
        super.init(managedObjectContext: context, fetchRequest: fetchRequest, isGroupedInAlphabeticSections: isGroupedInAlphabeticSections)
    }
    
    func search(searchText: String, onlyCached: Bool, displayFilter: DisplayCategoryFilter) {
        if searchText.count > 0 || onlyCached || displayFilter != .all {
            let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSCompoundPredicate(orPredicateWithSubpredicates: [
                    AbstractLibraryEntityMO.excludeRemoteDeleteFetchPredicate,
                    library.getFetchPredicate(onlyCachedAlbums: true)
                ]),
                AlbumMO.getIdentifierBasedSearchPredicate(searchText: searchText),
                library.getFetchPredicate(onlyCachedAlbums: onlyCached),
                library.getFetchPredicate(albumsDisplayFilter: displayFilter)
            ])
            search(predicate: predicate)
        } else {
            showAllResults()
        }
    }

}

class SongsFetchedResultsController: CachedFetchedResultsController<SongMO> {
    
    init(managedObjectContext context: NSManagedObjectContext, isGroupedInAlphabeticSections: Bool) {
        let fetchRequest = SongMO.identifierSortedFetchRequest
        fetchRequest.predicate = SongMO.excludeServerDeleteUncachedSongsFetchPredicate
        super.init(managedObjectContext: context, fetchRequest: fetchRequest, isGroupedInAlphabeticSections: isGroupedInAlphabeticSections)
    }
    
    func search(searchText: String, onlyCachedSongs: Bool, displayFilter: DisplayCategoryFilter) {
        if searchText.count > 0 || onlyCachedSongs || displayFilter != .all {
            let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                SongMO.excludeServerDeleteUncachedSongsFetchPredicate,
                SongMO.getIdentifierBasedSearchPredicate(searchText: searchText),
                library.getFetchPredicate(onlyCachedSongs: onlyCachedSongs),
                library.getFetchPredicate(songsDisplayFilter: displayFilter)
            ])
            search(predicate: predicate)
        } else {
            showAllResults()
        }
    }

}

class AlbumSongsFetchedResultsController: BasicFetchedResultsController<SongMO> {
    
    let album: Album
    
    init(forAlbum album: Album, managedObjectContext context: NSManagedObjectContext, isGroupedInAlphabeticSections: Bool) {
        self.album = album
        let library = LibraryStorage(context: context)
        let fetchRequest = SongMO.trackNumberSortedFetchRequest
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            SongMO.excludeServerDeleteUncachedSongsFetchPredicate,
            library.getFetchPredicate(forAlbum: album)
        ])
        super.init(managedObjectContext: context, fetchRequest: fetchRequest, isGroupedInAlphabeticSections: isGroupedInAlphabeticSections)
    }
    
    func search(searchText: String, onlyCachedSongs: Bool) {
        if searchText.count > 0 || onlyCachedSongs {
            let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                SongMO.excludeServerDeleteUncachedSongsFetchPredicate,
                library.getFetchPredicate(forAlbum: album),
                SongMO.getIdentifierBasedSearchPredicate(searchText: searchText),
                library.getFetchPredicate(onlyCachedSongs: onlyCachedSongs)
            ])
            search(predicate: predicate)
        } else {
            showAllResults()
        }
    }

}

class PlaylistItemsFetchedResultsController: BasicFetchedResultsController<PlaylistItemMO> {

    let playlist: Playlist
    
    init(forPlaylist playlist: Playlist, managedObjectContext context: NSManagedObjectContext, isGroupedInAlphabeticSections: Bool) {
        self.playlist = playlist
        let library = LibraryStorage(context: context)
        let fetchRequest = PlaylistItemMO.playlistOrderSortedFetchRequest
        fetchRequest.predicate = library.getFetchPredicate(forPlaylist: playlist)
        super.init(managedObjectContext: context, fetchRequest: fetchRequest, isGroupedInAlphabeticSections: isGroupedInAlphabeticSections)
    }
    
    func search(onlyCachedSongs: Bool) {
        if onlyCachedSongs {
            let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                library.getFetchPredicate(forPlaylist: playlist),
                library.getFetchPredicate(onlyCachedPlaylistItems: onlyCachedSongs)
            ])
            search(predicate: predicate)
        } else {
            showAllResults()
        }
    }

}

class PlaylistFetchedResultsController: BasicFetchedResultsController<PlaylistMO> {

    var sortType: PlaylistSortType
    
    init(managedObjectContext context: NSManagedObjectContext, sortType: PlaylistSortType, isGroupedInAlphabeticSections: Bool) {
        self.sortType = sortType
        var fetchRequest = PlaylistMO.identifierSortedFetchRequest
        switch sortType {
        case .name:
            fetchRequest = PlaylistMO.identifierSortedFetchRequest
        case .lastPlayed:
            fetchRequest = PlaylistMO.lastPlayedDateFetchRequest
        case .lastChanged:
            fetchRequest = PlaylistMO.lastChangedDateFetchRequest
        }
        fetchRequest.predicate = PlaylistMO.excludeSystemPlaylistsFetchPredicate
        super.init(managedObjectContext: context, fetchRequest: fetchRequest, isGroupedInAlphabeticSections: isGroupedInAlphabeticSections)
    }
    
    func search(searchText: String, playlistSearchCategory: PlaylistSearchCategory) {
        if searchText.count > 0 || playlistSearchCategory != .defaultValue {
            let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                PlaylistMO.excludeSystemPlaylistsFetchPredicate,
                PlaylistMO.getIdentifierBasedSearchPredicate(searchText: searchText),
                library.getFetchPredicate(forPlaylistSearchCategory: playlistSearchCategory)
            ])
            search(predicate: predicate)
        } else {
            showAllResults()
        }
    }

}

class PlaylistSelectorFetchedResultsController: CachedFetchedResultsController<PlaylistMO> {

    var sortType: PlaylistSortType
    
    init(managedObjectContext context: NSManagedObjectContext, sortType: PlaylistSortType, isGroupedInAlphabeticSections: Bool) {
        self.sortType = sortType
        var fetchRequest = PlaylistMO.identifierSortedFetchRequest
        switch sortType {
        case .name:
            fetchRequest = PlaylistMO.identifierSortedFetchRequest
        case .lastPlayed:
            fetchRequest = PlaylistMO.lastPlayedDateFetchRequest
        case .lastChanged:
            fetchRequest = PlaylistMO.lastChangedDateFetchRequest
        }
        let library = LibraryStorage(context: context)
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            PlaylistMO.excludeSystemPlaylistsFetchPredicate,
            library.getFetchPredicate(forPlaylistSearchCategory: .userOnly)
        ])
        super.init(managedObjectContext: context, fetchRequest: fetchRequest, isGroupedInAlphabeticSections: isGroupedInAlphabeticSections)
    }
    
    func search(searchText: String) {
        if searchText.count > 0 {
            let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                PlaylistMO.excludeSystemPlaylistsFetchPredicate,
                PlaylistMO.getIdentifierBasedSearchPredicate(searchText: searchText),
                library.getFetchPredicate(forPlaylistSearchCategory: .userOnly)
            ])
            search(predicate: predicate)
        } else {
            showAllResults()
        }
    }

}

class ErrorLogFetchedResultsController: BasicFetchedResultsController<LogEntryMO> {

    init(managedObjectContext context: NSManagedObjectContext, isGroupedInAlphabeticSections: Bool) {
        let fetchRequest = LogEntryMO.creationDateSortedFetchRequest
        super.init(managedObjectContext: context, fetchRequest: fetchRequest, isGroupedInAlphabeticSections: isGroupedInAlphabeticSections)
    }

}

class MusicFolderFetchedResultsController: CachedFetchedResultsController<MusicFolderMO> {
    
    init(managedObjectContext context: NSManagedObjectContext, isGroupedInAlphabeticSections: Bool) {
        let fetchRequest = MusicFolderMO.idSortedFetchRequest
        super.init(managedObjectContext: context, fetchRequest: fetchRequest, isGroupedInAlphabeticSections: isGroupedInAlphabeticSections)
    }
    
    func search(searchText: String) {
        if searchText.count > 0 {
            search(predicate: MusicFolderMO.getSearchPredicate(searchText: searchText))
        } else {
            showAllResults()
        }
    }

}

class MusicFolderDirectoriesFetchedResultsController: BasicFetchedResultsController<DirectoryMO> {
    
    let musicFolder: MusicFolder
    
    init(for musicFolder: MusicFolder, managedObjectContext context: NSManagedObjectContext, isGroupedInAlphabeticSections: Bool) {
        self.musicFolder = musicFolder
        let library = LibraryStorage(context: context)
        let fetchRequest = DirectoryMO.identifierSortedFetchRequest
        fetchRequest.predicate = library.getFetchPredicate(forMusicFolder: musicFolder)
        super.init(managedObjectContext: context, fetchRequest: fetchRequest, isGroupedInAlphabeticSections: isGroupedInAlphabeticSections)
    }

    func search(searchText: String) {
        if searchText.count > 0 {
            let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                library.getFetchPredicate(forMusicFolder: musicFolder),
                DirectoryMO.getIdentifierBasedSearchPredicate(searchText: searchText)
            ])
            search(predicate: predicate)
        } else {
            showAllResults()
        }
    }

}

class DirectorySubdirectoriesFetchedResultsController: BasicFetchedResultsController<DirectoryMO> {
    
    let directory: Directory
    
    init(for directory: Directory, managedObjectContext context: NSManagedObjectContext, isGroupedInAlphabeticSections: Bool) {
        self.directory = directory
        let library = LibraryStorage(context: context)
        let fetchRequest = DirectoryMO.identifierSortedFetchRequest
        fetchRequest.predicate = library.getDirectoryFetchPredicate(forDirectory: directory)
        super.init(managedObjectContext: context, fetchRequest: fetchRequest, isGroupedInAlphabeticSections: isGroupedInAlphabeticSections)
    }

    func search(searchText: String) {
        if searchText.count > 0 {
            let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                library.getDirectoryFetchPredicate(forDirectory: directory),
                DirectoryMO.getIdentifierBasedSearchPredicate(searchText: searchText)
            ])
            search(predicate: predicate)
        } else {
            showAllResults()
        }
    }

}


class DirectorySongsFetchedResultsController: BasicFetchedResultsController<SongMO> {
    
    let directory: Directory

    init(for directory: Directory, managedObjectContext context: NSManagedObjectContext, isGroupedInAlphabeticSections: Bool) {
        self.directory = directory
        let library = LibraryStorage(context: context)
        let fetchRequest = SongMO.trackNumberSortedFetchRequest
        fetchRequest.predicate = library.getSongFetchPredicate(forDirectory: directory)
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            SongMO.excludeServerDeleteUncachedSongsFetchPredicate,
            library.getSongFetchPredicate(forDirectory: directory)
        ])
        super.init(managedObjectContext: context, fetchRequest: fetchRequest, isGroupedInAlphabeticSections: isGroupedInAlphabeticSections)
    }
    
    func search(searchText: String, onlyCachedSongs: Bool) {
        if searchText.count > 0 || onlyCachedSongs {
            let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                SongMO.excludeServerDeleteUncachedSongsFetchPredicate,
                library.getSongFetchPredicate(forDirectory: directory),
                SongMO.getIdentifierBasedSearchPredicate(searchText: searchText),
                library.getFetchPredicate(onlyCachedSongs: onlyCachedSongs)
            ])
            search(predicate: predicate)
        } else {
            showAllResults()
        }
    }

}


class DownloadsFetchedResultsController: BasicFetchedResultsController<DownloadMO> {
    
    init(managedObjectContext context: NSManagedObjectContext, isGroupedInAlphabeticSections: Bool) {
        let fetchRequest: NSFetchRequest<DownloadMO> = DownloadMO.creationDateSortedFetchRequest
        fetchRequest.predicate = DownloadMO.onlyPlayablesPredicate
        super.init(managedObjectContext: context, fetchRequest: fetchRequest, isGroupedInAlphabeticSections: isGroupedInAlphabeticSections)
    }

}
