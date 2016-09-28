import UIKit


class SVariables{
    
    static var videoURL: NSURL?
    static var count = 0
    
    class func calcTimeString(time: CGFloat) -> String {
        var temp = "0:0s"
        temp = "" + String(Int(time/60))
        let remainder = time.remainder(dividingBy: 60)
        temp += String(Int(remainder))
//        temp = "" + String(Int(time/60)) + ":" + String(Int(time%60)) + "s"
        return temp
    }
    
    class func checkTime(time: String) -> Bool {
        
//        if NSNumberFormatter().numberFromString(time) != nil{
//            return true
//        }else {
//            return false
//        }
        if Double(time) != nil {
            return true
        }else{
            return false
        }
    }

    class func incCount(){
        count = (count + 1) % 4
    }
    
    class func compressVideo(inputURL: NSURL, outputURL: NSURL, handler:@escaping (_ session: AVAssetExportSession)-> Void) {
        let urlAsset = AVURLAsset(url: inputURL as URL, options: nil)
        if let exportSession = AVAssetExportSession(asset: urlAsset, presetName: AVAssetExportPresetMediumQuality) {
            exportSession.outputURL = outputURL as URL
            exportSession.outputFileType = AVFileTypeQuickTimeMovie
            exportSession.shouldOptimizeForNetworkUse = true
            exportSession.exportAsynchronously { () -> Void in
                handler(exportSession)
            }
        }
    }
}
