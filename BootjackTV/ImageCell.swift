//
//  ImageCell.swift
//  BootjackTV
//
//

import UIKit

class ImageCell: UICollectionViewCell {
    @IBOutlet var imageView: UIImageView!
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.cancelLoadingImage()
    }
    func fetchImage(url: String) {
        imageView.loadImage(url: url)
    }
}
