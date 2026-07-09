# Premium Lifetime Purchase Setup

This app uses Google Play Billing through Flutter `in_app_purchase`.

## Product

- Product type: **One-time product / Managed product**
- Product ID: `premium_lifetime`
- Consumption: **Non-consumable**

## Google Play Console Setup

1. Open Google Play Console.
2. Select the Gaming Wallpaper app.
3. Go to **Monetize > Products > One-time products**.
4. Create a product with Product ID:
   ```text
   premium_lifetime
   ```
5. Add name, description, and a lifetime price.
6. Activate the product.
7. Upload an Android build signed with the same package name:
   ```text
   com.gamingwalpaper.gamingwalpaper
   ```
8. Publish the build to Internal testing, Closed testing, or Production.

## License Testers

1. In Play Console, go to **Setup > License testing**.
2. Add tester Gmail accounts.
3. Save changes.
4. Install the app from the Play Store internal testing link.
5. Sign in on the device with a tester Gmail account.
6. Open the app and go to **Profile > Go Premium**.
7. Tap **Buy Premium**.

## Restore Purchases

The app restores purchases through Google Play Billing:

- Open **Profile > Go Premium**.
- Tap **Restore Purchases**.
- If Google Play returns a restored `premium_lifetime` purchase, Premium is unlocked again.

## Verification Notes

The app does not trust `SharedPreferences` as the source of truth. Local cache only improves startup speed. Premium is unlocked only after Google Play Billing returns a purchased or restored transaction for `premium_lifetime`.

For highest security, add a backend that verifies `PurchaseDetails.verificationData.serverVerificationData` with the Google Play Developer API and returns a signed entitlement to the app.

## Premium Effects

When Premium is active:

- AdMob banner ads are not loaded or displayed.
- Existing loaded banner ad is disposed.
- Premium wallpapers are unlocked.
- 4K wallpapers are unlocked.
- Future premium restrictions should check `PremiumService.instance.isPremium`.
