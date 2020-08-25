//
//  ViewController.swift
//  Compositional-Layout-Combine
//
//  Created by Kelby Mittan on 8/25/20.
//  Copyright © 2020 Kelby Mittan. All rights reserved.
//

import UIKit
import Combine

class PhotoSearchController: UIViewController {
    
    enum SectionKind: Int, CaseIterable {
        case main
    }
    
    private var collectionView: UICollectionView!
    
    typealias DataSource = UICollectionViewDiffableDataSource<SectionKind,Int>
    
    private var dataSource: DataSource!
    
    private var searchController: UISearchController!
    
    
    @Published private var searchText = ""
    
    // store subscriptions
    private var subsriptions: Set<AnyCancellable> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Photo Search"
        view.backgroundColor = .systemBackground
        
        configureCollectionView()
        configureDataSource()
        configSearchController()
        
        $searchText
            .debounce(for: .seconds(1.0), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { (text) in
                print(text)
                // call the api
                self.searchPhotos(for: text)
        }
        .store(in: &subsriptions)
    }
    
    private func searchPhotos(for query: String) {
        APIClient().searchPhotos(for: query)
            .sink(receiveCompletion: { (completion) in
                print(completion)
            }) { (photos) in
                dump(photos)
        }
        .store(in: &subsriptions)
    }
    
    private func configSearchController() {
        searchController = UISearchController(searchResultsController: nil)
        navigationItem.searchController = searchController
        searchController.searchResultsUpdater = self // delegate
        searchController.searchBar.autocapitalizationType = .none
        searchController.obscuresBackgroundDuringPresentation = false
    }
    
    private func configureCollectionView() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        collectionView.backgroundColor = .systemBackground
        collectionView.register(ImageCell.self, forCellWithReuseIdentifier: ImageCell.reuseIdentifier)
        collectionView.autoresizingMask = [.flexibleWidth,.flexibleHeight]
        view.addSubview(collectionView)
    }
    
    
    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            
            // item
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            let itemSpacing: CGFloat = 5
            item.contentInsets = NSDirectionalEdgeInsets(top: itemSpacing, leading: itemSpacing, bottom: itemSpacing, trailing: itemSpacing)
            
            // group (leadingGroup, trailingGroup, nestedGroup)
            let innerGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .fractionalHeight(1.0))
            let leadingGroup = NSCollectionLayoutGroup.vertical(layoutSize: innerGroupSize, subitem: item, count: 2)
            let trailingGroup = NSCollectionLayoutGroup.vertical(layoutSize: innerGroupSize, subitem: item, count: 3)
            let nestedGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(1000))
            let nestedGroup = NSCollectionLayoutGroup.horizontal(layoutSize: nestedGroupSize, subitems: [leadingGroup,trailingGroup])
            
            // section
            let section = NSCollectionLayoutSection(group: nestedGroup)
            return section
        }
        
        return layout
    }
    
    private func configureDataSource() {
        dataSource = DataSource(collectionView: collectionView, cellProvider: { (collectionView, indexPath, item) -> UICollectionViewCell? in
            
            // configure cell and return cell
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageCell.reuseIdentifier, for: indexPath) as? ImageCell else {
                fatalError("could not dequeue")
            }
            cell.backgroundColor = .systemTeal
            cell.layer.cornerRadius = 12
            return cell
        })
        
        
        var snapshot = dataSource.snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(Array(1...7))
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}

extension PhotoSearchController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text, !text.isEmpty else {
            return
        }
        searchText = text
    }
    
}
