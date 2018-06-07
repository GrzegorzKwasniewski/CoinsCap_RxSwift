//
//  CoinsDetailsVC.swift
//  CoinsCap_RxSwift
//

import UIKit
import RxSwift
import SwiftyJSON

class CoinsDetailsVC: UIViewController {
    
    @IBOutlet weak var coinName: UILabel!
    @IBOutlet weak var coinValue: UILabel!
    
    let disposeBag = DisposeBag()
    
    private let coinOfTheDay = PublishSubject<Coin>()
    
    var selectedCoin: Observable<Coin> {
        return coinOfTheDay.asObservable()
    }
    
    var singleCoin = Coin(coinData: JSON())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        coinName.text = singleCoin.coinName
        coinValue.text = singleCoin.coinPrice
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        coinOfTheDay.onCompleted()
    }
    
    @IBAction func setCoinOfTheDay(_ sender: UIButton) {
        coinOfTheDay.onNext(singleCoin)
    }
}
