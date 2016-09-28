

import UIKit
import MediaPlayer
import MobileCoreServices

class LoadVideoController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    let picker = UIImagePickerController()
    @IBOutlet weak var middleView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        middleView.layer.cornerRadius = middleView.bounds.width/2
        picker.delegate = self
    }
    
    @IBAction func loadVideoAction(_ sender: AnyObject) {
        picker.sourceType = .savedPhotosAlbum
        picker.mediaTypes = [kUTTypeMovie as NSString as String]
        picker.allowsEditing = true
        picker.modalPresentationStyle = .popover
        present(picker, animated: true, completion: nil)
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
