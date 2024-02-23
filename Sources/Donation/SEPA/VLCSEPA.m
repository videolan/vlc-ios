/*****************************************************************************
 * VLCSEPA.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2024 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCSEPA.h"

@implementation VLCSEPA

+ (BOOL)isAvailable
{
    NSLocale *locale = [NSLocale currentLocale];
    NSString *currentCountryCode = [locale objectForKey:NSLocaleCountryCode];
    NSArray *supportedCountries = @[@"AT", @"BE", @"HR", @"CY", @"EE", @"FI", @"FR", @"DE", @"GR", @"IE", @"IT", @"LV", @"LT", @"LU", @"MT", @"NL", @"PT", @"SK", @"SI", @"ES", @"BG", @"CZ", @"DK", @"HU", @"PL", @"RO", @"SE", @"IS", @"LI", @"NO", @"CH", @"AD", @"MC", @"SM", @"VA"];
    for (NSString *countryCode in supportedCountries) {
        if ([countryCode isEqualToString:currentCountryCode]) {
            if ([VLCSEPA authorizationTextForCurrentLocale] != nil) {
                APLog(@"Country %@ qualifies for SEPA, Authorization text is available, SEPA payment permitted.", countryCode);
                return YES;
            }
            APLog(@"Country %@ qualifies for SEPA, but no authorization text is available. Rejected.", countryCode);
            return NO;
        }
    }
    APLog(@"Country %@ not qualified for SEPA", currentCountryCode);
    return NO;
}

+ (NSString *)authorizationTextForCurrentLocale
{
    NSString *languageCode = [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode];
    NSDictionary *authorizationTexts = @{
        @"en" : @"By providing your payment information and confirming this payment, you authorise (A) VideoLAN and Stripe, our payment service provider, to send instructions to your bank to debit your account and (B) your bank to debit your account in accordance with those instructions. As part of your rights, you are entitled to a refund from your bank under the terms and conditions of your agreement with your bank. A refund must be claimed within 8 weeks starting from the date on which your account was debited. Your rights are explained in a statement that you can obtain from your bank. You agree to receive notifications for future debits up to 2 days before they occur.",
        @"de" : @"Durch Angabe Ihrer Zahlungsinformationen und der Bestätigung der vorliegenden Zahlung ermächtigen Sie (A) VideoLAN und Stripe, unseren Zahlungsdienstleister, Ihrem Kreditinstitut Anweisungen zur Belastung Ihres Kontos zu erteilen, und (B) Ihr Kreditinstitut, Ihr Konto gemäß diesen Anweisungen zu belasten. Im Rahmen Ihrer Rechte haben Sie, entsprechend den Vertragsbedingungen mit Ihrem Kreditinstitut, Anspruch auf eine Rückerstattung von Ihrem Kreditinstitut. Eine Rückerstattung muss innerhalb von 8 Wochen ab dem Tag, an dem Ihr Konto belastet wurde, geltend gemacht werden. Eine Erläuterung Ihrer Rechte können Sie von Ihrem Kreditinstitut anfordern. Sie erklären sich einverstanden, Benachrichtigungen über künftige Belastungen bis spätestens 2 Tage vor dem Buchungsdatum zu erhalten.",
        @"es" : @"Al proporcionar sus datos de pago y confirmar este pago, usted autoriza a (A) VideoLAN y Stripe, nuestro proveedor de servicios de pago, a enviar instrucciones a su banco para realizar un débito en su cuenta y (B) a su banco a realizar un cargo en su cuenta de conformidad con dichas instrucciones. Como parte de sus derechos, usted tiene derecho a un reembolso de su banco conforme a los términos y condiciones del contrato con su banco. El reembolso debe reclamarse en un plazo de 8 semanas a partir de la fecha en la que se haya efectuado el cargo en su cuenta. Sus derechos se explican en un extracto que puede obtener en su banco. Usted acepta recibir notificaciones de futuros débitos hasta 2 días antes de que se produzcan.",
        @"fi" : @"Antamalla maksutiedot ja vahvistamalla tämän maksun, valtuutat (A) VideoLAN ja Stripen, maksupalveluntarjoajamme, lähettämään ohjeet pankille tilisi veloittamiseksi ja (B) pankkisi veloittamaan tiliäsi kyseisten ohjeiden mukaisesti. Oikeuksiesi mukaisesti olet oikeutettu maksun palautukseen pankilta, kuten heidän kanssaan tekemässäsi sopimuksessa ja sen ehdoissa on kuvattu. Maksun palautus on lunastettava 8 viikon aikana alkaen päivästä, jolloin tiliäsi veloitettiin. Oikeutesi on selitetty pankilta saatavissa olevassa lausunnossa. Hyväksyt vastaanottamaan ilmoituksia tulevista veloituksista jopa kaksi päivää ennen niiden tapahtumista.",
        @"fr" : @"En fournissant vos informations de paiement et en confirmant ce paiement, vous autorisez (A) VideoLAN et Stripe, notre prestataire de services de paiement et/ou PPRO, son prestataire de services local, à envoyer des instructions à votre banque pour débiter votre compte et (B) votre banque à débiter votre compte conformément à ces instructions. Vous avez, entre autres, le droit de vous faire rembourser par votre banque selon les modalités et conditions du contrat conclu avec votre banque. La demande de remboursement doit être soumise dans un délai de 8 semaines à compter de la date à laquelle votre compte a été débité. Vos droits sont expliqués dans une déclaration disponible auprès de votre banque. Vous acceptez de recevoir des notifications des débits à venir dans les 2 jours précédant leur réalisation.",
        @"it" : @"Fornendo i dati di pagamento e confermando il pagamento, l’utente autorizza (A) VideoLAN e Stripe, il fornitore del servizio di pagamento locale, a inviare alla sua banca le istruzioni per eseguire addebiti sul suo conto e (B) la sua banca a effettuare addebiti conformemente a tali istruzioni. L’utente, fra le altre cose, ha diritto a un rimborso dalla banca, in base a termini e condizioni dell’accordo sottoscritto con l’istituto. Il rimborso va richiesto entro otto settimane dalla data dell’addebito sul conto. I diritti dell’utente sono illustrati in una comunicazione riepilogativa che è possibile richiedere alla banca. L’utente accetta di ricevere notifiche per i futuri addebiti fino a due giorni prima che vengano effettuati.",
        @"nl" : @"Door je betaalgegevens door te geven en deze betaling te bevestigen, geef je (A) VideoLAN en Stripe, onze betaaldienst, toestemming om instructies naar je bank te verzenden om het bedrag van je rekening af te schrijven, en (B) geef je je bank toestemming om het bedrag van je rekening af te schrijven conform deze aanwijzingen. Als onderdeel van je rechten kom je in aanmerking voor een terugbetaling van je bank conform de voorwaarden van je overeenkomst met de bank. Je moet terugbetalingen binnen acht weken claimen vanaf de datum waarop het bedrag is afgeschreven van je rekening. Je rechten worden toegelicht in een overzicht dat je bij de bank kunt opvragen. Je gaat ermee akkoord meldingen te ontvangen voor toekomstige afschrijvingen tot twee dagen voordat deze plaatsvinden."
    };
    return authorizationTexts[languageCode];
}

@end
