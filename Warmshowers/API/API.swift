//
//  API.swift
//  Warmshowers
//
//  Created by Michael Haeuslmann on 09/05/15.
//  Copyright (c) 2015 Michael Haeuslmann. All rights reserved.
//

import Alamofire
import SwiftyJSON
import BrightFutures

/// Warmshowers.org API
public class API
{
    /// Alamofire serves a singleton, but we want to be able to mock this
    var manager: Manager
    
    static let sharedInstance = API()
    
    private struct Paths {
        static let Login = "https://www.warmshowers.org/services/rest/user/login"
        static let Logout = "https://www.warmshowers.org/services/rest/user/logout"
        
        static let GetUser = "https://www.warmshowers.org/services/rest/user/"
        static let SearchByKeyword = "https://www.warmshowers.org/services/rest/hosts/by_keyword"
        static let SearchByLocation = "https://www.warmshowers.org/services/rest/hosts/by_location"
        
        static let GetPrivateMessages = "https://www.warmshowers.org/services/rest/message/get"
        static let GetUnreadMessagesCount = "https://www.warmshowers.org/services/rest/message/unreadCount"
        static let ReadMessageThread = "https://www.warmshowers.org/services/rest/message/getThread"
        static let MarkMessageThread = "https://www.warmshowers.org/services/rest/message/markThreadRead"
        static let SendMessage = "https://www.warmshowers.org/services/rest/message/send"
        static let ReplyMessage = "https://www.warmshowers.org/services/rest/message/reply"
        
        static let ReadFeedback = "https://www.warmshowers.org/user/%d/json_recommendations"
        static let CreateFeedback = "https://www.warmshowers.org/services/rest/node"
    }
    
    private struct Parameters {
        static let LoginUsername = "username"
        static let LoginPassword = "password"
        static let LogoutUsername = "username"
        static let LogoutPassword = "password"
        
        static let SearchKeyword = "keyword"
        static let SearchLimit = "limit"
        static let SearchPage = "page"
        static let SearchMinLatitude = "minlat"
        static let SearchMaxLatitude = "maxlat"
        static let SearchMinLongitude = "minlon"
        static let SearchMaxLongitude = "maxlon"
        static let SearchCenterLatitude = "centerlat"
        static let SearchCenterLongitude = "centerlon"
        
        static let FeedbackNodeType = "node[type]"
        static let FeedbackNodeTypeValue = "trust_referral"
        static let FeedbackUser = "node[field_member_i_trust][0][uid][uid]"
        static let FeedbackBody = "node[body]"
        static let FeedbackType = "node[field_guest_or_host][value]"
        static let FeedbackRating = "node[field_rating][value]"
        static let FeedbackYear = "node[field_hosting_date][0][value][year]"
        static let FeedbackMonth = "node[field_hosting_date][0][value][month]"
        
        static let MessageRecipients = "recipients"
        static let MessageSubject = "subject"
        static let MessageBody = "body"
        
        static let MessageThreadId = "thread_id"
        static let MessageThreadStatus = "status"
        static let MessageThreadStatusRead = 0
        static let MessageThreadStatusUnread = 1
        
    }
    
    public var loggedInUser: User?
    
    struct Status {
        static let AlreadyLoggedIn = 406
        static let LoginOk = 200
    }
    
    /**
        :param: manager Alamofire Manager
    */
    public init(manager: Manager = Alamofire.Manager.sharedInstance)
    {
        self.manager = manager
    }
    
    // MARK: Authentication API Methods
    
    /**
        Login a user.
    
        The login is cookie based. Alamofire is handling this in the background and there
        is nothing left to do on further requests. Trying to login while already logged in
        will produce an error and will *NOT* return the user object again. Because of this
        it is critical that the user object of the currently logged in user is safed on
        the first login.
    
        https://github.com/warmshowers/Warmshowers.org/wiki/Warmshowers-RESTful-Services-for-Mobile-Apps#wiki-login
    
        :param: username
        :param: password
    
        :returns: Future<User>
    */
    public func login(username: String, password: String) -> Future<User>
    {
        let promise = Promise<User>()
        
        let parameters = [
            Parameters.LoginUsername: username,
            Parameters.LoginPassword: password
        ]
        manager.request(.POST, Paths.Login, parameters: parameters)
            .responseJSON { (request, response, json, error) in
                if error != nil {
                    log.error(error?.description)
                    promise.failure(error!)
                } else {
                    if response?.statusCode == Status.LoginOk {
                        log.info("\(username) logged in with status \(response?.statusCode)")
                        var json = JSON(json!)
                        
                        let user = self.deserializeUserJson(json["user"])
                        user.password = password
                        self.loggedInUser = user
                        
                        promise.success(user)
                    } else if response?.statusCode == Status.AlreadyLoggedIn {
                        log.info("\(username) already logged in with status \(response?.statusCode)")
                        promise.failure(NSError(domain: "User already logged in", code: Status.AlreadyLoggedIn, userInfo: nil))
                    } else {
                        log.info("\(username) bad credentials with status \(response?.statusCode)")
                        promise.failure(NSError(domain: "User already logged in", code: Status.AlreadyLoggedIn, userInfo: nil))
                    }
                }
        }
        
        return promise.future
    }
    
    /**
        Logout a user.
    
        https://github.com/warmshowers/Warmshowers.org/wiki/Warmshowers-RESTful-Services-for-Mobile-Apps#wiki-logout
    
        :param: username
        :param: password
        
        :returns: Future<Bool>
    */
    public func logout(username: String, password: String) -> Future<Bool>
    {
        let promise = Promise<Bool>()
        
        let parameters = [
            Parameters.LogoutUsername: username,
            Parameters.LogoutPassword: password
        ]
        manager.request(.POST, Paths.Logout, parameters: parameters)
            .responseJSON { (request, response, json, error) in
                if error != nil {
                    log.error(error?.description)
                    promise.failure(error!)
                } else {
                    log.info("Logged out \(username) with status \(response?.statusCode)")
                    promise.success(true)
                }
        }
        
        return promise.future
    }
    
    // MARK: Search API Methods
    
    /**
        Get a single user by Id.
    
        https://github.com/warmshowers/Warmshowers.org/wiki/Warmshowers-RESTful-Services-for-Mobile-Apps#wiki-userretrieve
        
        :param: userId
        
        :return: Future<User>
    */
    public func getUser(userId: Int) -> Future<User>
    {
        let promise = Promise<User>()
        
        manager.request(.GET, "\(Paths.GetUser)\(userId)", parameters: nil)
            .responseJSON { (request, response, json, error) in
                if error != nil {
                    log.error(error?.description)
                    promise.failure(error!)
                } else {
                    log.info("Got user by id \(response?.statusCode)")
                    var json = JSON(json!)
                    promise.success(self.deserializeUserJson(json))
                }
        }
        
        return promise.future
    }
    
    /**
        Search for other user by keyword.
    
        The keyword can either be the username or email of a user or the name of a location.
    
        https://github.com/warmshowers/Warmshowers.org/wiki/Warmshowers-RESTful-Services-for-Mobile-Apps#wiki-bykeyword
    
        :param: keyword
        :param: limit Default: 4
        :param: page Default: 0
    
        :returns: Future<[Int:User]>
    */
    public func searchByKeyword(keyword: String, limit: Int = 4, page: Int = 0) -> Future<[Int:User]>
    {
        let promise = Promise<[Int:User]>()
        
        let parameters:[String:AnyObject] = [
            Parameters.SearchKeyword: keyword,
            Parameters.SearchLimit: limit,
            Parameters.SearchPage: page
        ]
        manager.request(.POST, Paths.SearchByKeyword, parameters: parameters)
            .responseJSON { (request, response, json, error) in
                if error != nil {
                    log.error(error?.description)
                    promise.failure(error!)
                } else {
                    log.info("Got hosts by keyword \(response?.statusCode)")
                    var json = JSON(json!)
                    var users = [Int:User]()
                    for (key: String, userJson: JSON) in json["accounts"] {
                        let uid = key.toInt()
                        let user = self.deserializeUserJson(userJson)
                        users[uid!] = user                      
                    }
                    promise.success(users)
                }
        }
        
        return promise.future
    }
    
    /**
        Search for users by location.
    
        https://github.com/warmshowers/Warmshowers.org/wiki/Warmshowers-RESTful-Services-for-Mobile-Apps#wiki-bylocation
        
        :params: minlat 
        :params: maxlat
        :params: minlon
        :params: maxlon
        :params: centerlat
        :params: centerlon
        :params: limit
    
        :returns: Future<[Int:User]>
    */
    public func searchByLocation(minlat: Double, maxlat: Double, minlon: Double, maxlon: Double, centerlat: Double, centerlon: Double, limit: Int) -> Future<[Int:User]>
    {
        let promise = Promise<[Int:User]>()
        
        let parameters: [String:AnyObject] = [
            Parameters.SearchMinLatitude: minlat,
            Parameters.SearchMaxLatitude: maxlat,
            Parameters.SearchMinLongitude: minlon,
            Parameters.SearchMaxLongitude: maxlon,
            Parameters.SearchCenterLatitude: centerlat,
            Parameters.SearchCenterLongitude: centerlon,
            Parameters.SearchLimit: limit
        ]
        manager.request(.POST, Paths.SearchByLocation, parameters: parameters)
            .responseJSON() { (request, response, json, error) in
                if error != nil {
                    log.error(error?.description)
                    promise.failure(error!)
                } else {
                    log.info("Got hosts by location \(response?.statusCode)")
                    var json = JSON(json!)
                    var users = [Int:User]()
                    for (key: String, userJson: JSON) in json["accounts"] {
                        let uid = key.toInt()!
                        let user = self.deserializeUserJson(userJson)
                        users[uid] = user
                    }
                    promise.success(users)
                }
        }
        return promise.future
    }

    // MARK: Feedback API Methods
    
    /**
        Get all the feedback of a user.
    
        https://github.com/warmshowers/Warmshowers.org/wiki/Warmshowers-RESTful-Services-for-Mobile-Apps#wiki-json_recommendations
    
        :param: userId User ID
    
        :returns: Future<[Feedback]>
    */
    func getFeedbackForUser(userId: Int) -> Future<[Feedback]>
    {
        let promise = Promise<[Feedback]>()
        
        let url = String(format: Paths.ReadFeedback, userId)
        manager
            .request(.GET, url, parameters: nil)
            .responseJSON() { (request, response, json, error) in
                if error != nil {
                    log.error(error?.description)
                    promise.failure(error!)
                } else {
                    var json = JSON(json!)
                    var feedback = [Feedback]()
                    for (key, feedbackJson) in json["recommendations"] {
                        feedback.append(self.deserializeFeedbackJson(feedbackJson["recommendation"]))
                    }
                    promise.success(feedback)
                }
            }
        
        return promise.future
    }
    
    /**
        Create new feedback for a user.
    
        https://github.com/warmshowers/Warmshowers.org/wiki/Warmshowers-RESTful-Services-for-Mobile-Apps#wiki-create_feedback
    
        :param: Feedback
    
        :returns: Future<Bool>
    */
    func createFeedbackForUser(feedback: Feedback) -> Future<Bool>
    {
        let promise = Promise<Bool>()
        
        let parameters: [String:AnyObject] = [
            Parameters.FeedbackNodeType: Parameters.FeedbackNodeTypeValue,
            Parameters.FeedbackUser: feedback.userForFeedback,
            Parameters.FeedbackBody: feedback.body,
            Parameters.FeedbackType: feedback.type,
            Parameters.FeedbackRating: feedback.rating,
            Parameters.FeedbackYear: feedback.year,
            Parameters.FeedbackMonth: feedback.month
        ]
        manager
            .request(.POST, Paths.CreateFeedback, parameters: parameters)
            .responseJSON() { (request, response, json, error) in
                if error != nil {
                    log.error(error?.description)
                    promise.failure(error!)
                } else {
                    promise.success(true)
                }
        }
        
        return promise.future
    }

    // MARK: Message API Methods
    
    /**
        Sends a private message to another user.
    
        Sending a message starts a new message thread (imagine GMail Conversations) and cannot be used for
        answering messages. Use the `replyMessage` for this purpose.
    
        https://github.com/warmshowers/Warmshowers.org/wiki/Warmshowers-RESTful-Services-for-Mobile-Apps#wiki-message_send
    
        :param: recipients
        :param: subject
        :param: body
    
        :returns: Future<Bool>
    */
    public func sendMessage(recipients: [User], subject: String, body: String) -> Future<Bool>
    {
        let promise = Promise<Bool>()
        let recipientsString = ",".join(recipients.map {$0.name})
        
        let parameters: [String:AnyObject] = [
            Parameters.MessageRecipients: recipientsString,
            Parameters.MessageSubject: subject,
            Parameters.MessageBody: body
        ]
        manager
            .request(.POST, Paths.SendMessage, parameters: parameters)
            .responseJSON() { (request, response, json, error) in
                if error != nil {
                    log.error(error?.description)
                    promise.failure(error!)
                } else {
                    promise.success(true)
                }
        }
        
        return promise.future
    }
    
    /**
        Reply to a message in a message thread.
    
        This is like sending a message, but for message threads that have already been created. Do not
        mix this and `sendMessage`.
    
        https://github.com/warmshowers/Warmshowers.org/wiki/Warmshowers-RESTful-Services-for-Mobile-Apps#wiki-privatemsg_reply
    
        :param: threadId
        :param: body
    
        :returns: Future<Bool>
    */
    public func replyMessage(threadId: Int, body: String) -> Future<Bool>
    {
        let promise =  Promise<Bool>()
        
        let parameters: [String:AnyObject] = [
            Parameters.MessageThreadId: threadId,
            Parameters.MessageBody: body
        ]
        manager
            .request(.POST, Paths.ReplyMessage, parameters: parameters)
            .responseJSON() { (request, response, json, error) in
                if error != nil {
                    log.error(error?.description)
                    promise.failure(error!)
                } else {
                    promise.success(true)
                }
        }
        
        return promise.future
    }
    
    /**
        Get the number of unread messages.
    
        This is quicker than getting all the messages and checking which are unread. Use when checking for new messages.
    
        https://github.com/warmshowers/Warmshowers.org/wiki/Warmshowers-RESTful-Services-for-Mobile-Apps#wiki-message_unread
    
        :returns: Future<Int>
    */
    public func getUnreadMessagesCount() -> Future<Int>
    {
        let promise = Promise<Int>()
        
        manager
            .request(.POST, Paths.GetUnreadMessagesCount, parameters: nil)
            .responseJSON() { (request, response, json, error) in
                if error != nil {
                    log.error(error?.description)
                    promise.failure(error!)
                } else {
                    var json = JSON(json!)
                    promise.success(json.intValue)
                }
        }

        return promise.future
    }
    
    /**
        Get all messages.
    
        This will return all message threads, but not the full thread itself.
    
        https://github.com/warmshowers/Warmshowers.org/wiki/Warmshowers-RESTful-Services-for-Mobile-Apps#wiki-message_get_all
    
        :returns: Future<Message>
    */
    public func getAllMessages() -> Future<[Message]>
    {
        let promise = Promise<[Message]>()
        
        manager
            .request(.POST, Paths.GetPrivateMessages, parameters: nil)
            .responseJSON() { (request, response, json, error) in
                if error != nil {
                    log.error(error?.description)
                    promise.failure(error!)
                } else {
                    var json = JSON(json!)
                    var messages = [Message]()
                    for (key, messageJson) in json {
                        messages.append(self.deserializeMessageJson(messageJson))
                    }
                    promise.success(messages)
                }
        }
        
        return promise.future
    }

    /**
        Get all full messages in a message thread.
    
        https://github.com/warmshowers/Warmshowers.org/wiki/Warmshowers-RESTful-Services-for-Mobile-Apps#wiki-message_get_thread
    
        :param: threadId
    */
    public func readMessageThread(threadId: Int) -> Future<MessageThread>
    {
        let promise = Promise<MessageThread>()
        
        manager
            .request(.POST, Paths.ReadMessageThread, parameters: [Parameters.MessageThreadId: threadId])
            .responseJSON() { (request, response, json, error) in
                if error != nil {
                    log.error(error?.description)
                    promise.failure(error!)
                } else {
                    var json = JSON(json!)
                    var messageThread = self.deserializeMessageThreadJson(json)
                    promise.success(messageThread)
                }
            }
        
        return promise.future
    }
    
    /**
        Mark message threads as read or unread.
    
        https://github.com/warmshowers/Warmshowers.org/wiki/Warmshowers-RESTful-Services-for-Mobile-Apps#wiki-markThreadRead
    
        :param: threadId
        :param: unread True if the message thread should be marked as unread or false if it should be marked read.
    
        :returns: Future<Bool>
    */
    public func markMessageThreadStatus(threadId: Int, unread: Bool) -> Future<Bool>
    {
        let promise = Promise<Bool>()
        
        let parameters: [String:AnyObject] = [
            Parameters.MessageThreadId: threadId,
            Parameters.MessageThreadStatus: unread
        ]
        manager
            .request(.POST, Paths.MarkMessageThread, parameters: parameters)
            .responseJSON() { (request, response, json, error) in
                if error != nil {
                    log.error(error?.description)
                    promise.failure(error!)
                } else {
                    var json = JSON(json!)
                    promise.success(json.boolValue)
                }
        }
        
        return promise.future
        
    }
    
    // MARK: Deserializers
    
    /**
        :param: json
    
        :returns: Message
    */
    private func deserializeMessageJson(json: JSON) -> Message
    {
        var users = [User]()
        for (key, user) in json["participants"] {
            users.append(User(uid: user["uid"].intValue, name: user["name"].stringValue))
        }
        
        var message = Message(
            threadId: json["thread_id"].intValue,
            subject: json["subject"].stringValue
        )
        
        message.participants = users
        message.count = json["count"].intValue
        message.isNew = json["is_new"].boolValue
        message.lastUpdatedTimestamp = json["last_updated"].intValue
        message.threadStartedTimestamp = json["thread_started"].intValue
        
        message.body = json["body"].string
        
        return message
    }
    
    /**
        :param: json
    
        :returns: Feedback
    */
    private func deserializeFeedbackJson(json: JSON) -> Feedback
    {
        let timestamp = json["field_hosting_date_value"].doubleValue
        let date = NSDate(timeIntervalSince1970: timestamp)
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components(.CalendarUnitYear | .CalendarUnitMonth, fromDate: date)
        let year = components.year
        let month = components.month

        return Feedback(
            userIdForFeedback: json["uid_1"].intValue,
            userForFeedback: json["name_1"].stringValue,
            body: json["body"].stringValue,
            year: year,
            month: month,
            rating: json["field_rating_value"].stringValue,
            type: json["field_guest_or_host_value"].stringValue
        )
    }
    
    /**
        :param: json
    
        :returns: MessageThread
    */
    private func deserializeMessageThreadJson(json: JSON) -> MessageThread
    {
        var messageThread = MessageThread(id: json["thread_id"].intValue)
        
        var participants = [User]()
        for (key, userJson) in json["participants"] {
            var user = User(uid: userJson["uid"].intValue, name: userJson["name"].stringValue)
            participants.append(user)
        }
                messageThread.participants = participants
        
        var messages = [Message]()
        for (key, messageJson) in json["messages"] {
            var message = Message(threadId: messageJson["thread_id"].intValue, subject: messageJson["subject"].stringValue)
            message.body = messageJson["body"].stringValue
            message.author = User(uid: messageJson["author"]["uid"].intValue, name: messageJson["author"]["name"].stringValue)
            messages.append(message)
        }
        messageThread.messages = messages
        
        var user = User(uid: json["user"]["uid"].intValue, name: json["user"]["name"].stringValue)
                messageThread.user = user
        
        messageThread.readAll = json["read_all"].boolValue
        messageThread.to = json["to"].intValue
        messageThread.messageCount = json["message_count"].intValue
        messageThread.from = json["from"].intValue
        messageThread.start = json["start"].intValue
        messageThread.subject = json["subject"].stringValue
        
        return messageThread
    }
    
    /**
        Deserializes the JSON user into a User object.
    
        // TODO: what if the JSON is messed up?
    
        :param: json JSON Swifty JSON data from the Alamofire request.
    
        :returns: User
    */
    public func deserializeUserJson(json: JSON) -> User
    {
        var user = User(
            uid: json["uid"].intValue,
            name: json["name"].stringValue
        )
        
        user.mode = json["mode"].intValue
        user.sort = json["sort"].intValue
        user.threshold = json["threshold"].intValue
        user.theme = json["theme"].intValue
        user.signature = json["signature"].intValue
        user.created = json["created"].intValue
        user.access = json["access"].intValue
        user.status = json["status"].intValue
        user.timezone = json["timezone"].intValue
        user.language = json["language"].stringValue
        user.picture = json["picture"].stringValue
        user.login = json["login"].intValue
        user.timezone_name = json["timezone_name"].stringValue
        user.signature_format = json["signature_format"].intValue
        user.force_password_change = json["force_password_change"].intValue
        user.fullname = json["fullname"].stringValue
        user.notcurrentlyavailable = json["notcurrentlyavailable"].intValue
        user.notcurrentlyavailable_reason = json["notcurrentlyavailable_reason"].stringValue
        user.fax_number = json["fax_number"].stringValue
        user.mobilephone = json["mobilephone"].stringValue
        user.workphone = json["workphone"].stringValue
        user.homephone = json["homephone"].stringValue
        user.preferred_notice = json["preferred_notice"].intValue
        user.cost = json["cost"].stringValue
        user.maxcyclists = json["maxcyclists"].intValue
        user.storage = json["storage"].intValue
        user.motel = json["motel"].stringValue
        user.campground = json["campground"].stringValue
        user.bikeshop = json["bikeshop"].stringValue
        user.comments = json["comments"].stringValue
        user.shower = json["shower"].intValue
        user.kitchenuse = json["kitchenuse"].intValue
        user.lawnspace = json["lawnspace"].intValue
        user.sag = json["sag"].intValue
        user.bed = json["bed"].intValue
        user.laundry = json["laundry"].intValue
        user.food = json["food"].intValue
        user.howdidyouhear = json["howdidyouhear"].stringValue
        user.lastcorrespondence = json["lastcorrespondence"].stringValue
        user.languagesspoken = json["languagesspoken"].stringValue
        user.URL = json["URL"].stringValue
        user.isstale = json["isstale"].intValue
        user.isstale_date = json["isstale_date"].intValue
        user.isstale_reason = json["isstale_reason"].stringValue
        user.isunreachable = json["isunreachable"].stringValue
        user.unreachable_date = json["unreachable_date"].stringValue
        user.unreachable_reason = json["unreachable_reason"].stringValue
        user.becomeavailable = json["becomeavailable"].intValue
        user.set_unavailable_timestamp = json["set_unavailable_timestamp"].intValue
        user.set_available_timestamp = json["set_available_timestamp"].intValue
        user.last_unavailability_pester  = json["last_unavailability_pester"].intValue
        user.hide_donation_status = json["hide_donation_status"].stringValue
        user.email_opt_out = json["email_opt_out"].intValue
        user.oid = json["oid"].intValue
        user.type = json["type"].intValue
        user.street = json["street"].stringValue
        user.additional = json["additional"].stringValue
        user.city = json["city"].stringValue
        user.province = json["province"].stringValue
        user.postal_code = json["postal_code"].intValue
        user.country = json["country"].stringValue
        user.latitude = json["latitude"].doubleValue
        user.longitude = json["longitude"].doubleValue
        user.source = json["source"].intValue
        user.node_notify_mailalert = json["node_notify_mailalert"].intValue
        user.comment_notify_mailalert = json["comment_notify_mailalert"].intValue
        
        return user
    }
}
