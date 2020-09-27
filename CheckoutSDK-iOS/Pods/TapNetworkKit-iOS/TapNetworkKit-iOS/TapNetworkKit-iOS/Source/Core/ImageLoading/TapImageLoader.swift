//
//  TapImageLoader.swift
//  TapNetworkManager/ImageLoading
//
//  Copyright © 2019 Tap Payments. All rights reserved.
//

import CoreGraphics
import class	SDWebImage.SDImageCache.SDImageCache
import class	SDWebImage.SDWebImageDownloader.SDWebImageDownloader
import struct	SDWebImage.SDWebImageDownloader.SDWebImageDownloaderOptions
import class	SDWebImage.SDWebImageManager.SDWebImageManager
import class	TapAdditionsKitV2.URLSession
import class	UIKit.UIImage.UIImage

/// Image loader.
public class TapImageLoader {

    // MARK: - Public -

    public typealias ImageResponse = (UIImage?, Error?) -> Void
    public typealias ImagesResponse = ([UIImage]?, Error?) -> Void
    public typealias ProgressCallback = (CGFloat) -> Void

    // MARK: Properties

    /// Shared instance.
    public static let shared = TapImageLoader()

    // MARK: Methods

    public func downloadImage(from url: URL, completion: @escaping ImageResponse) {

        self.downloadImage(from: url, progress: nil, completion: completion)
    }

    public func downloadImage(from url: URL, progress: ProgressCallback?, completion: @escaping ImageResponse) {

        let progressClosure: (URL, CGFloat) -> Void = { (url, theProgress) in

            progress?(theProgress)
        }

        let completionClosure: (URL, UIImage?, Error?) -> Void = { (request, image, error) in

            completion(image, error)
        }

        self.downloadImage(from: url, loadCacheSynchronously: false, loadImageSynchronously: false, progress: progressClosure, completion: completionClosure)
    }

    public func downloadImage(from url: URL, loadCacheSynchronously: Bool, loadImageSynchronously: Bool, completion: @escaping ImageResponse) {

        let completionClosure: (URL, UIImage?, Error?) -> Void = { (url, image, error) in

            completion(image, error)
        }

        self.downloadImage(from: url, loadCacheSynchronously: loadCacheSynchronously, loadImageSynchronously: loadImageSynchronously, progress: nil, completion: completionClosure)
    }

    public func downloadImages(from urls: [URL], loadCacheSynchronously: Bool, completion: @escaping ImagesResponse) {

        self.downloadImages(from: urls, loadCacheSynchronously: loadCacheSynchronously, loadImagesSynchronously: false, completion: completion)
    }

    public func fileUpdateDate(at url: URL) -> Date? {

        if url.isFileURL { return nil }

        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: Constants.timeoutInterval)
        request.httpMethod = TapHTTPMethod.HEAD.rawValue

        let response = URLSession.tap_synchronousDataTask(with: request).response

        guard response != nil else {

            return nil
        }

        guard let lastModifiedString = (response as? HTTPURLResponse)?.allHeaderFields[Constants.lastModifiedHeaderName] as? String else {

            return nil
        }

        if let date = self.lastModifiedDateFormatter.date(from: lastModifiedString) {

            return date
        }

        return nil
    }

    public func shouldDownloadFile(from url: URL, withExistingFilePath existingFilePath: String?) -> Bool {

        return shouldDownloadFile(from: url, withExistingFilePath: existingFilePath, remoteFileModificationDate: nil)
    }

    public func shouldDownloadFile(from url: URL, withExistingFilePath existingFilePath: String?, remoteFileModificationDate: AutoreleasingUnsafeMutablePointer<NSDate?>?) -> Bool {

        if existingFilePath == nil { return true }

        guard let serverFileDate = fileUpdateDate(at: url) else {

            return false
        }

        remoteFileModificationDate?.pointee = serverFileDate as NSDate?

        guard let localFileAttributes = try? FileManager.default.attributesOfItem(atPath: existingFilePath!) else {

            return true
        }

        guard let localFileDate = localFileAttributes[FileAttributeKey.modificationDate] as? Date else { return true }

        let shouldDownload = localFileDate.compare(serverFileDate) == .orderedAscending
        return shouldDownload
    }

    // MARK: - Private -

    private struct Constants {

        fileprivate static let timeoutInterval: TimeInterval = 60.0
        fileprivate static let localeIdentifier = "en_US_POSIX"
        fileprivate static let dateFormat = "EEE',' dd MMM yyyy HH':'mm':'ss 'GMT'"
        fileprivate static let timeZoneAbbreviation = "GMT"
        fileprivate static let lastModifiedHeaderName = "Last-Modified"

        @available(*, unavailable) private init() {}
    }

    // MARK: Properties

    private lazy var lastModifiedDateFormatter: DateFormatter = {

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: Constants.localeIdentifier)
        dateFormatter.dateFormat = Constants.dateFormat
        dateFormatter.timeZone = TimeZone(abbreviation: Constants.timeZoneAbbreviation)

        return dateFormatter
    }()

    private var imageLoadingQueue: OperationQueue = {

        let queue = OperationQueue()
        queue.name = "company.tap.tapnetworkmanager.imageloading.image_cache_loading_queue"
        queue.qualityOfService = .utility
        queue.maxConcurrentOperationCount = 10

        return queue
    }()

    // MARK: Methods

    private init() {}

    private func downloadImages(from urls: [URL], loadCacheSynchronously: Bool, loadImagesSynchronously: Bool, completion: @escaping ImagesResponse) {

        autoreleasepool {

            var completionToBeCalled: ImagesResponse? = completion

            let theURLs = urls

            var images: NSMutableArray? = NSMutableArray(capacity: urls.count)

            while images?.count ?? 0 < theURLs.count {

                images?.add(NSNull())
            }

            var numberOfLoadedImages = 0
            var downloadFailed = false

            let imageCompletionClosure: (URL, UIImage?, Error?) -> Void = { (url, image, error) in

                if downloadFailed { return }

                if error != nil || image == nil {

                    downloadFailed = true

                    DispatchQueue.main.async {

                        completionToBeCalled?(nil, error)
                        completionToBeCalled = nil
                    }

                    return
                }

                let nonnullImage = image!
                images![theURLs.firstIndex(of: url)!] = nonnullImage
                numberOfLoadedImages += 1

                if numberOfLoadedImages == images!.count {

                    if loadImagesSynchronously {

                        completionToBeCalled?(images as? [UIImage], nil)
                        completionToBeCalled = nil

                        images = nil

                    } else {

                        DispatchQueue.main.async {

                            completionToBeCalled?(images as? [UIImage], nil)
                            completionToBeCalled = nil

                            images = nil
                        }
                    }
                }
            }

            theURLs.forEach {

                self.downloadImage(from: $0,
                                   loadCacheSynchronously: loadCacheSynchronously,
                                   loadImageSynchronously: loadImagesSynchronously,
                                   progress: nil,
                                   completion: imageCompletionClosure)
            }
        }
    }

    private func downloadImage(from url: URL, loadCacheSynchronously: Bool, loadImageSynchronously: Bool, progress: ((URL, CGFloat) -> Void)?, completion: ((URL, UIImage?, Error?) -> Void)?) {

        self.loadImageFromCache(with: url, synchronously: loadCacheSynchronously) { (image) in

            if image != nil {

                if loadCacheSynchronously {

                    completion?(url, image, nil)

                } else {

                    DispatchQueue.main.async {

                        completion?(url, image, nil)
                    }
                }
                return
            }

            let progressClosure: (Int, Int, URL?) -> Void = { (bytesLoaded, bytesExpectedToLoad, _) in

                let cgfloatProgress = CGFloat(bytesLoaded) / CGFloat(bytesExpectedToLoad)

                if loadImageSynchronously {

                    progress?(url, cgfloatProgress)

                } else {

                    DispatchQueue.main.async {

                        progress?(url, cgfloatProgress)
                    }
                }
            }

            let completionClosure: (UIImage?, Data?, Swift.Error?, Bool) -> Void = { (image, imageData, error, finished) in

                if let nonnullImage = image {

                    self.save(nonnullImage, toCacheWith: url)
                }

                if loadImageSynchronously {

                    completion?(url, image, error)

                } else {

                    DispatchQueue.main.async {

                        completion?(url, image, error)
                    }
                }
            }

            let imageDownloader = SDWebImageDownloader.shared
            imageDownloader.config.downloadTimeout = Constants.timeoutInterval
            imageDownloader.config.maxConcurrentDownloads = 10

            _ = imageDownloader.downloadImage(with: url, options: SDWebImageDownloaderOptions.useNSURLCache, progress: progressClosure, completed: completionClosure)
        }
    }

    private func save(_ image: UIImage, toCacheWith url: URL) {

        let key = SDWebImageManager.shared.cacheKey(for: url)

        SDImageCache.shared.store(image, forKey: key)

        guard let imagePath = SDImageCache.shared.cachePath(forKey: key), let modificationDate = self.fileUpdateDate(at: url) else { return }

        let attributes = [FileAttributeKey.modificationDate: modificationDate]

        do {

            try FileManager.default.setAttributes(attributes, ofItemAtPath: imagePath)

        } catch let error as NSError {

            print(error.localizedDescription)
        }
    }

    private func loadImageFromCache(with url: URL) -> UIImage? {

        let key = SDWebImageManager.shared.cacheKey(for: url)
        let sharedCache = SDImageCache.shared

        var shouldLoadFromCache = false

        if sharedCache.diskImageDataExists(withKey: key) {

            shouldLoadFromCache = !self.shouldDownloadFile(from: url, withExistingFilePath: sharedCache.cachePath(forKey: key))
        }

        return shouldLoadFromCache ? sharedCache.imageFromDiskCache(forKey: key) : nil
    }

    private func loadImageFromCache(with url: URL, synchronously: Bool, completion: @escaping (UIImage?) -> Void) {

        if synchronously {

            completion(self.loadImageFromCache(with: url))

        } else {

            self.imageLoadingQueue.addOperation {

                completion(self.loadImageFromCache(with: url))
            }
        }
    }
}
