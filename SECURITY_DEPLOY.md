# TPL Pro production reward security

The app now treats coins, cash balances, referral bonuses, spins, scratches, conversions and withdrawals as server-authoritative operations.

## What is already in code

- Flutter reward mutations call Cloud Functions in `asia-south1`.
- Firestore client rules deny direct user writes to `coins`, `taskCash`, `referCash`, `spinsLeft`, `scratchLeft`, referral fields, transactions and withdrawals.
- Social-task claims are one-time server claims with a server timestamp/session and an 8-second minimum session.
- Spin/scratch counters and spin outcomes are generated server-side.
- Coin conversion and withdrawals are atomic server transactions.
- Referral bonus unlocking is server-side.
- CPAlead rewards use `subid=uid`, `lead_id` idempotency and a Secret Manager postback password.
- Firebase App Check with Android Play Integrity is enabled in the Flutter client and enforced by reward callables.
- Storage banner uploads are admin-only and image/size validated.

## One-time Firebase setup

Cloud Functions require the Firebase project to use the Blaze plan. Firebase documents Cloud Functions deployment and the Blaze prerequisite here:
https://firebase.google.com/docs/functions

### 1. Register Android App Check

Firebase Console -> Security -> App Check -> Apps.

Register the Android app that matches the release APK package. Use the release signing certificate SHA-256 printed by the GitHub Actions Verify APK package and signing step.

Because TPL may be distributed outside Google Play while testing, configure App Check for the intended distribution channel. For a Play + outside-Play setup, do not require `PLAY_RECOGNIZED` unless every installation will come from Google Play.

Firebase Play Integrity/App Check documentation:
https://firebase.google.com/docs/app-check/android/play-integrity-provider

### 2. Add GitHub Actions secrets

Repository -> Settings -> Secrets and variables -> Actions.

Add:

- `FIREBASE_SERVICE_ACCOUNT`: Google Cloud service-account JSON that is allowed to deploy Firebase Functions/rules.
- `CPALEAD_POSTBACK_SECRET`: a long random secret. Use the same value as the CPAlead postback password.

Do not commit either value to the repository.

### 3. Deploy the backend

GitHub -> Actions -> Deploy TPL Firebase Backend -> Run workflow.

This deploys:

- Cloud Functions
- Firestore rules
- Firestore indexes
- Storage rules

The workflow also creates/updates the CPAlead Secret Manager secret.

### 4. Configure CPAlead

Use CPAlead's postback configuration with the deployed HTTPS function URL and:

`subid={subid}&lead_id={lead_id}&payout={payout}&password={password}`

The exact URL is shown by Firebase after deploying `cpaleadPostback`.

CPAlead's current publisher documentation recommends passing your own user reference in `subid`, using `lead_id` for duplicate protection, `payout` as the reward input, and a shared postback password:
https://www.cpalead.com/en/postback/documentation

## Important limitation

A generic Instagram/Telegram URL opening is not proof that the user actually followed/subscribed. The server-side task claim prevents direct balance editing and duplicate claims, but true social verification requires a platform-supported verification API or a verified partner/postback flow. Do not treat app resume alone as proof of a follow/subscribe.

## Testing order

1. Deploy backend/rules.
2. Register App Check and release signing SHA-256.
3. Build/install the new APK.
4. Create a new test account.
5. Complete one task and confirm exactly one reward ledger entry.
6. Try the same task again: no second reward.
7. Try direct Firestore writes to `users/{uid}` economy fields: permission denied.
8. Spin twice in one daily window: second attempt denied.
9. Convert coins concurrently from two clients: only the valid atomic transaction succeeds.
10. Submit a withdrawal: the server re-checks balance atomically so it cannot go negative.
11. Replay the same CPAlead `lead_id`: no second reward.
