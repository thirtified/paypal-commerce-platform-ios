import PayPalCommercePlatform

class PayPalUATTestHelper {
    
    static func encodeUAT(_ dict: [String : Any]) -> String {
        let data = try! JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
        return "123.\(data.base64EncodedString().replacingOccurrences(of: "=", with: "")).456"
    }
}
