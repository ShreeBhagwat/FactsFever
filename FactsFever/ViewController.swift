//
//  ViewController.swift
//  FactsFever
//
//  Created by Gauri Bhagwat on 09/10/18.
//  Copyright © 2018 Development. All rights reserved.
//

import UIKit
import AVKit
import Foundation
import MobileCoreServices
import Firebase
import FirebaseStorage
import FirebaseDatabase
import SDWebImage
import ProgressHUD
import IDMPhotoBrowser
import ChameleonFramework
import PCLBlurEffectAlert
import SkeletonView

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDelegateFlowLayout {
    //MARK: Outlets
    
    @IBOutlet weak var uploadButtonOutlet: UIBarButtonItem!
    @IBOutlet weak var collectionView: UICollectionView!
    
    //MARK:- Properties
    
    var images: [UIImage] = []
    var factsArray:[Facts] = [Facts]()
    var factsStraightArray: [Facts] = [Facts]()
    var likeUsers:[String] = []
    let currentUser = Auth.auth().currentUser?.uid
  


    private let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        if #available(iOS 10.0, *) {
            collectionView.refreshControl = refreshControl
        } else {
            collectionView.addSubview(refreshControl)
        }
        refreshControl.addTarget(self, action: #selector(refreshView), for: .valueChanged)
        refreshControl.tintColor = UIColor.white
   
        collectionView.backgroundColor = UIColor.black
        observeFactsFromFirebase()
     
//        if let btn = self.navigationItem.rightBarButtonItem {
//            btn.isEnabled = false
//            btn.tintColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
//            btn.title = ""
//        }
        ProgressHUD.show("Welcome To FactsFever, Loading Facts, This might take a While")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            ProgressHUD.dismiss()
        }
        
         }


    @objc func refreshView(){
        observeFactsFromFirebase()
    }
    
//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        collectionView.collectionViewLayout.invalidateLayout()
//    }
    
    

    //MARK:- Upload Facts
    
    @IBAction func uploadButtonPressed(_ sender: Any) {

        self.selectPhoto()
    }

    // Image Picker View
    func selectPhoto(){
        uploadButtonOutlet.isEnabled = false
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = false
        picker.mediaTypes = [kUTTypeImage] as [String]
        present(picker, animated: true, completion: nil)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        var selectedImageFromPicker : UIImage?
        if let editedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage{
           print("Edited Image Size\(editedImage.size)")
            selectedImageFromPicker = editedImage
        }
        else if let orginalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            print("Size \(orginalImage.size)")
            selectedImageFromPicker = orginalImage
            
        }
        
        if let selectedImage = selectedImageFromPicker {
            uploadImageToFirebaseStorage(image: selectedImage) { (imageUrl) in
                print("Image Url\(imageUrl)")
                print("Image uploaded successfully ")
//                self.factLink.append(imageUrl)
//                self.addToDatabase(imageUrl: imageUrl)
                self.addCaptionToText(imageUrl: imageUrl, image: selectedImage)
            }


        }
        
        dismiss(animated: true, completion: nil)
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    private func uploadImageToFirebaseStorage(image: UIImage, completion: @escaping (_ imageUrl: String) -> ()){
        let imageName = NSUUID().uuidString + ".jpg"
        let ref = Storage.storage().reference().child("message_images").child(imageName)
        
        if let uploadData = image.jpegData(compressionQuality: 0.2){
            ref.putData(uploadData, metadata: nil, completion: { (metadata, error) in
                if error != nil {
                    print(" Failed to upload Image", error)
                }
                ref.downloadURL(completion: { (url, err) in
                    if let err = err {
                        print("Unable to upload image into storage due to \(err)")
                    }
                    let messageImageURL = url?.absoluteString
                    completion(messageImageURL!)
                    
                })
                
            })
        }
    }
    
    func addToDatabase(imageUrl:String, caption: String, image: UIImage){
        let Id = NSUUID().uuidString
        likeUsers.append(currentUser!)
        let timeStamp = NSNumber(value: Int(NSDate().timeIntervalSince1970))
        let factsDB = Database.database().reference().child("Facts")
        let factsDictionary = ["factsLink": imageUrl, "likes": likeUsers, "factsId": Id, "timeStamp": timeStamp, "captionText": caption, "imageWidth": image.size.width, "imageHeight": image.size.height] as [String : Any]
        factsDB.child(Id).setValue(factsDictionary){
            (error, reference) in
            
            if error != nil {
                print(error)
                ProgressHUD.showError("Image Upload Failed")
                self.uploadButtonOutlet.isEnabled = true
                return
                
            } else{
                print("Message Saved In DB")
                ProgressHUD.showSuccess("image Uploded Successfully")
                self.uploadButtonOutlet.isEnabled = true

                self.observeFactsFromFirebase()
            }
        }
    }
    
   
    var imageUrl: [String] = []
    func observeFactsFromFirebase(){
        
        let factsDB = Database.database().reference().child("Facts").queryOrdered(byChild: "timeStamp")
        factsDB.observe(.value){ (snapshot) in
            print("Observer Data snapshot \(snapshot.value)")
            
            self.factsArray = []
            self.imageUrl = []
            self.likeUsers = []
          
            if let snapshot = snapshot.children.allObjects as? [DataSnapshot] {
                for snap in snapshot {
                    
                    if let postDictionary = snap.value as? Dictionary<String, AnyObject> {
                        let id = snap.key
                        let facts = Facts(dictionary: postDictionary)
                        self.factsArray.insert(facts, at: 0)
                        self.imageUrl.insert(facts.factsLink, at: 0)
//                        self.factsArray.append(facts)
//                        self.imageUrl.append(facts.factsLink)
                        
                    }
                }
            }
            self.collectionView.reloadData()
          
            self.refreshControl.endRefreshing()
           
  
        }
        collectionView.reloadData()
    }
    // Download Image From Database

    func downloadImage(imageUrl: String,  completion: @escaping(_ image: UIImage?) -> Void) {
     
        let imageURL = NSURL(string: imageUrl)

        let imageFileName = (imageUrl.components(separatedBy: "%").last!).components(separatedBy: "?").first!


        if fileExistAtPath(path: imageFileName) {
            if let contentsOfFile = UIImage(contentsOfFile: fileInDocumentsDirectory(fileName: imageFileName)) {
                completion(contentsOfFile)
                ProgressHUD.dismiss()
            } else {
                print("could not generate image")
                completion(nil)
                
            }
        } else {
            let downloadQueue = DispatchQueue(label: "imageDownloadQueue")

            downloadQueue.async {

                let fetchedData = try? Data(contentsOf: imageURL! as URL)
                if fetchedData != nil {

                    var docURL = self.getDocumentsURL()
                    docURL = docURL.appendingPathComponent(imageFileName, isDirectory: false)

                    let imageToReturn = UIImage(data: fetchedData!)!
                    DispatchQueue.main.async {
                        completion(imageToReturn)
                    }
                }else {
                    DispatchQueue.main.async {
                        print("no image in database")
                        completion(nil)
                    }

                }
            }
        }
      

    }
    
    func fileInDocumentsDirectory(fileName: String) -> String {
        let fileURL = getDocumentsURL().appendingPathComponent(fileName)
        
        return fileURL.path
    }
    
    func getDocumentsURL() -> URL {
        let decumentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last
        return decumentURL!
    }
    
    func fileExistAtPath(path: String) -> Bool {
        
        var doesExist = false
        
        let filePath = fileInDocumentsDirectory(fileName: path)
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: filePath) {
            doesExist = true
        } else {
            doesExist = false
        }
        
        return doesExist
    }
    let alert = UIAlertController(title: nil, message: "Please wait...", preferredStyle: .alert)
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "newCellTrial", for: indexPath)as? NewCellCollectionViewCell
        var height:CGFloat = 400
        let facts = factsArray[indexPath.item]
        let cellClass = NewCellCollectionViewCell()
        let imageWidth = CGFloat(facts.imageWidht)
        let imageHieght = CGFloat(facts.imageHeight)
        let width:CGFloat = self.view.frame.width
        let imageSize = CGSize(width: imageWidth, height: imageHieght)
        let boundingRect = CGRect(x: 0, y: 0, width: width, height: CGFloat(MAXFLOAT))
        let rect = AVMakeRect(aspectRatio: imageSize, insideRect: boundingRect)
        let heightimage = rect.size.height
        cell?.imageHeightConstraint.constant = heightimage
        let caption = facts.captionText
        let captionHeight = estimatedFrameForText(text: caption!).height
        let totalHeight = heightimage + captionHeight + 8 + 8 + 8 + 40
        
        return CGSize(width: width, height: totalHeight)
        
    }
    
    func height(for text: String, with font: UIFont, width: CGFloat) -> CGFloat {
        let nsstring = NSString(string: text)
        let maxHeight = CGFloat(1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        let textAttributes = [NSAttributedString.Key.font: font]
        let boundingRect = nsstring.boundingRect(with: CGSize(width: width, height: maxHeight), options: options, attributes: textAttributes, context: nil)

        return ceil(boundingRect.height)
    }
    
    private func estimatedFrameForText(text:String) -> (CGRect){
        let width: CGFloat = view.frame.width
        let size = CGSize(width: width, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        
        return NSString(string:text).boundingRect(with: size, options: options, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], context: nil)
    }
    
 
    
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////

    //MARK: Data Source
extension ViewController: UICollectionViewDataSource{
 
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
       return factsArray.count
    }
    

    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let facts = factsArray[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "newCellTrial", for: indexPath) as? NewCellCollectionViewCell
//        cell?.imageHeightConstraint.constant = 400
        cell?.configureCell(fact: facts)
        cell?.infoButton.addTarget(self, action: #selector(reportButtonPressed), for: .touchUpInside)
       
        return cell!
    }

    
    
    @objc func reportButtonPressed(){
       let alert = PCLBlurEffectAlert.Controller(title: "Report This Fact?", message: "Do you want to report this fact? ", effect: UIBlurEffect(style: .dark), style: .alert)
        let cancelButton = PCLBlurEffectAlertAction.init(title: "Cancel", style: .destructive, handler: nil)
        alert.addAction(cancelButton)
        
        let yesButton = PCLBlurEffectAlertAction.init(title: "Yes", style: .default) { (alert) in
            self.showAlert()
        }
        alert.addAction(yesButton)
        alert.configure(cornerRadius: 30)
        alert.configure(titleColor: UIColor.orange)
        alert.configure(messageColor: UIColor.white)
        
        alert.show()
    }
    func showAlert(){
        let alert = PCLBlurEffectAlert.Controller(title: "Report Fact", message: "Click on the Below Option To report the problem", effect: UIBlurEffect(style: .dark), style: .alertVertical)
        let reportImageButton = PCLBlurEffectAlertAction.init(title: "Inappropriate Image", style: .default) { (alert) in
            print("Inappropriate Image Button Pressed")
            self.thankYouForReporting()
        }
        let reportMistakeButton = PCLBlurEffectAlertAction.init(title: "Wrong Fact", style: .default) { (alert) in
            print("Wrong Facts Button Pressed")
            self.thankYouForReporting()
        }
        let spellingMistake = PCLBlurEffectAlertAction.init(title: "Spelling Mistake", style: .default) { (alert) in
            print("Spelling Mistake Button Pressed")
            self.thankYouForReporting()
        }
        let cancelButton = PCLBlurEffectAlertAction.init(title: "Cancel", style: .destructive) { (alert) in
            print("Cancel Button Pressed")
        }
        alert.addAction(reportImageButton)
        alert.addAction(reportMistakeButton)
        alert.addAction(spellingMistake)
        alert.addAction(cancelButton)
        alert.configure(cornerRadius: 20)
        alert.configure(titleColor: UIColor.orange)
        alert.configure(messageColor: UIColor.white)
    
        alert.show()
        
    }
    func thankYouForReporting(){
        let picker = UIImagePickerController()
        let alert = PCLBlurEffectAlert.Controller(title: "Tank You For Reporting", message: "Developers Will Check The Fact Shortly", effect: UIBlurEffect(style: .dark), style: .alert)
        let button = PCLBlurEffectAlertAction.init(title: "OK", style: .default) { (alert) in
            
        }
        alert.configure(titleColor: UIColor.orange)
        alert.configure(messageColor: UIColor.white)
        alert.addAction(button)
        alert.present(picker, animated: true, completion: nil)
    }
    
    func addCaptionToText(imageUrl: String, image: UIImage){
        print("Caption Alert Method called")
        let alert = PCLBlurEffectAlert.Controller(title: "Add Caption", message: nil, effect: UIBlurEffect(style: .dark), style: .alert)
        
        alert.addTextField { (textFiled) in
            let button = PCLBlurEffectAlertAction.init(title: "Ok", style: .default) { (alert) in
                print(textFiled?.text)
                self.addToDatabase(imageUrl: imageUrl, caption: textFiled!.text!, image: image)
            }
            alert.addAction(button)
        }
        
        let can = PCLBlurEffectAlertAction.init(title: "Cancel", style: .cancel) { (alert) in
            
        }
        alert.configure(textFieldHeight: 30)
//        alert.addAction(button)
        alert.addAction(can)
        alert.show()
    }
    
    
    
}
extension ViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let photos = IDMPhoto.photos(withURLs: imageUrl)
        let browser = IDMPhotoBrowser(photos: photos)
        browser?.setInitialPageIndex(UInt(indexPath.row))
        self.present(browser!, animated: true, completion: nil)
    }
    

  
}

//extension ViewController: FactsFeverLayoutDelegate {
//    func collectionView(CollectionView: UICollectionView, heightForThePhotoAt indexPath: IndexPath, with width: CGFloat) -> CGFloat {
//        let facts = factsArray[indexPath.item]
//        let imageSize = CGSize(width: CGFloat(facts.imageWidht), height: CGFloat(facts.imageHeight))
//        let boundingRect = CGRect(x: 0, y: 0, width: width, height: CGFloat(MAXFLOAT))
//        let rect = AVMakeRect(aspectRatio: imageSize, insideRect: boundingRect)
//
//        return rect.size.height
//
//    }
//
//    func collectionView(CollectionView: UICollectionView, heightForCaptionAt indexPath: IndexPath, with width: CGFloat) -> CGFloat {
//        let fact = factsArray[indexPath.item]
//        let topPadding = CGFloat(8)
//        let bottomPadding = CGFloat(8)
//        let captionFont = UIFont.systemFont(ofSize: 15)
//        let viewHeight = CGFloat(40)
//        let captionHeight = self.height(for: fact.captionText, with: captionFont, width: width)
//        let height = topPadding + captionHeight + topPadding + viewHeight + bottomPadding + topPadding + 10
//
//        return height
//
//    }
//
//    func height(for text: String, with font: UIFont, width: CGFloat) -> CGFloat {
//        let nsstring = NSString(string: text)
//        let maxHeight = CGFloat(1000)
//        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
//        let textAttributes = [NSAttributedString.Key.font: font]
//        let boundingRect = nsstring.boundingRect(with: CGSize(width: width, height: maxHeight), options: options, attributes: textAttributes, context: nil)
//
//        return ceil(boundingRect.height)
//    }
//
//
//}



    
    





