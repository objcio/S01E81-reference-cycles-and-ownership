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
//final class Weak<A: AnyObject> {
//    weak var unbox: A?
//    init(_ value: A) {
//        unbox = value
//    }
//}
//
//final class Queue {
//    var observers: [Weak<Observer>] = []
//    static let shared = Queue()
//    var isProcessing = false
//    
//    func enqueue(_ newObservers: [Observer]) {
//        observers.append(contentsOf: newObservers.map(Weak.init))
//        observers.sort { ($0.unbox?.height ?? 0) < ($1.unbox?.height ?? 0) }
//        process()
//    }
//    
//    func process() {
//        guard !isProcessing else { return }
//        isProcessing = true
//        while let observer = observers.popLast()?.unbox {
//            observer.fire()
//        }
//        isProcessing = false
//    }
//}
//
//final class Disposable {
//    let dispose: () -> ()
//    init(_ dispose: @escaping () -> ()) {
//        self.dispose = dispose
//    }
//    deinit {
//        dispose()
//    }
//}
//
//class Observable<A> {
//    typealias Observers = Register<Observer>
//    private var observers: Observers = Observers()
//    private var strongReferences: [Any] = []
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
//    @discardableResult func observe(_ observer: @escaping (A) -> ()) -> Disposable {
//        observer(value)
//        let token =  observers.add(Observer(fire: { [unowned self] in
//            observer(self.value)
//            }, height: {
//                return 0
//        }))
//        return Disposable { self.observers.remove(token) }
//    }
//    
//    func stopObserving(_ token: Token) {
//        observers.remove(token)
//    }
//    
//    var height: Int {
//        let maxChildHeight = observers.values.map { $0.height }.max()
//        return (maxChildHeight ?? 0) + 1
//    }
//    
//    @discardableResult func addChild<A>(fire: @escaping () -> (), dependent: @escaping () -> Observable<A>) -> Disposable {
//        fire()
//        let token = observers.add(Observer(fire: fire, height: {
//            dependent().height
//        }))
//        return Disposable { self.observers.remove(token) }
//    }
//    
//    func map<B>(_ f: @escaping (A) -> B) -> Observable<B> {
//        let result = Observable<B>(f(value))
//        let disposable = addChild(fire: { [unowned self, unowned result] in
//            result.send(f(self.value))
//            }, dependent: { [unowned result] in
//                result
//        })
//        result.strongReferences.append(disposable)
//        return result
//    }
//    
//    func flatMap<B>(_ f: @escaping (A) -> Observable<B>) -> Observable<B> {
//        var currentBody = f(value)
//        currentBody.debugInfo = "\(self).flatMap body"
//        let result = Observable<B>(f(value).value)
//        var bodyDisposable: Disposable?
//        let disposable = addChild(fire: { [unowned self, unowned result] in
//            bodyDisposable = nil
//            currentBody = f(self.value)
//            bodyDisposable = currentBody.addChild(fire: { [unowned currentBody] in
//                result.send(currentBody.value)
//                }, dependent: {
//                    result
//            })
//            }, dependent: {
//                currentBody
//        })
//        result.strongReferences.append(disposable)
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
