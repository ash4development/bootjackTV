//
//  DataLoader.swift
//  BootjackTV
//
//

import Foundation

enum DataLoader {
    static func getAlbums(page: Int) async throws -> AlbumResponse {
        let endpoint = Endpoints.albums(page)
        return try await NetworkManager.hitAPI(url: endpoint.url, method: .get, headers: endpoint.header)
    }
    static func getVideos(uri: String, page: Int) async throws -> VideoResponse {
        let endPoint = Endpoints.videos(uri, page)
        //print("Video url \(endPoint.url)")
        return try await NetworkManager.hitAPI(url: endPoint.url, method: .get, headers: endPoint.header)
    }
}
enum Endpoints {
    case albums(Int),
         videos(String, Int)
    
    var baseURL: String {
        "https://api.vimeo.com"
    }
    
    var path: String {
        switch self {
        case .albums(let pageNumber):
            return "/me/albums?page=\(pageNumber)"
        case .videos(let uri, let pageNumber):
            return "\(uri.hasPrefix("/") ? "" : "/")\(uri)?page=\(pageNumber)"
        }
    }
    
    var url: String {
        baseURL + path
    }
    
    var header: [String: String] {
        ["Authorization": "Bearer c004c97057c60d626a88d7a16fe46e40"]
    }
}
