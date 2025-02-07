import Foundation
import CoreData
import UIKit

public class Podcast: AbstractLibraryEntity {
    
    let managedObject: PodcastMO
    
    init(managedObject: PodcastMO) {
        self.managedObject = managedObject
        super.init(managedObject: managedObject)
    }
    
    var identifier: String {
        return title
    }
    var title: String {
        get { return managedObject.title ?? "Unknown Podcast" }
        set { if managedObject.title != newValue { managedObject.title = newValue } }
    }
    var depiction: String {
        get { return managedObject.depiction ?? "" }
        set { if managedObject.depiction != newValue { managedObject.depiction = newValue } }
    }
    var episodes: [PodcastEpisode] {
        guard let episodesSet = managedObject.episodes, let episodesMO = episodesSet.array as? [PodcastEpisodeMO] else { return [PodcastEpisode]() }
        return episodesMO.compactMap{ PodcastEpisode(managedObject: $0) }.filter{ $0.userStatus != .deleted }.sortByPublishDate()
    }
    override var defaultImage: UIImage {
        return UIImage.podcastArtwork
    }

}

extension Podcast: PlayableContainable  {
    var name: String { return title }
    var subtitle: String? { return nil }
    var subsubtitle: String? { return nil }
    func infoDetails(for api: BackenApiType, type: DetailType) -> [String] {
        var infoContent = [String]()
        if episodes.count == 1 {
            infoContent.append("1 Episode")
        } else if episodes.count > 1 {
            infoContent.append("\(episodes.count) Episodes")
        }
        if type == .long {
            let completeDuration = episodes.reduce(0, {$0 + $1.duration})
            if completeDuration > 0 {
                infoContent.append("\(completeDuration.asDurationString)")
            }
        }
        return infoContent
    }
    var playables: [AbstractPlayable] {
        return episodes
    }
    var playContextType: PlayerMode { return .podcast }
    func fetchFromServer(inContext context: NSManagedObjectContext, syncer: LibrarySyncer) {
        let library = LibraryStorage(context: context)
        let podcastAsync = Podcast(managedObject: context.object(with: managedObject.objectID) as! PodcastMO)
        syncer.sync(podcast: podcastAsync, library: library)
    }
    var artworkCollection: ArtworkCollection {
        return ArtworkCollection(defaultImage: defaultImage, singleImageEntity: self)
    }
}

extension Podcast: Hashable, Equatable {
    public static func == (lhs: Podcast, rhs: Podcast) -> Bool {
        return lhs.managedObject == rhs.managedObject && lhs.managedObject == rhs.managedObject
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(managedObject)
    }
}
