//: Playground - noun: a place where people can play

import Foundation

typealias Token = Int

final class Register<A> {
    private var items: [Token:A] = [:]
    private let freshNumber: () -> Int
    init() {
        var iterator = (0...).makeIterator()
        freshNumber = { iterator.next()! }
    }

    @discardableResult
    func add(_ value: A) -> Token {
        let token = freshNumber()
        items[token] = value
        return token
    }

    func remove(_ token: Token) {
        let tmp = items[token]
        items[token] = nil
    }

    subscript(token: Token) -> A? {
        return items[token]
    }

    var values: AnySequence<A> {
        return AnySequence(items.values)
    }

    func removeAll() {
        items = [:]
    }

    var keys: AnySequence<Token> {
        return AnySequence(items.keys)
    }
}

final class Observer {
    let _height: () -> Int
    let fire: () -> ()

    init(fire: @escaping () -> (), height: @escaping () -> Int) {
        self.fire = fire
        self._height = height
    }
    var height: Int {
        return _height()
    }
}

final class Weak<A: AnyObject> {
    weak var value: A?
    
    init(_ value: A) {
        self.value = value
    }
}

final class Queue {
    var observers: [Weak<Observer>] = []
    static let shared = Queue()
    var isProcessing = false

    func enqueue(_ newObservers: [Observer]) {
        observers.append(contentsOf: newObservers.map { Weak($0) })
        observers.sort { ($0.value?.height ?? 0) < ($1.value?.height ?? 0) }
    }

    func process() {
        guard !isProcessing else { return }
        isProcessing = true
        while let observer = observers.popLast()?.value {
            observer.fire()
        }
        isProcessing = false
    }
}

final class Disposable {
    private let dispose: () -> ()
    init(_ dispose: @escaping () -> ()) {
        self.dispose = dispose
    }
    
    deinit {
        dispose()
    }
}

class Observable<A> {
    typealias Observers = Register<Observer>
    private var observers: Observers = Observers()
    var debugInfo: String

    var value: A

    init(_ value: A, debugInfo: String = "Observable") {
        self.value = value
        self.debugInfo = debugInfo
    }

    func send(_ value: A) {
        self.value = value
        Queue.shared.enqueue(Array(observers.values))
        Queue.shared.process()
    }

    @discardableResult func observe(_ observer: @escaping (A) -> ()) -> Token {
        observer(value)
        return observers.add(Observer(fire: { [unowned self] in
            observer(self.value)
        }, height: {
            return 0
        }))
    }

    var height: Int {
        let maxChildHeight = observers.values.map { $0.height }.max()
        return (maxChildHeight ?? 0) + 1
    }

    @discardableResult func addChild<A>(fire: @escaping () -> (), dependent: @escaping () -> Observable<A>) -> Disposable {
        fire()
        let token = observers.add(Observer(fire: fire, height: {
            dependent().height
        }))
        return Disposable {
            self.observers.remove(token)
        }
    }

    var strongReferences: [Any] = []
    
    func map<B>(_ f: @escaping (A) -> B) -> Observable<B> {
        let result = Observable<B>(f(value))
        let disposable = addChild(fire: { [unowned self, unowned result] in
            result.send(f(self.value))
        }, dependent: { [unowned result] in
            result
        })
        result.strongReferences.append(disposable)
        return result
    }

    func flatMap<B>(_ f: @escaping (A) -> Observable<B>) -> Observable<B> {
        var currentBody = f(value)
        currentBody.debugInfo = "\(self).flatMap body"
        let result = Observable<B>(f(value).value)
        var bodyDisposable: Disposable?
        let disposable = addChild(fire: { [unowned self, unowned result] in
            bodyDisposable = nil
            currentBody = f(self.value)
            bodyDisposable = currentBody.addChild(fire: { [unowned currentBody, unowned result] in
                result.send(currentBody.value)
            }, dependent: { [unowned result] in
                result
            })
        }, dependent: {
            currentBody
        })
        result.strongReferences.append(disposable)
        return result
    }
}

extension Observable: CustomDebugStringConvertible {
    var debugDescription: String {
        return debugInfo
    }
}

func &&(lhs: Observable<Bool>, rhs: Observable<Bool>) -> Observable<Bool> {
    return lhs.flatMap { [unowned lhs] l in
        let body = rhs.map { $0 && l }
        body.debugInfo = "\(lhs).flatMap body: \(rhs).map { $0 && l }"
        return body
    }
}

func test() {
    let airplaneMode = Observable<Bool>(false, debugInfo: "airplaneMode")
    let cellular = Observable<Bool>(true, debugInfo: "cellular")
    let wifi = Observable<Bool>(true, debugInfo: "wifi")

    let notAirplaneMode = airplaneMode.map { !$0 }
    notAirplaneMode.debugInfo = "notAirplaneMode"

    let cellularEnabled = notAirplaneMode && cellular
    cellularEnabled.debugInfo = "cellularEnabled"
    let wifiEnabled = notAirplaneMode && wifi
    wifiEnabled.debugInfo = "wifiEnabled"
    let wifiAndCellular = wifiEnabled && cellularEnabled
    wifiAndCellular.debugInfo = "wifiAndCellular"

    let disposable = wifiAndCellular.observe { print($0) }
    print("---")
    airplaneMode.send(true)
    print("---")
    airplaneMode.send(false)
}

test()

func test2() {
    let x = Observable(1)
    let sum = x.flatMap { value in x.map { value + $0 }}
    let disposable = sum.observe { print($0) }
    x.send(2)
}

test2()




