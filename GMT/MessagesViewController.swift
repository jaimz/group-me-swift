//
//  MessagesViewController.swift
//  GMT
//
//  Created by James O'Brien on 26/06/2016.
//  Copyright © 2016 James O'Brien. All rights reserved.
//

import UIKit

class MessagesViewController: UIViewController, UICollectionViewDelegate, UITextFieldDelegate {
    static let kComposerCornerRadius : CGFloat = 20.0


    @IBOutlet var messageCollectionView: UICollectionView!

    @IBOutlet var conversationAvatar: AvatarGem!


    @IBOutlet var titleLabel: UILabel!

    @IBOutlet var backButton: UIButton!


    @IBOutlet var textComposerBacking: UIView!
   
    @IBOutlet var textComposerAvatar: AvatarGem!

    @IBOutlet var textComposerField: UITextField!

    @IBOutlet var viewBottomConstraint: NSLayoutConstraint!

    @IBOutlet var showMediaTrayButton: UIButton!

    @IBOutlet var scribbleEditor: UIView!
    @IBOutlet var scribblerView: ScribblerView!

    @IBOutlet var sendScribbleButton: UIButton!

    @IBOutlet var composerHeightConstraint: NSLayoutConstraint!

    private var scribbleVisible = false

    var conversation : Conversation? = .None {
        didSet {
            titleLabel?.text = conversation?.name ??  ""
            conversationAvatar?.avatarUrl = conversation?.avatarUrl
        }
    }

    var collectionViewDataSource : UICollectionViewDataSource? = .None {
        didSet {
            messageCollectionView.dataSource = collectionViewDataSource
        }
    }

    var collectionViewDelegate : UICollectionViewDelegate? = .None {
        didSet {
            messageCollectionView.delegate = collectionViewDelegate
        }
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        configureViews()

        textComposerField.delegate = self

        GroupMe.instance.me { p in self.textComposerAvatar.avatarUrl = p?.avatarUrl }

        titleLabel?.text = conversation?.name ??  ""
        conversationAvatar?.avatarUrl = conversation?.avatarUrl
    }

    override func prepareForInterfaceBuilder() {
        configureViews()
    }

    private func configureViews() {
        backButton.setImage(GMTStyleKit.imageOfBackChevron, forState: UIControlState.Normal)

        showMediaTrayButton.setImage(GMTStyleKit.imageOfAddMediaButton, forState: UIControlState.Normal)


        scribbleEditor.alpha = 0.0

        sendScribbleButton.backgroundColor = GMTStyleKit.textBlue
        sendScribbleButton.setImage(GMTStyleKit.imageOfSendButtonIcon, forState: UIControlState.Normal)
        sendScribbleButton.layer.borderColor = UIColor.whiteColor().CGColor
        sendScribbleButton.layer.borderWidth = 1.0
        sendScribbleButton.layer.cornerRadius = 20.0


        let layer = textComposerBacking.layer
        layer.cornerRadius = MessagesViewController.kComposerCornerRadius
        DrawingUtils.ApplyShadowToView(GMTStyleKit.messageBoxShadow, view: textComposerBacking)
        DrawingUtils.ApplyShadowToView(GMTStyleKit.messageBoxShadow, view: scribbleEditor)
        textComposerAvatar.hasShadow = false
    }

    override func viewDidAppear(animated: Bool) {
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(MessagesViewController.keyboardWillShow(_:)),
                                                         name: UIKeyboardWillShowNotification,
                                                         object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(MessagesViewController.keyboardWillHide(_:)),
                                                         name: UIKeyboardWillHideNotification,
                                                         object: nil)

        conversation?.messages.conversationView =  self
        scrollToBottom()
    }

    override func viewWillDisappear(animated: Bool) {
        conversation?.messages.conversationView = .None
        self.textComposerField.resignFirstResponder()
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: self.view.window)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: self.view.window)
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        // TODO: Expand the cell...
        print("Got cell tap")
    }


    // TODO: Smarter registration of cell renderers...
    func registerClass(cellClass : AnyClass, forUseWithReuseIdentifier cellId : String) {
        messageCollectionView.registerClass(cellClass, forCellWithReuseIdentifier: cellId)
    }


    func didAppendMessages() {
        // If we are scrolled to the bottom assume we will need to keep at the bottom
        let needScroll = willNeedScroll()

        messageCollectionView.reloadData()

        if (needScroll) {
            scrollToBottom()
        }
    }

    private func willNeedScroll() -> Bool {
        let collectionViewHeight = floor(messageCollectionView.frame.size.height)
        let contentSizeHeight = floor(messageCollectionView.contentSize.height)
        let scrollOffset = floor(messageCollectionView.contentOffset.y)

        return (scrollOffset + collectionViewHeight == contentSizeHeight)
    }


    @objc func keyboardWillShow(sender: NSNotification) {
        self.adjustToKeyboard(sender)
    }

    @objc func keyboardWillHide(sender: NSNotification) {
        self.adjustToKeyboard(sender)
    }


    private func adjustToKeyboard(sender: NSNotification) {
        guard let userInfo : [NSObject : AnyObject] = sender.userInfo else {
            print("-=-=-= No user info in keyboard notification?")
            return
        }

        if let keyboardRect = userInfo[UIKeyboardFrameEndUserInfoKey]?.CGRectValue() {

                let duration = userInfo[UIKeyboardAnimationDurationUserInfoKey]?.doubleValue ?? 0.2
                let curve = userInfo[UIKeyboardAnimationCurveUserInfoKey]?.integerValue ?? UIViewAnimationCurve.EaseInOut.rawValue
                let newBottomOffset = self.view.frame.maxY - keyboardRect.minY
                let needScroll = self.willNeedScroll()

                UIView.animateWithDuration(duration,
                                           delay: 0,
                                           options: UIViewAnimationOptions(rawValue: UInt(curve << 16)),
                                           animations: {
                                            self.viewBottomConstraint.constant = newBottomOffset
                                            self.view.layoutIfNeeded()
                    }, completion: { completed in
                        if needScroll {
                            self.scrollToBottom()
                        }
                })
        }
    }


    @IBAction func showMediaPickerTapped(sender: UIButton) {
        toggleScribbler()
    }


    @IBAction func sendScribbleTapped(sender: AnyObject) {
        if let imageData = self.scribblerView.getJPEGImageData() {
            conversation?.sendImage(imageData)
        }

        toggleScribbler()
    }


    @IBAction func backButtonTapped(sender: AnyObject) {
        self.navigationController?.popViewControllerAnimated(true)
    }


    private func toggleScribbler() {
        let needScroll = self.willNeedScroll()

        var target : CGFloat = 60.0
        var buttonTransform = CGAffineTransformIdentity
        var alpha : CGFloat = 0.0

        if scribbleVisible == false {
            target = 360
            buttonTransform = CGAffineTransformMakeRotation(0.785398)
            alpha = 1.0
        }

        UIView.animateWithDuration(0.2,
                                   delay: 0,
                                   options: UIViewAnimationOptions.CurveEaseInOut,
                                   animations: {
                                    self.composerHeightConstraint.constant = target
                                    self.scribbleEditor.alpha = alpha
                                    self.textComposerAvatar?.alpha = 1.0 - alpha
                                    self.showMediaTrayButton.transform = buttonTransform
                                    self.textComposerBacking.layer.cornerRadius = MessagesViewController.kComposerCornerRadius - self.textComposerBacking.layer.cornerRadius
                                    self.view.layoutIfNeeded()
                },
                completion: { completed in
                    if needScroll {
                        self.scrollToBottom()
                    }

                    self.scribbleVisible = !self.scribbleVisible
                    if self.scribbleVisible == false {
                        self.scribblerView.clear()
                    }
        })
    }


    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent;
    }


    private func scrollToBottom() {
        guard let convo  = conversation else {
            return
        }

        // The dispatch ensures that the collection view scrolles after it has finished laying everything out
        // (i.e. the scroll is queued after any current work)
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            let targetIdx = convo.messages.loadedCount - 1
            let count = self.messageCollectionView.numberOfItemsInSection(0)
            if targetIdx > 0 && targetIdx <= count {
                self.messageCollectionView.scrollToItemAtIndexPath(NSIndexPath(forItem: convo.messages.loadedCount - 1, inSection: 0), atScrollPosition: UICollectionViewScrollPosition.Bottom, animated: true)
            }
        })
    }


    // MARK: UITextFieldDelegate
    func textFieldShouldEndEditing(textField: UITextField) -> Bool {
        return true
    }

    func textFieldDidEndEditing(textField: UITextField) {
        if let msgText = textField.text {
            conversation?.sendMessage(msgText, attachments: .None)
        }
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()

        return true
    }
}
