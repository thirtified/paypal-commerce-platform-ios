#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
Result type
*/
typedef NS_ENUM(NSInteger, BTPayPalValidatorResultType) {
    /// Card
    BTPayPalValidatorResultTypeCard = 0,

    /// PayPal
    BTPayPalValidatorResultTypePayPal,

    /// ApplePay
    BTPayPalValidatorResultTypeApplePay,
};

@interface BTPayPalValidatorResult : NSObject

@property (nonatomic, copy) NSString *orderID;

@property (nonatomic, assign) BTPayPalValidatorResultType type;

@end

NS_ASSUME_NONNULL_END
