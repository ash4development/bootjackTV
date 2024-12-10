//
//  VideoManager.swift
//  BootjackTV
//
//

import Foundation

class VideoManager {
    actor VideoManagerCache {
        private(set) var videos: [String: Set<VideoResponse.Video>] = [:]
        // The last video response for the uri
        private(set) var videoResponse: [String: VideoResponse] = [:]
        
        func cache(_ videoResponse: VideoResponse, for uri: String) {
            self.videoResponse[uri] = videoResponse
            if let cachedVideos = videos[uri] {
                self.videos[uri] = Set(Array(cachedVideos) + videoResponse.data)
            } else {
                self.videos[uri] = Set(videoResponse.data)
            }
        }
    }
    static let shared = VideoManager()
    private let cache = VideoManagerCache()
    func getVideos(for uri: String) async throws -> [VideoResponse.Video] {
        if let cachedVideos = await cache.videos[uri] {
            return Array(cachedVideos)
        }
        return []
    }
    func fetchVideosIfNeeded(for uri: String) async throws {
        let cachedVideoResponse = await cache.videoResponse[uri]
        if let videoResponse = cachedVideoResponse, !videoResponse.hasMorePages {
            return
        }
        
        let page: Int = if cachedVideoResponse?.hasMorePages ?? false {
            (cachedVideoResponse?.page ?? 0) + 1
        } else {
            1
        }
        do {
            let videoResponse = try await DataLoader.getVideos(uri: uri, page: page)
            await cache.cache(videoResponse, for: uri)
        } catch {
            print("Error fetching videos: \(error)")
            return
        }
    }
}
