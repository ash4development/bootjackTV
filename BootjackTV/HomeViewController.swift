//
//  HomeViewController.swift
//  BootjackTV
//
//

import UIKit
import AVKit

class HomeViewController: UIViewController {
    @IBOutlet var collectionView: UICollectionView! {
        didSet {
            collectionView.clipsToBounds = true
        }
    }
    @IBOutlet var selectedTitleLabel: UILabel! {
        didSet {
            selectedTitleLabel.text = nil
        }
    }
    @IBOutlet var selectedDescriptionLabel: UILabel! {
        didSet {
            selectedDescriptionLabel.text = nil
        }
    }
    @IBOutlet var selectedImageView: RadialGradientImageView!
    @IBOutlet var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet var logoImageView: UIImageView! {
        didSet {
            logoImageView.isHidden = true
        }
    }
    let sectionTitleKey = UICollectionView.elementKindSectionHeader
    let focusGuide = UIFocusGuide()
    var currentAlbumPage: Int = 1
    @MainActor
    var dataSource: UICollectionViewDiffableDataSource<AlbumResponse.Album, VideoResponse.Video>!
    var currentSnapshot: NSDiffableDataSourceSnapshot<AlbumResponse.Album, VideoResponse.Video>!
    var lastAlbumResponse: AlbumResponse?
    lazy var videoPlayerVC = AVPlayerViewController()
    lazy var player = AVPlayer()
    var isPlayingIntro = true
    override func viewDidLoad() {
        super.viewDidLoad()
        listenForPlayerCompletion()
        setupDataSource()
        addFocusGuide()
        collectionView.collectionViewLayout = createLayout()
        activityIndicatorView.isHidden = false
        
        Task {
            await self.getsAlbums()
        }
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isPlayingIntro {
            playLaunchVideo()
        }
    }
    func playLaunchVideo() {
        guard let videoUrl = Bundle.main.path(forResource: "bootjack", ofType: "mp4") else {
            return
        }
        player = AVPlayer(url: URL(fileURLWithPath: videoUrl))
        videoPlayerVC.player = player
        videoPlayerVC.delegate = self
        videoPlayerVC.showsPlaybackControls = false
        present(videoPlayerVC, animated: false) {
            self.logoImageView.isHidden = false
            self.player.play()
        }
    }
    func addFocusGuide() {
        view.addLayoutGuide(focusGuide)
        NSLayoutConstraint.activate([
            focusGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            focusGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            focusGuide.topAnchor.constraint(equalTo: view.topAnchor),
            focusGuide.bottomAnchor.constraint(equalTo: collectionView.topAnchor)
        ])
        focusGuide.preferredFocusEnvironments = [collectionView]
    }
    
    func createLayout() -> UICollectionViewLayout {
        let sectionProvider = { (sectionIndex: Int,
            layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                 heightDimension: .fractionalHeight(1.0))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1/4.25),
                                                  heightDimension: .absolute(250))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

            let section = NSCollectionLayoutSection(group: group)
            section.orthogonalScrollingBehavior = .continuous
            section.interGroupSpacing = 40
            section.contentInsets = NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)

            let titleSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                  heightDimension: .estimated(44))
            let titleSupplementary = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: titleSize,
                elementKind: self.sectionTitleKey,
                alignment: .top)
            section.boundarySupplementaryItems = [titleSupplementary]
            return section
        }

        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.interSectionSpacing = 20

        let layout = UICollectionViewCompositionalLayout(
            sectionProvider: sectionProvider, configuration: config)
        return layout
    }
    func setupDataSource() {
        dataSource = UICollectionViewDiffableDataSource<AlbumResponse.Album, VideoResponse.Video>(collectionView: collectionView) { collectionView, indexPath, video in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! ImageCell
            if let thumbnailURL = video.thumbnail {
                cell.fetchImage(url: thumbnailURL)
            }
            cell.imageView.backgroundColor = .lightGray.withAlphaComponent(0.5)
            cell.imageView.layer.cornerRadius = 10
            cell.imageView.clipsToBounds = true
            return cell
        }
        
        dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
            let header = self.collectionView.dequeueReusableSupplementaryView(ofKind: self.sectionTitleKey, withReuseIdentifier: "SectionHeaderView", for: indexPath) as! SectionHeaderView
            let album = self.currentSnapshot.sectionIdentifiers[indexPath.section]
            let title = album.name
            header.titleLabel.text = title
            return header
        }
        currentSnapshot = NSDiffableDataSourceSnapshot
        <AlbumResponse.Album, VideoResponse.Video>()
    }
    func getsAlbums() async {
        do {
            let albumResponse = try await DataLoader.getAlbums(page: currentAlbumPage)
            lastAlbumResponse = albumResponse
            var videosUrls: [String] = []
            for album in albumResponse.data {
                videosUrls.append(album.videoListURI)
                currentSnapshot.appendSections([album])
                if let videos = try? await VideoManager.shared.getVideos(for: album.videoListURI) {
                    currentSnapshot.appendItems(videos, toSection: album)
                }
            }
            await fetchVideos(videoUrls: videosUrls, albumResponse: albumResponse)
        } catch {
            let errorMsg = NetworkManager.errorMessage(from: error)
            let alert = UIAlertController(title: "Error", message: errorMsg, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
    func fetchVideos(videoUrls: [String], albumResponse: AlbumResponse) async {
        await withTaskGroup(of: Void.self) { taskGroup in
            for videoUrl in videoUrls {
                taskGroup.addTask {
                    try? await VideoManager.shared.fetchVideosIfNeeded(for: videoUrl)
                }
            }
        }
        for album in albumResponse.data {
            guard let videos = try? await VideoManager.shared.getVideos(for: album.videoListURI) else {
                continue
            }
            currentSnapshot.appendItems(videos, toSection: album)
        }
        await dataSource.apply(currentSnapshot)
        activityIndicatorView.isHidden = true
    }
}
extension HomeViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didUpdateFocusIn context: UICollectionViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        if let indexPath = context.previouslyFocusedIndexPath,
           let cell = collectionView.cellForItem(at: indexPath) {
            UIView.animate(withDuration: 0.3) {
                cell.transform = .identity
                cell.layer.borderWidth = 0
            }
        }

        if let indexPath = context.nextFocusedIndexPath,
           let cell = collectionView.cellForItem(at: indexPath) {
            UIView.animate(withDuration: 0.3) {
                cell.transform3D = CATransform3DMakeScale(1.18, 1.18, 1.5)
                cell.layer.cornerRadius = 10
                cell.layer.borderColor = UIColor.white.cgColor
                cell.layer.borderWidth = 5
            }
            collectionView.bringSubviewToFront(cell)
            showFocusedVideo(indexPath: indexPath)
        }
    }
    func showFocusedVideo(indexPath: IndexPath) {
        let album = currentSnapshot.sectionIdentifiers[indexPath.section]
        let video = currentSnapshot.itemIdentifiers(inSection: album)[indexPath.row]
        selectedImageView.cancelLoadingImage()
        selectedTitleLabel.text = video.name
        selectedDescriptionLabel.text = video.description
        if let thumbnailURL = video.thumbnail {
            selectedImageView.loadImage(url: thumbnailURL)
        }
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let album = currentSnapshot.sectionIdentifiers[indexPath.section]
        let video = currentSnapshot.itemIdentifiers(inSection: album)[indexPath.row]
        guard let urlStr = video.playbackURI, let url = URL(string: urlStr) else { return }
        player = AVPlayer(url: url)
        videoPlayerVC.player = player
        present(videoPlayerVC, animated: true) {
            self.player.play()
        }
    }
}
extension HomeViewController {
    func listenForPlayerCompletion() {
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
    }
    @objc func playerDidFinishPlaying() {
        videoPlayerVC.dismiss(animated: true)
        if isPlayingIntro {
            videoPlayerVC.showsPlaybackControls = true
            isPlayingIntro = false
        }
    }
}
extension HomeViewController: AVPlayerViewControllerDelegate {
    func playerViewControllerShouldDismiss(_ playerViewController: AVPlayerViewController) -> Bool {
        !isPlayingIntro
    }
}
