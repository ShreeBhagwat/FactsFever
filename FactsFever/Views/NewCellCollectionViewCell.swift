//
//  NewCellCollectionViewCell.swift
//  FactsFever
//
//  Created by Shree Bhagwat on 23/11/18.
//  Copyright © 2018 Development. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import ChameleonFramework
import SkeletonView

class NewCellCollectionViewCell: UICollectionViewCell {
    
    var facts: Facts!
    var currentUser = Auth.auth().currentUser?.uid
    
    // IBOutlets
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var likeLable: UILabel!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var infoButton: UIButton!
    @IBOutlet weak var buttonView: UIView!
    @IBOutlet weak var captionTextView: UITextView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        likeButton.setImage(UIImage(named: "noLike"), for: .normal)
        likeButton.setImage(UIImage(named: "like"), for: .selected)
        setupLayout()
    }
    
    
    func configureCell(fact: Facts){
        facts = fact
        
        imageView.sd_setImage(with: URL(string: fact.factsLink))
        likeLable.text = String(fact.factsLikes.count)
        captionTextView.text = fact.captionText
        let factsRef = Database.database().reference().child("Facts").child(facts.factsId).child("likes")
        factsRef.observeSingleEvent(of: .value) { (snapshot) in
            if fact.factsLikes.contains(self.currentUser!){
                self.likeButton.isSelected = true
            } else {
                self.likeButton.isSelected = false
            }
            
            
        }
    }
    
    func setupLayout(){
        imageView.layer.cornerRadius = 10
        imageView.layer.masksToBounds = true
        imageView.backgroundColor = UIColor.black
        
        captionTextView.backgroundColor = UIColor.black
        captionTextView.textColor = UIColor.white
        captionTextView.isEditable = false
        captionTextView.isSelectable = false
        captionTextView.isScrollEnabled = false
        
        likeLable.backgroundColor = #colorLiteral(red: 0.1242010223, green: 0.1241877451, blue: 0.1290884067, alpha: 1)
        likeLable.textColor = UIColor.white
        
        buttonView.backgroundColor = #colorLiteral(red: 0.1242010223, green: 0.1241877451, blue: 0.1290884067, alpha: 1)
        buttonView.layer.cornerRadius = 10
        
        infoButton.tintColor = UIColor.white
        likeButton.tintColor = UIColor.white
    }
    
    @IBAction func likeButtonPressed(_ sender: Any) {
        
            let factsRef = Database.database().reference().child("Facts").child(facts.factsId).child("likes")
            likeButton.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)

            UIView.animate(withDuration: 3.0,
                           delay: 0,
                           usingSpringWithDamping: CGFloat(0.30),
                           initialSpringVelocity: CGFloat(5.0),
                           options: UIView.AnimationOptions.allowUserInteraction,
                           animations: {
                            self.likeButton.transform = CGAffineTransform.identity
            },
                           completion: { Void in()  }
            )


            factsRef.observeSingleEvent(of: .value) { (snapshot) in
                if self.likeButton.isSelected == true {
                    self.likeButton.isSelected = false
                    self.facts.addSubtractLike(addLike: false)
                } else {
                    self.likeButton.isSelected = true
                    self.facts.addSubtractLike(addLike: true)

                }
            }
    }

    
//    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
//        super.apply(layoutAttributes)
//        if let attributes = layoutAttributes as? FactsFeverLayoutAttributes {
//            imageHeightConstraint.constant =  attributes.photoHeight
//        }
//    }
}
