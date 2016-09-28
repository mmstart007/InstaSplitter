
import UIKit
import AVFoundation

class EditVideoController: UIViewController {
    
    @IBOutlet weak var playView: ISVideoPlaybackView!
    @IBOutlet weak var preview: UIView!
    @IBOutlet weak var splitVideoInView: UIView!
    @IBOutlet weak var middle_text: UILabel!
    @IBOutlet weak var middleView: UIView!
    @IBOutlet weak var progressView: CircleProgressView!
    @IBOutlet weak var lblStartTime: UILabel!
    @IBOutlet weak var lblEndTime: UILabel!
    @IBOutlet weak var comboView: UIView!
    @IBOutlet weak var selectedComboText: UILabel!
    @IBOutlet weak var custom_split_time: UITextField!
    
    var isFirstAppear = true
    var isPlaying = false
    var indexFlag = true

    var startTime: CMTime!
    var endTime: CMTime!
    var splitTime = 10.0
    var frame = 1
    var is_first_split = true
    var splited_time: CMTime!
    var total_progress = 0.0
    var progressFlag = false
    var totalFrames = 1
    var videoAsset: AVAsset!
    var previewVideoPlayer: AVPlayer!
    var mySAVideoRangeSlider = SAVideoRangeSlider()
    var videoManager = VideoManager.shared()
    var rotate_save_session: AVAssetExportSession!
    var exportSession: AVAssetExportSession!
    var playTimer = Timer()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        videoAsset = AVURLAsset(url: SVariables.videoURL! as URL)
        let playerItem = AVPlayerItem(asset: videoAsset)
        previewVideoPlayer = AVPlayer(playerItem: playerItem)
        
        startTime = CMTimeMake(0, videoAsset.duration.timescale)
        endTime = videoAsset.duration
        lblStartTime.text = "0:0s"
        lblEndTime.text = SVariables.calcTimeString(time: CGFloat(endTime.seconds))
        if isFirstAppear == false {
            mySAVideoRangeSlider.removeFromSuperview()
            mySAVideoRangeSlider = SAVideoRangeSlider(frame: preview.bounds, videoUrl: SVariables.videoURL as URL!)
        }
        
        playTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(EditVideoController.playTimerEvent), userInfo: nil, repeats: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if isFirstAppear == true {
            isFirstAppear = false
            
            splitVideoInView.isHidden = true
            middleView.layer.cornerRadius = middleView.bounds.width/2
            
            mySAVideoRangeSlider = SAVideoRangeSlider(frame: preview.bounds, videoUrl: SVariables.videoURL as URL!)
            mySAVideoRangeSlider.delegate = self
            self.preview.addSubview(mySAVideoRangeSlider)
            self.playView.player = previewVideoPlayer!
            
            self.comboView.isHidden = true
        }
    }
    //MARK: - play timer event
    func playTimerEvent(){
        
        if self.isPlaying == true && self.previewVideoPlayer.currentTime() >= self.endTime{
            self.isPlaying = false
            self.previewVideoPlayer.seek(to: self.startTime, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
        }
        if self.rotate_save_session != nil {
            print("rotate session progress: \(self.rotate_save_session.progress) session status: \(self.rotate_save_session.status)")
            let progress = Double(self.rotate_save_session.progress)
            self.progressView.progress = progress / 2
        }
        if self.exportSession != nil {
            print("session progress: \(self.exportSession.progress) session status: \(self.exportSession.status)")
            let progress = Double(self.exportSession.progress) / Double(self.totalFrames)
            
            if SVariables.count == 0 {
                self.progressView.progress = progress + self.total_progress
            }
            else {
                self.progressView.progress = progress / 2 + self.total_progress
            }
        }
 
    }
    //mark: - split action
    @IBAction func splitAction(_ sender: AnyObject) {
        if progressFlag == true {
            return
        }
        
        self.mySAVideoRangeSlider.isUserInteractionEnabled = false
        if self.isPlaying == true {
            self.previewVideoPlayer.pause()
            self.isPlaying = false
        }
        self.middle_text.text = "Splitting"
        
        if splitVideoInView.isHidden == false{
            let temp = custom_split_time.text
            if let time = Double(temp!) {
                splitTime = time
            }else {
                showAlertView(title: "Error", content: "Please input valid number!")
                return
            }
        }
        self.progressFlag = true
        
        totalFrames = Int((endTime.seconds - startTime.seconds)/splitTime)
        let remainder = endTime.seconds.remainder(dividingBy: splitTime)
        if Int(remainder) > 0 {
            totalFrames += 1
        }
        let url = SVariables.videoURL
        
        rotate_save_session = VideoManager.rotateVideo(url as URL!, count: SVariables.count, completion: { (outputURL) in
            self.rotate_save_session = nil
            if outputURL != nil {
                print(outputURL)
                SVariables.videoURL = outputURL as NSURL?
                self.videoAsset = AVURLAsset(url: outputURL!)
                
                self.startTime = CMTimeMake(Int64(self.startTime.seconds * Double(self.videoAsset.duration.timescale)), self.videoAsset.duration.timescale)
                self.endTime = CMTimeMake(Int64(self.endTime.seconds * Double(self.videoAsset.duration.timescale)), self.videoAsset.duration.timescale)
                
                self.trimVideo(index: 1)
            } else {
                self.showAlertView(title: "ERROR", content: "Unsupported video format!")
                let rect = self.playView.videoRect()
                print("\(rect)")
                self.videoAsset = AVURLAsset(url: SVariables.videoURL! as URL)
                let playerItem = AVPlayerItem(asset: self.videoAsset)
                self.previewVideoPlayer = AVPlayer(playerItem: playerItem)
                self.playView.player = self.previewVideoPlayer
            }
        })
    }
    
    func trimVideo(index: NSInteger) {
        
        var split_start_time: CMTime!
        var split_end_time: CMTime!
        
        self.frame = index
        
        if self.is_first_split == false{
            split_start_time = self.splited_time
            split_end_time = CMTimeMake(Int64((split_start_time.seconds + Double(splitTime)) * Double(self.videoAsset.duration.timescale)), self.videoAsset.duration.timescale)
        }else{
            split_start_time = startTime
            split_end_time = CMTimeMake(Int64((split_start_time.seconds + Double(splitTime)) * Double(self.videoAsset.duration.timescale)), self.videoAsset.duration.timescale)
        }
        
        if index == totalFrames {
            split_end_time = endTime
        }
        
        if split_end_time.seconds <= split_start_time.seconds {
            showAlertView(title: "Error", content: "Time Error!")
            self.middle_text.text = "Split"
            
            self.progressView.progress = 0.0
            return
        }
        self.total_progress = self.progressView.progress
        self.exportSession = VideoManager.trimVideo(SVariables.videoURL as URL!, start: split_start_time, end: split_end_time, completion: { (outputURL) in
            if outputURL != nil {
                print(outputURL)
                VideoManager.save(outputURL)
                if index == self.totalFrames {
                    self.playTimer.invalidate()
                    let viewController: UIViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ResultVideoController")
                    self.present(viewController, animated: true, completion: nil)
                } else {
                    self.is_first_split = false
                    self.splited_time = split_end_time
                    self.trimVideo(index: index + 1)
                }
            }else {
                self.playTimer.invalidate()
                let viewController: UIViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ResultVideoController")
                self.present(viewController, animated: true, completion: nil)
            }
        })
    }
    //MARK: - button event
    @IBAction func btnPlayAction(_ sender: AnyObject) {
        if progressFlag == true {
            return
        }
        if isPlaying == false{
            isPlaying = true
            previewVideoPlayer.play()
        }else {
            isPlaying = false
            previewVideoPlayer.pause()
        }
    }

    @IBAction func cancelAction(_ sender: AnyObject) {
//        if progressFlag == true {
//            return
//        }
        self.playTimer.invalidate()
        if self.isPlaying == true {
            self.previewVideoPlayer.pause()
            self.isPlaying = false
        }
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func rotateAction(_ sender: AnyObject) {
        
        if progressFlag == true {
            return
        }
        if self.isPlaying == true {
            self.previewVideoPlayer.pause()
            self.isPlaying = false
        }
        SVariables.incCount()
        self.playView.transform = CGAffineTransform(rotationAngle: CGFloat(1.57 * CGFloat(SVariables.count)))
    }
    @IBAction func InstagramStoriesAction(_ sender: AnyObject) {
        selectedComboText.text = "Instagram Stories"
        comboView.isHidden = true
        splitVideoInView.isHidden = true
        splitTime = 9.8
    }
    @IBAction func instagramAction(_ sender: AnyObject) {
        selectedComboText.text = "Instagram"
        comboView.isHidden = true
        splitVideoInView.isHidden = true
        splitTime = 59
    }
    @IBAction func snapchatAction(_ sender: AnyObject) {
        selectedComboText.text = "Snapchat"
        comboView.isHidden = true
        splitVideoInView.isHidden = true
        splitTime = 9.8
    }
    
    @IBAction func customTimeAction(_ sender: AnyObject) {
        selectedComboText.text = "Custom time"
        comboView.isHidden = true
        splitVideoInView.isHidden = false
    }
    @IBAction func showComboAction(_ sender: AnyObject) {
        if progressFlag == true {
            return
        }
        if self.isPlaying == true {
            self.previewVideoPlayer.pause()
            self.isPlaying = false
        }
        if comboView.isHidden == true {
            comboView.isHidden = false
        }else{
            comboView.isHidden = true
        }
    }
    
    func showAlertView(title: String, content: String) {
        let alert = UIAlertController(title: title, message: content, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

extension EditVideoController: SAVideoRangeSliderDelegate{
    func videoRange(_ videoRange: SAVideoRangeSlider!, didChangeLeftPosition leftPosition: CGFloat, rightPosition: CGFloat) {
        if self.isPlaying == true {
            self.previewVideoPlayer.pause()
            self.isPlaying = false
        }
    }
    func videoRange(_ videoRange: SAVideoRangeSlider!, didGestureStateEndedLeftPosition leftPosition: CGFloat, rightPosition: CGFloat) {
        self.startTime = CMTimeMake(Int64(Int32(leftPosition) * self.videoAsset.duration.timescale), self.videoAsset.duration.timescale)
        self.endTime = CMTimeMake(Int64(Int32(rightPosition) * self.videoAsset.duration.timescale), self.videoAsset.duration.timescale)
        self.lblStartTime.text = SVariables.calcTimeString(time: leftPosition)
        self.lblEndTime.text = SVariables.calcTimeString(time: rightPosition)
        
        previewVideoPlayer.seek(to: startTime)
    }
}
