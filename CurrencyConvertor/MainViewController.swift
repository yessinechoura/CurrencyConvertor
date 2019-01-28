//
//  ViewController.swift
//  CurrencyConvertor
//
//  Created by Yessine on 1/27/19.
//  Copyright © 2019 Choura Yessine. All rights reserved.
//

import UIKit
import CoreData

class MainViewController: UIViewController {

    var currencyRates: [String : Float] = [:]
    let topView = UIView()
    let valueTextField = UITextField()
    var newDesiredAmout = "100"
    let fromCurrencyLabel = UILabel()
    let cellId = "rate.cell"
    let ratesTableView = UITableView()
    let refreshControl = UIRefreshControl()
    let currencyRatesStatus = "currencyRatesLoaded"
    let currencyRatesEntity = "CurrencyRate"
    let currencyAttribute = "currency"
    let rateAttribute = "rate"
    var fromRate = "USD"
    var timer: Timer!
    // The free plan is limited that's why I'm refreshing every 60 seconds
    let refreshTimer = 60.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        NotificationCenter.default.addObserver(self, selector: #selector(statusManager), name: .flagsChanged, object: Network.reachability)
        
        
        // Checking network connectivity and deciding between loading from Core Data or Internet
        guard let status = Network.reachability?.status else { return }
        switch status {
        case .unreachable:
            
            //Check if there's some stored data
            if UserDefaults.standard.bool(forKey: currencyRatesStatus) {
                print("fetching from local")
                setupView()
                fetchLocalCurrencyRates()
            } else {
                //No data!!
                print("unable to fetch")
                let errorLabel = UILabel(frame: view.bounds)
                view.addSubview(errorLabel)
                errorLabel.textAlignment = .center
                errorLabel.text = "No internet nor stored data!"
            }
        default:
            //Load new data
            print("fetching from net")
            setupView()
            fetchCurrencyRates()
        }
    }
    
    @objc func statusManager(_ notification: Notification) {
        
        guard let status = Network.reachability?.status else { return }
        switch status {
        case .unreachable:
            // Stopping timer when there's no more internet connectivity
            print("no connection, invalidating timer")
            timer.invalidate()
        default:
            print("refreshing each 60 sec")
            // If it's empty then it means that there was no connection nor stored data and we need to refresh as soon as we get connected
            if currencyRates.isEmpty {
                // We need to remove that error label
                view.subviews[0].removeFromSuperview()
                // Now we need to set up the view
                setupView()
                // And finally fetch data =D
                fetchCurrencyRates()
            }
            timer = Timer.scheduledTimer(timeInterval: refreshTimer, target: self, selector: #selector(fetchCurrencyRates), userInfo: nil, repeats: true)
        }
    }
    
    func setupView() {
        
        // Setting up button and text field
        setupTopView()
        
        // Setting up the table view
        setupRatesTableView()
    }
    
    func setupTopView() {
        
        view.addSubview(topView)
        // Applying auto layout constraints for the holder of both, the label and the text field
        topView.translatesAutoresizingMaskIntoConstraints = false
        topView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.08).isActive = true
        topView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        topView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        topView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor).isActive = true
        topView.layoutIfNeeded()
        // Applying a border
        topView.layer.addBorder(edge: .bottom, width: view.frame.width)
        topView.layer.addBorder(edge: .top, width: view.frame.width)
        
        setupfromCurrencyLabel()
        
        setupValueTextField()
    }
    
    func setupfromCurrencyLabel() {
        
        topView.addSubview(fromCurrencyLabel)
        // Applying auto layout constraints for the label
        fromCurrencyLabel.translatesAutoresizingMaskIntoConstraints = false
        fromCurrencyLabel.topAnchor.constraint(equalTo: topView.topAnchor).isActive = true
        fromCurrencyLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor).isActive = true
        fromCurrencyLabel.widthAnchor.constraint(equalTo: topView.widthAnchor, multiplier: 0.1).isActive = true
        fromCurrencyLabel.heightAnchor.constraint(equalTo: topView.heightAnchor).isActive = true
        fromCurrencyLabel.text = fromRate
        fromCurrencyLabel.textColor = .black
    }
    
    func setupValueTextField() {
        
        topView.addSubview(valueTextField)
        valueTextField.delegate = self
        // Applying auto layout constraints for the text field
        valueTextField.translatesAutoresizingMaskIntoConstraints = false
        valueTextField.centerYAnchor.constraint(equalTo: topView.centerYAnchor).isActive = true
        valueTextField.widthAnchor.constraint(equalTo: topView.widthAnchor, multiplier: 0.75).isActive = true
        valueTextField.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor).isActive = true
        valueTextField.heightAnchor.constraint(equalTo: topView.heightAnchor, multiplier: 0.6).isActive = true
        // Settings..
        valueTextField.placeholder = "Pick a number"
        valueTextField.text = newDesiredAmout
        valueTextField.borderStyle = .roundedRect
        valueTextField.keyboardType = .numberPad
        valueTextField.textAlignment = .right
        valueTextField.layer.borderColor = UIColor.black.cgColor
        valueTextField.layer.borderWidth = 0.6
        valueTextField.layer.cornerRadius = 6
        // Text changed target
        valueTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)

    }
    
    func setupRatesTableView() {
        
        view.addSubview(ratesTableView)
        ratesTableView.delegate = self
        ratesTableView.dataSource = self
        // Applying auto layout constraints for the table view
        ratesTableView.register(UITableViewCell.self, forCellReuseIdentifier: cellId)
        ratesTableView.translatesAutoresizingMaskIntoConstraints = false
        ratesTableView.topAnchor.constraint(equalTo: fromCurrencyLabel.bottomAnchor).isActive = true
        ratesTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        ratesTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        ratesTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        // Settings
        ratesTableView.separatorStyle = .none
        ratesTableView.keyboardDismissMode = .interactive
        // Pull to refresh target
        refreshControl.addTarget(self, action: #selector(refreshTableView), for: .valueChanged)
        ratesTableView.addSubview(refreshControl)
    }
    
    @objc func refreshTableView() {
        // Pull to refresh action
        // If there's no internet connection then there's no point in refreshing, that's why we have to check connectivity
        guard let status = Network.reachability?.status else { return }
        switch status {
        case .unreachable:
            // No Internet
            refreshControl.endRefreshing()
            showSimpleAlert(alertMessage: "No internet connection!")
        default:
            refreshControl.beginRefreshing()
            // Connected to the internet
            // Fetching currency rates
            fetchCurrencyRates()
        }
    }
    
    func calculateRates(to: String, value: Double) -> Double {
        if self.fromRate == to {
            return value
        }
        let fromRate = currencyRates[self.fromRate]
        let toRate = currencyRates[to]
        let coefficient = Double(toRate!) / Double(fromRate!)
        return value * coefficient
    }
}


// CoreData
extension MainViewController {
    
    func updateCurrencyRates() {
        
        var allDataStored = true
        
        // Saving/Updating each currency rate
        currencyRates.forEach({ (currency, value) in
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let managedContext = appDelegate.persistentContainer.viewContext
            let entity = NSEntityDescription.entity(forEntityName: currencyRatesEntity, in: managedContext)
            let currencyRate = NSManagedObject(entity: entity!, insertInto: managedContext)
            currencyRate.setValue(currency, forKey: currencyAttribute)
            currencyRate.setValue(value, forKey: rateAttribute)
            do {
                try managedContext.save()
            } catch let error {
                print("Error: ", error)
                allDataStored = false
            }
        })
        
        // Verifying if all the data has beed stored and storing a variable in the User Defauls so that we can know if there's a stored data on the next login
        if allDataStored {
            UserDefaults.standard.set(true, forKey: currencyRatesStatus)
        }
    }
    
    func fetchLocalCurrencyRates() {
        
        // Fetching data from local storage
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: currencyRatesEntity)
        request.returnsObjectsAsFaults = false
        do {
            let result = try context.fetch(request)
            // Storing currency rates in a global variable
            for data in result as! [NSManagedObject] {
                if let currency = data.value(forKey: currencyAttribute) as? String, let rate = data.value(forKey: rateAttribute) as? Float {
                    self.currencyRates[currency] = rate
                }
            }
            // Refreshing table view
            ratesTableView.reloadData()
        } catch let error {
            print("Error: ", error)
        }
    }
}


// TextField
extension MainViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        // Delete character
        if string == "" {
            return true
        } else {
            // Checking if the added string is numeric or not
            if string.isNumeric() {
                return true
            } else {
                showSimpleAlert(alertMessage: "Only numbers are allowed!")
                return false
            }
        }
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        // If the text field is empty we will store 1 as value
        newDesiredAmout = textField.text ?? "1"
        ratesTableView.reloadData()
    }
}


// TableView
extension MainViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currencyRates.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        
        // Settings for the cell
        cell.selectionStyle = .none
        cell.layer.addBorder(edge: .bottom, width: tableView.frame.width)
        
        let toCurrency = Array(currencyRates)[indexPath.row].key
        cell.textLabel?.text = toCurrency
        
        let desiredAmout = Double(newDesiredAmout) ?? 1.0
        // Creating a number formatter and picking the required settings
        let currencyFormatter = NumberFormatter()
        currencyFormatter.usesGroupingSeparator = true
        currencyFormatter.numberStyle = .currency
        currencyFormatter.locale = NSLocale(localeIdentifier: "es_ES") as Locale
        currencyFormatter.currencyCode = toCurrency
        
        var number: NSNumber!
        // If the from-rate is USD no need to do any other instruction
        if fromRate == "USD" {
            number = NSNumber(floatLiteral: Double(Array(currencyRates)[indexPath.row].value) * desiredAmout)
        } else {
            // Since selecting a from-currecy is not included in the free plan, we need to do some instructions to figure out the rates
            number = NSNumber(floatLiteral: calculateRates(to: toCurrency, value: desiredAmout))
        }
        // Formatting the calculated number
        let convertedString = currencyFormatter.string(from: number) ?? String(Array(currencyRates)[indexPath.row].value)
        
        // Since we are using reusable cells we need to check if the right label is created or not
        if let convertedValue = cell.accessoryView as? UILabel {
            convertedValue.text = convertedString
            convertedValue.sizeToFit()
        } else {
            // Creating the right label and applying some settings
            let convertedValue = UILabel()
            convertedValue.textColor = .black
            convertedValue.textAlignment = .right
            convertedValue.text = convertedString
            convertedValue.sizeToFit()
            cell.accessoryView = convertedValue
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // Reloading the table when selecting a new from-currency
        fromRate = Array(currencyRates)[indexPath.row].key
        fromCurrencyLabel.text = fromRate
        tableView.reloadData()
    }
}


// WebService
extension MainViewController {
    
    @objc func fetchCurrencyRates() {
        
        print("Fetching data from the internet")
        // Fetching currency rates from the internet (open exchange web service)
        // Creating an URL
        if var components = URLComponents(string: OpenExchangeRatesWebService.baseUrl + OpenExchangeRatesWebService.fetchCurrencyRates) {
            // Setting the URL's parameters
            components.queryItems = [
                URLQueryItem(name: OpenExchangeRatesWebService.appIdParam, value: OpenExchangeRatesWebService.appId)
            ]
            if let url = components.url {
                let request = URLRequest(url: url)
                let task = URLSession.shared.dataTask(with: request) {(data, response, error) in
                    guard let data = data else {
                        self.refreshControl.endRefreshing()
                        self.showSimpleAlert()
                        return
                    }
                    do {
                        let latestCurrencyRates = try JSONDecoder().decode(CurrencyRates.self, from: data)
                        self.currencyRates = latestCurrencyRates.rates
                        // We are calling this methods (reloading table view and updating user interface) from a background thread that's why we need add it to the main thread
                        DispatchQueue.main.async {
                            self.ratesTableView.reloadData()
                            self.refreshControl.endRefreshing()
                            self.updateCurrencyRates()
                        }
                    } catch let error {
                        // Some error occured while decoding json
                        self.refreshControl.endRefreshing()
                        self.showSimpleAlert()
                        print("Error: ", error)
                    }
                }
                
                task.resume()
            } else {
                // Some error occured
                self.refreshControl.endRefreshing()
                self.showSimpleAlert()
            }
        } else {
            // Some error occured
            self.refreshControl.endRefreshing()
            self.showSimpleAlert()
        }
    }
}
