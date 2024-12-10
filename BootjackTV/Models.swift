//
//  Models.swift
//  BootjackTV
//
//

import Foundation

struct AlbumResponse: Codable {
    struct Album: Codable, Identifiable, Hashable {
        struct MetaData: Codable, Hashable {
            struct Connection: Codable, Hashable {
                struct Video: Codable, Hashable {
                    let uri: String
                }
                let videos: Video
            }
            let connections: Connection
        }
        var id: String { uri }
        let name: String
        let description: String
        let uri: String
        let metadata: MetaData
        var videoListURI: String {metadata.connections.videos.uri}
    }
    let total: Int
    let perPage: Int
    let page: Int
    let data: [Album]
    var hasMorePages: Bool { page * perPage < total }
}
struct VideoResponse: Codable {
    struct Video: Codable, Identifiable, Hashable {
        struct Thumbnail: Codable, Hashable {
            let baseLink: String?
        }
        struct File: Codable, Hashable {
            let quality: String
            let rendition: String
            let link: String
        }
        var id: String { uri }
        let name: String?
        let description: String?
        let pictures: Thumbnail?
        var thumbnail: String? {
            pictures?.baseLink
        }
        let uri: String
        let duration: Double
        let language: String?
        let releaseTime: String?
        let files: [File]
        var playbackURI: String? {
            for file in files {
                if file.quality == "hls" {
                    return file.link
                } else if file.quality == "hd", file.rendition == "1080p" {
                    return file.link
                } else if file.quality == "sd", file.rendition == "360p" {
                    return file.link
                }
            }
            return nil
        }
    }
    let total: Int
    let perPage: Int
    let page: Int
    let data: [Video]
    var hasMorePages: Bool { page * perPage < total }
}
