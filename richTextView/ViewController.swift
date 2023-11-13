//
//  ViewController.swift
//  richTextView
//
//  Created by xuguangyin on 2022/9/1.
//

import UIKit

struct SrValue {
    var str: String?
    var img: UIImage?
}

class ViewController: UIViewController, UITextViewDelegate, UIGestureRecognizerDelegate {

    // 蓝 绿 紫 黄 橙 黑
    private let colorHexes: [String] = ["0x2E5E95", "0x00bf36", "0xeb04ac", "0xf5dc00", "0xff9102", "0x000000"]
    private var contentEditHeight: CGFloat = 0
    let margin: CGFloat = 20
    let mid: CGFloat = 10
    let viewH: CGFloat = 60
    let btnW: CGFloat = 30
    let inputH: CGFloat = 40

    let contentAttributes: [NSAttributedString.Key : Any] = [.font: UIFont.systemFont(ofSize: 16) as Any, .foregroundColor: UIColor.black as Any]

    var keyboardHeight: CGFloat?
    var fm: Int = 1
    var arr: [Int] = []
    var imgs: [UIImage] = []
    var m1: [SrValue] = []

    lazy var contentEditor: UITextView = {
        let editor = UITextView()
        editor.delegate = self
        editor.isScrollEnabled = true
        let para = NSMutableParagraphStyle()
        para.lineSpacing = 10
        let attr = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16), NSAttributedString.Key.strokeColor: UIColor.black, NSAttributedString.Key.paragraphStyle: para]
        editor.typingAttributes = attr
        editor.showsVerticalScrollIndicator = false
        editor.textContainer.lineFragmentPadding = 0

        // 这个是为了解决在iOS13.2到iOS14之间单击textView的附件，代理方法`-textView: shouldInteractWith: textAttachment`不调用的问题
        let version = UIDevice.current.systemVersion
        let isLarger = version.compare("13.1", options: .numeric) == .orderedDescending
        let isSmaller = version.compare("14.0.0", options: .numeric) == .orderedAscending
        if let gs = editor.gestureRecognizers, isLarger && isSmaller {
            for g in gs where g is UITapGestureRecognizer {
                if let name = g.name, name.hasPrefix("UITextInteractionNameLinkTap") {
                    g.delegate = self
                }
            }
        }
        return editor
    }()

    lazy var textText: UITextView = {
        let text = UITextView()
        text.font = .systemFont(ofSize: 14)
        text.textColor = .red
        text.delegate = self
        text.layer.borderColor = UIColor.blue.cgColor
        text.layer.borderWidth = 1
        return text
    }()

    lazy var bottomView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()

    lazy var colorBtn: UIButton = {
        let btn = UIButton()
        let icon = UIImage.init(named:"ar_colorboard")
        btn.setImage(icon, for: .normal)
//        btn.addTarget(self, action: #selector(colorClickAction), for: .touchDown)
        return btn
    }()

    lazy var cameraBtn: UIButton = {
        let btn = UIButton()
        let icon = UIImage.init(named: "plt_note_camera")
        btn.setImage(icon, for: .normal)
        btn.addTarget(self, action: #selector(cameraClickAction), for: .touchDown)
        return btn
    }()

    lazy var inputSendView: UIView = {
        let view = UIView()
        view.layer.borderWidth = 0.5
        view.layer.borderColor = UIColor.black.cgColor
        return view
    }()

    lazy var inputText: UITextView = {
        let text = UITextView()
        text.delegate = self
        text.font = .systemFont(ofSize: 15)
        text.returnKeyType = .default
        text.backgroundColor = .white
        text.enablesReturnKeyAutomatically = true
        return text
    }()

    lazy var sendBtn: UIButton = {
        let btn = UIButton()
        let icon = UIImage.init(named: "plt_note_send")
        btn.setImage(icon, for: .normal)
        btn.addTarget(self, action: #selector(sendTextAction), for: .touchDown)
        return btn
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        perpareUI()
        textText.isScrollEnabled = true
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(note:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyBoardWillHide(note:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    func perpareUI() {
        self.view.addSubview(contentEditor)
        self.view.addSubview(bottomView)
        bottomView.addSubview(colorBtn)
        bottomView.addSubview(cameraBtn)
        bottomView.addSubview(inputSendView)
        inputSendView.addSubview(inputText)
        inputSendView.addSubview(sendBtn)

        contentEditor.frame = CGRect(x: 10, y: 100, width: self.view.frame.width - 20, height: self.view.frame.height - 200)
        bottomView.frame = CGRect(x: 0, y: self.view.frame.height - viewH - 40, width: self.view.frame.width, height: viewH)
        colorBtn.frame = CGRect(x: margin, y: (viewH - btnW) / 2, width: btnW, height: btnW)
        cameraBtn.frame = CGRect(x: margin + mid + btnW, y: (viewH - btnW) / 2, width: btnW, height: btnW)
        let sendH: CGFloat = 40
        inputSendView.frame = CGRect(x: cameraBtn.frame.maxX + mid, y: (viewH - sendH)/2, width: UIScreen.main.bounds.width - 2 * mid - cameraBtn.frame.maxX, height: sendH)
        inputSendView.layer.cornerRadius = sendH/2
        let minus = (inputH - btnW) / 2
        inputText.frame = CGRect(x: mid + 5, y: 0, width: inputSendView.frame.width - mid - 5 - btnW - minus, height: inputH)
        sendBtn.frame = CGRect(x: inputText.frame.maxX, y: (inputH - btnW)/2, width: btnW, height: btnW)
    }

    @objc func keyboardWillShow(note: Notification) {
        let userInfo = note.userInfo as NSDictionary?
        let keyBoard = (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let duration = (userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        let deltaY = keyBoard.size.height
        keyboardHeight = deltaY
        let animations: (() -> Void) = {
            self.bottomView.transform = CGAffineTransform(translationX: 0, y: -deltaY + 40)
        }
        if duration > 0 {
            let options = UIView.AnimationOptions.init(rawValue: UInt((userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as! NSNumber).intValue << 16))
            UIView.animate(withDuration: duration, delay: 0, options: options, animations: animations, completion: nil)
        } else {
            animations()
        }
    }

    @objc func keyBoardWillHide(note: NSNotification) {
        let userInfo = note.userInfo as NSDictionary?
        let duration = (userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        let animations: (() -> Void) = {
            self.bottomView.transform = CGAffineTransform.identity
        }

        if duration > 0 {
            let options = UIView.AnimationOptions(rawValue: UInt((userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as! NSNumber).intValue << 16))
            UIView.animate(withDuration: duration, delay: 0, options: options, animations: animations, completion: nil)
        } else {
            animations()
        }
    }

    @objc func sendTextAction() {
        inputText.resignFirstResponder()

        if inputText.text != "" {
            let attr = NSMutableAttributedString(attributedString: contentEditor.attributedText)
            let text = NSMutableAttributedString(string: inputText.text)
            let ra = NSMakeRange(0, text.length)
            text.addAttribute(.font, value: UIFont.systemFont(ofSize: 16), range: ra)
            text.addAttribute(.strokeColor, value: UIColor.white, range: ra)
            let para = NSMutableParagraphStyle()
            para.lineSpacing = 5
            text.addAttribute(.paragraphStyle, value: para, range: ra)
            attr.append(text)
            contentEditor.attributedText = attr
        }
        contentEditor.resignFirstResponder()
        inputText.text = ""
    }

    @objc func cameraClickAction() {
        if fm > 5 {
            fm = 1
        }
        let imageName = String(format: "attement_", "") + String(fm)
        let attributedText = NSMutableAttributedString(attributedString: textText.attributedText!)
        // Add the image as an attachment.
        if let image = UIImage(named: imageName) {
            let textAttachment = NSTextAttachment()
            textAttachment.image = image
            let hei = image.size.height * (textText.frame.width / image.size.width)
            textAttachment.bounds = CGRect(origin: CGPoint.zero, size: CGSize(width: textText.frame.width - 5, height: hei))
            let textAttachmentString = NSAttributedString(attachment: textAttachment)
            let loa = textText.selectedRange.location
            arr.append(loa)
            print("下标1:  ",loa)
            attributedText.insert(textAttachmentString, at: loa)
            textText.attributedText = attributedText
            fm += 1
        }
    }
}
