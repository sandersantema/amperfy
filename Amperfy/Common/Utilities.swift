import Foundation
import UIKit
import os.log

protocol CustomEquatable {
    func isEqualTo(_ other: CustomEquatable) -> Bool
}

extension CustomEquatable where Self: Equatable {
    func isEqualTo(_ other: CustomEquatable) -> Bool {
        if let other = other as? Self { return self == other }
        return false
    }
}

extension Bool {
    mutating func toggle() {
        self = !self
    }
    
    static func random(probabilityForTrueInPercent probability: Float) -> Bool{
        return Float.random(in: 0..<100) <= probability
    }
}

extension Int16 {
    static func isValid(value: Int) -> Bool {
        return !((value < Int16.min) || (value > Int16.max))
    }
}

extension Int32 {
    static func isValid(value: Int) -> Bool {
        return !((value < Int32.min) || (value > Int32.max))
    }
}

extension Int64 {
    var asByteString: String {
        return ByteCountFormatter.string(fromByteCount: self, countStyle: ByteCountFormatter.CountStyle.decimal)
    }
}

extension Int {
    mutating func setOtherRandomValue(in targetRange: ClosedRange<Int>) {
        var newValue = 0
        repeat {
            newValue = Int.random(in: targetRange)
        } while (newValue == self)
        self = newValue
    }
    
    var asDurationString: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: TimeInterval(self))!
    }
    
    var asMinuteString: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute]
        formatter.unitsStyle = .short
        return formatter.string(from: TimeInterval(self))!
    }

    var asDayString: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day]
        formatter.unitsStyle = .short
        return formatter.string(from: TimeInterval(self))!
    }
}

extension String {
    func isFoundBy(searchText: String) -> Bool {
        return self.lowercased().contains(searchText.lowercased())
    }
    
    func isContainedIn(_ container: [String]) -> Bool {
        return container.contains(self)
    }
    
    var asIso8601Date: Date? {
        let dateFormatter = ISO8601DateFormatter()
        return dateFormatter.date(from: self)
    }
    
    var asByteCount: Int? {
        guard !self.isEmpty else { return nil }
        if self.hasSuffix(" GB") {
            let stringSize = self[..<self.index(self.endIndex, offsetBy: -3)]
            guard let stringFloat = Float(stringSize) else { return nil }
            return Int(stringFloat * 1000 * 1000 * 1000)
        } else if self.hasSuffix(" MB") {
            let stringSize = self[..<self.index(self.endIndex, offsetBy: -3)]
            guard let stringFloat = Float(stringSize) else { return nil }
            return Int(stringFloat * 1000 * 1000)
        } else if self.hasSuffix(" KB") {
            let stringSize = self[..<self.index(self.endIndex, offsetBy: -3)]
            guard let stringFloat = Float(stringSize) else { return nil }
            return Int(stringFloat * 1000)
        } else if self.hasSuffix(" B") {
            let stringSize = self[..<self.index(self.endIndex, offsetBy: -2)]
            guard let stringFloat = Float(stringSize) else { return nil }
            return Int(stringFloat)
        } else {
            return nil
        }
    }
    
    var asDurationInSeconds: Int? {
        let components = self.split{ $0 == ":" }.compactMap{ Int($0) }
        guard components.count == 3 else { return nil }
        return (components[0] * 60 * 24) + (components[1] * 60) + components[2]
    }
    
    static func generateRandomString(ofLength length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
    
    func deletingPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }
    
    private var html2AttributedString: NSAttributedString? {
        Data(utf8).html2AttributedString
    }
    var html2String: String {
        html2AttributedString?.string.html2AttributedString?.string ?? ""
    }
}

extension Array {
    func chunked(intoSubarrayCount chunkCount: Int) -> [[Element]] {
        let chuckSize: Int = Int(ceil(Float(count)/Float(chunkCount)))
        return chunked(intoSubarraySize: chuckSize)
    }
    
    func chunked(intoSubarraySize size: Int) -> [[Element]] {
        guard count > 0 else { return [[Element]]() }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

extension UIColor {
    convenience init(hue: CGFloat, saturation: CGFloat, lightness: CGFloat, alpha: CGFloat) {
        precondition(0...1 ~= hue &&
                     0...1 ~= saturation &&
                     0...1 ~= lightness &&
                     0...1 ~= alpha, "input range is out of range 0...1")
        
        // from HSL TO HSB
        var newSaturation: CGFloat = 0.0
        let brightness = lightness + saturation * min(lightness, 1-lightness)
        if brightness == 0 {
            newSaturation = 0.0
        } else {
            newSaturation = 2 * (1 - lightness / brightness)
        }
        self.init(hue: hue, saturation: newSaturation, brightness: brightness, alpha: alpha)
    }
    
    func getHue(_ hue: UnsafeMutablePointer<CGFloat>?, saturation targetSaturation: UnsafeMutablePointer<CGFloat>?, lightness targetLightness: UnsafeMutablePointer<CGFloat>?, alpha targetAlpha: UnsafeMutablePointer<CGFloat>?) -> Bool {
        var saturation, brightness, alpha: CGFloat
        (saturation, brightness, alpha) = (0.0, 0.0, 0.0)
        self.getHue(hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        // from HSB TO HSL
        var newSaturation: CGFloat = 0.0
        let lightness = brightness * (1 - saturation / 2)
        if lightness == 0 || lightness == 1 {
            newSaturation = 0.0
        } else {
            newSaturation = (brightness-lightness) / (min(lightness, 1-lightness))
        }

        targetSaturation?.pointee = newSaturation
        targetLightness?.pointee = lightness
        targetAlpha?.pointee = alpha
        return true
    }
    
    func getWithLightness(of: CGFloat) -> UIColor{
        precondition(0...1 ~= of, "input range is out of range 0...1")
        var hue, saturation, lightness, alpha: CGFloat
        (hue, saturation, lightness, alpha) = (0.0, 0.0, 0.0, 0.0)
        _ = self.getHue(&hue, saturation: &saturation, lightness: &lightness, alpha: &alpha)
        return UIColor(hue: hue, saturation: saturation, lightness: of, alpha: alpha)
    }
    
    // 007AFF
    // r:0 g:122 b:255
    static var defaultBlue: UIColor {
        return UIView().tintColor
    }
    
    static var gold: UIColor {
        return UIColor(displayP3Red: 241/255, green: 194/255, blue: 66/255, alpha: 1.0)
    }
    
    static var labelColor: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor.label
        } else {
            return UIColor.black
        }
    }
    
    static var fillColor: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor.systemFill
        } else {
            return UIColor(displayP3Red: 217/255, green: 214/255, blue: 209/255, alpha: 1.0)
        }
    }

    static var secondaryLabelColor: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor.secondaryLabel
        } else {
            return UIColor.systemGray
        }
    }
    
    static var backgroundColor: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor.systemBackground
        } else {
            return UIColor.white
        }
    }
}

extension UIActivityIndicatorView {
    static var defaultStyle: Style {
        if #available(iOS 13.0, *) {
            return .medium
        } else {
            return .gray
        }
    }
}

extension NSObject {
    class var typeName: String {
        return String(describing: self)
    }
}

extension NSData {
    var sizeInByte: Int64 {
        return Int64(length)
    }
}

extension Data {
    static func fetch(fromUrlString urlString: String) -> Data? {
        var data: Data? = nil
        guard let url = URL(string: urlString) else {
            return nil
        }
        do {
            let dataFromURL = try Data(contentsOf: url)
            data = dataFromURL
        } catch {}
        return data
    }
    var sizeInByte: Int64 {
        return Int64(count)
    }
    func createLocalUrl(fileName: String? = nil) -> URL {
        let tempDirectoryURL = NSURL.fileURL(withPath: NSTemporaryDirectory(), isDirectory: true)
        let url = tempDirectoryURL.appendingPathComponent(fileName ?? UUID().uuidString)
        try! self.write(to: url, options: Data.WritingOptions.atomic)
        return url
    }

    var html2AttributedString: NSAttributedString? {
        return try? NSAttributedString(data: self, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue], documentAttributes: nil)
    }
    var html2String: String { html2AttributedString?.string.html2String ?? "" }
}

extension Date {
    var asIso8601String: String {
        let dateFormatter = ISO8601DateFormatter()
        return dateFormatter.string(from: self)
    }
    
    var asShortDayMonthString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d. MMMM"
        dateFormatter.timeZone = NSTimeZone(name: "UTC")! as TimeZone
        return dateFormatter.string(from: self)
    }
}

extension URLComponents {
    mutating func addQueryItem(name: String, value: Int) {
        self.addQueryItem(name: name, value: String(value))
    }
    
    mutating func addQueryItem(name: String, value: String) {
        let queryItem = URLQueryItem(name: name, value: value)
        var queryItems = self.queryItems ?? [URLQueryItem]()
        queryItems.append(queryItem)
        self.queryItems = queryItems
    }
}

extension Array {
    func element(at index: Int) -> Element? {
        return index < self.count ? self[index] : nil
    }
}

extension Array where Element: Equatable {
    func allIndices(of element: Element) -> [Int] {
        return self.enumerated().filter {
            return $0.element == element
        }.map {
            $0.offset
        }
    }
}

extension Array where Element == String {
    func sortAlphabeticallyAscending() -> [String] {
        return self.sorted{ $0.localizedCaseInsensitiveCompare($1) == ComparisonResult.orderedAscending }
    }
    func sortAlphabeticallyDescending() -> [String] {
        return self.sorted{ $0.localizedCaseInsensitiveCompare($1) == ComparisonResult.orderedDescending }
    }
}

extension UIView {
    static let forceTouchClickLimit: Float = 1.0
    
    var is3DTouchAvailable: Bool {
        return  forceTouchCapability() == .available
    }
    
    func forceTouchCapability() -> UIForceTouchCapability {
        return UIApplication.shared.keyWindow?.rootViewController?.traitCollection.forceTouchCapability ?? .unknown
    }
    
    func normalizedForce(touches: Set<UITouch>) -> Float? {
        guard is3DTouchAvailable, let touch = touches.first else { return nil }
        let maximumForce = touch.maximumPossibleForce
        let force = touch.force
        let normalizedForce = (force / maximumForce)
        return Float(normalizedForce)
    }
    
    func isForceClicked(_ touches: Set<UITouch>) -> Bool {
        guard let force = normalizedForce(touches: touches) else { return false }
        if force < UIView.forceTouchClickLimit {
            return false
        } else {
            return true
        }
    }
    
    func setGradientBackground(colorTop: UIColor, colorBottom: UIColor) {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [colorBottom.cgColor, colorTop.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 1.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.locations = [0, 1]
        gradientLayer.frame = bounds
        layer.insertSublayer(gradientLayer, at: 0)
    }
    
    var screenshot: UIImage? {
        UIGraphicsBeginImageContextWithOptions(layer.frame.size, false, 0)
        defer {
            UIGraphicsEndImageContext()
        }
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        layer.render(in: context)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    func setBackgroundBlur(style: UIBlurEffect.Style, backupBackgroundColor: UIColor = .backgroundColor) {
        if #available(iOS 13.0, *) {
            self.backgroundColor = UIColor.clear
            let blurEffect = UIBlurEffect(style: .prominent)
            let blurEffectView = UIVisualEffectView(effect: blurEffect)
            blurEffectView.frame = self.frame
            self.insertSubview(blurEffectView, at: 0)
        } else {
            self.backgroundColor = backupBackgroundColor
        }
    }
}

extension UITableView {
    func dequeueCell<CellType: UITableViewCell>(for tableView: UITableView, at indexPath: IndexPath) -> CellType {
        guard let cell = self.dequeueReusableCell(withIdentifier: CellType.typeName, for: indexPath) as? CellType else {
            os_log(.error, "The dequeued cell is not an instance of %s", CellType.typeName)
            return CellType()
        }
        return cell
    }
}

extension UITableViewController {
    func dequeueCell<CellType: UITableViewCell>(for tableView: UITableView, at indexPath: IndexPath) -> CellType {
        return self.tableView.dequeueCell(for: tableView, at: indexPath)
    }
}

extension UITableView {
    func register(nibName: String) {
        self.register(UINib(nibName: nibName, bundle: nil), forCellReuseIdentifier: nibName)
    }
}

extension UIImageView {
    func downloaded(from url: URL, contentMode mode: UIView.ContentMode = .scaleAspectFit) {
        contentMode = mode
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
                else { return }
            DispatchQueue.main.async() {
                self.image = image
            }
            }.resume()
    }
    func downloaded(from link: String, contentMode mode: UIView.ContentMode = .scaleAspectFit) {
        guard let url = URL(string: link) else { return }
        downloaded(from: url, contentMode: mode)
    }
}

extension UIAlertController {
    /*
     Workaround to avoid false 'LayoutConstraints' warning:
     
     "2019-04-12 15:33:29.584076+0200 Appname[4688:39368] [LayoutConstraints] Unable to simultaneously satisfy constraints.
         Probably at least one of the constraints in the following list is one you don't want.
         Try this:
             (1) look at each constraint and try to figure out which you don't expect;
             (2) find the code that added the unwanted constraint or constraints and fix it.
     (
         "<NSLayoutConstraint:0x6000025a1e50 UIView:0x7f88fcf6ce60.width == - 16   (active)>"
     )

     Will attempt to recover by breaking constraint
     <NSLayoutConstraint:0x6000025a1e50 UIView:0x7f88fcf6ce60.width == - 16   (active)>"
     
     Found fix for this here:
     https://stackoverflow.com/questions/55653187/swift-default-alertviewcontroller-breaking-constraints
     --> Remove invalid constrain from UIAlertController
     */
    func pruneNegativeWidthConstraintsToAvoidFalseConstraintWarnings() {
        for subview in self.view.subviews {
            for constraint in subview.constraints where constraint.debugDescription.contains("width == - 16") {
                subview.removeConstraint(constraint)
            }
        }
    }
    
    func setOptionsForIPadToDisplayPopupCentricIn(view: UIView) {
        if let popoverController = self.popoverPresentationController {
            popoverController.sourceView = view
            popoverController.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
    }
}

extension UIAlertAction {
    convenience init(title: String?, image: UIImage, style: Style, handler: ((UIAlertAction) -> Void)? = nil) {
        self.init(title: title, style: style, handler: handler)
        self.actionImage = image
    }

    var actionImage: UIImage {
        get { return self.value(forKey: "image") as? UIImage ?? UIImage() }
        set(image) { self.setValue(image, forKey: "image") }
    }
}

extension UISlider {
    func setUnicolorThumbImage(thumbSize: CGFloat, color: UIColor, for state: UIControl.State){
        let thumbImage = createThumbImage(size: thumbSize, color: color)
        self.setThumbImage(thumbImage, for: state)
    }

    private func createThumbImage(size: CGFloat, color: UIColor) -> UIImage {
        let layerFrame = CGRect(x: 0, y: 0, width: size, height: size)

        let shapeLayer = CAShapeLayer()
        shapeLayer.path = CGPath(ellipseIn: layerFrame.insetBy(dx: 1, dy: 1), transform: nil)
        shapeLayer.fillColor = color.cgColor
        shapeLayer.strokeColor = color.withAlphaComponent(0.65).cgColor

        let layer = CALayer.init()
        layer.frame = layerFrame
        layer.addSublayer(shapeLayer)
        return self.imageFromLayer(layer: layer)
    }

    private func imageFromLayer(layer: CALayer) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(layer.frame.size, false, UIScreen.main.scale)
        layer.render(in: UIGraphicsGetCurrentContext()!)
        let outputImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return outputImage
    }
}

extension UIImage {
    func averageColor() -> UIColor {
        var bitmap = [UInt8](repeating: 0, count: 4)

        let context = CIContext(options: nil)
        let cgImg = context.createCGImage(CoreImage.CIImage(cgImage: self.cgImage!), from: CoreImage.CIImage(cgImage: self.cgImage!).extent)

        let inputImage = CIImage(cgImage: cgImg!)
        let extent = inputImage.extent
        let inputExtent = CIVector(x: extent.origin.x, y: extent.origin.y, z: extent.size.width, w: extent.size.height)
        let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: inputExtent])!
        let outputImage = filter.outputImage!
        let outputExtent = outputImage.extent
        assert(outputExtent.size.width == 1 && outputExtent.size.height == 1)

        // Render to bitmap.
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: CIFormat.RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())

        // Compute result.
        let result = UIColor(red: CGFloat(bitmap[0]) / 255.0, green: CGFloat(bitmap[1]) / 255.0, blue: CGFloat(bitmap[2]) / 255.0, alpha: CGFloat(bitmap[3]) / 255.0)
        return result
    }
    
    func invertedImage() -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }
        let ciImage = CoreImage.CIImage(cgImage: cgImage)
        guard let filter = CIFilter(name: "CIColorInvert") else { return nil }
        filter.setDefaults()
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        let context = CIContext(options: nil)
        guard let outputImage = filter.outputImage else { return nil }
        guard let outputImageCopy = context.createCGImage(outputImage, from: outputImage.extent) else { return nil }
        return UIImage(cgImage: outputImageCopy, scale: self.scale, orientation: .up)
    }
}

extension NSPredicate {
    static var alwaysTrue = NSPredicate(format: "nil == nil")
}

extension UIDevice {
    var totalDiskCapacityInByte: Int64? {
        let fileURL = URL(fileURLWithPath:"/")
        guard let values = try? fileURL.resourceValues(forKeys: [.volumeTotalCapacityKey]),
              let capacity = values.volumeTotalCapacity else { return nil }
        return Int64(capacity)
    }
    
    var availableDiskCapacityInByte: Int64? {
        let fileURL = URL(fileURLWithPath:"/")
        guard let values = try? fileURL.resourceValues(forKeys: [.volumeAvailableCapacityKey]),
              let capacity = values.volumeAvailableCapacity else { return nil }
        return Int64(capacity)
    }
}

extension MarqueeLabel {
    func applyAmperfyStyle() {
        if trailingBuffer != 30.0 {
            self.trailingBuffer = 30.0
        }
        if leadingBuffer != 0.0 {
            self.leadingBuffer = 0.0
        }
        if animationDelay != 2.0 {
            self.animationDelay = 2.0
        }
        if type != .continuous {
            self.type = .continuous
        }
        if speed.value != 30.0 {
            self.speed = .rate(30.0)
        }
        if fadeLength != 10.0 {
            self.fadeLength = 10.0
        }
    }
}
