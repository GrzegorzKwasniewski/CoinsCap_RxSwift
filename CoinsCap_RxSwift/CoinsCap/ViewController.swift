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

class ViewController: UITableViewController {
    
    fileprivate let coins = Variable<[Coin]>([])
    fileprivate let bag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Coins Market Cap"
        
        tableView.dataSource = self
        tableView.delegate = self

        setupRefreshControll()
        
        getCurrentCoinsCap(fromURL: "https://api.coinmarketcap.com/v1/ticker/")

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
        
        // 1 krok - czy "from" jest tu potrzebne - sprawdzić inne możlwiości
        // Jeżeli to jest kolekcja, to czy w przypadku większej ilości elementów
        // dla każdego zostanie wykonany ten sam zestaw operacji?
        
          let response = Observable.from([url])
            .map { url -> URL in // 2 krok
                return URL(string: url)!
            }.map { url -> URLRequest in // 3 krok
                return URLRequest(url: url)
            }.flatMap { request -> Observable<(response: HTTPURLResponse, data: Data)> in // 4 krok
                
                print("main: \(Thread.isMainThread)")
                
                return URLSession.shared.rx.response(request: request) // wykonanie tej funkcji oznacza odebranie danych z serwera
        }.share(replay: 1)
        
        // operacja wykonywana już po odebraniu danych z serwera
        filterSuccesResponse(response)
        
        filterErrorResponse(response)
    }
    
    func filterSuccesResponse(_ response: Observable<(response: HTTPURLResponse, data: Data)>) {
        response
            .filter { response, _ in
                
                print("main: \(Thread.isMainThread)")

                return 200..<300 ~= response.statusCode // operattora używamy z "rangem" - jak range jest po lewej to sprawdzane jest, czy wartość po prawej w nim się znajduje
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
            .disposed(by: bag)
    }
    
    func filterErrorResponse(_ response: Observable<(response: HTTPURLResponse, data: Data)>) {
        
        response
            .filter {response, _ in
                return 400..<600 ~= response.statusCode
            }.flatMap { response, _ -> Observable<Int> in
                
                print("main: \(Thread.isMainThread)")

                return Observable.just(response.statusCode)
            }.subscribe(onNext: { [weak self] statusCode in
                self?.showAlert("Something is wrong", description: "\(statusCode)")
            })
            .disposed(by: bag)
        
    }
    
    func updateUIWithCoins(coinsCollection: [Coin]) {

        self.coins.value = coinsCollection
        
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
            self?.refreshControl?.endRefreshing()
        }
    }
    
    @objc func refreshCoins() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.getCurrentCoinsCap(fromURL: "https://api.coinmarketcap.com/v1/ticker/")
        }
    }
    
    func showAlert(_ title: String, description: String) -> Observable<Void> {
        return Observable.create({ [weak self] observer in
            
            let alert = UIAlertController(title: title, message: description, preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Close", style: .default, handler: { _ in
                
                observer.onCompleted()
                
                }
            ))
            
            self?.present(alert, animated: true, completion: nil)
            
            // W momencie anulowania subskrypcji, alert zostanie porawnie zamknięty.
            
            return Disposables.create {
                self?.dismiss(animated: true, completion: nil)
            }
        })
    }
}

extension ViewController {
    
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
}
