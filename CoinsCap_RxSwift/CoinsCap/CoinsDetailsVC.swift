//
//  CoinsDetailsVC.swift
//  CoinsCap_RxSwift
//
//  Created by Grzegorz Kwasniewski on 17/05/2018.
//

import UIKit
import RxSwift
import SwiftyJSON

class CoinsDetailsVC: UIViewController {
    
    @IBOutlet weak var coinName: UILabel!
    @IBOutlet weak var coinValue: UILabel!
    
    let disposeBag = DisposeBag()
    
    private let coinOfTheDay = Variable(Coin())
    
    var selectedCoin: Observable<Coin> {
        return coinOfTheDay.asObservable()
    }
    
    var singleCoin = Coin(coinData: JSON())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        coinName.text = singleCoin.coinName
        coinValue.text = singleCoin.coinPrice
    }
    
    @IBAction func setCoinOfTheDay(_ sender: UIButton) {
        coinOfTheDay.value = singleCoin

        self.showMessage("Coin \(singleCoin.coinName) was selected", description: "")

    }

    func showMessage(_ title: String, description: String) {
        let alert = UIAlertController(title: title, message: description, preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Close", style: .default, handler: { _ in

            self.dismiss(animated: true, completion: nil)
        }))

        self.present(alert, animated: true, completion: nil)
    }
}
