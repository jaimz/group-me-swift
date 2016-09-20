//
//  MessageCollectionFlowLayout.swift
//  GMT
//
//  Created by James O'Brien on 13/07/2016.
//  Copyright © 2016 James O'Brien. All rights reserved.
//

import UIKit

class MessageCollectionFlowLayout: UICollectionViewFlowLayout {

    override init() {
        super.init()
        setupMetrics()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupMetrics()
    }

    override func prepareLayout() {
        let collectionViewWidth = self.collectionView?.bounds.size.width ?? 0
        self.itemSize = CGSize(width: collectionViewWidth, height: 100)

        super.prepareLayout()
    }

    private func setupMetrics() {
        self.minimumLineSpacing = 0
        self.minimumInteritemSpacing = 0
    }

}
