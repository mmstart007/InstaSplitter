

import UIKit
import MediaPlayer
import MobileCoreServices

class ResultVideoController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let picker = UIImagePickerController()
    
    @IBOutlet weak var middleView: UIView!
    @IBOutlet weak var comboView: UIView!
    @IBOutlet weak var combo_label: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        middleView.layer.cornerRadius = middleView.bounds.width/2
        comboView.isHidden = true
        picker.delegate = self
    }
    
    func startMediaBrowserFromViewController(viewController: UIViewController, usingDelegate delegate: UINavigationControllerDelegate & UIImagePickerControllerDelegate) -> Bool {
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) == false {
            return false
        }
        let mediaUI = UIImagePickerController()
        mediaUI.sourceType = .savedPhotosAlbum
        mediaUI.mediaTypes = [kUTTypeMovie as NSString as String]
        mediaUI.allowsEditing = true
        mediaUI.delegate = delegate
        present(mediaUI, animated: true, completion: nil)
        return true
    }
    
    @IBAction func loadVideoAction(_ sender: AnyObject) {
        picker.sourceType = .savedPhotosAlbum
        picker.mediaTypes = [kUTTypeMovie as NSString as String]
        picker.allowsEditing = true
        picker.modalPresentationStyle = .popover
        present(picker, animated: true, completion: nil)
    }
    @IBAction func comboAction(_ sender: AnyObject) {
        
    }
    @IBAction func showComboView(_ sender: AnyObject) {
        comboView.isHidden = false
    }
    @IBAction func instagramItemAction(_ sender: AnyObject) {
        combo_label.text = "Instagram stories"
        comboView.isHidden = true
        let url = NSURL(string: "instagram://location?id=1")
        if UIApplication.shared.canOpenURL(url! as URL){
            UIApplication.shared.openURL(url! as URL)
        }else{
            UIApplication.shared.openURL(NSURL(string: "https://itunes.apple.com/in/app/instagram/id389801252?m")! as URL)
        }
    }
    @IBAction func snapchatItemAction(_ sender: AnyObject) {
        combo_label.text = "Snapchat"
        comboView.isHidden = true
        let url = NSURL(string: "snapchat://")
        if UIApplication.shared.canOpenURL(url! as URL){
            UIApplication.shared.openURL(url! as URL)
        }else{
            UIApplication.shared.openURL(NSURL(string: "https://itunes.apple.com/au/app/snapchat/id447188370")! as URL)
        }
    }
    
    //mark: - Delegates
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let mediaType = info[UIImagePickerControllerMediaType] as! NSString
        dismiss(animated: true) {
            if mediaType == kUTTypeMovie {
                if let referURL = info[UIImagePickerControllerReferenceURL] as? NSURL {
                    SVariables.videoURL = referURL
                    SVariables.count = 0
                    
                    let viewController: UIViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "EditViewController")
                    self.present(viewController, animated: true, completion: nil)
                }
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}

