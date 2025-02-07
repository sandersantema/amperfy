import Foundation

class AmpacheXmlParser: GenericXmlParser {
    
    var error: ResponseError?
    private var statusCode: Int = 0
    private var message = ""

    override func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        super.parser(parser, didStartElement: elementName, namespaceURI: namespaceURI, qualifiedName: qName, attributes: attributeDict)
        
        switch(elementName) {
        case "error":
            statusCode = Int(attributeDict["errorCode"] ?? "0") ?? 0
        default:
            break
        }
    }
    
    override func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        switch(elementName) {
        case "errorMessage":
            message = buffer
        case "error":
            error = ResponseError(statusCode: statusCode, message: message)
        default:
            break
        }
        
        super.parser(parser, didEndElement: elementName, namespaceURI: namespaceURI, qualifiedName: qName)
    }

}

class AmpacheNotifiableXmlParser: AmpacheXmlParser {
    
    var parseNotifier: ParsedObjectNotifiable?
    
    init(parseNotifier: ParsedObjectNotifiable? = nil) {
        self.parseNotifier = parseNotifier
    }
    
}

class AmpacheXmlLibParser: AmpacheNotifiableXmlParser {
    
    var library: LibraryStorage
    var syncWave: SyncWave
    
    init(library: LibraryStorage, syncWave: SyncWave, parseNotifier: ParsedObjectNotifiable? = nil) {
        self.library = library
        self.syncWave = syncWave
        super.init(parseNotifier: parseNotifier)
    }
    
    func parseArtwork(urlString: String) -> Artwork? {
        guard let artworkRemoteInfo = AmpacheXmlServerApi.extractArtworkInfoFromURL(urlString: urlString) else { return nil }
        if let foundArtwork = library.getArtwork(remoteInfo: artworkRemoteInfo) {
            return foundArtwork
        } else {
            let createdArtwork = library.createArtwork()
            createdArtwork.remoteInfo = artworkRemoteInfo
            createdArtwork.url = urlString
            return createdArtwork
        }
    }
    
}
