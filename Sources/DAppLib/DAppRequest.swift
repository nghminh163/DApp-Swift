import Foundation
import WalletConnectSwift
import UIKit

public class DAppRequest{
    
    public var client: Client!
    public var session: Session!
    public var delegate:UIViewController!
    public init(_delegate:UIViewController,_client: Client, _session:Session) {
        self.client = _client
        self.session=_session
        self.delegate=_delegate
    }
    
    public func disconnect(){
        guard let session = session else { return }
        try? client.disconnect(from: session)
    }
    
    private func nonceRequest() -> Request {
        return .eth_getTransactionCount(url: session.url, account: session.walletInfo!.accounts[0])
    }
    
    private func nonce(from response: Response) -> String? {
        return try? response.result(as: String.self)
    }
    
    
    
    var walletAccount: String {
        return session.walletInfo!.accounts[0]
    }
    
    
    public func sendTransaction(to:String, gas:String?, gasPrice:String?, value:String){
        let transaction = transaction(from: self.walletAccount, to:to, gas: gas, gasPrice:gasPrice, value:value)
        try? self.client.eth_sendTransaction(url: session.url, transaction: transaction) { [weak self] response in
            self?.handleReponse(response, expecting: "Hash")
        }
    }
    
    
    private func transaction(from address: String,to:String, gas:String?, gasPrice:String?, value:String) -> Client.Transaction {
        return Client.Transaction(from: address,
                                  to:to,
                                  data:"",
                                  gas: gas,
                                  gasPrice: gasPrice,
                                  value: value,
                                  nonce: nil,
                                  type: nil,
                                  accessList: nil,
                                  chainId: nil,
                                  maxPriorityFeePerGas: nil,
                                  maxFeePerGas: nil)
    }
    
    private func handleReponse(_ response: Response, expecting: String) {
        if let error = response.error {
            show(UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert))
            return
        }
        do {
            let result = try response.result(as: String.self)
            show(UIAlertController(title: expecting, message: result, preferredStyle: .alert))
        } catch {
            show(UIAlertController(title: "Error",
                                   message: "Unexpected response type error: \(error)",
                                   preferredStyle: .alert))
        }
    }
    
    private func show(_ alert: UIAlertController) {
        alert.addAction(UIAlertAction(title: "Close", style: .cancel))
        DispatchQueue.main.async {
            self.delegate.present(alert, animated: true)
        }
    }
    
}

extension Request {
    static func eth_getTransactionCount(url: WCURL, account: String) -> Request {
        return try! Request(url: url, method: "eth_getTransactionCount", params: [account, "latest"])
    }
    
    static func eth_gasPrice(url: WCURL) -> Request {
        return Request(url: url, method: "eth_gasPrice")
    }
}
