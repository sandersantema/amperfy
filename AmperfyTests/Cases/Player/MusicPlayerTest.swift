import XCTest
import AVFoundation
import CoreData
@testable import Amperfy

class MOCK_AVPlayerItem: AVPlayerItem {
    override var status: AVPlayerItem.Status {
        return AVPlayerItem.Status.readyToPlay
    }
}

class MOCK_AVPlayer: AVPlayer {
    var useMockCurrentItem = false
    
    override var currentItem: AVPlayerItem? {
        guard let curItem = super.currentItem else { return nil }
        if !useMockCurrentItem {
            return curItem
        } else {
            return MOCK_AVPlayerItem(asset: curItem.asset)
        }
    }
    
    override func currentTime() -> CMTime {
        let oldUseMock = useMockCurrentItem
        useMockCurrentItem = false
        let curTime = super.currentTime()
        useMockCurrentItem = oldUseMock
        return curTime
    }
}

class MOCK_SongDownloader: DownloadManageable {
    var downloadables = [Downloadable]()
    func isNoDownloadRequested() -> Bool {
        return downloadables.count == 0
    }

    var backgroundFetchCompletionHandler: CompleteHandlerBlock? { get {return nil} set {} }
    func download(object: Downloadable) { downloadables.append(object) }
    func download(objects: [Downloadable]) { downloadables.append(contentsOf: objects) }
    func removeFinishedDownload(for object: Downloadable) {}
    func removeFinishedDownload(for objects: [Downloadable]) {}
    func clearFinishedDownloads() {}
    func resetFailedDownloads() {}
    func cancelDownloads() {}
    func start() {}
    func stopAndWait() {}
}

class MOCK_AlertDisplayable: AlertDisplayable {
    func display(notificationBanner popupVC: LibrarySyncPopupVC) {}
    func display(popup popupVC: LibrarySyncPopupVC) {}
}

class MOCK_LibrarySyncer: LibrarySyncer {
    var artistCount: Int = 0
    var albumCount: Int = 0
    var songCount: Int = 0
    var genreCount: Int = 0
    var playlistCount: Int = 0
    var podcastCount: Int = 0
    func sync(currentContext: NSManagedObjectContext, persistentContainer: NSPersistentContainer, statusNotifyier: SyncCallbacks?) {}
    func sync(genre: Genre, library: LibraryStorage) {}
    func sync(artist: Artist, library: LibraryStorage) {}
    func sync(album: Album, library: LibraryStorage) {}
    func sync(song: Song, library: LibraryStorage) {}
    func syncLatestLibraryElements(library: LibraryStorage) {}
    func syncFavoriteLibraryElements(library: LibraryStorage) {}
    func syncDownPlaylistsWithoutSongs(library: LibraryStorage) {}
    func syncDown(playlist: Playlist, library: LibraryStorage) {}
    func syncUpload(playlistToUpdateName playlist: Playlist, library: LibraryStorage) {}
    func syncUpload(playlistToAddSongs playlist: Playlist, songs: [Song], library: LibraryStorage) {}
    func syncUpload(playlistToDeleteSong playlist: Playlist, index: Int, library: LibraryStorage) {}
    func syncUpload(playlistToUpdateOrder playlist: Playlist, library: LibraryStorage) {}
    func syncUpload(playlistToDelete playlist: Playlist) {}
    func syncDownPodcastsWithoutEpisodes(library: LibraryStorage) {}
    func sync(podcast: Podcast, library: LibraryStorage) {}
    func searchArtists(searchText: String, library: LibraryStorage) {}
    func searchAlbums(searchText: String, library: LibraryStorage) {}
    func searchSongs(searchText: String, library: LibraryStorage) {}
    func syncMusicFolders(library: LibraryStorage) {}
    func syncIndexes(musicFolder: MusicFolder, library: LibraryStorage) {}
    func sync(directory: Directory, library: LibraryStorage) {}
    func requestRandomSongs(playlist: Playlist, count: Int, library: LibraryStorage) {}
    func requestPodcastEpisodeDelete(podcastEpisode: PodcastEpisode) {}
    func scrobble(song: Song, date: Date?) {}
    func setRating(song: Song, rating: Int) {}
    func setRating(album: Album, rating: Int) {}
    func setRating(artist: Artist, rating: Int) {}
    func setFavorite(song: Song, isFavorite: Bool) {}
    func setFavorite(album: Album, isFavorite: Bool) {}
    func setFavorite(artist: Artist, isFavorite: Bool) {}
}

class MOCK_BackgroundLibrarySyncer: BackgroundLibrarySyncer {
    func syncInBackground(library: LibraryStorage) {}
    var isActive: Bool = false
    func stop() {}
    func stopAndWait() {}
}

class MOCK_BackgroundLibraryVersionResyncer: BackgroundLibraryVersionResyncer {
    func resyncDueToNewLibraryVersionInBackground(library: LibraryStorage, libraryVersion: LibrarySyncVersion) {}
    var isActive: Bool = false
    func stop() {}
    func stopAndWait() {}
}

class MOCK_DownloadManagerDelegate: DownloadManagerDelegate {
    var requestPredicate: NSPredicate { return NSPredicate.alwaysTrue }
    func prepareDownload(download: Download, context: NSManagedObjectContext) throws -> URL { throw DownloadError.urlInvalid }
    func validateDownloadedData(download: Download) -> ResponseError? { return nil }
    func completedDownload(download: Download, context: NSManagedObjectContext) {}
}

class MOCK_BackendApi: BackendApi {
    var clientApiVersion: String = ""
    var serverApiVersion: String = ""
    var isPodcastSupported: Bool = false
    func provideCredentials(credentials: LoginCredentials) {}
    func authenticate(credentials: LoginCredentials) {}
    func isAuthenticated() -> Bool { return false }
    func isAuthenticationValid(credentials: LoginCredentials) -> Bool { return false }
    func generateUrl(forDownloadingPlayable playable: AbstractPlayable) -> URL? { return nil }
    func generateUrl(forStreamingPlayable playable: AbstractPlayable) -> URL? { return nil }
    func generateUrl(forArtwork artwork: Artwork) -> URL? { return nil }
    func checkForErrorResponse(inData data: Data) -> ResponseError? { return nil }
    func createLibrarySyncer() -> LibrarySyncer { return MOCK_LibrarySyncer() }
    func createArtworkArtworkDownloadDelegate() -> DownloadManagerDelegate { return MOCK_DownloadManagerDelegate() }
    func extractArtworkInfoFromURL(urlString: String) -> ArtworkRemoteInfo? { return nil }
}

class MusicPlayerTest: XCTestCase {
    
    var cdHelper: CoreDataHelper!
    var library: LibraryStorage!
    var mockAlertDisplayer: MOCK_AlertDisplayable!
    var eventLogger: EventLogger!
    var userStatistics: UserStatistics!
    var songDownloader: MOCK_SongDownloader!
    var backendApi: MOCK_BackendApi!
    var backendPlayer: BackendAudioPlayer!
    var playerData: PlayerData!
    var testMusicPlayer: Amperfy.MusicPlayer!
    var testPlayer: Amperfy.PlayerFacade!
    var testQueueHandler: Amperfy.PlayQueueHandler!
    var mockAVPlayer: MOCK_AVPlayer!
    
    var songCached: Song!
    var songToDownload: Song!
    var playlistThreeCached: Playlist!
    let fillCount = 5

    override func setUp() {
        cdHelper = CoreDataHelper()
        library = cdHelper.createSeededStorage()
        songDownloader = MOCK_SongDownloader()
        mockAVPlayer = MOCK_AVPlayer()
        mockAlertDisplayer = MOCK_AlertDisplayable()
        eventLogger = EventLogger(alertDisplayer: mockAlertDisplayer, persistentContainer: cdHelper.persistentContainer)
        userStatistics = library.getUserStatistics(appVersion: "")
        backendApi = MOCK_BackendApi()
        backendPlayer = BackendAudioPlayer(mediaPlayer: mockAVPlayer, eventLogger: eventLogger, backendApi: backendApi, playableDownloader: songDownloader, cacheProxy: library, userStatistics: userStatistics)
        playerData = library.getPlayerData()
        testQueueHandler = PlayQueueHandler(playerData: playerData)
        testMusicPlayer = MusicPlayer(coreData: playerData, queueHandler: testQueueHandler, backendAudioPlayer: backendPlayer, userStatistics: userStatistics)
        testPlayer = PlayerFacadeImpl(playerStatus: playerData, queueHandler: testQueueHandler, musicPlayer: testMusicPlayer, library: library, playableDownloadManager: songDownloader, backendAudioPlayer: backendPlayer, userStatistics: userStatistics)
        
        guard let songCachedFetched = library.getSong(id: "36") else { XCTFail(); return }
        songCached = songCachedFetched
        guard let songToDownloadFetched = library.getSong(id: "3") else { XCTFail(); return }
        songToDownload = songToDownloadFetched
        guard let playlistCached = library.getPlaylist(id: cdHelper.seeder.playlists[1].id) else { XCTFail(); return }
        playlistThreeCached = playlistCached
    }

    override func tearDown() {
    }
    
    func prepareWithCachedPlaylist() {
        for song in playlistThreeCached.playables {
            testQueueHandler.appendContextQueue(playables: [song])
        }
    }
    
    func markAsCached(playable: AbstractPlayable) {
        let playableFile = library.createPlayableFile()
        playableFile.info = playable
        playableFile.data = Data(base64Encoded: "Test", options: .ignoreUnknownCharacters)
    }
    
    func prepareNoWaitingQueuePlaying() {
        playerData.removeAllItems()
        fillPlayerWithSomeSongsAndWaitingQueue()
        playerData.isUserQueuePlaying = false
    }
    
    func prepareWithWaitingQueuePlaying() {
        prepareNoWaitingQueuePlaying()
        playerData.isUserQueuePlaying = true
    }
    
    func fillPlayerWithSomeSongs() {
        for i in 0...fillCount-1 {
            guard let song = library.getSong(id: cdHelper.seeder.songs[i].id) else { XCTFail(); return }
            testPlayer.appendContextQueue(playables: [song])
        }
    }
    
    func fillPlayerWithSomeSongsAndWaitingQueue() {
        fillPlayerWithSomeSongs()
        for i in 0...3 {
            guard let song = library.getSong(id: cdHelper.seeder.songs[fillCount+i].id) else { XCTFail(); return }
            testPlayer.appendUserQueue(playables: [song])
        }
    }
    
    func checkPlaylistIndexEqualSeedIndex(playlistIndex: Int, seedIndex: Int) {
        guard let song = library.getSong(id: cdHelper.seeder.songs[seedIndex].id) else { XCTFail(); return }
        XCTAssertEqual(playerData.contextQueue.playables[playlistIndex].id, song.id)
    }
    
    func checkQueueItems(queue: [AbstractPlayable], seedIds: [Int]) {
        XCTAssertEqual(queue.count, seedIds.count)
        if queue.count == seedIds.count, queue.count > 0 {
            for i in 0...queue.count-1 {
                guard let song = library.getSong(id: cdHelper.seeder.songs[seedIds[i]].id) else { XCTFail(); return }
                let queueId = queue[i].id
                let songId = song.id
                XCTAssertEqual(queueId, songId)
            }
        }
    }
    
    func checkCurrentlyPlaying(idToBe: Int?) {
        if let idToBe = idToBe {
            guard let song = library.getSong(id: cdHelper.seeder.songs[idToBe].id) else { XCTFail(); return }
            XCTAssertEqual(testQueueHandler.currentlyPlaying?.id, song.id)
        } else {
            XCTAssertNil(testQueueHandler.currentlyPlaying)
        }
    }
    
    // -------------------------------------------------------------
    
    func testCreation() {
        XCTAssertFalse(testPlayer.isPlaying)
        XCTAssertFalse(testPlayer.isShuffle)
        XCTAssertEqual(testPlayer.currentlyPlaying, nil)
        XCTAssertEqual(testPlayer.prevQueue, [AbstractPlayable]())
        XCTAssertEqual(testPlayer.userQueue, [AbstractPlayable]())
        XCTAssertEqual(testPlayer.nextQueue, [AbstractPlayable]())
        XCTAssertEqual(testPlayer.elapsedTime, 0.0)
        XCTAssertEqual(testPlayer.duration, 0.0)
        XCTAssertEqual(testPlayer.repeatMode, RepeatMode.off)
        XCTAssertTrue(songDownloader.isNoDownloadRequested())
    }
    
    func testPlay_EmptyPlaylist() {
        testPlayer.play()
        XCTAssertFalse(testPlayer.isPlaying)
        XCTAssertEqual(testPlayer.currentlyPlaying, nil)
    }
    
    func testPlay_OneCachedSongInPlayer_IsPlayingTrue() {
        testPlayer.appendContextQueue(playables: [songCached])
        testPlayer.play()
        XCTAssertTrue(testPlayer.isPlaying)
        XCTAssertEqual(testPlayer.currentlyPlaying, songCached)
    }
    
    func testPlay_OneCachedSongInPlayer_NoDownloadRequest() {
        testPlayer.appendContextQueue(playables: [songCached])
        testPlayer.play()
        XCTAssertTrue(songDownloader.isNoDownloadRequested())
    }
    
    func testPlay_OneSongToDownload_IsPlayingTrue_AfterSuccessfulDownload() {
        testPlayer.appendContextQueue(playables: [songToDownload])
        testPlayer.play()
        XCTAssertTrue(testPlayer.isPlaying)
        XCTAssertEqual(testPlayer.currentlyPlaying, songToDownload)
    }
    
    func testPlay_OneSongToDownload_CheckDownloadRequest() {
        testPlayer.appendContextQueue(playables: [songToDownload])
        testPlayer.play()
        XCTAssertEqual(songDownloader.downloadables.count, 1)
        XCTAssertEqual((songDownloader.downloadables.first! as! AbstractPlayable).asSong!, songToDownload)
    }
    
    func testPlaySong_Cached() {
        testPlayer.play(context: PlayContext(name: "", playables: [songCached]))
        XCTAssertEqual(testPlayer.currentlyPlaying, songCached)
    }
    
    func testContextName() {
        testPlayer.play(context: PlayContext(name: "asdf", playables: [songCached]))
        XCTAssertEqual(testPlayer.contextName, "asdf")
    }
    
    func testContextName_changeContext() {
        testPlayer.play(context: PlayContext(name: "asdf", playables: [songCached]))
        XCTAssertEqual(testPlayer.contextName, "asdf")
        testPlayer.play(context: PlayContext(name: "uio qwe", playables: [songCached]))
        XCTAssertEqual(testPlayer.contextName, "uio qwe")
    }
    
    func testContextName_insertContext() {
        testPlayer.play(context: PlayContext(name: "asdf", playables: [songCached]))
        testPlayer.insertContextQueue(playables: [songCached])
        XCTAssertEqual(testPlayer.contextName, "Mixed Context")
    }
    
    func testContextName_appendContext() {
        testPlayer.play(context: PlayContext(name: "asdf", playables: [songCached]))
        testPlayer.appendContextQueue(playables: [songCached])
        XCTAssertEqual(testPlayer.contextName, "Mixed Context")
    }
    
    func testContextName_insertUser() {
        testPlayer.play(context: PlayContext(name: "asdf", playables: [songCached]))
        testPlayer.insertUserQueue(playables: [songCached])
        XCTAssertEqual(testPlayer.contextName, "asdf")
    }
    
    func testContextName_appendUser() {
        testPlayer.play(context: PlayContext(name: "asdf", playables: [songCached]))
        testPlayer.appendUserQueue(playables: [songCached])
        XCTAssertEqual(testPlayer.contextName, "asdf")
    }

    func testPlaySong_CheckPlaylistClear() {
        prepareWithCachedPlaylist()
        testPlayer.play(context: PlayContext(name: "", playables: [songCached]))
        XCTAssertEqual(testPlayer.prevQueue, [AbstractPlayable]())
        XCTAssertEqual(testPlayer.userQueue, [AbstractPlayable]())
        XCTAssertEqual(testPlayer.nextQueue, [AbstractPlayable]())
        XCTAssertEqual(testPlayer.currentlyPlaying, songCached)
    }
    
    func testPlaySongInPlaylistAt_EmptyPlaylist() {
        testPlayer.play(playerIndex: PlayerIndex(queueType: .prev, index: 0))
        XCTAssertFalse(testPlayer.isPlaying)
        XCTAssertEqual(testPlayer.currentlyPlaying, nil)
        testPlayer.play(playerIndex: PlayerIndex(queueType: .next, index: 5))
        XCTAssertFalse(testPlayer.isPlaying)
        XCTAssertEqual(testPlayer.currentlyPlaying, nil)
        testPlayer.play(playerIndex: PlayerIndex(queueType: .prev, index: -1))
        XCTAssertFalse(testPlayer.isPlaying)
        XCTAssertEqual(testPlayer.currentlyPlaying, nil)
    }
    
    func testPlaySongInPlaylistAt_Cached_FullPlaylist() {
        prepareWithCachedPlaylist()
        testPlayer.play(playerIndex: PlayerIndex(queueType: .next, index: 2))
        XCTAssertTrue(testPlayer.isPlaying)
        XCTAssertEqual(playerData.currentIndex, 3)
    }
    
    func testPlaySongInPlaylistAt_FetchSuccess_FullPlaylist() {
        prepareWithCachedPlaylist()
        testPlayer.play(playerIndex: PlayerIndex(queueType: .next, index: 1))
        XCTAssertTrue(testPlayer.isPlaying)
        XCTAssertEqual(playerData.currentIndex, 2)
    }

    
    func testPause_EmptyPlaylist() {
        testMusicPlayer.pause()
        XCTAssertFalse(testPlayer.isPlaying)
    }

    func testPause_CurrentlyPlaying() {
        testPlayer.appendContextQueue(playables: [songCached])
        testPlayer.play()
        testMusicPlayer.pause()
        XCTAssertFalse(testPlayer.isPlaying)
    }
    
    func testPause_CurrentlyPaused() {
        testPlayer.appendContextQueue(playables: [songCached])
        testMusicPlayer.pause()
        XCTAssertFalse(testPlayer.isPlaying)
    }
    
    func testPause_SongInMiddleOfPlaylist() {
        prepareWithCachedPlaylist()
        testPlayer.play(playerIndex: PlayerIndex(queueType: .next, index: 2))
        XCTAssertTrue(testPlayer.isPlaying)
        XCTAssertEqual(playerData.currentIndex, 3)
        testMusicPlayer.pause()
        XCTAssertFalse(testPlayer.isPlaying)
        XCTAssertEqual(playerData.currentIndex, 3)
        testPlayer.play()
        XCTAssertTrue(testPlayer.isPlaying)
        XCTAssertEqual(playerData.currentIndex, 3)
    }
    
    func testAddToPlaylist() {
        XCTAssertEqual(testPlayer.nextQueue.count, 0)
        testPlayer.appendContextQueue(playables: [songCached])
        XCTAssertEqual(testPlayer.nextQueue.count, 0)
        testPlayer.appendContextQueue(playables: [songToDownload])
        XCTAssertEqual(testPlayer.nextQueue.count, 1)
        testPlayer.appendContextQueue(playables: [songCached])
        XCTAssertEqual(testPlayer.nextQueue.count, 2)
        testPlayer.appendContextQueue(playables: [songToDownload])
        XCTAssertEqual(testPlayer.nextQueue.count, 3)
    }
  
    func testPlaylistClear_EmptyPlaylist() {
        testPlayer.clearContextQueue()
        XCTAssertFalse(testPlayer.isPlaying)
        XCTAssertEqual(testPlayer.prevQueue.count, 0)
        XCTAssertEqual(testPlayer.userQueue.count, 0)
        XCTAssertEqual(testPlayer.nextQueue.count, 0)
        XCTAssertEqual(testPlayer.currentlyPlaying, nil)
    }
    
    func testPlaylistClear_EmptyPlaylist_WaitingQueueHasEntries() {
        guard let songId0 = library.getSong(id: cdHelper.seeder.songs[0].id) else { XCTFail(); return }
        testPlayer.appendUserQueue(playables: [songId0])
        XCTAssertFalse(testPlayer.isPlaying)
        testPlayer.clearContextQueue()
        XCTAssertFalse(testPlayer.isPlaying)
        XCTAssertEqual(testPlayer.prevQueue.count, 0)
        XCTAssertEqual(testPlayer.userQueue.count, 0)
        XCTAssertEqual(testPlayer.nextQueue.count, 0)
        XCTAssertEqual(testPlayer.currentlyPlaying, songId0)
    }
    
    func testPlaylistClear_EmptyPlaylist_WaitingQueueHasEntries2() {
        guard let songId0 = library.getSong(id: cdHelper.seeder.songs[0].id) else { XCTFail(); return }
        testPlayer.appendUserQueue(playables: [songId0])
        guard let songId1 = library.getSong(id: cdHelper.seeder.songs[1].id) else { XCTFail(); return }
        testPlayer.appendUserQueue(playables: [songId1])
        XCTAssertFalse(testPlayer.isPlaying)
        testPlayer.clearContextQueue()
        XCTAssertFalse(testPlayer.isPlaying)
        XCTAssertEqual(testPlayer.prevQueue.count, 0)
        XCTAssertEqual(testPlayer.userQueue.count, 1)
        XCTAssertEqual(testPlayer.nextQueue.count, 0)
        XCTAssertEqual(testPlayer.currentlyPlaying, songId0)
    }
    
    func testPlaylistClear_EmptyPlaylist_WaitingQueueHasEntries3() {
        guard let songId0 = library.getSong(id: cdHelper.seeder.songs[0].id) else { XCTFail(); return }
        testPlayer.insertUserQueue(playables: [songId0])
        XCTAssertFalse(testPlayer.isPlaying)
        testPlayer.clearContextQueue()
        XCTAssertFalse(testPlayer.isPlaying)
        XCTAssertEqual(testPlayer.prevQueue.count, 0)
        XCTAssertEqual(testPlayer.userQueue.count, 0)
        XCTAssertEqual(testPlayer.nextQueue.count, 0)
        XCTAssertEqual(testPlayer.currentlyPlaying, songId0)
    }
    
    func testPlaylistClear_EmptyPlaylist_WaitingQueueHasEntries4() {
        guard let songId0 = library.getSong(id: cdHelper.seeder.songs[0].id) else { XCTFail(); return }
        testPlayer.insertUserQueue(playables: [songId0])
        guard let songId1 = library.getSong(id: cdHelper.seeder.songs[1].id) else { XCTFail(); return }
        testPlayer.insertUserQueue(playables: [songId1])
        XCTAssertFalse(testPlayer.isPlaying)
        testPlayer.clearContextQueue()
        XCTAssertFalse(testPlayer.isPlaying)
        XCTAssertEqual(testPlayer.prevQueue.count, 0)
        XCTAssertEqual(testPlayer.userQueue.count, 1)
        XCTAssertEqual(testPlayer.nextQueue.count, 0)
        XCTAssertEqual(testPlayer.currentlyPlaying, songId0)
        XCTAssertEqual(testPlayer.userQueue[0], songId1)
    }
    
    func testPlaylistClear_EmptyPlaylist_WaitingQueueHasEntries5() {
        guard let songId0 = library.getSong(id: cdHelper.seeder.songs[0].id) else { XCTFail(); return }
        testPlayer.appendUserQueue(playables: [songId0])
        guard let songId1 = library.getSong(id: cdHelper.seeder.songs[1].id) else { XCTFail(); return }
        testPlayer.appendUserQueue(playables: [songId1])
        testPlayer.play()
        XCTAssertTrue(testPlayer.isPlaying)
        testPlayer.clearContextQueue()
        XCTAssertTrue(testPlayer.isPlaying)
        XCTAssertEqual(testPlayer.prevQueue.count, 0)
        XCTAssertEqual(testPlayer.userQueue.count, 1)
        XCTAssertEqual(testPlayer.nextQueue.count, 0)
        XCTAssertEqual(testPlayer.currentlyPlaying, songId0)
    }
    
    func testPlaylistClear_FilledPlaylist() {
        prepareWithCachedPlaylist()
        testPlayer.clearContextQueue()
        XCTAssertFalse(testPlayer.isPlaying)
        XCTAssertEqual(testPlayer.prevQueue.count, 0)
        XCTAssertEqual(testPlayer.userQueue.count, 0)
        XCTAssertEqual(testPlayer.nextQueue.count, 0)
        XCTAssertEqual(testPlayer.currentlyPlaying, nil)
    }
    
    func testPlaylistClear_FilledPlaylist_WaitingQueuePlaying() {
        prepareWithCachedPlaylist()
        guard let songId0 = library.getSong(id: cdHelper.seeder.songs[0].id) else { XCTFail(); return }
        testPlayer.appendUserQueue(playables: [songId0])
        guard let songId1 = library.getSong(id: cdHelper.seeder.songs[1].id) else { XCTFail(); return }
        testPlayer.appendUserQueue(playables: [songId1])
        testPlayer.clearContextQueue()
        XCTAssertTrue(testPlayer.isPlaying)
        XCTAssertEqual(testPlayer.prevQueue.count, 0)
        XCTAssertEqual(testPlayer.userQueue.count, 1)
        XCTAssertEqual(testPlayer.nextQueue.count, 0)
        XCTAssertEqual(testPlayer.currentlyPlaying, songId0)
    }

    func testPlaylistClear_FilledPlaylist_WaitingQueuePlaying2() {
        prepareWithCachedPlaylist()
        guard let songId0 = library.getSong(id: cdHelper.seeder.songs[0].id) else { XCTFail(); return }
        testPlayer.appendUserQueue(playables: [songId0])
        guard let songId1 = library.getSong(id: cdHelper.seeder.songs[1].id) else { XCTFail(); return }
        testPlayer.appendUserQueue(playables: [songId1])
        testPlayer.playNext()
        testPlayer.clearContextQueue()
        XCTAssertTrue(testPlayer.isPlaying)
        XCTAssertEqual(testPlayer.prevQueue.count, 0)
        XCTAssertEqual(testPlayer.userQueue.count, 1)
        XCTAssertEqual(testPlayer.nextQueue.count, 0)
        XCTAssertEqual(testPlayer.currentlyPlaying, songId0)
    }
    
    func testPlayMulitpleSongs_WaitingQueuePlaying() {
        prepareWithCachedPlaylist()
        playerData.currentIndex = 1
        guard let songId0 = library.getSong(id: cdHelper.seeder.songs[0].id) else { XCTFail(); return }
        testPlayer.appendUserQueue(playables: [songId0])
        testPlayer.playNext()
        
        testPlayer.clearContextQueue()
        guard let songId1 = library.getSong(id: cdHelper.seeder.songs[1].id) else { XCTFail(); return }
        guard let songId2 = library.getSong(id: cdHelper.seeder.songs[2].id) else { XCTFail(); return }
        guard let songId3 = library.getSong(id: cdHelper.seeder.songs[3].id) else { XCTFail(); return }
        testPlayer.appendContextQueue(playables: [songId1, songId2, songId3])
        testPlayer.play(playerIndex: PlayerIndex(queueType: .next, index: 0))
        XCTAssertTrue(testPlayer.isPlaying)
        XCTAssertEqual(testPlayer.prevQueue.count, 0)
        XCTAssertEqual(testPlayer.userQueue.count, 0)
        XCTAssertEqual(testPlayer.nextQueue.count, 2)
        XCTAssertEqual(testPlayer.currentlyPlaying, songId1)
    }

    func testPlayMulitpleSongs_WaitingQueuePlaying2() {
        prepareWithCachedPlaylist()
        playerData.currentIndex = 1
        guard let songId0 = library.getSong(id: cdHelper.seeder.songs[0].id) else { XCTFail(); return }
        testPlayer.appendUserQueue(playables: [songId0])
        testPlayer.playNext()
        
        guard let songId1 = library.getSong(id: cdHelper.seeder.songs[1].id) else { XCTFail(); return }
        guard let songId2 = library.getSong(id: cdHelper.seeder.songs[2].id) else { XCTFail(); return }
        guard let songId3 = library.getSong(id: cdHelper.seeder.songs[3].id) else { XCTFail(); return }
        testPlayer.play(context: PlayContext(name: "", playables: [songId1, songId2, songId3]))
        XCTAssertTrue(testPlayer.isPlaying)
        XCTAssertEqual(testPlayer.prevQueue.count, 0)
        XCTAssertEqual(testPlayer.userQueue.count, 0)
        XCTAssertEqual(testPlayer.nextQueue.count, 3)
        XCTAssertEqual(testPlayer.currentlyPlaying, songId0)
    }

    func testPlayMulitpleSongs_WaitingQueuePlaying8() {
        prepareWithCachedPlaylist()
        playerData.currentIndex = 1
        guard let songId0 = library.getSong(id: cdHelper.seeder.songs[0].id) else { XCTFail(); return }
        testPlayer.appendUserQueue(playables: [songId0])

        guard let songId1 = library.getSong(id: cdHelper.seeder.songs[1].id) else { XCTFail(); return }
        guard let songId2 = library.getSong(id: cdHelper.seeder.songs[2].id) else { XCTFail(); return }
        guard let songId3 = library.getSong(id: cdHelper.seeder.songs[3].id) else { XCTFail(); return }
        testPlayer.play(context: PlayContext(name: "", playables: [songId1, songId2, songId3]))
        XCTAssertTrue(testPlayer.isPlaying)
        XCTAssertEqual(testPlayer.prevQueue.count, 0)
        XCTAssertEqual(testPlayer.userQueue.count, 0)
        XCTAssertEqual(testPlayer.nextQueue.count, 3)
        XCTAssertEqual(testPlayer.currentlyPlaying, songId0)
    }

    func testPlaySong_WaitingQueuePlaying8() {
        prepareWithCachedPlaylist()
        playerData.currentIndex = 1
        guard let songId0 = library.getSong(id: cdHelper.seeder.songs[0].id) else { XCTFail(); return }
        testPlayer.appendUserQueue(playables: [songId0])

        guard let songId1 = library.getSong(id: cdHelper.seeder.songs[1].id) else { XCTFail(); return }
        testPlayer.play(context: PlayContext(name: "", playables: [songId1]))
        XCTAssertTrue(testPlayer.isPlaying)
        XCTAssertEqual(testPlayer.prevQueue.count, 0)
        XCTAssertEqual(testPlayer.userQueue.count, 0)
        XCTAssertEqual(testPlayer.nextQueue.count, 1)
        XCTAssertEqual(testPlayer.currentlyPlaying, songId0)
    }

    func testPlaySong_WaitingQueuePlaying9() {
        prepareWithCachedPlaylist()
        playerData.currentIndex = 1
        guard let songId0 = library.getSong(id: cdHelper.seeder.songs[0].id) else { XCTFail(); return }
        guard let songId1 = library.getSong(id: cdHelper.seeder.songs[1].id) else { XCTFail(); return }
        guard let songId2 = library.getSong(id: cdHelper.seeder.songs[2].id) else { XCTFail(); return }
        testPlayer.appendUserQueue(playables: [songId0])
        testPlayer.appendUserQueue(playables: [songId1])
        testPlayer.appendUserQueue(playables: [songId2])
        testPlayer.playNext()

        guard let songId3 = library.getSong(id: cdHelper.seeder.songs[3].id) else { XCTFail(); return }
        testPlayer.play(context: PlayContext(name: "", playables: [songId3]))
        XCTAssertTrue(testPlayer.isPlaying)
        XCTAssertEqual(testPlayer.prevQueue.count, 0)
        XCTAssertEqual(testPlayer.userQueue.count, 2)
        XCTAssertEqual(testPlayer.nextQueue.count, 1)
        XCTAssertEqual(testPlayer.currentlyPlaying, songId0)
    }

    func testPlayMulitpleSongs_WaitingQueuePlaying3() {
        prepareWithCachedPlaylist()
        playerData.currentIndex = 1
        guard let songId0 = library.getSong(id: cdHelper.seeder.songs[0].id) else { XCTFail(); return }
        guard let songId1 = library.getSong(id: cdHelper.seeder.songs[1].id) else { XCTFail(); return }
        guard let songId2 = library.getSong(id: cdHelper.seeder.songs[2].id) else { XCTFail(); return }
        testPlayer.appendUserQueue(playables: [songId0])
        testPlayer.appendUserQueue(playables: [songId1])
        testPlayer.appendUserQueue(playables: [songId2])
        testPlayer.playNext()
        
        guard let songId3 = library.getSong(id: cdHelper.seeder.songs[3].id) else { XCTFail(); return }
        testPlayer.play(context: PlayContext(name: "", playables: [songId3]))
        XCTAssertTrue(testPlayer.isPlaying)
        XCTAssertEqual(testPlayer.prevQueue.count, 0)
        XCTAssertEqual(testPlayer.userQueue.count, 2)
        XCTAssertEqual(testPlayer.nextQueue.count, 1)
        XCTAssertEqual(testPlayer.currentlyPlaying, songId0)
    }

    func testPlayMulitpleSongs_WaitingQueuePlaying4() {
        prepareWithCachedPlaylist()
        playerData.currentIndex = 1
        guard let songId0 = library.getSong(id: cdHelper.seeder.songs[0].id) else { XCTFail(); return }
        testPlayer.appendUserQueue(playables: [songId0])
        testPlayer.playNext()
        
        guard let songId1 = library.getSong(id: cdHelper.seeder.songs[1].id) else { XCTFail(); return }
        testPlayer.play(context: PlayContext(name: "", playables: [songId1]))
        XCTAssertTrue(testPlayer.isPlaying)
        XCTAssertEqual(testPlayer.prevQueue.count, 0)
        XCTAssertEqual(testPlayer.userQueue.count, 0)
        XCTAssertEqual(testPlayer.nextQueue.count, 1)
        XCTAssertEqual(testPlayer.currentlyPlaying, songId0)
    }

    func testPlayMulitpleSongs_WaitingQueuePlaying5() {
        prepareWithCachedPlaylist()
        playerData.currentIndex = 1
        guard let songId0 = library.getSong(id: cdHelper.seeder.songs[0].id) else { XCTFail(); return }
        testPlayer.appendUserQueue(playables: [songId0])
        testPlayer.playNext()
        
        guard let songId1 = library.getSong(id: cdHelper.seeder.songs[1].id) else { XCTFail(); return }
        testPlayer.play(context: PlayContext(name: "", playables: [songId1]))
        XCTAssertTrue(testPlayer.isPlaying)
        XCTAssertEqual(testPlayer.prevQueue.count, 0)
        XCTAssertEqual(testPlayer.userQueue.count, 0)
        XCTAssertEqual(testPlayer.nextQueue.count, 1)
        XCTAssertEqual(testPlayer.currentlyPlaying, songId0)
    }

    func testPlayMulitpleSongs_WaitingQueuePlaying6() {
        prepareWithCachedPlaylist()
        guard let songId0 = library.getSong(id: cdHelper.seeder.songs[0].id) else { XCTFail(); return }
        testPlayer.play(context: PlayContext(name: "", playables: [songId0]))

        guard let songId1 = library.getSong(id: cdHelper.seeder.songs[1].id) else { XCTFail(); return }
        testPlayer.play(context: PlayContext(name: "", playables: [songId1]))
        XCTAssertTrue(testPlayer.isPlaying)
        XCTAssertEqual(testPlayer.prevQueue.count, 0)
        XCTAssertEqual(testPlayer.userQueue.count, 0)
        XCTAssertEqual(testPlayer.nextQueue.count, 0)
        XCTAssertEqual(testPlayer.currentlyPlaying?.id, songId1.id)
    }
    
    func testPlayMulitpleSongs_userQueueHasElements_notUserQueuePlaying() {
        playerData.removeAllItems()
        playerData.isUserQueuePlaying = false
        guard let songId0 = library.getSong(id: cdHelper.seeder.songs[0].id) else { XCTFail(); return }
        testPlayer.appendUserQueue(playables: [songId0])

        guard let songId1 = library.getSong(id: cdHelper.seeder.songs[1].id) else { XCTFail(); return }
        testPlayer.play(context: PlayContext(name: "", playables: [songId1]))
        XCTAssertTrue(testPlayer.isPlaying)
        XCTAssertEqual(testPlayer.prevQueue.count, 0)
        XCTAssertEqual(testPlayer.userQueue.count, 0)
        XCTAssertEqual(testPlayer.nextQueue.count, 1)
        XCTAssertEqual(testPlayer.currentlyPlaying?.id, songId0.id)
    }

    func testPlayMulitpleSongs_userQueueHasElements_notUserQueuePlaying2() {
        playerData.removeAllItems()
        playerData.isUserQueuePlaying = false
        guard let songId0 = library.getSong(id: cdHelper.seeder.songs[0].id) else { XCTFail(); return }
        testPlayer.appendUserQueue(playables: [songId0])

        guard let songId1 = library.getSong(id: cdHelper.seeder.songs[1].id) else { XCTFail(); return }
        guard let songId2 = library.getSong(id: cdHelper.seeder.songs[2].id) else { XCTFail(); return }
        guard let songId3 = library.getSong(id: cdHelper.seeder.songs[3].id) else { XCTFail(); return }
        testPlayer.play(context: PlayContext(name: "", playables: [songId1, songId2, songId3]))
        XCTAssertTrue(testPlayer.isPlaying)
        XCTAssertEqual(testPlayer.prevQueue.count, 0)
        XCTAssertEqual(testPlayer.userQueue.count, 0)
        XCTAssertEqual(testPlayer.nextQueue.count, 3)
        XCTAssertEqual(testPlayer.currentlyPlaying?.id, songId0.id)
    }
    
    func testPlayMulitpleSongs_userQueueHasElements_notUserQueuePlaying3() {
        playerData.removeAllItems()
        playerData.isUserQueuePlaying = false
        guard let songId0 = library.getSong(id: cdHelper.seeder.songs[0].id) else { XCTFail(); return }
        testPlayer.appendUserQueue(playables: [songId0])

        guard let songId1 = library.getSong(id: cdHelper.seeder.songs[1].id) else { XCTFail(); return }
        guard let songId2 = library.getSong(id: cdHelper.seeder.songs[2].id) else { XCTFail(); return }
        guard let songId3 = library.getSong(id: cdHelper.seeder.songs[3].id) else { XCTFail(); return }
        testPlayer.play(context: PlayContext(name: "", index: 1, playables: [songId1, songId2, songId3]))
        XCTAssertTrue(testPlayer.isPlaying)
        XCTAssertEqual(testPlayer.prevQueue.count, 1)
        XCTAssertEqual(testPlayer.userQueue.count, 0)
        XCTAssertEqual(testPlayer.nextQueue.count, 2)
        XCTAssertEqual(testPlayer.currentlyPlaying?.id, songId0.id)
    }
    
    func testPlayMulitpleSongs_userQueueHasElements_notUserQueuePlaying4() {
        playerData.removeAllItems()
        playerData.isUserQueuePlaying = false
        guard let songId0 = library.getSong(id: cdHelper.seeder.songs[0].id) else { XCTFail(); return }
        guard let songId4 = library.getSong(id: cdHelper.seeder.songs[4].id) else { XCTFail(); return }
        guard let songId5 = library.getSong(id: cdHelper.seeder.songs[5].id) else { XCTFail(); return }
        testPlayer.appendUserQueue(playables: [songId0, songId4, songId5])

        guard let songId1 = library.getSong(id: cdHelper.seeder.songs[1].id) else { XCTFail(); return }
        guard let songId2 = library.getSong(id: cdHelper.seeder.songs[2].id) else { XCTFail(); return }
        guard let songId3 = library.getSong(id: cdHelper.seeder.songs[3].id) else { XCTFail(); return }
        testPlayer.play(context: PlayContext(name: "", index: 2, playables: [songId1, songId2, songId3]))
        XCTAssertTrue(testPlayer.isPlaying)
        XCTAssertEqual(testPlayer.prevQueue.count, 2)
        XCTAssertEqual(testPlayer.userQueue.count, 2)
        XCTAssertEqual(testPlayer.nextQueue.count, 1)
        XCTAssertEqual(testPlayer.currentlyPlaying?.id, songId0.id)
        XCTAssertEqual(testPlayer.userQueue[0].id, songId4.id)
        XCTAssertEqual(testPlayer.userQueue[1].id, songId5.id)
    }
    
    func testPlayMulitpleSongs_switchPlayerMode_toMusic() {
        playerData.removeAllItems()
        playerData.isUserQueuePlaying = false
        guard let songId0 = library.getSong(id: cdHelper.seeder.songs[0].id) else { XCTFail(); return }
        guard let songId4 = library.getSong(id: cdHelper.seeder.songs[4].id) else { XCTFail(); return }
        guard let songId5 = library.getSong(id: cdHelper.seeder.songs[5].id) else { XCTFail(); return }
        testPlayer.appendContextQueue(playables: [songId0, songId4, songId5])

        guard let songId1 = library.getSong(id: cdHelper.seeder.songs[1].id) else { XCTFail(); return }
        guard let songId2 = library.getSong(id: cdHelper.seeder.songs[2].id) else { XCTFail(); return }
        guard let songId3 = library.getSong(id: cdHelper.seeder.songs[3].id) else { XCTFail(); return }
        testPlayer.insertPodcastQueue(playables: [songId1, songId2, songId3])
        testPlayer.setPlayerMode(.podcast)
        
        guard let songId7 = library.getSong(id: cdHelper.seeder.songs[7].id) else { XCTFail(); return }
        guard let songId8 = library.getSong(id: cdHelper.seeder.songs[8].id) else { XCTFail(); return }
        guard let songId9 = library.getSong(id: cdHelper.seeder.songs[9].id) else { XCTFail(); return }
        testPlayer.play(context: PlayContext(name: "", index: 1, playables: [songId7, songId8, songId9]))
        XCTAssertEqual(testPlayer.playerMode, PlayerMode.music)
        XCTAssertTrue(testPlayer.isPlaying)
        XCTAssertEqual(testPlayer.prevQueue.count, 1)
        XCTAssertEqual(testPlayer.userQueue.count, 0)
        XCTAssertEqual(testPlayer.nextQueue.count, 1)
        XCTAssertEqual(testPlayer.currentlyPlaying?.id, songId8.id)
        XCTAssertEqual(testPlayer.prevQueue[0].id, songId7.id)
        XCTAssertEqual(testPlayer.nextQueue[0].id, songId9.id)
        
        testPlayer.setPlayerMode(.podcast)
        XCTAssertEqual(testPlayer.prevQueue.count, 0)
        XCTAssertEqual(testPlayer.userQueue.count, 0)
        XCTAssertEqual(testPlayer.nextQueue.count, 2)
        XCTAssertEqual(testPlayer.currentlyPlaying?.id, songId1.id)
        XCTAssertEqual(testPlayer.nextQueue[0].id, songId2.id)
        XCTAssertEqual(testPlayer.nextQueue[1].id, songId3.id)
    }
    
    
    func testPlayMulitpleSongs_switchPlayerMode_toMusic2() {
        playerData.removeAllItems()
        playerData.isUserQueuePlaying = false
        guard let songId0 = library.getSong(id: cdHelper.seeder.songs[0].id) else { XCTFail(); return }
        guard let songId4 = library.getSong(id: cdHelper.seeder.songs[4].id) else { XCTFail(); return }
        guard let songId5 = library.getSong(id: cdHelper.seeder.songs[5].id) else { XCTFail(); return }
        testPlayer.appendContextQueue(playables: [songId0, songId4, songId5])
        playerData.currentIndex = 0

        testPlayer.setPlayerMode(.podcast)
        guard let songId1 = library.getSong(id: cdHelper.seeder.songs[1].id) else { XCTFail(); return }
        guard let songId2 = library.getSong(id: cdHelper.seeder.songs[2].id) else { XCTFail(); return }
        guard let songId3 = library.getSong(id: cdHelper.seeder.songs[3].id) else { XCTFail(); return }
        testPlayer.insertPodcastQueue(playables: [songId1, songId2, songId3])
        playerData.currentIndex = 1

        guard let songId7 = library.getSong(id: cdHelper.seeder.songs[7].id) else { XCTFail(); return }
        guard let songId8 = library.getSong(id: cdHelper.seeder.songs[8].id) else { XCTFail(); return }
        guard let songId9 = library.getSong(id: cdHelper.seeder.songs[9].id) else { XCTFail(); return }
        testPlayer.play(context: PlayContext(name: "", type: .music, index: 2, playables: [songId7, songId8, songId9]))
        XCTAssertEqual(testPlayer.playerMode, PlayerMode.music)
        XCTAssertTrue(testPlayer.isPlaying)
        XCTAssertEqual(testPlayer.prevQueue.count, 2)
        XCTAssertEqual(testPlayer.userQueue.count, 0)
        XCTAssertEqual(testPlayer.nextQueue.count, 0)
        XCTAssertEqual(testPlayer.currentlyPlaying?.id, songId9.id)
        XCTAssertEqual(testPlayer.prevQueue[0].id, songId7.id)
        XCTAssertEqual(testPlayer.prevQueue[1].id, songId8.id)
        
        testPlayer.setPlayerMode(.podcast)
        XCTAssertEqual(testPlayer.prevQueue.count, 1)
        XCTAssertEqual(testPlayer.userQueue.count, 0)
        XCTAssertEqual(testPlayer.nextQueue.count, 1)
        XCTAssertEqual(testPlayer.currentlyPlaying?.id, songId2.id)
        XCTAssertEqual(testPlayer.prevQueue[0].id, songId1.id)
        XCTAssertEqual(testPlayer.nextQueue[0].id, songId3.id)
    }
    
    func testPlayMulitpleSongs_switchPlayerMode_toPodcast() {
        playerData.removeAllItems()
        playerData.isUserQueuePlaying = false
        guard let songId0 = library.getSong(id: cdHelper.seeder.songs[0].id) else { XCTFail(); return }
        guard let songId4 = library.getSong(id: cdHelper.seeder.songs[4].id) else { XCTFail(); return }
        guard let songId5 = library.getSong(id: cdHelper.seeder.songs[5].id) else { XCTFail(); return }
        testPlayer.appendContextQueue(playables: [songId0, songId4, songId5])

        guard let songId1 = library.getSong(id: cdHelper.seeder.songs[1].id) else { XCTFail(); return }
        guard let songId2 = library.getSong(id: cdHelper.seeder.songs[2].id) else { XCTFail(); return }
        guard let songId3 = library.getSong(id: cdHelper.seeder.songs[3].id) else { XCTFail(); return }
        testPlayer.insertPodcastQueue(playables: [songId1, songId2, songId3])

        guard let songId7 = library.getSong(id: cdHelper.seeder.songs[7].id) else { XCTFail(); return }
        guard let songId8 = library.getSong(id: cdHelper.seeder.songs[8].id) else { XCTFail(); return }
        guard let songId9 = library.getSong(id: cdHelper.seeder.songs[9].id) else { XCTFail(); return }
        testPlayer.play(context: PlayContext(name: "", type: .podcast, index: 1, playables: [songId7, songId8, songId9]))
        XCTAssertEqual(testPlayer.playerMode, PlayerMode.podcast)
        XCTAssertTrue(testPlayer.isPlaying)
        XCTAssertEqual(testPlayer.prevQueue.count, 1)
        XCTAssertEqual(testPlayer.userQueue.count, 0)
        XCTAssertEqual(testPlayer.nextQueue.count, 1)
        XCTAssertEqual(testPlayer.currentlyPlaying?.id, songId8.id)
        XCTAssertEqual(testPlayer.prevQueue[0].id, songId7.id)
        XCTAssertEqual(testPlayer.nextQueue[0].id, songId9.id)
        
        testPlayer.setPlayerMode(.music)
        XCTAssertEqual(testPlayer.prevQueue.count, 0)
        XCTAssertEqual(testPlayer.userQueue.count, 0)
        XCTAssertEqual(testPlayer.nextQueue.count, 2)
        XCTAssertEqual(testPlayer.currentlyPlaying?.id, songId0.id)
        XCTAssertEqual(testPlayer.nextQueue[0].id, songId4.id)
        XCTAssertEqual(testPlayer.nextQueue[1].id, songId5.id)
    }
    
    func testPlayMulitpleSongs_switchPlayerMode_toPodcast2() {
        playerData.removeAllItems()
        playerData.isUserQueuePlaying = false
        guard let songId0 = library.getSong(id: cdHelper.seeder.songs[0].id) else { XCTFail(); return }
        guard let songId4 = library.getSong(id: cdHelper.seeder.songs[4].id) else { XCTFail(); return }
        guard let songId5 = library.getSong(id: cdHelper.seeder.songs[5].id) else { XCTFail(); return }
        testPlayer.appendContextQueue(playables: [songId0, songId4, songId5])
        playerData.currentIndex = 1

        testPlayer.setPlayerMode(.podcast)
        guard let songId1 = library.getSong(id: cdHelper.seeder.songs[1].id) else { XCTFail(); return }
        guard let songId2 = library.getSong(id: cdHelper.seeder.songs[2].id) else { XCTFail(); return }
        guard let songId3 = library.getSong(id: cdHelper.seeder.songs[3].id) else { XCTFail(); return }
        testPlayer.insertPodcastQueue(playables: [songId1, songId2, songId3])
        playerData.currentIndex = 0

        guard let songId7 = library.getSong(id: cdHelper.seeder.songs[7].id) else { XCTFail(); return }
        guard let songId8 = library.getSong(id: cdHelper.seeder.songs[8].id) else { XCTFail(); return }
        guard let songId9 = library.getSong(id: cdHelper.seeder.songs[9].id) else { XCTFail(); return }
        testPlayer.play(context: PlayContext(name: "", type: .podcast, index: 2, playables: [songId7, songId8, songId9]))
        XCTAssertEqual(testPlayer.playerMode, PlayerMode.podcast)
        XCTAssertTrue(testPlayer.isPlaying)
        XCTAssertEqual(testPlayer.prevQueue.count, 2)
        XCTAssertEqual(testPlayer.userQueue.count, 0)
        XCTAssertEqual(testPlayer.nextQueue.count, 0)
        XCTAssertEqual(testPlayer.currentlyPlaying?.id, songId9.id)
        XCTAssertEqual(testPlayer.prevQueue[0].id, songId7.id)
        XCTAssertEqual(testPlayer.prevQueue[1].id, songId8.id)
        
        testPlayer.setPlayerMode(.music)
        XCTAssertEqual(testPlayer.prevQueue.count, 1)
        XCTAssertEqual(testPlayer.userQueue.count, 0)
        XCTAssertEqual(testPlayer.nextQueue.count, 1)
        XCTAssertEqual(testPlayer.currentlyPlaying?.id, songId4.id)
        XCTAssertEqual(testPlayer.prevQueue[0].id, songId0.id)
        XCTAssertEqual(testPlayer.nextQueue[0].id, songId5.id)
    }
    
    func testPlay_ContextNameChanges() {
        playerData.removeAllItems()
        guard let songId0 = library.getSong(id: cdHelper.seeder.songs[0].id) else { XCTFail(); return }
        guard let songId1 = library.getSong(id: cdHelper.seeder.songs[1].id) else { XCTFail(); return }
        
        testPlayer.play(context: PlayContext(name: "Blub", playables: [songId0, songId1]))
        XCTAssertEqual(testPlayer.contextName, "Blub")
        testPlayer.setPlayerMode(.podcast)
        XCTAssertEqual(testPlayer.contextName, "Podcasts")
        testPlayer.appendContextQueue(playables: [songId0])
        XCTAssertEqual(testPlayer.contextName, "Podcasts")
        testPlayer.setPlayerMode(.music)
        XCTAssertEqual(testPlayer.contextName, "Mixed Context")
        
        testPlayer.play(context: PlayContext(name: "YYYY", playables: [songId0, songId1]))
        XCTAssertEqual(testPlayer.contextName, "YYYY")
        testPlayer.play(context: PlayContext(name: "GoGo Podcasts", type: .podcast, playables: [songId0, songId1]))
        XCTAssertEqual(testPlayer.contextName, "Podcasts")
        testPlayer.setPlayerMode(.music)
        XCTAssertEqual(testPlayer.contextName, "YYYY")
        
        testPlayer.play(context: PlayContext(name: "BBBB", playables: [songId0, songId1]))
        XCTAssertEqual(testPlayer.contextName, "BBBB")
        testPlayer.appendPodcastQueue(playables: [songId0])
        XCTAssertEqual(testPlayer.contextName, "BBBB")
        testPlayer.setPlayerMode(.podcast)
        XCTAssertEqual(testPlayer.contextName, "Podcasts")
        testPlayer.insertPodcastQueue(playables: [songId0])
        testPlayer.setPlayerMode(.music)
        XCTAssertEqual(testPlayer.contextName, "BBBB")

        testPlayer.setPlayerMode(.music)
        testPlayer.insertContextQueue(playables: [songId0])
        XCTAssertEqual(testPlayer.contextName, "Mixed Context")
    }
    
    func testSeek_EmptyPlaylist() {
        testPlayer.seek(toSecond: 3.0)
        XCTAssertEqual(testPlayer.elapsedTime, 0.0)
    }
    
    func testSeek_FilledPlaylist() {
        testPlayer.play(context: PlayContext(name: "", playables: [songCached]))
        testPlayer.seek(toSecond: 3.0)
        mockAVPlayer.useMockCurrentItem = true
        let elapsedTime = testPlayer.elapsedTime
        XCTAssertEqual(elapsedTime, 3.0)
        mockAVPlayer.useMockCurrentItem = false
    }
    
    func testPlayPreviousOrReplay_EmptyPlaylist() {
        testPlayer.playPreviousOrReplay()
        XCTAssertEqual(testPlayer.currentlyPlaying, nil)
    }
    
    func testPlayPreviousOrReplay_Previous() {
        prepareWithCachedPlaylist()
        testPlayer.play(playerIndex: PlayerIndex(queueType: .next, index: 2))
        testPlayer.playPreviousOrReplay()
        XCTAssertEqual(playerData.currentIndex, 2)
        XCTAssertEqual(testPlayer.prevQueue.count, 2)
        XCTAssertEqual(testPlayer.userQueue.count, 0)
        XCTAssertEqual(testPlayer.nextQueue.count, 6)
        XCTAssertEqual(testPlayer.elapsedTime, 0.0)
    }
    
    func testPlayPreviousOrReplay_Replay() {
        prepareWithCachedPlaylist()
        testPlayer.play(playerIndex: PlayerIndex(queueType: .next, index: 2))
        testPlayer.seek(toSecond: 10.0)
        mockAVPlayer.useMockCurrentItem = true
        testPlayer.playPreviousOrReplay()
        mockAVPlayer.useMockCurrentItem = false
        XCTAssertEqual(playerData.currentIndex, 3)
        XCTAssertEqual(testPlayer.prevQueue.count, 3)
        XCTAssertEqual(testPlayer.userQueue.count, 0)
        XCTAssertEqual(testPlayer.nextQueue.count, 5)
        XCTAssertEqual(testPlayer.elapsedTime, 0.0)
    }
    
    func testPlayPrevious_EmptyPlaylist() {
        testMusicPlayer.playPrevious()
        XCTAssertEqual(testPlayer.currentlyPlaying, nil)
    }

    func testPlayPrevious_Normal() {
        prepareWithCachedPlaylist()
        testPlayer.play(playerIndex: PlayerIndex(queueType: .next, index: 2))
        testMusicPlayer.playPrevious()
        XCTAssertEqual(playerData.currentIndex, 2)
        testMusicPlayer.playPrevious()
        XCTAssertEqual(playerData.currentIndex, 1)
    }
    
    func testPlayPrevious_AtStart() {
        prepareWithCachedPlaylist()
        testPlayer.play()
        testMusicPlayer.playPrevious()
        XCTAssertEqual(playerData.currentIndex, 0)
        testMusicPlayer.playPrevious()
        XCTAssertEqual(playerData.currentIndex, 0)
    }
    
    func testPlayPrevious_RepeatAll() {
        prepareWithCachedPlaylist()
        testPlayer.setRepeatMode(.all)
        testPlayer.play(playerIndex: PlayerIndex(queueType: .next, index: 0))
        testMusicPlayer.playPrevious()
        testMusicPlayer.playPrevious()
        XCTAssertEqual(playerData.currentIndex, 8)
    }
    
    func testPlayPrevious_RepeatAll_OnlyOneSong() {
        testPlayer.play(context: PlayContext(name: "", playables: [songCached]))
        testPlayer.setRepeatMode(.all)
        testMusicPlayer.playPrevious()
        testMusicPlayer.playPrevious()
        XCTAssertEqual(playerData.currentIndex, 0)
    }
    
    func testPlayPrevious_StartPlayIfPaused() {
        prepareWithCachedPlaylist()
        testPlayer.play(playerIndex: PlayerIndex(queueType: .next, index: 3))
        testMusicPlayer.pause()
        testMusicPlayer.playPrevious()
        XCTAssertTrue(testPlayer.isPlaying)
    }
    
    func testPlayPrevious_IsPlayingStaysTrue() {
        prepareWithCachedPlaylist()
        testPlayer.play(playerIndex: PlayerIndex(queueType: .next, index: 3))
        testMusicPlayer.playPrevious()
        XCTAssertTrue(testPlayer.isPlaying)
    }

    func testPlayNext_EmptyPlaylist() {
        testPlayer.playNext()
        XCTAssertEqual(testPlayer.currentlyPlaying, nil)
    }

    func testPlayNext_Normal() {
        prepareWithCachedPlaylist()
        testPlayer.play(playerIndex: PlayerIndex(queueType: .next, index: 2))
        testPlayer.playNext()
        XCTAssertEqual(playerData.currentIndex, 4)
        testPlayer.playNext()
        XCTAssertEqual(playerData.currentIndex, 5)
    }
    
    func testPlayNext_AtStart() {
        prepareWithCachedPlaylist()
        testPlayer.play()
        testPlayer.playNext()
        XCTAssertEqual(playerData.currentIndex, 1)
        testPlayer.playNext()
        XCTAssertEqual(playerData.currentIndex, 2)
    }
    
    func testPlayNext_RepeatAll() {
        prepareWithCachedPlaylist()
        testPlayer.setRepeatMode(.all)
        testPlayer.play(playerIndex: PlayerIndex(queueType: .next, index: 7))
        testPlayer.playNext()
        testPlayer.playNext()
        XCTAssertEqual(playerData.currentIndex, 1)
    }
    
    func testPlayNext_RepeatAll_OnlyOneSong() {
        testPlayer.play(context: PlayContext(name: "", playables: [songCached]))
        testPlayer.setRepeatMode(.all)
        testPlayer.playNext()
        testPlayer.playNext()
        XCTAssertEqual(playerData.currentIndex, 0)
        XCTAssertEqual(testPlayer.currentlyPlaying?.id, songCached.id)
    }
    
    func testPlayNext_StartPlayIfPaused() {
        prepareWithCachedPlaylist()
        testPlayer.play(playerIndex: PlayerIndex(queueType: .next, index: 3))
        testMusicPlayer.pause()
        testPlayer.playNext()
        XCTAssertTrue(testPlayer.isPlaying)
    }
    
    func testPlayNext_IsPlayingStaysTrue() {
        prepareWithCachedPlaylist()
        testPlayer.play(playerIndex: PlayerIndex(queueType: .next, index: 3))
        testPlayer.playNext()
        XCTAssertTrue(testPlayer.isPlaying)
    }
    
    func testStop_EmptyPlaylist() {
        testPlayer.stop()
        XCTAssertFalse(testPlayer.isPlaying)
        XCTAssertEqual(testPlayer.currentlyPlaying, nil)
    }
    
    func testStop_Playing() {
        prepareWithCachedPlaylist()
        testPlayer.play(playerIndex: PlayerIndex(queueType: .next, index: 6))
        testPlayer.stop()
        XCTAssertFalse(testPlayer.isPlaying)
        XCTAssertEqual(testPlayer.currentlyPlaying?.id, playlistThreeCached.playables[0].id)
    }
    
    func testStop_AlreadyStopped() {
        prepareWithCachedPlaylist()
        testPlayer.play(playerIndex: PlayerIndex(queueType: .next, index: 6))
        testPlayer.stop()
        testPlayer.stop()
        XCTAssertFalse(testPlayer.isPlaying)
        XCTAssertEqual(playerData.currentIndex, 0)
    }
    
    func testTogglePlay_EmptyPlaylist() {
        testPlayer.togglePlayPause()
        XCTAssertFalse(testPlayer.isPlaying)
        testPlayer.togglePlayPause()
        XCTAssertFalse(testPlayer.isPlaying)
        testPlayer.togglePlayPause()
        XCTAssertFalse(testPlayer.isPlaying)
    }
    
    func testTogglePlay_AfterPlay() {
        prepareWithCachedPlaylist()
        testPlayer.play(playerIndex: PlayerIndex(queueType: .next, index: 6))
        testPlayer.togglePlayPause()
        XCTAssertFalse(testPlayer.isPlaying)
        testPlayer.togglePlayPause()
        XCTAssertTrue(testPlayer.isPlaying)
        testPlayer.togglePlayPause()
        XCTAssertFalse(testPlayer.isPlaying)
        testPlayer.togglePlayPause()
        XCTAssertTrue(testPlayer.isPlaying)
    }
    
    func testRemoveFromPlaylist_RemoveNotCurrentSong() {
        prepareWithCachedPlaylist()
        testPlayer.play(playerIndex: PlayerIndex(queueType: .next, index: 3))
        testPlayer.removePlayable(at: PlayerIndex(queueType: .prev, index: 2))
        XCTAssertEqual(playerData.currentIndex, 3)
        testPlayer.removePlayable(at: PlayerIndex(queueType: .next, index: 1))
        XCTAssertEqual(playerData.currentIndex, 3)
        testPlayer.removePlayable(at: PlayerIndex(queueType: .next, index: 0))
        XCTAssertEqual(playerData.currentIndex, 3)
        testPlayer.removePlayable(at: PlayerIndex(queueType: .prev, index: 0))
        XCTAssertEqual(playerData.currentIndex, 2)
    }
    
    func testPlayer_InsertNextInMainQueue_emptyMainQueue() {
        testPlayer.clearContextQueue()
        playerData.currentIndex = 0
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [])
        testPlayer.insertContextQueue(playables: [songCached])
        checkCurrentlyPlaying(idToBe: 4)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [])
    }
    
    func testPlayer_InsertNextInMainQueue_emptyMainQueue_userQueuePlaing() {
        playerData.currentIndex = 0
        testPlayer.insertUserQueue(playables: [songCached])
        checkCurrentlyPlaying(idToBe: 4)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [])
        testPlayer.insertContextQueue(playables: [songToDownload])
        checkCurrentlyPlaying(idToBe: 4)
        XCTAssertEqual(playerData.currentIndex, -1)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [0])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [])
    }
    
    func testPlayer_InsertNextInMainQueue_WithWaitingQueuePlaying_nextEmpty() {
        prepareWithWaitingQueuePlaying()
        playerData.currentIndex = 2
        testPlayer.removePlayable(at: PlayerIndex(queueType: .next, index: 0))
        testPlayer.removePlayable(at: PlayerIndex(queueType: .next, index: 0))
        checkCurrentlyPlaying(idToBe: 5)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [0, 1, 2])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [6, 7, 8])
        testPlayer.insertContextQueue(playables: [songCached])
        checkCurrentlyPlaying(idToBe: 5)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [0, 1, 2])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [4])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [6, 7, 8])
    }
    
    func testPlayer_InsertNextInMainQueue_noWaitingQueuePlaying_nextEmpty() {
        prepareNoWaitingQueuePlaying()
        playerData.currentIndex = 2
        testPlayer.removePlayable(at: PlayerIndex(queueType: .next, index: 0))
        testPlayer.removePlayable(at: PlayerIndex(queueType: .next, index: 0))
        checkCurrentlyPlaying(idToBe: 2)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [0, 1])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [5, 6, 7, 8])
        testPlayer.insertContextQueue(playables: [songCached])
        checkCurrentlyPlaying(idToBe: 2)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [0, 1])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [4])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [5, 6, 7, 8])
    }

    func testPlayer_InsertNextInMainQueue_WithWaitingQueuePlaying() {
        prepareWithWaitingQueuePlaying()
        playerData.currentIndex = 2
        checkCurrentlyPlaying(idToBe: 5)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [0, 1, 2])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [3, 4])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [6, 7, 8])
        testPlayer.insertContextQueue(playables: [songCached])
        checkCurrentlyPlaying(idToBe: 5)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [0, 1, 2])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [4, 3, 4])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [6, 7, 8])
    }
    
    func testPlayer_InsertNextInMainQueue_noWaitingQueuePlaying() {
        prepareNoWaitingQueuePlaying()
        playerData.currentIndex = 2
        checkCurrentlyPlaying(idToBe: 2)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [0, 1])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [3, 4])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [5, 6, 7, 8])
        testPlayer.insertContextQueue(playables: [songCached])
        checkCurrentlyPlaying(idToBe: 2)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [0, 1])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [4, 3, 4])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [5, 6, 7, 8])
    }
    

    func testPlayer_AppendNextInMainQueue_WithWaitingQueuePlaying() {
        prepareWithWaitingQueuePlaying()
        playerData.currentIndex = 2
        checkCurrentlyPlaying(idToBe: 5)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [0, 1, 2])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [3, 4])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [6, 7, 8])
        testPlayer.appendContextQueue(playables: [songToDownload])
        checkCurrentlyPlaying(idToBe: 5)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [0, 1, 2])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [3, 4, 0])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [6, 7, 8])
    }
    
    func testPlayer_AppendNextInMainQueue_noWaitingQueuePlaying() {
        prepareNoWaitingQueuePlaying()
        playerData.currentIndex = 2
        checkCurrentlyPlaying(idToBe: 2)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [0, 1])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [3, 4])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [5, 6, 7, 8])
        testPlayer.appendContextQueue(playables: [songToDownload])
        checkCurrentlyPlaying(idToBe: 2)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [0, 1])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [3, 4, 0])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [5, 6, 7, 8])
    }
    
    func testPlayer_PlayPrev_WithWaitingQueue_noWaitingQueuePlaying() {
        prepareNoWaitingQueuePlaying()
        playerData.currentIndex = 3
        testMusicPlayer.playPrevious()
        checkCurrentlyPlaying(idToBe: 2)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [0, 1])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [3, 4])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [5, 6, 7, 8])
        testMusicPlayer.playPrevious()
        checkCurrentlyPlaying(idToBe: 1)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [0])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [2, 3, 4])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [5, 6, 7, 8])
        testMusicPlayer.playPrevious()
        checkCurrentlyPlaying(idToBe: 0)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [Int]())
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [1, 2, 3, 4])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [5, 6, 7, 8])

        prepareNoWaitingQueuePlaying()
        playerData.currentIndex = 0
        testPlayer.setRepeatMode(.all)
        testMusicPlayer.playPrevious()
        checkCurrentlyPlaying(idToBe: 4)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [0, 1, 2, 3])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [Int]())
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [5, 6, 7, 8])
    }
    
    func testPlayer_PlayPrev_WithWaitingQueue_withWaitingQueuePlaying() {
        prepareWithWaitingQueuePlaying()
        playerData.currentIndex = 2
        testMusicPlayer.playPrevious()
        checkCurrentlyPlaying(idToBe: 2)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [0, 1])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [3, 4])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [6, 7, 8])
        testMusicPlayer.playPrevious()
        checkCurrentlyPlaying(idToBe: 1)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [0])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [2, 3, 4])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [6, 7, 8])
        testMusicPlayer.playPrevious()
        checkCurrentlyPlaying(idToBe: 0)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [Int]())
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [1, 2, 3, 4])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [6, 7, 8])

        prepareWithWaitingQueuePlaying()
        playerData.currentIndex = -1
        checkCurrentlyPlaying(idToBe: 5)
        testMusicPlayer.playPrevious()
        checkCurrentlyPlaying(idToBe: 5)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [Int]())
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [0, 1, 2, 3, 4])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [6, 7, 8])

        prepareWithWaitingQueuePlaying()
        playerData.currentIndex = -1
        testPlayer.setRepeatMode(.all)
        checkCurrentlyPlaying(idToBe: 5)
        testMusicPlayer.playPrevious()
        checkCurrentlyPlaying(idToBe: 4)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [0, 1, 2, 3])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [Int]())
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [6, 7, 8])
    }
    
    func testPlayer_PlayNext_WithWaitingQueue_noWaitingQueuePlaying() {
        prepareNoWaitingQueuePlaying()
        playerData.currentIndex = 2
        testPlayer.playNext()
        checkCurrentlyPlaying(idToBe: 5)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [0, 1, 2])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [3, 4])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [6, 7, 8])
        
        prepareNoWaitingQueuePlaying()
        playerData.currentIndex = 0
        testPlayer.playNext()
        checkCurrentlyPlaying(idToBe: 5)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [0])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [1, 2, 3, 4])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [6, 7, 8])

        prepareNoWaitingQueuePlaying()
        playerData.currentIndex = 4
        testPlayer.playNext()
        checkCurrentlyPlaying(idToBe: 5)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [0, 1, 2, 3, 4])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [Int]())
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [6, 7, 8])
    }
    
    func testPlayer_PlayNext_WithWaitingQueue_withWaitingQueuePlaying() {
        prepareWithWaitingQueuePlaying()
        playerData.currentIndex = 2
        testPlayer.playNext()
        checkCurrentlyPlaying(idToBe: 6)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [0, 1, 2])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [3, 4])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [7, 8])
        
        prepareWithWaitingQueuePlaying()
        playerData.currentIndex = -1
        checkCurrentlyPlaying(idToBe: 5)
        testPlayer.playNext()
        checkCurrentlyPlaying(idToBe: 6)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [Int]())
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [0, 1, 2, 3, 4])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [7, 8])
        testPlayer.removePlayable(at: PlayerIndex(queueType: .user, index: 0))
        testPlayer.removePlayable(at: PlayerIndex(queueType: .user, index: 0))
        testPlayer.playNext()
        checkCurrentlyPlaying(idToBe: 0)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [Int]())
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [1, 2, 3, 4])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [Int]())
        
        prepareWithWaitingQueuePlaying()
        playerData.currentIndex = 0
        testPlayer.playNext()
        checkCurrentlyPlaying(idToBe: 6)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [0])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [1, 2, 3, 4])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [7, 8])
        testPlayer.playNext()
        checkCurrentlyPlaying(idToBe: 7)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [0])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [1, 2, 3, 4])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [8])
        testPlayer.playNext()
        checkCurrentlyPlaying(idToBe: 8)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [0])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [1, 2, 3, 4])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [Int]())
        testPlayer.playNext()
        checkCurrentlyPlaying(idToBe: 1)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [0])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [2, 3, 4])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [Int]())
        
        prepareWithWaitingQueuePlaying()
        testPlayer.removePlayable(at: PlayerIndex(queueType: .user, index: 0))
        testPlayer.removePlayable(at: PlayerIndex(queueType: .user, index: 0))
        playerData.currentIndex = 4
        testPlayer.playNext()
        checkCurrentlyPlaying(idToBe: 8)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [0, 1, 2, 3, 4])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [Int]())
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [Int]())
        testPlayer.setRepeatMode(.all)
        testPlayer.playNext()
        checkCurrentlyPlaying(idToBe: 0)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [Int]())
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [1, 2, 3, 4])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [Int]())
        
        prepareWithWaitingQueuePlaying()
        testPlayer.removePlayable(at: PlayerIndex(queueType: .user, index: 0))
        testPlayer.removePlayable(at: PlayerIndex(queueType: .user, index: 0))
        playerData.currentIndex = 4
        testPlayer.playNext()
        checkCurrentlyPlaying(idToBe: 8)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [0, 1, 2, 3, 4])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [Int]())
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [Int]())
        testPlayer.setRepeatMode(.single)
        testPlayer.playNext()
        XCTAssertFalse(testPlayer.isPlaying)
        XCTAssertFalse(playerData.isUserQueuePlaying)
        checkCurrentlyPlaying(idToBe: 0)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [Int]())
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [1, 2, 3, 4])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [Int]())
    }
    
    func testPlayer_Play_indexValidation() {
        prepareNoWaitingQueuePlaying()
        playerData.currentIndex = -1
        checkCurrentlyPlaying(idToBe: 0)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [Int]())
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [1, 2, 3, 4])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [5, 6, 7, 8])
        testPlayer.play()
        checkCurrentlyPlaying(idToBe: 0)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [Int]())
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [1, 2, 3, 4])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [5, 6, 7, 8])
    }

    func testPlayer_PlayPlayIndex_prev_noWaitingQueuePlaying() {
        prepareNoWaitingQueuePlaying()
        playerData.currentIndex = 1
        testPlayer.play(playerIndex: PlayerIndex(queueType: .prev, index: 0))
        checkCurrentlyPlaying(idToBe: 0)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [Int]())
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [1, 2, 3, 4])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [5, 6, 7, 8])
        
        prepareNoWaitingQueuePlaying()
        playerData.currentIndex = 2
        testPlayer.play(playerIndex: PlayerIndex(queueType: .prev, index: 0))
        checkCurrentlyPlaying(idToBe: 0)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [Int]())
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [1, 2, 3, 4])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [5, 6, 7, 8])

        prepareNoWaitingQueuePlaying()
        playerData.currentIndex = 2
        testPlayer.play(playerIndex: PlayerIndex(queueType: .prev, index: 1))
        checkCurrentlyPlaying(idToBe: 1)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [0])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [2, 3, 4])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [5, 6, 7, 8])

        prepareNoWaitingQueuePlaying()
        playerData.currentIndex = 4
        testPlayer.play(playerIndex: PlayerIndex(queueType: .prev, index: 3))
        checkCurrentlyPlaying(idToBe: 3)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [0, 1, 2])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [4])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [5, 6, 7, 8])

        prepareNoWaitingQueuePlaying()
        playerData.currentIndex = 4
        testPlayer.play(playerIndex: PlayerIndex(queueType: .prev, index: 0))
        checkCurrentlyPlaying(idToBe: 0)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [Int]())
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [1, 2, 3, 4])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [5, 6, 7, 8])
    }

    func testPlayer_PlayPlayIndex_prev_withWaitingQueuePlaying() {
        prepareWithWaitingQueuePlaying()
        playerData.currentIndex = 0
        testPlayer.play(playerIndex: PlayerIndex(queueType: .prev, index: 0))
        checkCurrentlyPlaying(idToBe: 0)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [Int]())
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [1, 2, 3, 4])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [6, 7, 8])
        
        prepareWithWaitingQueuePlaying()
        playerData.currentIndex = 2
        testPlayer.play(playerIndex: PlayerIndex(queueType: .prev, index: 0))
        checkCurrentlyPlaying(idToBe: 0)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [Int]())
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [1, 2, 3, 4])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [6, 7, 8])

        prepareWithWaitingQueuePlaying()
        playerData.currentIndex = 2
        testPlayer.play(playerIndex: PlayerIndex(queueType: .prev, index: 1))
        checkCurrentlyPlaying(idToBe: 1)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [0])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [2, 3, 4])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [6, 7, 8])

        prepareWithWaitingQueuePlaying()
        playerData.currentIndex = 4
        testPlayer.play(playerIndex: PlayerIndex(queueType: .prev, index: 4))
        checkCurrentlyPlaying(idToBe: 4)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [0, 1, 2, 3])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [Int]())
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [6, 7, 8])

        prepareWithWaitingQueuePlaying()
        playerData.currentIndex = 4
        testPlayer.play(playerIndex: PlayerIndex(queueType: .prev, index: 3))
        checkCurrentlyPlaying(idToBe: 3)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [0, 1, 2])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [4])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [6, 7, 8])

        prepareWithWaitingQueuePlaying()
        playerData.currentIndex = 4
        testPlayer.play(playerIndex: PlayerIndex(queueType: .prev, index: 0))
        checkCurrentlyPlaying(idToBe: 0)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [Int]())
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [1, 2, 3, 4])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [6, 7, 8])
    }
    
    func testPlayer_PlayPlayIndex_next_noWaitingQueuePlaying() {
        prepareNoWaitingQueuePlaying()
        playerData.currentIndex = 3
        testPlayer.play(playerIndex: PlayerIndex(queueType: .next, index: 0))
        checkCurrentlyPlaying(idToBe: 4)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [0, 1, 2, 3])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [Int]())
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [5, 6, 7, 8])
        
        prepareNoWaitingQueuePlaying()
        playerData.currentIndex = 2
        testPlayer.play(playerIndex: PlayerIndex(queueType: .next, index: 0))
        checkCurrentlyPlaying(idToBe: 3)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [0, 1, 2])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [4])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [5, 6, 7, 8])

        prepareNoWaitingQueuePlaying()
        playerData.currentIndex = 2
        testPlayer.play(playerIndex: PlayerIndex(queueType: .next, index: 1))
        checkCurrentlyPlaying(idToBe: 4)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [0, 1, 2, 3])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [Int]())
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [5, 6, 7, 8])

        prepareNoWaitingQueuePlaying()
        playerData.currentIndex = 0
        testPlayer.play(playerIndex: PlayerIndex(queueType: .next, index: 3))
        checkCurrentlyPlaying(idToBe: 4)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [0, 1, 2, 3])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [Int]())
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [5, 6, 7, 8])

        prepareNoWaitingQueuePlaying()
        playerData.currentIndex = 0
        testPlayer.play(playerIndex: PlayerIndex(queueType: .next, index: 0))
        checkCurrentlyPlaying(idToBe: 1)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [0])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [2, 3, 4])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [5, 6, 7, 8])
    }

    func testPlayer_PlayPlayIndex_next_withWaitingQueuePlaying() {
        prepareWithWaitingQueuePlaying()
        playerData.currentIndex = 3
        testPlayer.play(playerIndex: PlayerIndex(queueType: .next, index: 0))
        checkCurrentlyPlaying(idToBe: 4)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [0, 1, 2, 3])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [Int]())
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [6, 7, 8])
        
        prepareWithWaitingQueuePlaying()
        playerData.currentIndex = 2
        testPlayer.play(playerIndex: PlayerIndex(queueType: .next, index: 0))
        checkCurrentlyPlaying(idToBe: 3)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [0, 1, 2])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [4])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [6, 7, 8])

        prepareWithWaitingQueuePlaying()
        playerData.currentIndex = 2
        testPlayer.play(playerIndex: PlayerIndex(queueType: .next, index: 1))
        checkCurrentlyPlaying(idToBe: 4)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [0, 1, 2, 3])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [Int]())
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [6, 7, 8])

        prepareWithWaitingQueuePlaying()
        playerData.currentIndex = -1
        testPlayer.play(playerIndex: PlayerIndex(queueType: .next, index: 0))
        checkCurrentlyPlaying(idToBe: 0)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [Int]())
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [1, 2, 3, 4])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [6, 7, 8])

        prepareWithWaitingQueuePlaying()
        playerData.currentIndex = -1
        testPlayer.play(playerIndex: PlayerIndex(queueType: .next, index: 4))
        checkCurrentlyPlaying(idToBe: 4)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [0, 1, 2, 3])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [Int]())
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [6, 7, 8])

        prepareWithWaitingQueuePlaying()
        playerData.currentIndex = -1
        testPlayer.play(playerIndex: PlayerIndex(queueType: .next, index: 2))
        checkCurrentlyPlaying(idToBe: 2)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [0, 1])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [3, 4])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [6, 7, 8])

        prepareWithWaitingQueuePlaying()
        playerData.currentIndex = 0
        testPlayer.play(playerIndex: PlayerIndex(queueType: .next, index: 0))
        checkCurrentlyPlaying(idToBe: 1)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [0])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [2, 3, 4])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [6, 7, 8])
    }

    func testPlayer_PlayPlayIndex_wait_noWaitingQueuePlaying() {
        prepareNoWaitingQueuePlaying()
        playerData.currentIndex = 3
        testPlayer.play(playerIndex: PlayerIndex(queueType: .user, index: 0))
        checkCurrentlyPlaying(idToBe: 5)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [0, 1, 2, 3])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [4])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [6, 7, 8])
        
        prepareNoWaitingQueuePlaying()
        playerData.currentIndex = 2
        testPlayer.play(playerIndex: PlayerIndex(queueType: .user, index: 0))
        checkCurrentlyPlaying(idToBe: 5)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [0, 1, 2])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [3, 4])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [6, 7, 8])

        prepareNoWaitingQueuePlaying()
        playerData.currentIndex = 2
        testPlayer.play(playerIndex: PlayerIndex(queueType: .user, index: 1))
        checkCurrentlyPlaying(idToBe: 6)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [0, 1, 2])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [3, 4])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [7, 8])

        prepareNoWaitingQueuePlaying()
        playerData.currentIndex = 0
        testPlayer.play(playerIndex: PlayerIndex(queueType: .user, index: 3))
        checkCurrentlyPlaying(idToBe: 8)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [0])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [1, 2, 3, 4])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [Int]())

        prepareNoWaitingQueuePlaying()
        playerData.currentIndex = 0
        testPlayer.play(playerIndex: PlayerIndex(queueType: .user, index: 2))
        checkCurrentlyPlaying(idToBe: 7)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [0])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [1, 2, 3, 4])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [8])

        prepareNoWaitingQueuePlaying()
        playerData.currentIndex = 4
        testPlayer.play(playerIndex: PlayerIndex(queueType: .user, index: 0))
        checkCurrentlyPlaying(idToBe: 5)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [0, 1, 2, 3, 4])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [Int]())
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [6, 7, 8])
        
        prepareNoWaitingQueuePlaying()
        testPlayer.removePlayable(at: PlayerIndex(queueType: .user, index: 0))
        testPlayer.removePlayable(at: PlayerIndex(queueType: .user, index: 0))
        testPlayer.removePlayable(at: PlayerIndex(queueType: .user, index: 0))
        playerData.currentIndex = 4
        testPlayer.play(playerIndex: PlayerIndex(queueType: .user, index: 0))
        checkCurrentlyPlaying(idToBe: 8)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [0, 1, 2, 3, 4])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [Int]())
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [Int]())
    }

    func testPlayer_PlayPlayIndex_wait_withWaitingQueuePlaying() {
        prepareWithWaitingQueuePlaying()
        playerData.currentIndex = 3
        testPlayer.play(playerIndex: PlayerIndex(queueType: .user, index: 0))
        checkCurrentlyPlaying(idToBe: 6)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [0, 1, 2, 3])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [4])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [7, 8])
        
        prepareWithWaitingQueuePlaying()
        playerData.currentIndex = 2
        testPlayer.play(playerIndex: PlayerIndex(queueType: .user, index: 0))
        checkCurrentlyPlaying(idToBe: 6)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [0, 1, 2])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [3, 4])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [7, 8])

        prepareWithWaitingQueuePlaying()
        playerData.currentIndex = 2
        testPlayer.play(playerIndex: PlayerIndex(queueType: .user, index: 1))
        checkCurrentlyPlaying(idToBe: 7)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [0, 1, 2])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [3, 4])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [8])

        prepareWithWaitingQueuePlaying()
        playerData.currentIndex = 4
        testPlayer.play(playerIndex: PlayerIndex(queueType: .user, index: 2))
        checkCurrentlyPlaying(idToBe: 8)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [0, 1, 2, 3, 4])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [Int]())
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [Int]())

        prepareWithWaitingQueuePlaying()
        playerData.currentIndex = 0
        testPlayer.play(playerIndex: PlayerIndex(queueType: .user, index: 2))
        checkCurrentlyPlaying(idToBe: 8)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [0])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [1, 2, 3, 4])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [Int]())

        prepareWithWaitingQueuePlaying()
        testPlayer.removePlayable(at: PlayerIndex(queueType: .user, index: 0))
        testPlayer.removePlayable(at: PlayerIndex(queueType: .user, index: 0))
        playerData.currentIndex = 0
        testPlayer.play(playerIndex: PlayerIndex(queueType: .user, index: 0))
        checkCurrentlyPlaying(idToBe: 8)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [0])
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [1, 2, 3, 4])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [Int]())

        prepareWithWaitingQueuePlaying()
        playerData.currentIndex = -1
        testPlayer.play(playerIndex: PlayerIndex(queueType: .user, index: 0))
        checkCurrentlyPlaying(idToBe: 6)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [Int]())
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [0, 1, 2, 3, 4])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [7, 8])
        
        prepareWithWaitingQueuePlaying()
        playerData.currentIndex = -1
        testPlayer.play(playerIndex: PlayerIndex(queueType: .user, index: 1))
        checkCurrentlyPlaying(idToBe: 7)
        checkQueueItems(queue: testQueueHandler.prevQueue, seedIds: [Int]())
        checkQueueItems(queue: testQueueHandler.nextQueue, seedIds: [0, 1, 2, 3, 4])
        checkQueueItems(queue: testQueueHandler.userQueue, seedIds: [8])
    }

}
