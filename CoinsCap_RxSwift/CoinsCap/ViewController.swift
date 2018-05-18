//
//  ViewController.swift
//  CoinsCap_RxSwift
//
//  Created by Grzegorz Kwasniewski on 17/05/2018.
//

import UIKit
import RxSwift

class ViewController: UITableViewController {
    
    fileprivate let coins = Variable<[Coin]>([])
    fileprivate let bag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Coins Market Cap"

        setupRefreshControll()

    }
    
    func setupRefreshControll() {
        
        self.refreshControl = UIRefreshControl()
        let refreshControl = self.refreshControl!
        
        refreshControl.backgroundColor = UIColor(white: 0.98, alpha: 1.0)
        refreshControl.tintColor = UIColor.darkGray
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        
    }
    
    @objc func refresh() {
        
    }
}

extension ViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return coins.value.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let coin = coins.value[indexPath.row]
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") else {
            return UITableViewCell()
        }
        
        cell.textLabel?.text = coin.coinName
        cell.detailTextLabel?.text = coin.coinPrice

        return cell
    }
}
