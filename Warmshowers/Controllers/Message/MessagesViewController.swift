//
//  MessagesViewController.swift
//  Warmshowers
//
//  Created by Michael Haeuslmann on 20/05/15.
//  Copyright (c) 2015 Michael Haeuslmann. All rights reserved.
//

import UIKit
import Haneke

class MessagesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate
{
    private let messageRepository = MessageRepository.sharedInstance
    private let userRepository = UserRepository.sharedInstance
    private var messages = [Message]()

    private var refreshControl: UIRefreshControl!

    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
            
            tableView.estimatedRowHeight = 160
            tableView.rowHeight = UITableViewAutomaticDimension;
        }
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()

        self.refreshControl = UIRefreshControl()
        self.refreshControl.addTarget(self, action: "refresh", forControlEvents: UIControlEvents.ValueChanged)
        self.tableView.addSubview(refreshControl)

        refresh()
    }

    func refresh()
    {
        messageRepository.getAll().onSuccess() { messages in
            if self.messages != messages {
                self.messages = messages
                self.tableView.reloadData()
            }
        }

        refreshControl.endRefreshing()
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
        if segue.identifier == Storyboard.ShowMessageThreadSegue {
            if let messageThreadViewController = segue.destinationViewController as? MessageThreadViewController {
                if let messageThreadId = sender as? Int {
                    messageThreadViewController.threadId = messageThreadId
                }
            }
        }
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        let messageThreadId = messages[indexPath.row].threadId
        performSegueWithIdentifier(Storyboard.ShowMessageThreadSegue, sender: messageThreadId)
    }
    
    // MARK: UITableViewDataSource
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        var cell = tableView.dequeueReusableCellWithIdentifier(Storyboard.MessageCellIdentifier) as? MessageCell
        if cell == nil {
            cell = MessageCell(style: UITableViewCellStyle.Default, reuseIdentifier: Storyboard.MessageCellIdentifier)
        }

        let message = messages[indexPath.row]
        if let author = message.participants {
            UserPictureCache.sharedInstance.thumbnailById(author.id).onSuccess { image in
                cell?.userPictureImageView.image = image
            }.onFailure { error in
                cell?.userPictureImageView.image = UserPictureCache.defaultThumbnail
            }
            
            userRepository.findById(author.id).onSuccess() { user in
                cell?.usernameLabel.text = user.fullname
            }
        }

        cell?.lastMessageLabel.text = Utils.longDateFromTimestamp(message.lastUpdatedTimestamp)
        cell?.subjectLabel.text = messages[indexPath.row].subject
        
        cell?.sizeToFit()
        return cell!
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return messages.count
    }
}
