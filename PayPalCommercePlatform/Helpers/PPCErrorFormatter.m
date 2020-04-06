#import "PPCErrorFormatter.h"
#import "PPCValidatorClient.h"

@implementation PPCErrorFormatter

+ (NSError *)convertToPPCError:(NSError *)error withDomain:(NSString *)errorDomain {
    NSError *ppcError = [[NSError alloc] initWithDomain:([error.domain hasPrefix:@"PPC"]
                                                         ? error.domain : PPCValidatorErrorDomain)
                                                   code:0
                                               userInfo:@{NSLocalizedDescriptionKey:
                                                              error.localizedDescription ?: @"An error occured completing the checkout."}];
    return ppcError;
}

@end
