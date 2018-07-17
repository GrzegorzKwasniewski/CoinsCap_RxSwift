//
//  ViewController.swift
//  CoinsCap_RxSwift
//
//  Created by Grzegorz Kwasniewski on 17/05/2018.
//

import UIKit
import RxSwift
import RxCocoa
import SwiftyJSON

class MainViewVC: UITableViewController {
    
    @IBOutlet weak var coinLabel: UILabel!
    
    fileprivate let coins = Variable<[Coin]>([])
    fileprivate let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Coins Market Cap"
        
        tableView.dataSource = self
        tableView.delegate = self

        setupRefreshControll()
        
        getCurrentCoinsCap(fromURL: "https://api.coinmarketcap.com/v1/ticker/")

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("Resource count \(RxSwift.Resources.total)")
    }
    
    func setupRefreshControll() {
        
        self.refreshControl = UIRefreshControl()
        let refreshControl = self.refreshControl!
        
        refreshControl.backgroundColor = .white
        refreshControl.tintColor = .blue
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(refreshCoins), for: .valueChanged)
        
    }
    
    func getCurrentCoinsCap(fromURL url: String) {
        
          let response = Observable.just(url)
            .map { url -> URL in
                return URL(string: url)!
            }.map { url -> URLRequest in
                return URLRequest(url: url)
            }.flatMap { request -> Observable<(response: HTTPURLResponse, data: Data)> in
                
                print("Are we on main thread: \(Thread.isMainThread)")
                
                return URLSession.shared.rx.response(request: request)
        }.share(replay: 1)
        
        // W tym momemncie kod pobierania z serwera nie jest jeszcze wykonywany. Będzie dopiero w momencie zapisania się jakiegoś obiektu.
        filterSuccessResponse(response)
        
        filterErrorResponse(response)
    }
    
    func filterSuccessResponse(_ response: Observable<(response: HTTPURLResponse, data: Data)>) {

        response
                .observeOn(MainScheduler.instance)
                .filter { response, _ in
                
                print("main: \(Thread.isMainThread)")

                return 200..<300 ~= response.statusCode
            }.map { _, data -> JSON in

                do {
                    let json = try JSON(data: data)
                    
                    return json
                } catch (let error) {
                    
                    print("Error \(error.localizedDescription)")
                    
                    return JSON()
                }
                
            }.filter { objects in
                return objects.count > 0
            }.map { objects -> [Coin] in
                
                if let dataObjects = objects.array {
                    return dataObjects.map {
                        Coin(coinData: $0)
                    }
                } else {
                    return [Coin(coinData: JSON())]
                }
            }.subscribe(onNext: { [weak self] coins in
                self?.updateUIWithCoins(coinsCollection: coins)
            })
            .disposed(by: disposeBag)
    }
    
    func filterErrorResponse(_ response: Observable<(response: HTTPURLResponse, data: Data)>) {
        
        response
                .observeOn(MainScheduler.instance)
                .filter { response, _ in

                    return 400..<600 ~= response.statusCode

                }.flatMap { response, _ -> Observable<Int> in
                
                print("Are we on main thread? : \(Thread.isMainThread)")

                return Observable.just(response.statusCode)
            }.subscribe(onNext: { [weak self] statusCode in
                self?.showMessage("Something is wrong", description: "\(statusCode)")
            }).disposed(by: disposeBag)
        
    }
    
    func updateUIWithCoins(coinsCollection: [Coin]) {

        self.coins.value = coinsCollection

        self.tableView.reloadData()
        self.refreshControl?.endRefreshing()

    }
    
    @objc func refreshCoins() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.getCurrentCoinsCap(fromURL: "https://api.coinmarketcap.com/v1/ticker/")
        }
    }
    
    func showMessage(_ title: String, description: String) {
        let alert = UIAlertController(title: title, message: description, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Close", style: .default, handler: { _ in
            
            self.dismiss(animated: true, completion: nil)
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
}

extension MainViewVC {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return coins.value.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let coin = coins.value[indexPath.row]
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "CoinCell") else {
            return UITableViewCell()
        }
        
        cell.textLabel?.text = coin.coinName
        cell.detailTextLabel?.text = coin.coinPrice

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let coin = coins.value[indexPath.row]
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let coinsDetailsVC = storyboard.instantiateViewController(withIdentifier: "CoinsDetailsVC") as! CoinsDetailsVC
        coinsDetailsVC.singleCoin = coin
        
        coinsDetailsVC.selectedCoin
            .subscribe(onNext: { [weak self] (selectedCoin) in
                
                self?.coinLabel.text = selectedCoin.coinName

                }, onError: { (error) in
                    print("Error was emited.")
            }, onCompleted: {
                print("onCompleted event was emited")
            }) {
                print("onDisposed event was emited")
            }.disposed(by: coinsDetailsVC.disposeBag)

        
        navigationController?.pushViewController(coinsDetailsVC, animated: true)
        
    }
}
