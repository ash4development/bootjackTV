//
//  NetworkManager.swift
//
//

import Foundation
import Alamofire
import AlamofireImage
import UIKit

enum NetworkManager {
    static func hitAPI<ModelClass: Codable>(
        url: String,
        parameters: [String: Any]? = nil,
        method: HTTPMethod,
        headers: [String: String] = [:]) async throws -> ModelClass {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            async let dataTask = AF.request(
                url,
                method: method,
                parameters: parameters,
                headers: HTTPHeaders(headers)
            )
                .validate()
                .responseString(completionHandler: { responseString in
                    //print(responseString.value ?? "No value")
                })
                .serializingDecodable(
                    ModelClass.self,
                    decoder: decoder)
                
            let response = await dataTask.response
            switch response.result {
            case .success(let value):
                return value
            case .failure(let error):
                throw error
            }
            
        }
    
    static func errorMessage(from error: Error) -> String {
        if let afError = error as? AFError {
            if case .sessionTaskFailed(let error) = afError {
                if (error as NSError).code == NSURLErrorNotConnectedToInternet {
                    return "The Internet connection appears to be offline. Please check your connection and try again."
                }
            }
            return afError.localizedDescription
        }
        return "Unable to fetch content. Please try after sometime."
    }
}
extension UIImageView {
    func cancelLoadingImage() {
        af.cancelImageRequest()
    }
    func loadImage(url: String, resizeImage: Bool = true) {
        af.setImage(
            withURL: URL(string: url)!,
            completion:  {[weak self] response in
                guard let self else {
                    return
                }
                switch response.result {
                case .success(let image):
                    if resizeImage {
                        let size = CGSize(
                            width: bounds.size.width * UIScreen.main.scale,
                            height: bounds.size.height * UIScreen.main.scale
                        )
                        self.image = image.preparingThumbnail(of: size)
                        self.contentMode = .scaleAspectFill
                    } else {
                        self.image = image
                    }
                    
                case .failure(_):
                    print("")
                }
            })
    }
}
