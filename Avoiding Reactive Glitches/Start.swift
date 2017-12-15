////: Playground - noun: a place where people can play
//
//import Foundation
//
//typealias Token = Int
//
//struct Register<A> {
//    private var items: [Token:A] = [:]
//    private let freshNumber: () -> Int
//    init() {
//        var iterator = (0...).makeIterator()
//        freshNumber = { iterator.next()! }
//    }
//    
//    @discardableResult
//    mutating func add(_ value: A) -> Token {
//        let token = freshNumber()
//        items[token] = value
//        return token
//    }
//    
//    mutating func remove(_ token: Token) {
//        items[token] = nil
//    }
//    
//    subscript(token: Token) -> A? {
//        return items[token]
//    }
//    
//    var values: AnySequence<A> {
//        return AnySequence(items.values)
//    }
//    
//    mutating func removeAll() {
//        items = [:]
//    }
//    
//    var keys: AnySequence<Token> {
//        return AnySequence(items.keys)
//    }
//}
//
//final class Observer {
//    let _height: () -> Int
//    let fire: () -> ()
//    var cancelled = false
//    
//    init(fire: @escaping () -> (), height: @escaping () -> Int) {
//        self.fire = fire
//        self._height = height
//    }
//    var height: Int {
//        return _height()
//    }
//}
//
//final class Queue {
//    var observers: [Observer] = []
//    static let shared = Queue()
//    var isProcessing = false
//    
//    func enqueue(_ newObservers: [Observer]) {
//        observers.append(contentsOf: newObservers)
//        observers.sort { $0.height < $1.height }
//        process()
//    }
//    
//    func process() {
//        guard !isProcessing else { return }
//        isProcessing = true
//        while let observer = observers.popLast() {
//            guard !observer.cancelled else { continue }
//            observer.fire()
//        }
//        isProcessing = false
//    }
//}
//
//class Observable<A> {
//    typealias Observers = Register<Observer>
//    private var observers: Observers = Observers()
//    var debugInfo: String
//    
//    var value: A
//    
//    init(_ value: A, debugInfo: String = "Observable") {
//        self.value = value
//        self.debugInfo = debugInfo
//    }
//    
//    func send(_ value: A) {
//        self.value = value
//        Queue.shared.enqueue(Array(observers.values))
//    }
//    
//    @discardableResult func observe(_ observer: @escaping (A) -> ()) -> Token {
//        observer(value)
//        return observers.add(Observer(fire: {
//            observer(self.value)
//        }, height: {
//            return 0
//        }))
//    }
//    
//    func stopObserving(_ token: Token) {
//        observers[token]?.cancelled = true
//        observers.remove(token)
//    }
//    
//    var height: Int {
//        let maxChildHeight = observers.values.map { $0.height }.max()
//        return (maxChildHeight ?? 0) + 1
//    }
//    
//    @discardableResult func addChild<A>(fire: @escaping () -> (), dependent: @escaping () -> Observable<A>) -> Token {
//        fire()
//        return observers.add(Observer(fire: fire, height: {
//            dependent().height
//        }))
//    }
//    
//    func map<B>(_ f: @escaping (A) -> B) -> Observable<B> {
//        let result = Observable<B>(f(value))
//        addChild(fire: {
//            result.send(f(self.value))
//        }, dependent: {
//            result
//        })
//        return result
//    }
//    
//    func flatMap<B>(_ f: @escaping (A) -> Observable<B>) -> Observable<B> {
//        var currentBody = f(value)
//        currentBody.debugInfo = "\(self).flatMap body"
//        let result = Observable<B>(f(value).value)
//        var token: Token?
//        addChild(fire: {
//            if let t = token {
//                currentBody.stopObserving(t)
//            }
//            currentBody = f(self.value)
//            token = currentBody.addChild(fire: {
//                result.send(currentBody.value)
//            }, dependent: {
//                result
//            })
//        }, dependent: {
//            currentBody
//        })
//        return result
//    }
//}
//
//extension Observable: CustomDebugStringConvertible {
//    var debugDescription: String {
//        return debugInfo
//    }
//}
//
//func &&(lhs: Observable<Bool>, rhs: Observable<Bool>) -> Observable<Bool> {
//    return lhs.flatMap { [unowned lhs] l in
//        let body = rhs.map { $0 && l }
//        body.debugInfo = "\(lhs).flatMap body: \(rhs).map { $0 && l }"
//        return body
//    }
//}
//
//func test() {
//    let airplaneMode = Observable<Bool>(false, debugInfo: "airplaneMode")
//    let cellular = Observable<Bool>(true, debugInfo: "cellular")
//    let wifi = Observable<Bool>(true, debugInfo: "wifi")
//    
//    let notAirplaneMode = airplaneMode.map { !$0 }
//    notAirplaneMode.debugInfo = "notAirplaneMode"
//    
//    let cellularEnabled = notAirplaneMode && cellular
//    cellularEnabled.debugInfo = "cellularEnabled"
//    let wifiEnabled = notAirplaneMode && wifi
//    wifiEnabled.debugInfo = "wifiEnabled"
//    let wifiAndCellular = wifiEnabled && cellularEnabled
//    wifiAndCellular.debugInfo = "wifiAndCellular"
//    
//    let foo = wifiAndCellular.observe { print($0) }
//    print("---")
//    airplaneMode.send(true)
//    print("---")
//    airplaneMode.send(false)
//}
//
//test()
//
//print("done")
//
//
//
//
