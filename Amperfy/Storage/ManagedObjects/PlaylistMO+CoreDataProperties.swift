import Foundation
import CoreData


extension PlaylistMO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PlaylistMO> {
        return NSFetchRequest<PlaylistMO>(entityName: "Playlist")
    }

    @NSManaged public var id: String
    @NSManaged public var name: String?
    @NSManaged public var songCount: Int16
    @NSManaged public var items: NSSet?
    @NSManaged public var changeDate: Date?
    @NSManaged public var lastPlayedDate: Date?
    @NSManaged public var playCount: Int32
    @NSManaged public var playersContextPlaylist: PlayerMO?
    @NSManaged public var playersShuffledContextPlaylist: PlayerMO?
    @NSManaged public var playersUserQueuePlaylist: PlayerMO?
    @NSManaged public var playersPodcastPlaylist: PlayerMO?

}

// MARK: Generated accessors for items
extension PlaylistMO {

    @objc(addItemsObject:)
    @NSManaged public func addToItems(_ value: PlaylistItemMO)

    @objc(removeItemsObject:)
    @NSManaged public func removeFromItems(_ value: PlaylistItemMO)

    @objc(addItems:)
    @NSManaged public func addToItems(_ values: NSSet)

    @objc(removeItems:)
    @NSManaged public func removeFromItems(_ values: NSSet)

}
