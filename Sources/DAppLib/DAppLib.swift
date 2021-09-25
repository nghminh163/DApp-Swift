import Foundation
import WalletConnectSwift

public protocol WalletConnectDelegate {
    func failedToConnect()
    func didConnect(wcURI: String)
    func didConnect()
    func didDisconnect()
}

public class DAppLib {
    public var client: Client!
    public var session: Session!
    var delegate: WalletConnectDelegate
    
    
    let sessionKey = "sessionKey"
    
    public init(delegate: WalletConnectDelegate) {
        self.delegate = delegate
    }
    
    public func connect() {
        // gnosis wc bridge: https://safe-walletconnect.gnosis.io/
        // test bridge with latest protocol version: https://bridge.walletconnect.org
        let wcUrl =  WCURL(topic: UUID().uuidString,
                           bridgeURL: URL(string: "https://u.bridge.walletconnect.org")!,
                           key: try! randomKey())
        let clientMeta = Session.ClientMeta(name: "ExampleDApp",
                                            description: "WalletConnectSwift ",
                                            icons: [],
                                            url: URL(string: "https://safe.gnosis.io")!)
        let dAppInfo = Session.DAppInfo(peerId: UUID().uuidString, peerMeta: clientMeta)
        client = Client(delegate: self, dAppInfo: dAppInfo)
        
        print("WalletConnect URL: \(wcUrl.absoluteString)")
        
        try! client.connect(to: wcUrl)
    }
    
    public func reconnectIfNeeded() {
        if let oldSessionObject = UserDefaults.standard.object(forKey: sessionKey) as? Data,
           let session = try? JSONDecoder().decode(Session.self, from: oldSessionObject) {
            client = Client(delegate: self, dAppInfo: session.dAppInfo)
            try? client.reconnect(to: session)
        }
    }
    
    // https://developer.apple.com/documentation/security/1399291-secrandomcopybytes
    private func randomKey() throws -> String {
        var bytes = [Int8](repeating: 0, count: 32)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        if status == errSecSuccess {
            return Data(bytes: bytes, count: 32).toHexString()
        } else {
            // we don't care in the example app
            enum TestError: Error {
                case unknown
            }
            throw TestError.unknown
        }
    }
}

extension DAppLib: ClientDelegate {
    public func client(_ client: Client, didFailToConnect url: WCURL) {
        delegate.failedToConnect()
    }
    
    public func client(_ client: Client, didConnect url: WCURL) {
        delegate.didConnect(wcURI: url.absoluteString)
    }
    
    public func client(_ client: Client, didConnect session: Session) {
        self.session = session
        let sessionData = try! JSONEncoder().encode(session)
        UserDefaults.standard.set(sessionData, forKey: sessionKey)
        delegate.didConnect()
    }
    
    public func client(_ client: Client, didDisconnect session: Session) {
        UserDefaults.standard.removeObject(forKey: sessionKey)
        delegate.didDisconnect()
    }
    
    public func client(_ client: Client, didUpdate session: Session) {
        // do nothing
    }
}
