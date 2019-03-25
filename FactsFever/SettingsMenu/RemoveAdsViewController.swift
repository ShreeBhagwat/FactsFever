//
//  RemoveAdsViewController.swift
//  FactsFever
//
//  Created by Shree Bhagwat on 25/03/19.
//  Copyright © 2019 Development. All rights reserved.
//

import UIKit
import StoreKit
import ProgressHUD

class RemoveAdsViewController: UIViewController, SKPaymentTransactionObserver, SKProductsRequestDelegate {
    
    var product: SKProduct?
    var ProductID = "com.shreebhagwat.factsfever.RemoveAds"
    @IBOutlet weak var descriptionLabelOutlet: UILabel!
    @IBOutlet weak var removeAdsLabelOutlet: UILabel!
    @IBOutlet weak var restorePurchaseButtonOutlet: UIButton!
    @IBOutlet weak var purchaseButtonOutlet: UIButton!
    @IBOutlet weak var removeAdsImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        purchaseButtonOutlet.isEnabled = false
        restorePurchaseButtonOutlet.isEnabled = false
        restorePurchaseButtonOutlet.isHidden = true
        SKPaymentQueue.default().add(self)
        getPurchaseInfo()
        ProgressHUD.show("Getting Payment Data. Hold on")
      
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        restorePurchaseButtonOutlet.layer.cornerRadius = restorePurchaseButtonOutlet.frame.height * 0.5
        restorePurchaseButtonOutlet.clipsToBounds = true
        purchaseButtonOutlet.layer.cornerRadius = purchaseButtonOutlet.frame.height * 0.5
        purchaseButtonOutlet.clipsToBounds = true
        navigationController?.isNavigationBarHidden = false
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.isNavigationBarHidden = true
    }
    @IBAction func purchaseButtonPressed(_ sender: Any) {
        let payment = SKPayment(product: product!)
        SKPaymentQueue.default().add(payment)
    }
    
    @IBAction func restorePurchaseButtonPressed(_ sender: Any) {
        
    }
    
    func getPurchaseInfo(){
        
        if SKPaymentQueue.canMakePayments(){
            let request = SKProductsRequest(productIdentifiers: NSSet(object: self.ProductID) as! Set<String>)
            request.delegate = self
            request.start()
            ProgressHUD.dismiss()
        } else {
            ProgressHUD.dismiss()
            removeAdsLabelOutlet.text = "Warning"
            descriptionLabelOutlet.text = "Please enable in app purchases in your phone settings"
        }
        
    }
    
    
    //MARK:- Delegate Methods
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        ProgressHUD.dismiss()
        var products = response.products
        
        if(products.count == 0){
            removeAdsLabelOutlet.text = "Error"
            descriptionLabelOutlet.text = "Product not found. Check internet Connection or in app purchase settings"
        }else {
            product = products[0]
            removeAdsLabelOutlet.text = "Remove Ads"
            purchaseButtonOutlet.isEnabled = true
        }
        let invalids = response.invalidProductIdentifiers
        for product in invalids {
            removeAdsLabelOutlet.text = "Error"
            descriptionLabelOutlet.text = "Invalid Product"
        }
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            
            switch transaction.transactionState {
            case .purchased:
                SKPaymentQueue.default().finishTransaction(transaction)
                removeAdsLabelOutlet.text = "Purchase Successfull"
                descriptionLabelOutlet.text = "Thank you for your support !"
                purchaseButtonOutlet.isEnabled = false
                purchaseButtonOutlet.isHidden = true
                let save = UserDefaults.standard
                save.set(true, forKey: "purchase")
                save.synchronize()
            case .purchasing:
                break
            case .failed:
                SKPaymentQueue.default().finishTransaction(transaction)
                removeAdsLabelOutlet.text = "Warning"
                descriptionLabelOutlet.text = "There was some error in payment. Try again"
                break
            case .restored:
                break
            case .deferred:
                break
            
            }
        }
        
    }
    
    
    
    
    
    
}