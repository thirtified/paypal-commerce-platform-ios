#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface BTPayPalValidatorResult : NSObject

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

/**
Order ID associated with the checkout
*/
@property (nonatomic, copy) NSString *orderID;

/**
Payment method type of the checkout
*/
@property (nonatomic, assign) BTPayPalValidatorResultType type;

@end

NS_ASSUME_NONNULL_END
