//: Playground - noun: a place where people can play

import UIKit

var str = "James William O'Brien "

let c = str.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: " ")).componentsSeparatedByString(" ")
let i = c.filter({ (s) -> Bool in !s.isEmpty }).map { (s : String) in s[s.startIndex]}
i

String(i)

let f = { (a, b) in return a > b }
f