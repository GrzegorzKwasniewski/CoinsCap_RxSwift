//
//  Coin.swift
//  CoinsCap_RxSwift
//
//  Created by Grzegorz Kwasniewski on 18/05/2018.
//

import Foundation
import SwiftyJSON

struct Coin: Decodable {
    
    private(set) var coinName: String
    private(set) var coinPrice: String
    
    init(coinData: JSON) {
        coinName = coinData.dictionary?["name"]?.string ?? "no data"
        coinPrice = coinData.dictionary?["price_usd"]?.string ?? "no data"
    }
}
