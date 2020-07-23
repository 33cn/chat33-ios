//
//  String+Tool.swift
//  Chat33
//
//  Created by 吴文拼 on 2018/9/19.
//  Copyright © 2018年 吴文拼. All rights reserved.
//

import Foundation
import BHURLHelper


extension String{
    
    static func dateString(with timestamp: Double) -> String {
        let date = Date(timeIntervalSince1970: timestamp / 1000)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        
        let dateString = formatter.string(from: date)
        let todayString = formatter.string(from: Date())
        formatter.dateFormat = "HH:mm"
        var resultDateString = formatter.string(from: date)
        guard let dateNumber = Int(dateString), let todayNumber = Int(todayString) else {
            return resultDateString
        }
        if dateNumber == todayNumber {
            // 上午下午待定
        } else if dateNumber == todayNumber - 1 {
            resultDateString = "昨天" + resultDateString
        } else {
            formatter.dateFormat = "yyyy/MM/dd"
            resultDateString = formatter.string(from: date)
        }
        return resultDateString
    }
    
    static func yyyyMMddDateString(with timestamp: Double) -> String {
        let date = Date(timeIntervalSince1970: timestamp / 1000)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: date)
    }
    static func yyyy_MM_dd_DateString(with timestamp: Double) -> String {
        let date = Date(timeIntervalSince1970: timestamp / 1000)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    static func mm_dd_DateString(with timestamp: Double) -> String {
        let date = Date.init(timeIntervalSince1970: timestamp / 1000)
        let formatter = DateFormatter.init()
        formatter.dateFormat = "MM.dd"
        return formatter.string(from: date)
    }
    
    static func showTimeString(with timestamp: Double) -> String {
        let date = Date(timeIntervalSince1970: timestamp / 1000)
        let formatter = DateFormatter()
        if date.isToday {
            formatter.dateFormat = "HH:mm"
        }else if date.isYesterday {
            formatter.dateFormat = "昨天HH:mm"
        }else if date.isTheYear {
            formatter.dateFormat = "M月d日 HH:mm"
        }else{
            formatter.dateFormat = "yyyy年M月d日 HH:mm"
        }
        
        return formatter.string(from: date)
    }
    
    static func showTimeString2(with timestamp: Double) -> String {
        let date = Date(timeIntervalSince1970: timestamp / 1000)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/M/d HH:mm"
        
        return formatter.string(from: date)
    }
    
    
    static func timeString(with timestamp: Double) -> String {
        let date = Date(timeIntervalSince1970: timestamp / 1000)
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
    
    //获取毫秒级的时间字符串
    static func getTimeStampStr() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddhhmmssSSS"
        return dateFormatter.string(from: Date())
    }
    
    //字符串转为utf8格式data
    var utf8Encoded: Data {
        return data(using: .utf8)!
    }
    
    static func getAppVersion() -> String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return ""
    }
    
    
    //字符串操作
    /// range转换为NSRange
    func nsRange(from range: Range<String.Index>) -> NSRange {
        return NSRange(range, in: self)
    }
    
    func nsRange(from string: String) -> NSRange {
        let range = self.range(of: string)
        return self.nsRange(from: range!)
    }
    
    /// NSRange转化为range
    func range(from nsRange: NSRange) -> Range<String.Index>? {
        guard
            let from16 = utf16.index(utf16.startIndex, offsetBy: nsRange.location, limitedBy: utf16.endIndex),
            let to16 = utf16.index(from16, offsetBy: nsRange.length, limitedBy: utf16.endIndex),
            let from = String.Index(from16, within: self),
            let to = String.Index(to16, within: self)
            else { return nil }
        return from ..< to
    }
    
    ///在字符串中查找另一字符串首次出现的位置（如果backwards参数设置为true，则返回最后出现的位置）
    func positionOf(sub:String, backwards:Bool = false)->Int {
        // 如果没有找到就返回-1
        var pos = -1
        if let range = range(of:sub, options: backwards ? .backwards : .literal ) {
            if !range.isEmpty {
                pos = self.distance(from:startIndex, to:range.lowerBound)
            }
        }
        return pos
    }
    
    /// 使用下标截取字符串 例: "示例字符串"[0..<2] 结果是 "示例"
    subscript (r: Range<Int>) -> String {
        get {
            if (r.lowerBound > count) || (r.upperBound > count) { return "截取超出范围" }
            let startIndex = self.index(self.startIndex, offsetBy: r.lowerBound)
            let endIndex = self.index(self.startIndex, offsetBy: r.upperBound)
            return String(self[startIndex..<endIndex])
        }
    }
    
    func substring(with nsRange : NSRange) -> String {
        return self.substring(from: nsRange.location, length: nsRange.length)
    }
    
    func substring(from: Int?, to: Int?) -> String {
        if let start = from {
            guard start < self.count else {
                return ""
            }
        }
        
        if let end = to {
            guard end >= 0 else {
                return ""
            }
        }
        
        if let start = from, let end = to {
            guard end - start >= 0 else {
                return ""
            }
        }
        
        let startIndex: String.Index
        if let start = from, start >= 0 {
            startIndex = self.index(self.startIndex, offsetBy: start)
        } else {
            startIndex = self.startIndex
        }
        
        let endIndex: String.Index
        if let end = to, end >= 0, end < self.count {
            endIndex = self.index(self.startIndex, offsetBy: end + 1)
        } else {
            endIndex = self.endIndex
        }
        
        return String(self[startIndex ..< endIndex])
    }
    
    func substring(from: Int) -> String {
        return self.substring(from: from, to: nil)
    }
    
    func substring(to: Int) -> String {
        return self.substring(from: nil, to: to)
    }
    
    func substring(from: Int?, length: Int) -> String {
        guard length > 0 else {
            return ""
        }
        
        let end: Int
        if let start = from, start > 0 {
            end = start + length - 1
        } else {
            end = length - 1
        }
        
        return self.substring(from: from, to: end)
    }
    
    func substring(length: Int, to: Int?) -> String {
        guard let end = to, end > 0, length > 0 else {
            return ""
        }
        
        let start: Int
        if let end = to, end - length > 0 {
            start = end - length + 1
        } else {
            start = 0
        }
        
        return self.substring(from: start, to: to)
    }
    
    func pathExtension() -> String {
        return (self as NSString).pathExtension as String
    }
    
    func lastPathComponent() -> String {
        return formatFileName()
    }
    
    func formatFileName() -> String {
        return (self as NSString).lastPathComponent as String
    }
    
    func fileName() -> String {
        let str = self.formatFileName()
        return (str as NSString).deletingPathExtension as String
    }
    
    //根据宽度获取需求尺寸的图片的下载地址
    func getDownloadUrlString(width: Int) -> String {
        return "\(self)?x-oss-process=image/resize,w_\(width*2)"
    }
    
    //获取拼音首字母（大写字母）
    func findFirstLetterFromString() -> String {
        //转变成可变字符串
        let mutableString = NSMutableString.init(string: self)
        //将中文转换成带声调的拼音
        CFStringTransform(mutableString as CFMutableString, nil, kCFStringTransformToLatin, false)
        //去掉声调
        let pinyinString = mutableString.folding(options: String.CompareOptions.diacriticInsensitive, locale: NSLocale.current)
        //将拼音首字母换成大写
        let strPinYin = pinyinString.uppercased()
        //截取大写首字母
        let firstString = strPinYin.substring(from: 0, to: 0)
        //判断首字母是否为大写
        let regexA = "^[A-Z]$"
        let predA = NSPredicate.init(format: "SELF MATCHES %@", regexA)
        return predA.evaluate(with: firstString) ? firstString : "#"
    }
    //文字转为拼音
    func findAllLetterFromString() -> String {
        //转变成可变字符串
        let mutableString = NSMutableString.init(string: self)
        //将中文转换成带声调的拼音
        CFStringTransform(mutableString as CFMutableString, nil, kCFStringTransformToLatin, false)
        //去掉声调
        let pinyinString = mutableString.folding(options: String.CompareOptions.diacriticInsensitive, locale: NSLocale.current)
        //将拼音首字母换成小写
        let strPinYin = pinyinString.lowercased()
        return strPinYin
    }
    
    var urlParameter : [String : AnyObject]? {
        let str = self as NSString
        guard let param = str.parseURLParameters() as? [String : AnyObject] else { return nil }
        return param
    }
    
    //获取内容size
    func getContentSize(size: CGSize, font: UIFont) -> CGSize {
        if self.count == 0 {
            return CGSize.zero
        }
        return (self as NSString).boundingRect(with: size, options: NSStringDrawingOptions(rawValue: NSStringDrawingOptions.usesLineFragmentOrigin.rawValue | NSStringDrawingOptions.usesFontLeading.rawValue), attributes: [.font: font], context: nil).size
    }
    func getContentHeight(width: CGFloat, font: UIFont) -> CGFloat {
        return self.getContentSize(size: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude), font: font).height
    }
    func getContentWidth(height: CGFloat, font: UIFont) -> CGFloat {
        return self.getContentSize(size: CGSize(width: CGFloat.greatestFiniteMagnitude, height: height), font: font).width
    }
    
    static func transToHourMinSec(time: Double) -> String
    {
        let allTime: Int = Int(time)
        var hours = 0
        var minutes = 0
        var seconds = 0
        var hoursText = ""
        var minutesText = ""
        var secondsText = ""
        
        hours = allTime / 3600
        hoursText = hours > 9 ? "\(hours)" : "0\(hours)"
        
        minutes = allTime % 3600 / 60
        minutesText = minutes > 9 ? "\(minutes)" : "0\(minutes)"
        
        seconds = allTime % 3600 % 60
        secondsText = seconds > 9 ? "\(seconds)" : "0\(seconds)"
        if hours == 0 {
            return "\(minutesText):\(secondsText)"
        }
        return "\(hoursText):\(minutesText):\(secondsText)"
    }
    
    static func getStringFrom(double doubleVal: Double) -> String? {
        let formatter = NumberFormatter()
        formatter.usesSignificantDigits = true;
        formatter.maximumSignificantDigits = 100
        formatter.groupingSeparator = "";
        formatter.numberStyle = .decimal
        let stringValue = formatter.string(from: NSNumber.init(value: doubleVal));
        return stringValue
    }
    
    func isIncludeChinese() -> Bool {
        
        for (_, value) in self.enumerated() {
            
            if ("\u{4E00}" <= value  && value <= "\u{9FA5}") {
                return true
            }
        }
        
        return false
    }
}

extension String{
    static let random_hex_str_characters = "0123456789abcdefABCDEF"
    static func randomHexStr(len : Int) -> String{
        var ranStr = ""
        for _ in 0..<len {
            let index = Int(arc4random_uniform(UInt32(random_hex_str_characters.count)))
            ranStr.append(random_hex_str_characters[random_hex_str_characters.index(random_hex_str_characters.startIndex, offsetBy: index)])
        }
        return ranStr
    }
    
    static let random_str_characters = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    static func randomStr(len : Int) -> String{
        var ranStr = ""
        for _ in 0..<len {
            let index = Int(arc4random_uniform(UInt32(random_str_characters.count)))
            ranStr.append(random_str_characters[random_str_characters.index(random_str_characters.startIndex, offsetBy: index)])
        }
        return ranStr
    }
}

extension String {
    func isURL() -> Bool {
        let predicateStr = "^(https?://)?(www\\.)?([-a-z0-9]{1,63}\\.)*?[a-z0-9][-a-z0-9]{0,61}[a-z0-9]\\.[a-z]{2,6}(/[-\\w@\\+\\.~#\\?&/=%]*)?$"
        let predicate =  NSPredicate(format: "SELF MATCHES %@" ,predicateStr)
        return predicate.evaluate(with: self)
    }
}
//去除浮点字符串后面的无效0
extension String {
    var numberStringWithoutZero:String{
        get{
            guard let _ = Double(self) else {return "0"}
            guard self.contains(".") else {return self}
            var str = self
            while str.hasSuffix("0") {
                str.removeLast()
            }
            
            if str.hasSuffix(".") {
                str.removeLast()
            }
            
            return str
        }
    }
}


extension String {
    func isEncryptMedia() -> Bool {
        return self.contains("%24ENC%24")
    }
    
    static func getEncryptStringPrefix() -> String {
        return "+3581F5OXkN@SqquE!foUh"
    }
    
    func isEncryptString() -> Bool {
        return self.contains(String.getEncryptStringPrefix())
    }
}
