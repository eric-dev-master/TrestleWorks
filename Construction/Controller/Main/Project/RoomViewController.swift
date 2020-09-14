//
//  RoomViewController.swift
//  Construction
//
//  Created by Macmini on 3/14/18.
//  Copyright © 2018 LekshmySankar. All rights reserved.
//

import UIKit
import MessageKit
import MapKit
import IQKeyboardManagerSwift
import SDWebImage

let messageLimit: Int = 30

extension User { //Sender
    func sender() -> Sender {
        return Sender(id: self.id, displayName: self.name ?? "")
    }
    
    class func avatar(userId: String, completion: ((Avatar?)->Void)?) {
        guard let completion = completion else {
            return
        }
        
        User.observeSingle(userId, eventType: .value) { (user) in
            if let user = user {
                if let file = user.thumbnail, let url = file.downloadURL {
                    if SDImageCache.shared().diskImageDataExists(withKey: url.absoluteString) == false {
                        if file.data == nil {
                            if file.downloadTask == nil {
                                let _ = file.dataWithMaxSize(9999999, completion: { (data, err) in
                                    if let data = data {
                                        file.data = data
                                        DispatchQueue.global(qos: .background).async {
                                            SDImageCache.shared().storeImageData(toDisk: data, forKey: url.absoluteString)
                                            DispatchQueue.main.async {
                                                if let image = UIImage(data: data) {
                                                    completion(Avatar(image: image, initials: user.name ?? "M"))
                                                }
                                            }
                                        }
                                    }
                                })
                            }
                        }
                        else {
                            if let image = UIImage(data: file.data!) {
                                completion(Avatar(image: image, initials: user.name ?? "M"))
                            }
                        }
                    }
                    else {
                        if let image = SDImageCache.shared().imageFromCache(forKey: url.absoluteString) {
                            completion(Avatar(image: image, initials: user.name ?? "M"))
                        }
                    }
                }
                else {
                    completion(Avatar(image: nil, initials: user.name ?? "M"))
                }
            }
            else {
                completion(nil)
            }
        }
    }
}

extension Message: MessageType {
    var sender: Sender {
        return Sender(id: self.userID ?? "0", displayName: self.userName ?? "")
    }
    
    var messageId: String {
        return self.id
    }
    
    var sentDate: Date {
        return self.createdAt
    }
    
    var data: MessageData {
        return .text(self.text ?? "")
    }
}

class RoomViewController: MessagesViewController {
    var dataSource: DataSource<Message>?
    var room: Room? = nil

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        IQKeyboardManager.sharedManager().enable = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        IQKeyboardManager.sharedManager().enable = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let room = self.room {
            self.title = room.name
        }
        
        self.setupDataSource()
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        messagesCollectionView.showsVerticalScrollIndicator = false
        
        scrollsToBottomOnKeybordBeginsEditing = true // default false
        maintainPositionOnKeyboardFrameChanged = true // default false
        
        self.messageInputBar = MessageInputBar()
        messageInputBar.sendButton.tintColor = Colors.darkColor
        messageInputBar.isTranslucent = false
        messageInputBar.backgroundView.backgroundColor = .white
        messageInputBar.separatorLine.isHidden = true
        messageInputBar.inputTextView.backgroundColor = UIColor(red: 245/255, green: 245/255, blue: 245/255, alpha: 1)
        messageInputBar.inputTextView.placeholderTextColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
        messageInputBar.inputTextView.textContainerInset = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 36)
        messageInputBar.inputTextView.placeholderLabelInsets = UIEdgeInsets(top: 8, left: 20, bottom: 8, right: 36)
        messageInputBar.inputTextView.layer.borderColor = UIColor(red: 200/255, green: 200/255, blue: 200/255, alpha: 1).cgColor
        messageInputBar.inputTextView.layer.borderWidth = 1.0
        messageInputBar.inputTextView.layer.cornerRadius = 16.0
        messageInputBar.inputTextView.layer.masksToBounds = true
        messageInputBar.inputTextView.scrollIndicatorInsets = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        messageInputBar.inputTextView.enablesReturnKeyAutomatically = true
        
        messageInputBar.setRightStackViewWidthConstant(to: 36, animated: true)
        messageInputBar.setStackViewItems([messageInputBar.sendButton], forStack: .right, animated: true)
        messageInputBar.sendButton.imageView?.backgroundColor = UIColor.clear//UIColor(red: 69/255, green: 193/255, blue: 89/255, alpha: 1)
//        messageInputBar.sendButton.contentEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        messageInputBar.sendButton.setSize(CGSize(width: 36, height: 36), animated: true)
        messageInputBar.sendButton.image = #imageLiteral(resourceName: "icon_send")
        messageInputBar.sendButton.title = nil
//        messageInputBar.sendButton.imageView?.layer.cornerRadius = 16
        messageInputBar.sendButton.backgroundColor = .clear
        messageInputBar.textViewPadding.right = -38
        messageInputBar.delegate = self
        reloadInputViews()
    }
    
    func sendText(text: String) {
        let message: Message = Message()
        message.userID = Manager.shared.user.id
        message.userName = Manager.shared.user.name ?? String(Manager.shared.user.id.suffix(2))
        message.text = text
        
        message.save({ (ref, err) in
            if let room = self.room {
                if room.messages.count > messageLimit {
                    if let source = self.dataSource {
                        let message = source.objects[0]
                        message.remove()
                        room.ref.child("messages").child(message.id).removeValue()
                    }
                }
                room.messages.insert(message.id)
                self.messagesCollectionView.scrollToBottom(animated: true)
            }
        })
    }
    
    func setupDataSource() {
        let options: Options = Options()
        options.limit = 20
        options.sortDescirptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        if let room = self.room {
            self.dataSource = DataSource(reference: room.ref.child("messages"), options: options, block: { (changes) in
                switch changes {
                case .initial:
                    self.messagesCollectionView.reloadData()
                    self.messagesCollectionView.scrollToBottom(animated: true)
                case .update(let deletions, let insertions, let modifications):
                    self.messagesCollectionView.performBatchUpdates({
                        self.messagesCollectionView.insertSections(IndexSet(insertions))
                        self.messagesCollectionView.deleteSections(IndexSet(deletions))
                        self.messagesCollectionView.reloadSections(IndexSet(modifications))
                    }, completion: { (finished) in
                        self.messagesCollectionView.scrollToBottom(animated: true)
                    });
                case .error(let error):
                    print(error)
                }
            })
        }
    }
}

extension RoomViewController: MessagesDataSource {
    
    func currentSender() -> Sender {
        return Manager.shared.user.sender()
    }
    
    func numberOfMessages(in messagesCollectionView: MessagesCollectionView) -> Int {
        return self.dataSource?.count ?? 0
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        if let source = self.dataSource{
            if indexPath.section < source.count {
                let message = source.objects[indexPath.section]
                return message
            }
        }
        return Message()
    }
    
    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let name = message.sender.displayName
        return NSAttributedString(string: name, attributes: [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: .caption1)])
    }
    
    func cellBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        
        struct ConversationDateFormatter {
            static let formatter: DateFormatter = {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                return formatter
            }()
        }
        let formatter = ConversationDateFormatter.formatter
        let dateString = message.sentDate.toString(dateStyle: .medium, timeStyle: .short)//formatter.string(from: message.sentDate)
        return NSAttributedString(string: dateString, attributes: [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: .caption2)])
    }
}

// MARK: - MessagesDisplayDelegate

extension RoomViewController: MessagesDisplayDelegate {
    
    // MARK: - Text Messages
    
    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? .white : .darkText
    }
    
    func detectorAttributes(for detector: DetectorType, and message: MessageType, at indexPath: IndexPath) -> [NSAttributedStringKey : Any] {
        return MessageLabel.defaultAttributes
    }
    
    func enabledDetectors(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> [DetectorType] {
        return [.url, .address, .phoneNumber, .date]
    }
    
    // MARK: - All Messages
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
//        return isFromCurrentSender(message: message) ? UIColor(red: 69/255, green: 193/255, blue: 89/255, alpha: 1) : UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1)
        return isFromCurrentSender(message: message) ? Colors.lightColor : Colors.darkColor.withAlphaComponent(0.2)
    }
    
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
        return .bubbleTail(corner, .curved)
        //        let configurationClosure = { (view: MessageContainerView) in}
        //        return .custom(configurationClosure)
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        if message.sender.displayName.count == 0 {
             avatarView.set(avatar: Avatar(image: nil, initials: String(message.sender.id.suffix(1))))
        }
        else {
            avatarView.set(avatar: Avatar(image: nil, initials: String(message.sender.displayName.prefix(1))))
        }
        
        User.avatar(userId: message.sender.id) { (avatar) in
            if let avatar = avatar {
                avatarView.set(avatar: avatar)
            }
        }
    }
    
    // MARK: - Location Messages
    
    func annotationViewForLocation(message: MessageType, at indexPath: IndexPath, in messageCollectionView: MessagesCollectionView) -> MKAnnotationView? {
        let annotationView = MKAnnotationView(annotation: nil, reuseIdentifier: nil)
        let pinImage = #imageLiteral(resourceName: "pin")
        annotationView.image = pinImage
        annotationView.centerOffset = CGPoint(x: 0, y: -pinImage.size.height / 2)
        return annotationView
    }
    
    func animationBlockForLocation(message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> ((UIImageView) -> Void)? {
        return { view in
            view.layer.transform = CATransform3DMakeScale(0, 0, 0)
            view.alpha = 0.0
            UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: [], animations: {
                view.layer.transform = CATransform3DIdentity
                view.alpha = 1.0
            }, completion: nil)
        }
    }
    
    func snapshotOptionsForLocation(message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> LocationMessageSnapshotOptions {
        
        return LocationMessageSnapshotOptions()
    }
}

// MARK: - MessagesLayoutDelegate

extension RoomViewController: MessagesLayoutDelegate {
    
    func avatarPosition(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> AvatarPosition {
        return AvatarPosition(horizontal: .natural, vertical: .messageBottom)
    }
    
    func messagePadding(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIEdgeInsets {
        if isFromCurrentSender(message: message) {
            return UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 4)
        } else {
            return UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 30)
        }
    }
    
    func cellTopLabelAlignment(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> LabelAlignment {
        if isFromCurrentSender(message: message) {
            return .messageTrailing(UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10))
        } else {
            return .messageLeading(UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0))
        }
    }
    
    func cellBottomLabelAlignment(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> LabelAlignment {
        if isFromCurrentSender(message: message) {
            return .messageLeading(UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0))
        } else {
            return .messageTrailing(UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10))
        }
    }
    
    func footerViewSize(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGSize {
        
        return CGSize(width: messagesCollectionView.bounds.width, height: 10)
    }
    
    // MARK: - Location Messages
    
    func heightForLocation(message: MessageType, at indexPath: IndexPath, with maxWidth: CGFloat, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 200
    }
    
}

// MARK: - MessageCellDelegate

extension RoomViewController: MessageCellDelegate {
    
    func didTapAvatar(in cell: MessageCollectionViewCell) {
        print("Avatar tapped")
        self.messageInputBar.inputTextView.resignFirstResponder()
    }
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
        print("Message tapped")
        self.messageInputBar.inputTextView.resignFirstResponder()
    }
    
    func didTapTopLabel(in cell: MessageCollectionViewCell) {
        print("Top label tapped")
        self.messageInputBar.inputTextView.resignFirstResponder()
    }
    
    func didTapBottomLabel(in cell: MessageCollectionViewCell) {
        print("Bottom label tapped")
        self.messageInputBar.inputTextView.resignFirstResponder()
    }
    
}

// MARK: - MessageLabelDelegate

extension RoomViewController: MessageLabelDelegate {
    
    func didSelectAddress(_ addressComponents: [String : String]) {
        print("Address Selected: \(addressComponents)")
    }
    
    func didSelectDate(_ date: Date) {
        print("Date Selected: \(date)")
    }
    
    func didSelectPhoneNumber(_ phoneNumber: String) {
        print("Phone Number Selected: \(phoneNumber)")
    }
    
    func didSelectURL(_ url: URL) {
        print("URL Selected: \(url)")
    }
    
}

// MARK: - MessageInputBarDelegate

extension RoomViewController: MessageInputBarDelegate {
    
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        for component in inputBar.inputTextView.components {
            if let _ = component as? UIImage {
                continue
            } else if let text = component as? String {
                self.sendText(text: text)
            }
        }
        inputBar.inputTextView.text = String()
        messagesCollectionView.scrollToBottom()
    }
}
