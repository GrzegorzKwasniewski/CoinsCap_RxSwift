//
//  CoinsDetailsVC.swift
//  CoinsCap_RxSwift
//

import UIKit
import SwiftyJSON

class CoinsDetailsVC: UIViewController {
    
    @IBOutlet weak var coinName: UILabel!
    @IBOutlet weak var coinValue: UILabel!
    
    var singleCoin = Coin(coinData: JSON())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        coinName.text = singleCoin.coinName
        coinValue.text = singleCoin.coinPrice
    }
    
}
